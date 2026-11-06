import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationRepository {
  AuthenticationRepository(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await ensureProfile();
  }

  Future<void> register(String name, String email, String password) async {
    final result = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user!.updateDisplayName(name.trim());
    await ensureProfile();
  }

  Future<void> ensureProfile() async {
    final user = auth.currentUser!;
    final profile = db.collection('users').doc(user.uid);
    await db.runTransaction((tx) async {
      if (!(await tx.get(profile)).exists) {
        tx.set(profile, {
          'displayName': (user.displayName ?? 'Little bear').trim(),
          'accessory': 'none',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> reset(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found') rethrow;
    }
  }

  Future<void> logout() async {
    final uid = auth.currentUser?.uid;
    await auth.signOut();
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where(
        (k) => k.startsWith('touch_outbox_${uid}_'),
      )) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> reauthenticate(String password) async {
    final user = auth.currentUser!;
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
  }

  Future<void> changePassword(String current, String next) async {
    if (next.length < 8) throw ArgumentError('Use at least 8 characters.');
    await reauthenticate(current);
    await auth.currentUser!.updatePassword(next);
  }
}

class UserRepository {
  UserRepository(this.db);
  final FirebaseFirestore db;
  Future<void> updateName(String uid, String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 40) {
      throw ArgumentError('Choose a name between 1 and 40 characters.');
    }
    return db.collection('users').doc(uid).update({'displayName': cleaned});
  }

  Future<void> updateAccessory(String uid, String value) =>
      db.collection('users').doc(uid).update({'accessory': value});
}
