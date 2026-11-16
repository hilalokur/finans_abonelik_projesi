class UserProfile {
  final String fullName;
  final String email;
  final String photoUrl;

  const UserProfile({
    required this.fullName,
    required this.email,
    this.photoUrl = '',
  });

  factory UserProfile.empty() =>
      const UserProfile(fullName: 'Demo Kullanıcı', email: 'demo@ornek.com');
}
