import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/providers.dart';
import '../../affection/data/affection_repository.dart';
import '../../affection/domain/models.dart';
import '../domain/touch_intent.dart';

/// A single durable, explicitly submitted intent per account/world. No raw
/// trajectories and no Firestore disk cache. Retries run only while pending.
class TouchEchoRepository extends ChangeNotifier {
  TouchEchoRepository(
    this.affection, {
    String? Function()? currentUid,
    Future<void> Function(String, TouchIntent, String?)? commitTouch,
  }) : _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _commitOverride = commitTouch {
    ready = _restore();
  }
  final String? Function() _currentUid;
  final Future<void> Function(String, TouchIntent, String?)? _commitOverride;
  late final Future<void> ready;
  final AffectionRepository affection;
  TouchFlowState state = TouchFlowState.idle;
  TouchIntent? pendingIntent;
  String? pendingId, replyToEventId;
  Object? error;
  bool _disposed = false, _busy = false;
  int _attempt = 0;
  Timer? _retry;
  String get _key =>
      'touch_outbox_${affection.uid}_${affection.pair.invitationId}';
  CollectionReference<Json> get _moments => affection.collection('moments');
  CollectionReference<Json> get _payloads => affection.collection('payloads');
  String newId() => _moments.doc().id;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool get _authorized => !_disposed && _currentUid() == affection.uid;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_authorized) return;
    final text = prefs.getString(_key);
    if (text == null) return;
    try {
      final d = jsonDecode(text) as Map<String, dynamic>;
      pendingId = d['id'] as String;
      replyToEventId = d['replyToEventId'] as String?;
      pendingIntent = TouchIntent.fromJson(
        Map<String, dynamic>.from(d['touch'] as Map),
      );
      state = TouchFlowState.sendPending;
      _notify();
      unawaited(retry());
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  Future<void> submit(String id, TouchIntent intent, {String? replyTo}) async {
    await ready;
    if (_busy || state == TouchFlowState.sendPending) return;
    if (!_authorized) throw StateError('Sign in to send this touch.');
    pendingId = id;
    pendingIntent = intent;
    replyToEventId = replyTo;
    state = TouchFlowState.sendPending;
    error = null;
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'id': id,
        'touch': intent.toJson(),
        'replyToEventId': replyTo,
      }),
    );
    if (!_authorized) return;
    state = TouchFlowState.sendPending;
    error = null;
    _notify();
    await retry();
  }

  Future<void> retry() async {
    if (_busy || pendingIntent == null || pendingId == null || !_authorized) {
      return;
    }
    _retry?.cancel();
    _busy = true;
    state = TouchFlowState.sendPending;
    error = null;
    _notify();
    final id = pendingId!, intent = pendingIntent!, reply = replyToEventId;
    try {
      if (_commitOverride != null) {
        await _commitOverride(id, intent, reply);
      } else {
        await affection.db.runTransaction((tx) async {
          if (!_authorized) throw StateError('Your session has changed.');
          final pairDoc = await tx.get(affection.db.doc('privatePair/main'));
          final live = pairDoc.data();
          if (live?['status'] != 'active' ||
              live?['invitationId'] != affection.pair.invitationId) {
            throw StateError('This pairing is no longer active.');
          }
          final existing = await tx.get(_moments.doc(id));
          if (existing.exists) {
            final old = await tx.get(_payloads.doc(id));
            final d = old.data();
            // Firestore map ordering is not part of the immutable contract.
            if (d?['touch'] is! Map ||
                !mapEquals(
                  Map<String, dynamic>.from(d!['touch']),
                  intent.toJson(),
                ) ||
                d['replyToEventId'] != reply ||
                existing.data()?['senderUid'] != affection.uid) {
              throw StateError('This touch ID belongs to another draft.');
            }
            return;
          }
          final settings = await tx.get(
            affection
                .collection('touchPreferences')
                .doc(affection.pair.otherUid(affection.uid)),
          );
          if (settings.data()?['receiveTouches'] == false) {
            throw StateError('Your partner has paused Touch Echoes.');
          }
          final rateRef = affection
              .collection('touchSendLimits')
              .doc(affection.uid);
          await tx.get(
            rateRef,
          ); // Rules apply the server-time minimum interval.
          if (!_authorized) throw StateError('Your session has changed.');
          tx.set(_moments.doc(id), {
            'senderUid': affection.uid,
            'receiverUid': affection.pair.otherUid(affection.uid),
            'createdAt': FieldValue.serverTimestamp(),
            'openedAt': null,
            'playedAt': null,
            'genericLabel': 'A little surprise arrived.',
            'kind': 'touch_echo',
          });
          tx.set(_payloads.doc(id), {
            'senderUid': affection.uid,
            'receiverUid': affection.pair.otherUid(affection.uid),
            'interactionType': intent.kind.legacyType.name,
            'animationVariant': intent.style == TouchStyle.playful
                ? 'playful'
                : 'gentle',
            'personalMessage': '',
            'senderBear': affection.pair.bearFor(affection.uid).name,
            'receiverBear': affection.pair.bearFor(affection.uid).other.name,
            'assetVersion': 1,
            'touch': intent.toJson(),
            'replyToEventId': reply,
          });
          tx.set(rateRef, {
            'eventId': id,
            'sentAt': FieldValue.serverTimestamp(),
          });
        }, maxAttempts: 3);
      }
      await (await SharedPreferences.getInstance()).remove(_key);
      if (_disposed) return;
      state = TouchFlowState.sent;
      _attempt = 0;
      pendingIntent = null;
      _notify();
    } catch (e) {
      if (_disposed) return;
      error = e;
      final permanent =
          e is StateError ||
          e is FormatException ||
          (e is FirebaseException &&
              [
                'permission-denied',
                'unauthenticated',
                'invalid-argument',
              ].contains(e.code));
      state = permanent ? TouchFlowState.failed : TouchFlowState.sendPending;
      if (!permanent && _authorized) {
        final seconds = [3, 8, 20, 60][_attempt.clamp(0, 3)];
        _attempt++;
        _retry = Timer(Duration(seconds: seconds), () => unawaited(retry()));
      }
      _notify();
    } finally {
      _busy = false;
    }
  }

  Future<void> discard() async {
    if (_busy) {
      throw StateError('Wait for the current delivery attempt to finish.');
    }
    _retry?.cancel();
    pendingId = null;
    pendingIntent = null;
    replyToEventId = null;
    state = TouchFlowState.idle;
    error = null;
    await (await SharedPreferences.getInstance()).remove(_key);
    _notify();
  }

  Future<void> receiveTouches(bool enabled) => affection
      .collection('touchPreferences')
      .doc(affection.uid)
      .set({'receiveTouches': enabled});
  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    super.dispose();
  }
}

final touchEchoRepositoryProvider = Provider<TouchEchoRepository?>((ref) {
  final repo = ref.watch(affectionRepositoryProvider);
  if (repo == null) return null;
  final touch = TouchEchoRepository(repo);
  ref.onDispose(touch.dispose);
  return touch;
});
final receiveTouchesProvider = StreamProvider.autoDispose<bool>((ref) {
  final repo = ref.watch(affectionRepositoryProvider);
  if (repo == null) return Stream.value(true);
  return repo
      .collection('touchPreferences')
      .doc(repo.uid)
      .snapshots()
      .map((d) => d.data()?['receiveTouches'] != false);
});
