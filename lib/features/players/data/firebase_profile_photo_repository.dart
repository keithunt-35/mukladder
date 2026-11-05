import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseProfilePhotoRepository {
  FirebaseProfilePhotoRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  static const maximumPhotoSizeBytes = 5 * 1024 * 1024;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<String> uploadPhoto({
    required String userId,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty || bytes.length > maximumPhotoSizeBytes) {
      throw ArgumentError.value(
        bytes.length,
        'bytes.length',
        'Choose an image that is no larger than 5 MB.',
      );
    }

    final reference = _storage
        .ref()
        .child('profilePhotos')
        .child(userId)
        .child('profile.jpg');
    final snapshot = await reference.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    if (snapshot.state != TaskState.success) {
      throw StateError('The profile photo upload did not complete.');
    }
    return snapshot.ref.getDownloadURL();
  }

  Future<void> savePhotoUrl({
    required String userId,
    required String displayName,
    required String photoUrl,
  }) async {
    final playerSnapshots = await _firestore
        .collection('players')
        .where('userId', isEqualTo: userId)
        .get();
    final batch = _firestore.batch()
      ..update(_firestore.collection('users').doc(userId), {
        'photoUrl': photoUrl,
        'photoStoragePath': 'profilePhotos/$userId/profile.jpg',
        'updatedAt': FieldValue.serverTimestamp(),
      });

    if (playerSnapshots.docs.isEmpty) {
      batch.set(_firestore.collection('players').doc(userId), {
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'photoStoragePath': 'profilePhotos/$userId/profile.jpg',
        'registrationStatus': 'pending',
        'paymentStatus': 'unknown',
        'active': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      for (final player in playerSnapshots.docs) {
        batch.update(player.reference, {
          'photoUrl': photoUrl,
          'photoStoragePath': 'profilePhotos/$userId/profile.jpg',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }
}
