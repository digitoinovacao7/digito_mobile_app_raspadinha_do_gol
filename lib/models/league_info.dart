class LeagueInfo {
  final int id;
  final String name;
  final String? logoUrl;
  final int? season;

  const LeagueInfo({
    required this.id,
    required this.name,
    this.logoUrl,
    this.season,
  });
}
