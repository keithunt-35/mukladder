class PendingRegistration {
  const PendingRegistration({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.createdAt,
    this.photoUrl,
    this.joinRequestStatus = 'requested',
    this.paymentReference,
  });

  static const membershipFeeUgx = 40000;
  static const membershipFeeDisplay = '40,000';

  final String userId;
  final String displayName;
  final String email;
  final DateTime? createdAt;
  final String? photoUrl;
  final String joinRequestStatus;
  final String? paymentReference;

  bool get paymentReported => joinRequestStatus == 'paymentReported';
}
