import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import 'package:intl/intl.dart';

class TokenHistoryScreen extends ConsumerWidget {
  const TokenHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Extrato de Tokens')),
        body: const Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrato de Tokens'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: Column(
              children: [
                const Text(
                  'Saldo Atual',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '${user.tokens}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('token_transactions')
                  .where('uid', isEqualTo: user.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar extrato: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];
                
                // Ordenação local para evitar necessidade de índice composto no Firebase
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final timeA = dataA['createdAt'] as Timestamp?;
                  final timeB = dataB['createdAt'] as Timestamp?;
                  
                  if (timeA == null && timeB == null) return 0;
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;
                  
                  return timeB.compareTo(timeA); // descending
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Nenhuma transação encontrada.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final amount = data['amount'] as int? ?? 0;
                    final type = data['type'] as String? ?? 'unknown';
                    final description = data['description'] as String? ?? 'Transação';
                    final createdAt = data['createdAt'] as Timestamp?;
                    
                    final dateStr = createdAt != null 
                        ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
                        : 'Data desconhecida';

                    IconData iconData;
                    Color iconColor;
                    Color amountColor;
                    String sign = '';

                    if (type == 'quiz_reward') {
                      iconData = Icons.psychology;
                      iconColor = Colors.green;
                      amountColor = Colors.green;
                      sign = '+';
                    } else if (type == 'quiz_failure') {
                      iconData = Icons.cancel;
                      iconColor = Colors.red;
                      amountColor = Colors.grey;
                    } else if (type == 'prize_redemption' || type == 'pix_withdrawal') {
                      iconData = Icons.shopping_cart;
                      iconColor = Colors.orange;
                      amountColor = Colors.red;
                    } else {
                      iconData = Icons.swap_horiz;
                      iconColor = Colors.grey;
                      amountColor = amount > 0 ? Colors.green : Colors.red;
                      sign = amount > 0 ? '+' : '';
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withOpacity(0.1),
                        child: Icon(iconData, color: iconColor),
                      ),
                      title: Text(description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        '$sign$amount',
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
