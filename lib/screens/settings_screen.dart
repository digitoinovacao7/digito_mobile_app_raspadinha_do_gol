import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import '../core/theme.dart';
import '../core/legal_texts.dart';
import 'legal_text_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<String?> _showPhoneDialog(BuildContext context) async {
    String phone = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Qual seu WhatsApp?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Para receber os alertas, precisamos do seu número com DDD.'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular/WhatsApp',
                  hintText: '(11) 99999-9999',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                onChanged: (val) => phone = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: () => Navigator.pop(context, phone),
              child: const Text('Salvar e Ativar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
                
                // Se está ligando a chavinha e não tem telefone salvo
                if (value && (user.phone == null || user.phone!.trim().isEmpty)) {
                  final phone = await _showPhoneDialog(context);
                  if (phone != null && phone.trim().isNotEmpty) {
                    final updatedUser = user.copyWith(phone: phone.trim(), wantsWhatsappNotifications: true);
                    // Atualiza o perfil com o novo telefone e a chavinha
                    await dbService.updateUserProfile(updatedUser);
                    await dbService.toggleWhatsappNotifications(user.id, true);
                    
                    ref.read(currentUserProvider.notifier).state = updatedUser;
                    ref.invalidate(appUserFutureProvider(user.id));
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp salvo e alertas ativados!')));
                    }
                  }
                  // Se cancelou, não faz nada (chavinha continua desligada)
                } else {
                  // Se já tem telefone ou está apenas desligando
                  final updatedUser = user.copyWith(wantsWhatsappNotifications: value);
                  await dbService.toggleWhatsappNotifications(user.id, value);
                  
                  ref.read(currentUserProvider.notifier).state = updatedUser;
                  ref.invalidate(appUserFutureProvider(user.id));
                }
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalTextScreen(title: 'Regulamento', markdownContent: LegalTexts.regulamento))),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalTextScreen(title: 'Política de Privacidade', markdownContent: LegalTexts.privacidade))),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalTextScreen(title: 'Termos de Uso', markdownContent: LegalTexts.termos))),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Jogo Responsável'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalTextScreen(title: 'Jogo Responsável', markdownContent: LegalTexts.jogoResponsavel))),
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
              final url = Uri.parse('https://www.youtube.com/@digitoinovacao');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Could not launch YouTube: $e');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Colors.pink),
            title: const Text('Instagram'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () async {
              final url = Uri.parse('https://www.instagram.com/digitoinovacaooficial/');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Could not launch Instagram: $e');
              }
            },
          ),
        ],
      ),
    );
  }
}
