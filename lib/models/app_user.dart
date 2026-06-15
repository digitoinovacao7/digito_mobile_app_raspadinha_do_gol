class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'user' or 'admin'
  final int tokens;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.tokens = 0,
  });

  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      tokens: map['tokens'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'tokens': tokens,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    int? tokens,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      tokens: tokens ?? this.tokens,
    );
  }
}
