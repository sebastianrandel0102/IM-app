import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../domain/touch_classifier.dart';
import '../domain/touch_intent.dart';

/// Owns one ephemeral pointer sequence. Boops wait for the double-tap window,
/// while immediate visual feedback is independent of classification callbacks.
class TouchInputController {
  TouchInputController({required this.onResult});
  final ValueChanged<TouchResult> onResult;
  final List<TouchSample> _samples = [];
  int? _pointer;
  TouchZone? zone;
  Timer? _tapTimer;
  TouchResult? _pendingTap;
  TouchSample? _lastTap;
  bool heartMode = false;
  double sensitivity = 1;
  bool get tracking => _pointer != null;
  List<TouchSample> get samples => List.unmodifiable(_samples);
  void begin(int id, TouchZone? hit, Offset point, Duration time) {
    if (tracking) {
      cancel();
      return;
    }
    if (hit == null && !heartMode) return;
    _pointer = id;
    zone = heartMode ? TouchZone.heart : hit;
    _samples.add(TouchSample(point, time));
  }

  bool move(int id, Offset point, Duration time, {required bool inside}) {
    if (id != _pointer) return false;
    if (!inside ||
        _samples.length >= 2048 ||
        (point - _samples.last.point).distance > .65) {
      cancel();
      return false;
    }
    _samples.add(TouchSample(point, time));
    return true;
  }

  void end(int id, Offset point, Duration time, {required bool inside}) {
    if (!move(id, point, time, inside: inside)) return;
    final previous = _lastTap;
    final first = _samples.first;
    final doubleTap =
        _pendingTap != null &&
        previous != null &&
        (first.time - previous.time).inMilliseconds <= 300 &&
        (first.point - previous.point).distance < .18;
    final result = TouchClassifier.classify(
      _samples,
      zone!,
      heartMode: heartMode,
      sensitivity: sensitivity,
      repetitions: doubleTap ? 2 : 1,
    );
    _pointer = null;
    _samples.clear();
    if (result.intent?.kind == TouchKind.noseBoop) {
      if (doubleTap) {
        _tapTimer?.cancel();
        _pendingTap = null;
        _lastTap = null;
        onResult(result);
      } else {
        if (_pendingTap != null) onResult(_pendingTap!);
        _tapTimer?.cancel();
        _pendingTap = result;
        _lastTap = TouchSample(point, time);
        _tapTimer = Timer(const Duration(milliseconds: 300), () {
          final pending = _pendingTap;
          _pendingTap = null;
          _lastTap = null;
          if (pending != null) onResult(pending);
        });
      }
    } else {
      _tapTimer?.cancel();
      _pendingTap = null;
      _lastTap = null;
      onResult(result);
    }
  }

  void cancel() {
    _tapTimer?.cancel();
    _pendingTap = null;
    _lastTap = null;
    final active = tracking;
    _pointer = null;
    _samples.clear();
    zone = null;
    if (active) onResult(const TouchResult(TouchResultKind.canceled));
  }

  void dispose() {
    _tapTimer?.cancel();
    _pendingTap = null;
    _lastTap = null;
    _pointer = null;
    _samples.clear();
  }
}
