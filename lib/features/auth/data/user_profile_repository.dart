import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createPlayerProfile({
    required AppUser user,
    required String email,
  }) {
    return _firestore.collection('users').doc(user.id).set({
      'uid': user.id,
      'displayName': user.displayName,
      'email': email,
      'role': 'player',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser> getCurrentUser(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('The signed-in user profile was not found.');
    }
    return AppUser(
      id: uid,
      displayName: data['displayName'] as String,
      role: switch (data['role']) {
        'admin' => AppRole.admin,
        'treasurer' => AppRole.treasurer,
        _ => AppRole.player,
      },
    );
  }
}
