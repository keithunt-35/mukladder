import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/membership_application_repository.dart';

final membershipApplicationRepositoryProvider =
    Provider<MembershipApplicationRepository>((ref) {
      return MembershipApplicationRepository();
    });
