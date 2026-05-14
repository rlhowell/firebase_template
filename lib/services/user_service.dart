import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

abstract class UserService {
  Stream<UserProfile?> streamProfile(String uid);
  Future<void> createProfileIfAbsent(User user);
  Future<void> updateProfile(String uid, Map<String, dynamic> fields);
}
