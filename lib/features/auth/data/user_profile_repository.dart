import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createPlayerProfile({
    required AppUser user,
    required String email,
  }) async {
    final userReference = _firestore.collection('users').doc(user.id);
    final playerReference = _firestore.collection('players').doc(user.id);
    final batch = _firestore.batch()
      ..set(userReference, {
        'uid': user.id,
        'displayName': user.displayName,
        'email': email,
        'role': 'player',
        'status': 'active',
        'photoUrl': user.photoUrl,
        'photoStoragePath': user.photoUrl == null
            ? null
            : 'profilePhotos/${user.id}/profile.jpg',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(playerReference, {
        'userId': user.id,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'photoStoragePath': user.photoUrl == null
            ? null
            : 'profilePhotos/${user.id}/profile.jpg',
        'registrationStatus': 'pending',
        'paymentStatus': 'unknown',
        'active': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
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
      photoUrl: data['photoUrl'] as String?,
      role: switch (data['role']) {
        'admin' => AppRole.admin,
        'treasurer' => AppRole.treasurer,
        _ => AppRole.player,
      },
    );
  }
}
