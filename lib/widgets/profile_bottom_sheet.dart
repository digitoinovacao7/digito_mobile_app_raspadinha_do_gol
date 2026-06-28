import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../core/auth_wrapper.dart';
import '../screens/settings_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/profile_edit_screen.dart';
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
            leading: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
            title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppTheme.primaryGreen),
            title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
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
                // Fecha o bottom sheet primeiro
                Navigator.of(context).pop();
                
                final authService = ref.read(authServiceProvider);
                
                // Limpa o estado local
                ref.read(currentUserProvider.notifier).state = null;
                
                // Faz o logout (o AuthWrapper na raiz do app vai detectar isso e mandar pro Login automaticamente)
                await authService.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
