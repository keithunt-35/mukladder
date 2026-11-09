enum AppRole {
  player('Player'),
  admin('Admin'),
  treasurer('Treasurer');

  const AppRole(this.label);

  final String label;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.registrationApproved = true,
    this.registrationStatus = 'approved',
    this.joinRequestStatus = 'notRequested',
    this.paymentReference,
  });

  final String id;
  final String displayName;
  final AppRole role;
  final String? photoUrl;
  final bool registrationApproved;
  final String registrationStatus;
  final String joinRequestStatus;
  final String? paymentReference;
}
