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

class _WalletStoreScreenState extends ConsumerState<WalletStoreScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final currentTokens = user?.tokens ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitrine de Prêmios'),
      ),
      body: Column(
        children: [
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
                const Icon(Icons.card_giftcard, color: AppTheme.accentGold, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Jogue as raspadinhas e concorra a estes prêmios incríveis!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
