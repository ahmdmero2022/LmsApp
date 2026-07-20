enum UserRole { student, instructor }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.instructor:
        return 'Instructor';
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? passwordSalt;
  final String? passwordHash;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.passwordSalt,
    this.passwordHash,
  });

  bool get hasPassword => passwordHash != null && passwordSalt != null;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? passwordSalt,
    String? passwordHash,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'passwordSalt': passwordSalt,
      'passwordHash': passwordHash,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.student,
      ),
      passwordSalt: map['passwordSalt'] as String?,
      passwordHash: map['passwordHash'] as String?,
    );
  }
}
