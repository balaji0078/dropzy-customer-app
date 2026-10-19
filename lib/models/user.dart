class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role;
  final String? profileImageUrl;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final s = (f + l).trim();
    return s.isEmpty ? (email.isNotEmpty ? email[0].toUpperCase() : '?') : s.toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: '${j['id'] ?? ''}',
        firstName: j['first_name'] ?? j['firstName'] ?? '',
        lastName: j['last_name'] ?? j['lastName'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone']?.toString(),
        role: j['role'] ?? 'customer',
        profileImageUrl: j['profile_image_url'] ?? j['profileImageUrl'],
      );
}
