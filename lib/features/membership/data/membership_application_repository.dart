import 'package:cloud_functions/cloud_functions.dart';

class MembershipApplicationRepository {
  MembershipApplicationRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<void> requestToJoinLadder() async {
    await _functions.httpsCallable('requestToJoinLadder').call();
  }

  Future<void> reportPayment({required String transactionReference}) async {
    await _functions.httpsCallable('reportLadderPayment').call({
      'transactionReference': transactionReference.trim(),
    });
  }
}
