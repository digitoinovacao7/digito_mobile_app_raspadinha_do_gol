import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import 'profile_edit_screen.dart';

class WalletStoreScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExploreGames;

  const WalletStoreScreen({super.key, this.onExploreGames});

  @override
  ConsumerState<WalletStoreScreen> createState() => _WalletStoreScreenState();
}

class _WalletStoreScreenState extends ConsumerState<WalletStoreScreen> {
  String? _redeemingPrizeId;

  Future<void> _redeemPrize(
    String prizeId,
    Map<String, dynamic> prize,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final cost = (prize['token_cost'] as num?)?.toInt() ?? 0;
    final name = prize['name']?.toString() ?? 'Prêmio';
    if (cost <= 0 || _redeemingPrizeId != null) return;

    if ((user.phone?.trim().isEmpty ?? true) ||
        (user.cpf?.trim().isEmpty ?? true)) {
      final completeProfile = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete seu perfil'),
          content: const Text(
            'Precisamos do seu telefone e CPF para identificar e entregar o prêmio.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Completar perfil'),
            ),
          ],
        ),
      );
      if (completeProfile == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar resgate'),
        content: Text('Resgatar “$name” por $cost tokens?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _redeemingPrizeId = prizeId);
    try {
      final db = DbService();
      await db.redeemPrize(
        user.id,
        cost,
        {
          'uid': user.id,
          'userName': user.name,
          'userEmail': user.email,
          'userPhone': user.phone,
          'userCpf': user.cpf,
          'prizeId': prizeId,
          'prizeName': name,
          'type': prize['type'] ?? 'produto',
          'cost': cost,
          'prizeLink': prize['prize_link'],
          'status': 'pendente',
        },
        name,
      );
      final updatedUser = await db.getUser(user.id);
      if (updatedUser != null) {
        ref.read(currentUserProvider.notifier).state = updatedUser;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resgate solicitado com sucesso!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _redeemingPrizeId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final currentTokens = user?.tokens ?? 0;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: AppTheme.accentGold,
                  size: 42,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Troque seus tokens por prêmios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Seu saldo: $currentTokens tokens',
                    style: const TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('prizes')
                  .where('active', isEqualTo: true)
                  .where('scope', isEqualTo: 'global')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _StoreMessage(
                    icon: Icons.cloud_off,
                    title: 'Não foi possível carregar os prêmios',
                    subtitle: 'Verifique sua conexão e tente novamente.',
                    buttonLabel: 'Ver jogos',
                    onPressed: widget.onExploreGames,
                  );
                }

                final prizes = snapshot.data?.docs ?? [];
                if (prizes.isEmpty) {
                  return _StoreMessage(
                    icon: Icons.card_giftcard_outlined,
                    title: 'Novos prêmios estão chegando',
                    subtitle: 'Enquanto isso, acompanhe os jogos e acumule tokens.',
                    buttonLabel: 'Ver jogos disponíveis',
                    onPressed: widget.onExploreGames,
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: prizes.length,
                  itemBuilder: (context, index) {
                    final doc = prizes[index];
                    final prize = doc.data() as Map<String, dynamic>;
                    final cost = (prize['token_cost'] as num?)?.toInt() ?? 0;
                    final name = prize['name']?.toString() ?? 'Prêmio';
                    final imageUrl = prize['image_url']?.toString() ?? '';
                    final canAfford = currentTokens >= cost;
                    final isRedeeming = _redeemingPrizeId == doc.id;

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ColoredBox(
                              color: Colors.grey.shade100,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.card_giftcard,
                                        size: 52,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.card_giftcard,
                                      size: 52,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cost > 0 ? '$cost tokens' : 'Só na raspadinha',
                                  style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: cost > 0 && canAfford && !isRedeeming
                                        ? () => _redeemPrize(doc.id, prize)
                                        : null,
                                    child: isRedeeming
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            cost <= 0
                                                ? 'Indisponível'
                                                : canAfford
                                                ? 'Resgatar'
                                                : 'Saldo insuficiente',
                                            maxLines: 1,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _StoreMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.sports_soccer),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
