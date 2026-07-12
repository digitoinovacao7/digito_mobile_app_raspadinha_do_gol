class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'user' or 'admin'
  final int tokens;
  final String? phone;
  final String? cpf;
  final Map<String, int> answeredQuizzesCount;
  final bool wantsWhatsappNotifications;
  final int? watchingFixtureId;
  final String? watchingHomeTeam;
  final String? watchingAwayTeam;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.tokens = 0,
    this.phone,
    this.cpf,
    this.answeredQuizzesCount = const {},
    this.wantsWhatsappNotifications = false,
    this.watchingFixtureId,
    this.watchingHomeTeam,
    this.watchingAwayTeam,
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
      answeredQuizzesCount: map['answered_quizzes_count'] != null
          ? Map<String, int>.from(map['answered_quizzes_count'])
          : {},
      wantsWhatsappNotifications: map['wants_whatsapp_notifications'] ?? false,
      watchingFixtureId: map['watching_fixture_id'] is int
          ? map['watching_fixture_id'] as int
          : int.tryParse(map['watching_fixture_id']?.toString() ?? ''),
      watchingHomeTeam: map['watching_home_team'],
      watchingAwayTeam: map['watching_away_team'],
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
      'answered_quizzes_count': answeredQuizzesCount,
      'wants_whatsapp_notifications': wantsWhatsappNotifications,
      if (watchingFixtureId != null) 'watching_fixture_id': watchingFixtureId,
      if (watchingHomeTeam != null) 'watching_home_team': watchingHomeTeam,
      if (watchingAwayTeam != null) 'watching_away_team': watchingAwayTeam,
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
    Map<String, int>? answeredQuizzesCount,
    bool? wantsWhatsappNotifications,
    int? watchingFixtureId,
    String? watchingHomeTeam,
    String? watchingAwayTeam,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      tokens: tokens ?? this.tokens,
      phone: phone ?? this.phone,
      cpf: cpf ?? this.cpf,
      answeredQuizzesCount: answeredQuizzesCount ?? this.answeredQuizzesCount,
      wantsWhatsappNotifications:
          wantsWhatsappNotifications ?? this.wantsWhatsappNotifications,
      watchingFixtureId: watchingFixtureId ?? this.watchingFixtureId,
      watchingHomeTeam: watchingHomeTeam ?? this.watchingHomeTeam,
      watchingAwayTeam: watchingAwayTeam ?? this.watchingAwayTeam,
    );
  }
}
