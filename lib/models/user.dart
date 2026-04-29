class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String city;
  final String? profileImageUrl;
  final bool isActive;
  final bool isVerified;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.city,
    this.profileImageUrl,
    this.isActive = true,
    this.isVerified = false,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      city: json['city'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'city': city,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'isVerified': isVerified,
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? city,
    String? profileImageUrl,
    bool? isActive,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      city: city ?? this.city,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
