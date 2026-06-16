class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'user' or 'admin'
  final int tokens;
  final String? phone;
  final String? cpf;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.tokens = 0,
    this.phone,
    this.cpf,
  });

  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      tokens: map['tokens'] ?? 0,
      phone: map['phone'],
      cpf: map['cpf'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'tokens': tokens,
      if (phone != null) 'phone': phone,
      if (cpf != null) 'cpf': cpf,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    int? tokens,
    String? phone,
    String? cpf,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      tokens: tokens ?? this.tokens,
      phone: phone ?? this.phone,
      cpf: cpf ?? this.cpf,
    );
  }
}
