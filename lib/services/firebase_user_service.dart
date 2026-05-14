import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../utils/app_logger.dart';
import 'user_service.dart';

class FirebaseUserService implements UserService {
  FirebaseUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _kCollection = 'users';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_kCollection);

  @override
  Stream<UserProfile?> streamProfile(String uid) {
    return _col.doc(uid).snapshots().map(
          (snap) => snap.exists ? UserProfile.fromFirestore(snap) : null,
        );
  }

  @override
  Future<void> createProfileIfAbsent(User user) async {
    final doc = await _col.doc(user.uid).get();
    if (doc.exists) return;

    log.i('Creating user profile for ${user.uid}');
    await _col.doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    await _col.doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
