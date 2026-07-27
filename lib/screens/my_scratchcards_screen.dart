import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';

class MyScratchcardsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExploreGames;

  const MyScratchcardsScreen({super.key, this.onExploreGames});

  @override
  ConsumerState<MyScratchcardsScreen> createState() =>
      _MyScratchcardsScreenState();
}

class _MyScratchcardsScreenState extends ConsumerState<MyScratchcardsScreen> {
  int _selectedFilter = 0; // 0 = Todas, 1 = Premiadas, 2 = Não Premiadas

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Você precisa estar logado para ver suas cartelas.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final dbService = DbService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: dbService.getUserScratchHistory(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentGold),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar histórico: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final scratchcards = snapshot.data ?? [];

        // Calcular Estatísticas
        final totalCount = scratchcards.length;
        final wonCards = scratchcards.where((c) {
          final winCount = c['winCount'] as int? ?? 0;
          return winCount >= 3;
        }).toList();
        final wonCount = wonCards.length;
        int totalTokensWon = 0;
        for (final c in wonCards) {
          totalTokensWon += (c['wonTokens'] as int? ?? 0);
        }

        // Filtrar cartelas
        final filteredList = scratchcards.where((c) {
          final winCount = c['winCount'] as int? ?? 0;
          final isWon = winCount >= 3;
          if (_selectedFilter == 1) return isWon;
          if (_selectedFilter == 2) return !isWon;
          return true;
        }).toList();

        return Container(
          color: const Color(0xFF0F172A), // Fundo azul escuro estádio
          child: Column(
            children: [
              // Top Stats Banner
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.style,
                      iconColor: Colors.blueAccent,
                      title: 'Raspadas',
                      value: '$totalCount',
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    _buildStatItem(
                      icon: Icons.emoji_events,
                      iconColor: AppTheme.accentGold,
                      title: 'Premiadas',
                      value: '$wonCount',
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    _buildStatItem(
                      icon: Icons.stars,
                      iconColor: Colors.amber,
                      title: 'Tokens Ganhas',
                      value: '+$totalTokensWon',
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildFilterChip(0, 'Todas ($totalCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, '🏆 Premiadas ($wonCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Outras (${totalCount - wonCount})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Empty State ou Lista
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState(context, totalCount == 0)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final card = filteredList[index];
                          return _buildScratchcardCard(context, card);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(int filterIndex, String label) {
    final isSelected = _selectedFilter == filterIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filterIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentGold
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentGold
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTotalEmpty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.style_outlined,
                size: 64,
                color: AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTotalEmpty
                  ? 'Nenhuma cartela raspada ainda'
                  : 'Nenhuma cartela neste filtro',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTotalEmpty
                  ? 'Acompanhe os jogos ao vivo, acerte as perguntas do quiz e raspe cartelas premiadas!'
                  : 'Tente alterar o filtro acima para visualizar suas outras cartelas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            if (isTotalEmpty && widget.onExploreGames != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  onPressed: widget.onExploreGames,
                  icon: const Icon(Icons.sports_soccer, size: 22),
                  label: const Text(
                    'Ver Jogos Disponíveis',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScratchcardCard(BuildContext context, Map<String, dynamic> card) {
    final winCount = card['winCount'] as int? ?? 0;
    final won = winCount >= 3;
    final dateObj = card['date'];

    String formattedDate = '';
    if (dateObj is Timestamp) {
      formattedDate = DateFormat('dd/MM/yyyy • HH:mm').format(dateObj.toDate());
    }

    final prizeType = card['prizeType'] as String? ?? 'none';
    final wonTokens = card['wonTokens'] as int? ?? 0;

    String prizeText = 'Sem prêmio';
    if (prizeType == 'tokens' && wonTokens > 0) {
      prizeText = '+$wonTokens Tokens';
    } else if (prizeType == 'item') {
      prizeText = 'Prêmio Físico Exclusivo!';
    } else if (won) {
      prizeText = 'Cartela Premiada!';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: won
              ? [
                  const Color(0xFF1E293B),
                  AppTheme.primaryGreen.withValues(alpha: 0.25),
                ]
              : [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: won
              ? AppTheme.accentGold.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: won ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ícone da Cartela
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: won
                    ? AppTheme.accentGold.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: won ? AppTheme.accentGold : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Icon(
                won ? Icons.emoji_events : Icons.sports_soccer,
                color: won ? AppTheme.accentGold : Colors.white54,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Informações da Cartela
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        won ? 'VITORIOSA' : 'TENTATIVA',
                        style: TextStyle(
                          color: won ? AppTheme.accentGold : Colors.white54,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: won
                              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$winCount/3 Bolas',
                          style: TextStyle(
                            color: won ? Colors.greenAccent : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    won ? 'Cartela Premiada 🏆' : 'Raspadinha do Gol',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            // Prêmio / Resultado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (won) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      prizeText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Não premiada',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
