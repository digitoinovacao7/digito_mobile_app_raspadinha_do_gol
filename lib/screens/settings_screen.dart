import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import '../core/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _launchUrl(String path) async {
    final url = Uri.parse('https://raspadinhadogol.web.app$path');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Notificações', style: TextStyle(fontSize: 14, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            activeColor: AppTheme.primaryGreen,
            secondary: const Icon(Icons.wechat, color: Colors.green),
            title: const Text('Receber Alertas no WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Avisaremos você quando rolar prêmios ou começar jogos importantes.'),
            value: user?.wantsWhatsappNotifications ?? false,
            onChanged: (bool value) async {
              if (user != null) {
                final dbService = DbService();
                await dbService.toggleWhatsappNotifications(user.id, value);
                ref.invalidate(appUserFutureProvider(user.id));
              }
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Documentos Legais', style: TextStyle(fontSize: 14, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Regulamento'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('/regulamento'),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('/privacidade'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('/termos'),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Jogo Responsável'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('/jogo-responsavel'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Redes Sociais', style: TextStyle(fontSize: 14, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_fill_outlined, color: Colors.red),
            title: const Text('YouTube'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () async {
              final url = Uri.parse('https://www.youtube.com/@guiadoplayeroficial');
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note, color: Colors.black),
            title: const Text('TikTok'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () async {
              final url = Uri.parse('https://www.tiktok.com/@guiadoplayeroficial');
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}
