class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'user' or 'admin'
  final double balance;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.balance = 0.0,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      balance: (map['balance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'balance': balance,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    double? balance,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      balance: balance ?? this.balance,
    );
  }
}
