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
  });

  final String id;
  final String displayName;
  final AppRole role;
  final String? photoUrl;
}
