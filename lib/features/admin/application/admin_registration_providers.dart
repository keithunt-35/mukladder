import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_admin_points_repository.dart';
import '../data/firestore_admin_registration_repository.dart';
import '../domain/admin_player_points.dart';
import '../domain/pending_registration.dart';

final adminPointsRepositoryProvider = Provider<FirestoreAdminPointsRepository>((
  ref,
) {
  return FirestoreAdminPointsRepository();
});

final adminPlayerPointsProvider = StreamProvider<List<AdminPlayerPoints>>((
  ref,
) {
  return ref.watch(adminPointsRepositoryProvider).watchPlayerPoints();
});

final adminRegistrationRepositoryProvider =
    Provider<FirestoreAdminRegistrationRepository>((ref) {
      return FirestoreAdminRegistrationRepository();
    });

final pendingRegistrationsProvider = StreamProvider<List<PendingRegistration>>((
  ref,
) {
  return ref
      .watch(adminRegistrationRepositoryProvider)
      .watchPendingRegistrations();
});
