import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_treasurer_repository.dart';

final treasurerRepositoryProvider = Provider<FirestoreTreasurerRepository>((
  ref,
) {
  return FirestoreTreasurerRepository();
});

/// Real-time stream of the payment overview used in the Treasurer screen.
final paymentOverviewProvider = StreamProvider<List<TreasurerPlayerEntry>>((
  ref,
) {
  return ref.watch(treasurerRepositoryProvider).watchPaymentOverview();
});
