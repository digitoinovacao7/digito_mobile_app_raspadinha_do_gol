import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import '../widgets/smart_image.dart';

class FavoriteTeamScreen extends ConsumerStatefulWidget {
  const FavoriteTeamScreen({super.key});

  @override
  ConsumerState<FavoriteTeamScreen> createState() => _FavoriteTeamScreenState();
}

class _FavoriteTeamScreenState extends ConsumerState<FavoriteTeamScreen> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> _brasileiraoTeams = [
    {'id': 134, 'name': 'Athletico-PR', 'logo': 'https://media.api-sports.io/football/teams/134.png'},
    {'id': 125, 'name': 'Atlético-GO', 'logo': 'https://media.api-sports.io/football/teams/125.png'},
    {'id': 106, 'name': 'Atlético-MG', 'logo': 'https://media.api-sports.io/football/teams/106.png'},
    {'id': 118, 'name': 'Bahia', 'logo': 'https://media.api-sports.io/football/teams/118.png'},
    {'id': 120, 'name': 'Botafogo', 'logo': 'https://media.api-sports.io/football/teams/120.png'},
    {'id': 131, 'name': 'Corinthians', 'logo': 'https://media.api-sports.io/football/teams/131.png'},
    {'id': 150, 'name': 'Criciúma', 'logo': 'https://media.api-sports.io/football/teams/150.png'},
    {'id': 135, 'name': 'Cruzeiro', 'logo': 'https://media.api-sports.io/football/teams/135.png'},
    {'id': 1193, 'name': 'Cuiabá', 'logo': 'https://media.api-sports.io/football/teams/1193.png'},
    {'id': 127, 'name': 'Flamengo', 'logo': 'https://media.api-sports.io/football/teams/127.png'},
    {'id': 124, 'name': 'Fluminense', 'logo': 'https://media.api-sports.io/football/teams/124.png'},
    {'id': 154, 'name': 'Fortaleza', 'logo': 'https://media.api-sports.io/football/teams/154.png'},
    {'id': 130, 'name': 'Grêmio', 'logo': 'https://media.api-sports.io/football/teams/130.png'},
    {'id': 119, 'name': 'Internacional', 'logo': 'https://media.api-sports.io/football/teams/119.png'},
    {'id': 137, 'name': 'Juventude', 'logo': 'https://media.api-sports.io/football/teams/137.png'},
    {'id': 121, 'name': 'Palmeiras', 'logo': 'https://media.api-sports.io/football/teams/121.png'},
    {'id': 794, 'name': 'Red Bull Bragantino', 'logo': 'https://media.api-sports.io/football/teams/794.png'},
    {'id': 126, 'name': 'São Paulo', 'logo': 'https://media.api-sports.io/football/teams/126.png'},
    {'id': 133, 'name': 'Vasco', 'logo': 'https://media.api-sports.io/football/teams/133.png'},
    {'id': 136, 'name': 'Vitória', 'logo': 'https://media.api-sports.io/football/teams/136.png'},
  ];

  Future<void> _selectTeam(Map<String, dynamic> team) async {
    final auth = ref.read(authServiceProvider);
    final firebaseUser = auth.currentUser;
    final currentUser = ref.read(currentUserProvider);

    if (firebaseUser == null || currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DbService().updateUser(firebaseUser.uid, {
        'favorite_team_id': team['id'],
        'favorite_team_name': team['name'],
      });

      ref.read(currentUserProvider.notifier).state = currentUser.copyWith(
        favoriteTeamId: team['id'],
        favoriteTeamName: team['name'],
      );
      ref.invalidate(appUserFutureProvider(firebaseUser.uid));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${team['name']} definido como Time do Coração!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final favoriteTeamId = currentUser?.favoriteTeamId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time do Coração'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _brasileiraoTeams.length,
              itemBuilder: (context, index) {
                final team = _brasileiraoTeams[index];
                final isSelected = favoriteTeamId == team['id'];

                return InkWell(
                  onTap: () => _selectTeam(team),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (team['logo'] != null)
                          SmartImage(
                            team['logo'],
                            width: 48,
                            height: 48,
                            errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Colors.grey, size: 48),
                          )
                        else
                          const Icon(Icons.shield, color: Colors.grey, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          team['name'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryGreen : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
