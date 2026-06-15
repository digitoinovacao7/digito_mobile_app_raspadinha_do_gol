import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen.withOpacity(0.9),
              AppTheme.primaryGreen,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo & Title
                  const Icon(
                    Icons.sports_soccer,
                    size: 90,
                    color: AppTheme.accentGold,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Raspadinha do Gol',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        const Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diversão com segurança garantida!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Acesse sua conta',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Entrar com Google'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final authService = ref.read(authServiceProvider);
                            final user = await authService.signInWithGoogle();
                            
                            if (user != null) {
                              ref.read(currentUserProvider.notifier).state = user;
                              
                              if (user.isAdmin) {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                              } else {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Falha ao fazer login.')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Ambiente 100% Seguro',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Trust Badges / Footer Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTrustBadge(Icons.security, 'Site Seguro'),
                      const SizedBox(width: 24),
                      _buildTrustBadge(Icons.verified, 'Empresa Verificada'),
                      const SizedBox(width: 24),
                      _buildTrustBadge(Icons.health_and_safety, 'Jogo Responsável'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      final url = Uri.parse('https://raspadinhadogol.web.app');
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Could not launch $url: $e');
                      }
                    },
                    child: const Text(
                      'Visite nosso site',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
