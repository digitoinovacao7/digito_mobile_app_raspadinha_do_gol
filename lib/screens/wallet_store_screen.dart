import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import '../core/theme.dart';
import 'withdraw_screen.dart';
import 'profile_edit_screen.dart';
import 'token_history_screen.dart';

class WalletStoreScreen extends ConsumerStatefulWidget {
  const WalletStoreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WalletStoreScreen> createState() => _WalletStoreScreenState();
}

class _WalletStoreScreenState extends ConsumerState<WalletStoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _redeemPhysicalPrize(Map<String, dynamic> prize, int currentTokens) {
    final cost = prize['token_cost'] as int? ?? 0;
    
    if (currentTokens < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tokens insuficientes para resgatar este prêmio.')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (user.phone == null || user.phone?.isEmpty == true || user.cpf == null || user.cpf?.isEmpty == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Completar Perfil'),
          content: const Text('Para resgatar prêmios físicos, você precisa completar seu cadastro (Telefone e CPF).'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
              },
              child: const Text('Editar Perfil'),
            )
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Resgate'),
        content: Text('Deseja resgatar "${prize['name']}" por $cost Tokens?\n${(prize['prize_link'] != null && prize['prize_link'].toString().isNotEmpty) ? 'Você receberá o link para acessar o seu voucher/prêmio no nosso parceiro.' : 'Nossa equipe entrará em contato via WhatsApp para o envio.'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              try {
                final dbService = DbService();
                await dbService.redeemPrize(user.id, cost, {
                  'userId': user.id,
                  'userName': user.name,
                  'userEmail': user.email,
                  'userPhone': user.phone,
                  'userCpf': user.cpf,
                  'prizeId': prize['id'] ?? 'unknown',
                  'prizeName': prize['name'],
                  'cost': cost,
                  'type': 'physical',
                  'status': 'pendente', // pendente, enviado, rejeitado
                }, prize['name']);
                
                // Optimistic update locally
                ref.read(currentUserProvider.notifier).state = user.copyWith(tokens: user.tokens - cost);

                if (mounted) {
                  final link = prize['prize_link']?.toString() ?? '';
                  if (link.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (ctx2) => AlertDialog(
                        title: const Text('Resgate Concluído!'),
                        content: const Text('Seu cupom/voucher está pronto para ser acessado.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx2);
                            },
                            child: const Text('Fechar'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final url = Uri.parse(link);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: const Text('Acessar Cupom'),
                          )
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resgate solicitado com sucesso! Em breve entraremos em contato.')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao solicitar resgate: $e')),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final currentTokens = user?.tokens ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteira e Loja'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentGold,
          tabs: const [
            Tab(text: 'Saque (PIX)'),
            Tab(text: 'Prêmios Físicos'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Balance
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Saldo Disponível',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 40),
                    const SizedBox(width: 8),
                    Text(
                      '$currentTokens',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TokenHistoryScreen()));
                  },
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Ver Extrato Completo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ABA 1: PIX
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('system_config').doc('general').get(),
                  builder: (context, snapshot) {
                    int tokensPerReal = 100; // Default
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null && data.containsKey('economy')) {
                        final economy = data['economy'] as Map<String, dynamic>;
                        tokensPerReal = economy['tokens_per_real'] ?? 100;
                      }
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pix, size: 80, color: Colors.teal),
                          const SizedBox(height: 24),
                          Text(
                            'Transforme Tokens em Dinheiro Vivo!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'A cada $tokensPerReal Tokens você pode resgatar R\$ 1,00 direto na sua chave PIX de forma instantânea.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => WithdrawScreen(tokensPerReal: tokensPerReal)));
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            ),
                            child: const Text('Fazer Saque PIX'),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                
                // ABA 2: STORE
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('prizes').where('active', isEqualTo: true).where('scope', isEqualTo: 'global').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Erro ao carregar loja.'));
                    }

                    final prizes = snapshot.data?.docs ?? [];

                    if (prizes.isEmpty) {
                      return const Center(
                        child: Text('Nenhum prêmio disponível no momento.'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: prizes.length,
                      itemBuilder: (context, index) {
                        final prize = prizes[index].data() as Map<String, dynamic>;
                        final cost = prize['token_cost'] as int? ?? 0;
                        final name = prize['name'] ?? 'Prêmio';
                        final imageUrl = prize['image_url'] ?? '';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  child: imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: Image.network(imageUrl, fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.image, size: 48, color: Colors.grey),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$cost',
                                          style: const TextStyle(
                                            color: AppTheme.accentGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _redeemPhysicalPrize(prize, currentTokens),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        child: const Text('Resgatar', style: TextStyle(fontSize: 12)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
