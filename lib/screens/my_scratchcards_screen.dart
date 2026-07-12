import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';

class MyScratchcardsScreen extends ConsumerWidget {
  const MyScratchcardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Center(child: Text('Você precisa estar logado.'));
    }

    final dbService = DbService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: dbService.getUserScratchHistory(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar histórico: ${snapshot.error}'));
        }

        final scratchcards = snapshot.data ?? [];

        if (scratchcards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.style_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Você ainda não raspou nenhuma cartela.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                // Banner (Publicidade ou Chamada)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: AppTheme.accentGold, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Participe de mais jogos!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Acompanhe os jogos ao vivo e raspe cartelas durante os eventos da partida para ganhar prêmios.',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scratchcards.length,
          itemBuilder: (context, index) {
            final card = scratchcards[index];
            final winCount = card['winCount'] as int? ?? 0;
            final won = winCount >= 2;
            final dateObj = card['date'];
            
            String formattedDate = '';
            if (dateObj is Timestamp) {
              formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateObj.toDate());
            }

            final prizeType = card['prizeType'] as String? ?? 'none';
            final wonTokens = card['wonTokens'] as int? ?? 0;

            String prizeText = '';
            if (prizeType == 'tokens' && wonTokens > 0) {
              prizeText = '$wonTokens Tokens';
            } else if (prizeType == 'item') {
              prizeText = 'Prêmio Físico';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: won ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey[200],
                  child: Icon(
                    won ? Icons.emoji_events : Icons.mood_bad,
                    color: won ? AppTheme.accentGold : Colors.grey[500],
                  ),
                ),
                title: Text(
                  won ? 'Vitória! (${winCount} bolas)' : 'Não Premiada',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Data: $formattedDate'),
                ),
                trailing: won
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Prêmio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            prizeText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Quase...',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
