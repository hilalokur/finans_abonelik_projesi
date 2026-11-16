import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/user_profile.dart';

class AppAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _firebaseReady = false;

  static Future<void> ensureInitialized() async {
    if (_firebaseReady) {
      return;
    }

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      _firebaseReady = false;
    }
  }

  static Future<UserProfile?> currentUserProfile() async {
    await ensureInitialized();
    if (!_firebaseReady) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final document = await _firestore.collection('users').doc(user.uid).get();
      return UserProfile(
        fullName:
            document.data()?['fullName'] as String? ??
            user.displayName ??
            'Kullanıcı',
        email: user.email ?? '',
      );
    } catch (_) {
      return UserProfile(
        fullName: user.displayName ?? 'Kullanıcı',
        email: user.email ?? '',
      );
    }
  }

  static Future<UserProfile?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await ensureInitialized();

    if (!_firebaseReady) {
      return UserProfile(fullName: 'Demo Kullanıcı', email: email);
    }

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(result.user?.uid)
          .get();
      final data = doc.data() ?? {};

      return UserProfile(
        fullName: (data['fullName'] as String?) ?? 'Kullanıcı',
        email: result.user?.email ?? email,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static Future<UserProfile?> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await ensureInitialized();

    if (!_firebaseReady) {
      return UserProfile(fullName: fullName, email: email);
    }

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _firestore.collection('users').doc(result.user?.uid).set({
        'fullName': fullName,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return UserProfile(fullName: fullName, email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await ensureInitialized();
    if (!_firebaseReady) {
      throw StateError(
        'Demo modunda e-posta ile şifre sıfırlama kullanılamıyor.',
      );
    }
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    await ensureInitialized();
    if (!_firebaseReady) return;
    await _auth.signOut();
  }
}
