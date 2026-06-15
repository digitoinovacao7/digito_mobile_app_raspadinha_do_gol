import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/my_scratchcards_screen.dart';
import '../core/theme.dart';

class ProfileBottomSheet extends ConsumerWidget {
  const ProfileBottomSheet({super.key});

  Future<void> _launchUrl(String path) async {
    final url = Uri.parse('https://raspadinhadogol.web.app$path');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / User Info
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                child: const Icon(Icons.person, size: 36, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Usuário',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user?.isAdmin == true ? Colors.red.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Role: ${user?.role ?? "user"}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: user?.isAdmin == true ? Colors.red.shade800 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${user?.id}',
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // Menu Options
          ListTile(
            leading: const Icon(Icons.style_outlined, color: AppTheme.primaryGreen),
            title: const Text('Minhas Raspadinhas', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyScratchcardsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Regulamento'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              Navigator.pop(context);
              _launchUrl('/regulamento');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              Navigator.pop(context);
              _launchUrl('/privacidade');
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              Navigator.pop(context);
              _launchUrl('/termos');
            },
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Jogo Responsável'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              Navigator.pop(context);
              _launchUrl('/jogo-responsavel');
            },
          ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'Sair da Conta',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                
                if (context.mounted) {
                  // Limpa as rotas e volta para o login
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
