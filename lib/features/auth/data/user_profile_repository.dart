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
    final roleString = switch (user.role) {
      AppRole.admin => 'admin',
      AppRole.treasurer => 'treasurer',
      AppRole.player => 'player',
    };
    final batch = _firestore.batch()
      ..set(userReference, {
        'uid': user.id,
        'displayName': user.displayName,
        'email': email,
        'role': roleString,
        'status': 'active',
        'registrationStatus': user.registrationStatus,
        'joinRequestStatus': user.joinRequestStatus,
        'paymentStatus': 'pending',
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
        'registrationStatus': user.registrationStatus,
        'joinRequestStatus': user.joinRequestStatus,
        'paymentStatus': 'pending',
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
    return _toAppUser(uid, data);
  }

  Future<AppUser> getOrCreateSignedInPlayer({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data != null) {
      return _toAppUser(uid, data);
    }

    final player = AppUser(
      id: uid,
      displayName: displayName.trim().isEmpty
          ? email.split('@').first
          : displayName.trim(),
      role: AppRole.player,
      registrationApproved: false,
      registrationStatus: 'notRequested',
      joinRequestStatus: 'notRequested',
    );
    await createPlayerProfile(user: player, email: email);
    return player;
  }

  Stream<AppUser> watchCurrentUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        throw StateError('The signed-in user profile was not found.');
      }
      return _toAppUser(uid, data);
    });
  }

  Future<void> recordActivity(String uid) async {
    final userReference = _firestore.collection('users').doc(uid);
    final rosterSnapshot = await _firestore
        .collection('players')
        .where('userId', isEqualTo: uid)
        .get();
    final playerReferences = <DocumentReference<Map<String, dynamic>>>{
      ...rosterSnapshot.docs.map((document) => document.reference),
    };
    final ownPlayerReference = _firestore.collection('players').doc(uid);
    if (rosterSnapshot.docs.isEmpty &&
        (await ownPlayerReference.get()).exists) {
      playerReferences.add(ownPlayerReference);
    }

    final batch = _firestore.batch()
      ..update(userReference, {'lastActivityAt': FieldValue.serverTimestamp()});
    for (final reference in playerReferences) {
      batch.update(reference, {'lastActivityAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  AppUser _toAppUser(String uid, Map<String, dynamic> data) {
    final registrationStatus =
        data['registrationStatus'] as String? ?? 'approved';
    return AppUser(
      id: uid,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      registrationApproved: registrationStatus == 'approved',
      registrationStatus: registrationStatus,
      joinRequestStatus:
          data['joinRequestStatus'] as String? ??
          (registrationStatus == 'pending' ? 'requested' : 'notRequested'),
      paymentReference: data['paymentReference'] as String?,
      role: switch (data['role']) {
        'admin' => AppRole.admin,
        'treasurer' => AppRole.treasurer,
        _ => AppRole.player,
      },
    );
  }
}
