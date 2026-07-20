import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'session_state.dart';

class ProfileService {
  ProfileService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    final profile = SessionState.instance.user;
    if (user == null || profile == null || user.uid != profile.uid) {
      throw StateError('No authenticated profile.');
    }

    final normalized = displayName.trim();
    if (normalized.length < 2 || normalized.length > 120) {
      throw ArgumentError('Display name must be between 2 and 120 characters.');
    }

    await user.updateDisplayName(normalized);
    await _db.collection('users').doc(user.uid).set(
      <String, dynamic>{
        'displayName': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    SessionState.instance.updateUser(
      profile.copyWith(displayName: normalized),
    );
  }
}
