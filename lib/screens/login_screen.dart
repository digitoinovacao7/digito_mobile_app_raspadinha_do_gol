import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_soccer,
                size: 100,
                color: AppTheme.accentGold,
              ),
              const SizedBox(height: 24),
              Text(
                'Raspadinha do Gol',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Faça login para ganhar prêmios ao vivo!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Entrar com Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
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
            ],
          ),
        ),
      ),
    );
  }
}
