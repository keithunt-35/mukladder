class Player {
  const Player({
    required this.id,
    required this.displayName,
    required this.lastActivityAt,
    this.photoUrl,
    this.paymentStatus = PaymentStatus.unknown,
    this.active = true,
  }) : assert(id != ''),
       assert(displayName != '');

  final String id;
  final String displayName;
  final DateTime lastActivityAt;
  final String? photoUrl;
  final PaymentStatus paymentStatus;
  final bool active;
}

enum PaymentStatus { unknown, pending, paid, overdue }
