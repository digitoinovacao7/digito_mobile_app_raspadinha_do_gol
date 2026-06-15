import 'package:flutter/material.dart';
import '../core/theme.dart';

class MyScratchcardsScreen extends StatelessWidget {
  const MyScratchcardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dados simulados para validar o design visual
    final List<Map<String, dynamic>> mockScratchcards = [
      {
        'id': '10293',
        'match': 'Flamengo 2 x 0 Vasco',
        'date': 'Hoje, 21:30',
        'won': true,
        'prize': 'R\$ 500,00'
      },
      {
        'id': '10292',
        'match': 'Corinthians 1 x 1 Palmeiras',
        'date': 'Ontem, 16:00',
        'won': false,
        'prize': null
      },
      {
        'id': '10291',
        'match': 'São Paulo 3 x 0 Santos',
        'date': '12/06/2026, 20:00',
        'won': true,
        'prize': 'R\$ 50,00'
      },
      {
        'id': '10290',
        'match': 'Grêmio 1 x 2 Internacional',
        'date': '10/06/2026, 18:30',
        'won': false,
        'prize': null
      },
    ];

    final body = mockScratchcards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Você ainda não raspou nenhuma cartela.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockScratchcards.length,
              itemBuilder: (context, index) {
                final card = mockScratchcards[index];
                final won = card['won'] as bool;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: won ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.grey[200],
                      child: Icon(
                        won ? Icons.emoji_events : Icons.close,
                        color: won ? AppTheme.accentGold : Colors.grey[500],
                      ),
                    ),
                    title: Text(
                      card['match'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Data: ${card['date']}'),
                    ),
                    trailing: won
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Prêmio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                card['prize'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Não Premiada',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                  ),
                );
              },
            );

    return body;
  }
}
