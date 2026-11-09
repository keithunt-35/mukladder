import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_admin_overview_repository.dart';
import '../domain/admin_overview.dart';

final adminOverviewProvider = FutureProvider<AdminOverview>((ref) {
  return FirestoreAdminOverviewRepository().getOverview();
});
