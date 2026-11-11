import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../core/theme.dart';
import '../providers/game_provider.dart';
import '../models/league_info.dart';
import 'admin_bolao_manager.dart';
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _apiFootballController = TextEditingController();
  final _mercadoPagoController = TextEditingController();
  final _zApiController = TextEditingController();
  final _geminiApiController = TextEditingController();
  final _scratchcardCostController = TextEditingController();
  final _quizRewardController = TextEditingController();
  final _dailyQuizLimitController = TextEditingController();
  final _globalWinChanceController = TextEditingController();
  final _newPrizeNameCtrl = TextEditingController();
  final _newPrizeImageCtrl = TextEditingController();
  final _newPrizeTokenCostCtrl = TextEditingController();
  final _newPrizeLinkCtrl = TextEditingController();
  final _monthlyUsersCtrl = TextEditingController(text: '1000');
  final _adImpressionsCtrl = TextEditingController(text: '30');
  final _adEcpmCtrl = TextEditingController(text: '5,00');
  final _otherRevenueCtrl = TextEditingController(text: '0');
  final _monthlyPrizeCostCtrl = TextEditingController(text: '500');
  final _monthlyOperationCostCtrl = TextEditingController(text: '300');
  String _newPrizeType = 'produto'; // Prêmios 100% físicos e oficiais
  String _newPrizeScope = 'global'; // 'global', 'league', 'match'
  int? _selectedLeagueId;
  int? _selectedFixtureId;
  List<dynamic> _fetchedMatches = [];
  bool _isFetchingMatches = false;
  List<LeagueInfo> _activeLeagues = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingPrize = false;
  bool _isSyncingShopisa = false;

  final _newSponsorNameCtrl = TextEditingController();
  final _newSponsorLogoCtrl = TextEditingController();
  final _newSponsorLinkCtrl = TextEditingController();
  final _newSponsorOrderCtrl = TextEditingController(text: '0');
  bool _isSavingSponsor = false;
  final _simTeamCtrl = TextEditingController(text: 'Atlético Mineiro');
  final _simOpponentCtrl = TextEditingController(text: 'Cruzeiro');
  bool _isSimulatingGoal = false;
  final ValueNotifier<int> _sectionRevision = ValueNotifier<int>(0);

  final _userSearchCtrl = TextEditingController();
  String _userSearchQuery = '';

  // Estatísticas em tempo real para a Home do Painel Admin
  int _totalUsersCount = 0;
  int _totalBoloesCount = 0;
  double _totalBoloesPot = 0.0;
  int _totalPrizesCount = 0;
  int _pendingRedemptionsCount = 0;
  int _completedRedemptionsCount = 0;
  int _productPrizesCount = 0;
  bool _isLoadingDashboardStats = false;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _sectionRevision.value++;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    setState(() => _isLoadingDashboardStats = true);
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Total de Usuários
      try {
        final usersCountSnap = await firestore.collection('users').count().get();
        _totalUsersCount = usersCountSnap.count ?? 0;
      } catch (_) {}

      // 2. Bolões e Pote Total
      try {
        final boloesSnap = await firestore.collection('boloes').get();
        _totalBoloesCount = boloesSnap.size;
        double potSum = 0.0;
        for (final doc in boloesSnap.docs) {
          final data = doc.data();
          final count = (data['participantsCount'] as num?)?.toInt() ?? 0;
          final feeStr = data['entryFee']?.toString().replaceAll(',', '.') ?? '0';
          final fee = double.tryParse(feeStr) ?? 0.0;
          potSum += (count * fee);
        }
        _totalBoloesPot = potSum;
      } catch (_) {}

      // 3. Prêmios Cadastrados
      try {
        final prizesSnap = await firestore.collection('prizes').get();
        _totalPrizesCount = prizesSnap.size;
        _productPrizesCount = prizesSnap.size;
      } catch (_) {}

      // 4. Resgates (Pendentes vs Concluídos)
      try {
        final redemptionsSnap = await firestore.collection('redemptions').get();
        int pending = 0;
        int completed = 0;
        for (final doc in redemptionsSnap.docs) {
          final status = doc.data()['status']?.toString().toLowerCase() ?? '';
          if (status == 'completed' || status == 'approved' || status == 'pago') {
            completed++;
          } else {
            pending++;
          }
        }
        _pendingRedemptionsCount = pending;
        _completedRedemptionsCount = completed;
      } catch (_) {}
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas do dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDashboardStats = false);
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .get();

      if (docSnap.exists) {
        final data = docSnap.data() ?? {};

        final apiKeys = (data['api_keys'] as Map<String, dynamic>?) ?? {};

        _apiFootballController.text =
            apiKeys['api_football']?.toString() ??
            data['api_football_key']?.toString() ??
            data['api_football']?.toString() ??
            '';
        _mercadoPagoController.text =
            apiKeys['mercado_pago']?.toString() ??
            data['mercado_pago_key']?.toString() ??
            data['mercado_pago']?.toString() ??
            '';
        _zApiController.text =
            apiKeys['z_api']?.toString() ??
            data['z_api_key']?.toString() ??
            data['z_api']?.toString() ??
            '';
        _geminiApiController.text =
            apiKeys['gemini']?.toString() ??
            data['gemini_api_key']?.toString() ??
            data['gemini_key']?.toString() ??
            data['gemini']?.toString() ??
            '';

        if (data.containsKey('economy')) {
          final economy = data['economy'] as Map<String, dynamic>;
          _scratchcardCostController.text =
              economy['scratchcard_token_cost']?.toString() ?? '1000';
          _quizRewardController.text =
              economy['quiz_reward']?.toString() ?? '250';
          _dailyQuizLimitController.text =
              economy['daily_quiz_limit']?.toString() ?? '3';
        }

        if (data.containsKey('prize_rules')) {
          _globalWinChanceController.text =
              data['prize_rules']['global_win_chance']?.toString() ?? '10';
        }

      }



      // Usa exatamente a mesma lista de campeonatos principais exibida na Home.
      final service = ref.read(footballServiceProvider);
      final leagues = await service.getPopularLeagues();
      if (mounted) {
        _activeLeagues = leagues;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar configurações: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _apiFootballController.dispose();
    _mercadoPagoController.dispose();
    _zApiController.dispose();
    _geminiApiController.dispose();
    _scratchcardCostController.dispose();
    _quizRewardController.dispose();
    _dailyQuizLimitController.dispose();
    _globalWinChanceController.dispose();
    _newPrizeNameCtrl.dispose();
    _newPrizeImageCtrl.dispose();
    _newPrizeTokenCostCtrl.dispose();
    _newPrizeLinkCtrl.dispose();
    _monthlyUsersCtrl.dispose();
    _adImpressionsCtrl.dispose();
    _adEcpmCtrl.dispose();
    _otherRevenueCtrl.dispose();
    _monthlyPrizeCostCtrl.dispose();
    _monthlyOperationCostCtrl.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .set({
            'active_football_api': 'api_football',
            'api_keys': {
              'api_football': _apiFootballController.text,
              'mercado_pago': _mercadoPagoController.text,
              'z_api': _zApiController.text,
              'gemini': _geminiApiController.text,
            },
            'economy': {
              'scratchcard_token_cost':
                  int.tryParse(_scratchcardCostController.text) ?? 1000,
              'quiz_reward': int.tryParse(_quizRewardController.text) ?? 250,
              'daily_quiz_limit':
                  int.tryParse(_dailyQuizLimitController.text) ?? 3,
            },
            'prize_rules': {
              'global_win_chance':
                  int.tryParse(_globalWinChanceController.text) ?? 10,
            },
          }, SetOptions(merge: true));



      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openAdminSection(String title, Widget Function() contentBuilder) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ValueListenableBuilder<int>(
        valueListenable: _sectionRevision,
        builder: (context, _, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primaryGreen,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: contentBuilder(),
          );
        },
      );
    }));
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigShortcutTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryGreen,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSettings();
          await _loadDashboardStats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header com Status Geral e Boas-Vindas
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF041D10), Color(0xFF07301A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  '⚽ Painel Executivo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGold,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isLoadingDashboardStats
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.refresh, size: 16),
                              label: const Text('Atualizar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: _isLoadingDashboardStats ? null : _loadDashboardStats,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Indicadores em tempo real, inteligência de receita e atalhos de configuração.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sports_soccer, size: 14, color: AppTheme.accentGold),
                                  SizedBox(width: 6),
                                  Text(
                                    'API: API-Football (Exclusiva)',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.smart_toy, size: 14, color: Colors.lightGreenAccent),
                                  SizedBox(width: 6),
                                  Text(
                                    'IA Gemini: Ativa',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: Colors.amber),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sem Apostas / 100% Legal',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Grid de KPIs Principais
                  GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.4 : 1.15,
                    children: [
                      _buildKpiCard(
                        title: 'Torcedores',
                        value: '$_totalUsersCount',
                        subtitle: 'Usuários cadastrados',
                        icon: Icons.people_alt_outlined,
                        color: Colors.blue,
                        onTap: () => _openAdminSection('Torcedores Cadastrados', _buildUsersTab),
                      ),
                      _buildKpiCard(
                        title: 'Bolões do Gol',
                        value: 'R\$ ${_totalBoloesPot.toStringAsFixed(0)}',
                        subtitle: '$_totalBoloesCount bolões criados',
                        icon: Icons.sports_soccer,
                        color: Colors.teal,
                        onTap: () => _openAdminSection('Gestão de Bolões', () => const AdminBolaoManager()),
                      ),
                      _buildKpiCard(
                        title: 'Prêmios Ativos',
                        value: '$_totalPrizesCount itens',
                        subtitle: '$_productPrizesCount Produtos Físicos / Parceiros',
                        icon: Icons.card_giftcard,
                        color: Colors.amber.shade800,
                        onTap: () => _openAdminSection('Gerenciar Prêmios', _buildPrizesTab),
                      ),
                      _buildKpiCard(
                        title: 'Resgates',
                        value: '$_pendingRedemptionsCount pendentes',
                        subtitle: '$_completedRedemptionsCount concluídos',
                        icon: Icons.receipt_long,
                        color: Colors.orange,
                        onTap: () => _openAdminSection('Resgates', _buildRedemptionsTab),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. Seção de Atalhos Rápidos e Configurações
                  const Text(
                    '⚙️ Atalhos de Configuração da Plataforma',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Column(
                    children: [
                      _buildConfigShortcutTile(
                        title: 'Torcedores Cadastrados',
                        subtitle: 'Lista completa de usuários, saldos em moedas e reais, times do coração e concessão de bônus',
                        icon: Icons.people_alt,
                        color: Colors.blue.shade700,
                        badgeText: 'Torcedores',
                        onTap: () => _openAdminSection('Torcedores Cadastrados', _buildUsersTab),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigShortcutTile(
                        title: 'Regras de Economia',
                        subtitle: 'Tokens por real, custo da cartela, limites diários de quiz e chance global de vitória',
                        icon: Icons.settings_applications,
                        color: Colors.teal.shade700,
                        badgeText: 'Economia',
                        onTap: () => _openAdminSection('Regras de Economia', _buildRulesTab),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigShortcutTile(
                        title: 'Gerenciar Prêmios',
                        subtitle: 'Cadastrar camisas oficiais, bolas, vale-compras e produtos parceiros',
                        icon: Icons.stars,
                        color: Colors.amber.shade800,
                        badgeText: 'Raspadinha & Loja',
                        onTap: () => _openAdminSection('Gerenciar Prêmios', _buildPrizesTab),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigShortcutTile(
                        title: 'Gestão de Bolões',
                        subtitle: 'Acompanhar bolões da galera e de bares, participantes e apuração automática ao apito final',
                        icon: Icons.sports_soccer,
                        color: Colors.indigo.shade700,
                        badgeText: 'Amigos & Bares',
                        onTap: () => _openAdminSection('Gestão de Bolões', () => const AdminBolaoManager()),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigShortcutTile(
                        title: 'Patrocinadores & Parceiros',
                        subtitle: 'Logos e banners oficiais exibidos no carrossel do aplicativo e landing page web',
                        icon: Icons.handshake,
                        color: Colors.blue.shade700,
                        badgeText: 'Parcerias',
                        onTap: () => _openAdminSection('Patrocinadores', _buildSponsorsTab),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigShortcutTile(
                        title: 'Integrações e APIs',
                        subtitle: 'Chaves da Football-Data.org, Google Gemini IA (Quizzes), Z-API WhatsApp e Mercado Pago',
                        icon: Icons.api,
                        color: Colors.purple.shade700,
                        badgeText: 'Conexões',
                        onTap: () => _openAdminSection('Integrações', _buildIntegrationsTab),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigShortcutTile(
                        title: 'Fila de Resgates de Prêmios',
                        subtitle: 'Gerenciar envios de prêmios e rastrear entrega de camisas e produtos aos ganhadores',
                        icon: Icons.receipt_long,
                        color: Colors.orange.shade700,
                        badgeText: 'Entregas',
                        onTap: () => _openAdminSection('Resgates', _buildRedemptionsTab),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigShortcutTile(
                        title: 'Chamados de Suporte',
                        subtitle: 'Mensagens, dúvidas e solicitações enviadas pelos torcedores pelo formulário do site oficial',
                        icon: Icons.support_agent,
                        color: Colors.deepOrange.shade700,
                        badgeText: 'Atendimento',
                        onTap: () => _openAdminSection('Chamados de Suporte', _buildSupportTicketsTab),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigShortcutTile(
                        title: 'Simulador de Lucro e Métricas',
                        subtitle: 'Calculadora completa de faturamento com anúncios AdMob, eCPM e ponto de equilíbrio',
                        icon: Icons.trending_up,
                        color: Colors.green.shade700,
                        badgeText: 'Rentabilidade',
                        onTap: () => _openAdminSection('Lucro', _buildProfitGuideTab),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildIntegrationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        Icons.api,
                        'Provedor de Futebol (API-Football)',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Provedor oficial: API-Football (cobre Copa do Brasil, Sul-Americana, Brasileirão Série A/B, Libertadores e ligas internacionais).',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        Icons.vpn_key,
                        'Chaves de Integração',
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _apiFootballController,
                        label: 'Chave API-Football (x-apisports-key)',
                        hint: 'Insira sua chave do API-Sports',
                        helpText: 'Obtenha em dashboard.api-football.com.',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://dashboard.api-football.com/'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text(
                            'Obter Chave no Dashboard da API-Football',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _geminiApiController,
                        label: 'Chave Gemini (Google IA)',
                        hint: 'Usada para gerar os Quizzes do jogo',
                        helpText:
                            'Chave da API do Google Gemini. Necessária para a Inteligência Artificial gerar perguntas sobre futebol em tempo real. Obtenha no Google AI Studio.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _mercadoPagoController,
                        label: 'Chave Mercado Pago',
                        hint:
                            'Usada para cobranças e checkout (Futuro)',
                        helpText:
                            'Chave da API do Mercado Pago. Mantida para cobranças ou pacotes de tokens via checkout seguro.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _zApiController,
                        label: 'Chave Z-API',
                        hint: 'Usada para notificações via WhatsApp',
                        helpText:
                            'Chave de instância da Z-API. Necessária para enviar comprovantes e notificações de premiação diretamente no WhatsApp do ganhador.',
                      ),

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                ),
                color: const Color(0xFF0F291E),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.sports_soccer, color: Colors.black, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Simular Gol do Time do Coração',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Toca o áudio oficial (goal.wav) no app e notifica os torcedores no WhatsApp!',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _simTeamCtrl,
                        label: 'Time que marcou o gol',
                        hint: 'Ex: Atlético Mineiro, Flamengo, Corinthians',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _simOpponentCtrl,
                        label: 'Adversário',
                        hint: 'Ex: Cruzeiro, Vasco, Palmeiras',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBF24),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isSimulatingGoal
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.campaign, size: 22),
                          label: Text(
                            _isSimulatingGoal ? 'Disparando...' : '⚽ Disparar Gol de Teste',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onPressed: _isSimulatingGoal ? null : _simulateGoalNotification,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simulateGoalNotification() async {
    final team = _simTeamCtrl.text.trim();
    final opponent = _simOpponentCtrl.text.trim();
    if (team.isEmpty) return;

    setState(() => _isSimulatingGoal = true);
    try {
      // 1. Grava no recent_goals para acionar o som goal.wav no app
      await FirebaseFirestore.instance.collection('recent_goals').add({
        'fixtureId': 999999,
        'scoringTeam': team,
        'homeTeamName': team,
        'awayTeamName': opponent.isEmpty ? 'Adversário' : opponent,
        'homeScore': 1,
        'awayScore': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Chama a Cloud Function para disparar WhatsApp aos torcedores
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('triggerGoalNotification');
        final res = await callable.call({
          'teamName': team,
          'opponentName': opponent,
          'homeScore': 1,
          'awayScore': 0,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.data['message']?.toString() ?? 'Gol disparado com sucesso!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } catch (fErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gol acionado no app! (Notificação WhatsApp: $fErr)'),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao simular gol: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSimulatingGoal = false);
      }
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Salvando...' : 'Salvar Configurações'),
        onPressed: _isSaving ? null : _saveSettings,
      ),
    );
  }

  double _profitNumber(TextEditingController controller) {
    return double.tryParse(
          controller.text.trim().replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
  }

  String _brl(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  Widget _buildProfitGuideTab() {
    final users = _profitNumber(_monthlyUsersCtrl);
    final impressionsPerUser = _profitNumber(_adImpressionsCtrl);
    final ecpm = _profitNumber(_adEcpmCtrl);
    final otherRevenue = _profitNumber(_otherRevenueCtrl);
    final prizeCost = _profitNumber(_monthlyPrizeCostCtrl);
    final operationCost = _profitNumber(_monthlyOperationCostCtrl);
    final adRevenue = users * impressionsPerUser / 1000 * ecpm;
    final totalRevenue = adRevenue + otherRevenue;
    final totalCost = prizeCost + operationCost;
    final estimatedProfit = totalRevenue - totalCost;
    final adRevenuePerUser = impressionsPerUser / 1000 * ecpm;
    final breakEvenUsers = adRevenuePerUser > 0
        ? ((totalCost - otherRevenue).clamp(0, double.infinity) /
                  adRevenuePerUser)
              .ceil()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        Icons.account_balance_wallet_outlined,
                        'Como este app pode gerar lucro',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Lucro = receitas de anúncios, patrocínios e afiliados − prêmios, APIs, infraestrutura, impostos e divulgação.',
                        style: TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      _buildRevenueGuideItem(
                        icon: Icons.ads_click,
                        title: '1. Anúncios AdMob — já implementado',
                        description:
                            'A Home possui anúncio nativo e vídeo recompensado. A receita cresce com usuários ativos e impressões válidas. Nunca incentive cliques; recompense apenas a visualização permitida pela política do AdMob.',
                        color: Colors.green,
                      ),
                      _buildRevenueGuideItem(
                        icon: Icons.handshake_outlined,
                        title: '2. Prêmios patrocinados — operação comercial',
                        description:
                            'Negocie com lojas, clubes e marcas para que forneçam o prêmio ou paguem pela exposição. Cadastre o item como Global / Loja e identifique a campanha no nome.',
                        color: Colors.blue,
                      ),
                      _buildRevenueGuideItem(
                        icon: Icons.link,
                        title: '3. Links de afiliado — parcialmente preparado',
                        description:
                            'O cadastro já guarda o link afiliado, mas ainda é necessário definir onde ele será apresentado e medir cliques/conversões antes de considerar essa receita.',
                        color: Colors.orange,
                      ),
                      _buildRevenueGuideItem(
                        icon: Icons.token_outlined,
                        title: '4. Venda de tokens — ainda não implementada',
                        description:
                            'Só ofereça pacotes depois de implementar pagamento, confirmação no servidor, restauração e regras das lojas. Não conte tokens gratuitos como receita.',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        Icons.calculate_outlined,
                        'Simulador mensal',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use os valores reais dos painéis do AdMob, Firebase e fornecedores. A simulação não garante resultado.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth > 650
                              ? (constraints.maxWidth - 16) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _profitField(
                                width,
                                _monthlyUsersCtrl,
                                'Usuários ativos/mês',
                              ),
                              _profitField(
                                width,
                                _adImpressionsCtrl,
                                'Impressões por usuário/mês',
                              ),
                              _profitField(
                                width,
                                _adEcpmCtrl,
                                'eCPM médio dos anúncios (R\$)',
                              ),
                              _profitField(
                                width,
                                _otherRevenueCtrl,
                                'Patrocínios e afiliados (R\$)',
                              ),
                              _profitField(
                                width,
                                _monthlyPrizeCostCtrl,
                                'Custo mensal dos prêmios (R\$)',
                              ),
                              _profitField(
                                width,
                                _monthlyOperationCostCtrl,
                                'APIs, infraestrutura e divulgação (R\$)',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildProfitMetric(
                            'Receita de anúncios',
                            _brl(adRevenue),
                            Colors.blue,
                          ),
                          _buildProfitMetric(
                            'Receita total',
                            _brl(totalRevenue),
                            Colors.green,
                          ),
                          _buildProfitMetric(
                            'Custos',
                            _brl(totalCost),
                            Colors.orange,
                          ),
                          _buildProfitMetric(
                            estimatedProfit >= 0 ? 'Lucro estimado' : 'Prejuízo estimado',
                            _brl(estimatedProfit),
                            estimatedProfit >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          adRevenuePerUser <= 0
                              ? 'Informe impressões e eCPM para calcular o ponto de equilíbrio.'
                              : 'Com esses valores, o ponto de equilíbrio por anúncios é aproximadamente $breakEvenUsers usuários ativos por mês.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.checklist, 'Ordem recomendada'),
                      const SizedBox(height: 16),
                      const Text(
                        '1. Medir usuários ativos, retenção e impressões no Firebase/AdMob.\n'
                        '2. Limitar o custo mensal máximo de prêmios.\n'
                        '3. Buscar prêmios patrocinados antes de pagar estoque próprio.\n'
                        '4. Comparar receita real com custos toda semana.\n'
                        '5. Só aumentar a chance de vitória quando a margem permitir.\n'
                        '6. Validar regras fiscais, promoções comerciais, jogos e políticas da Google Play/App Store antes de envolver dinheiro ou prêmios em escala.',
                        style: TextStyle(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profitField(
    double width,
    TextEditingController controller,
    String label,
  ) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildRevenueGuideItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitMetric(String label, String value, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        Icons.monetization_on,
                        'Regra de Economia',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Defina os custos, recompensas e a chance global de um usuário ser premiado na raspadinha (Sorteio RNG).',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      _buildTextField(
                        controller: _scratchcardCostController,
                        label: 'Custo da Raspadinha',
                        hint: 'Ex: 1000',
                        keyboardType: TextInputType.number,
                        helpText:
                            'Tokens descontados do saldo do usuário para raspar 1 vez.\nSugestão: 1000 (Assim o usuário precisa acertar 4 quizzes para ter o direito de jogar).',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _quizRewardController,
                        label: 'Prêmio por Acerto',
                        hint: 'Ex: 100',
                        keyboardType: TextInputType.number,
                        helpText:
                            'Tokens ganhos DE GRAÇA ao acertar a pergunta da IA durante o jogo ao vivo.\nSugestão: 100 (Gera dopamina de ganho rápido).',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _globalWinChanceController,
                        label: 'Chance de Vitória (%)',
                        hint: 'Ex: 10',
                        keyboardType: TextInputType.number,
                        helpText:
                            'A probabilidade global (RNG) de qualquer raspadinha ser premiada.\nEx: 10 significa que 10% das jogadas ganharão um dos prêmios ativos.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _dailyQuizLimitController,
                        label: 'Limite Diário de Quizzes',
                        hint: 'Ex: 3',
                        keyboardType: TextInputType.number,
                        helpText:
                            'Quantidade máxima de quizzes que um usuário pode gerar por dia (para controle de custos da API do Gemini). Digite 0 para quizzes ilimitados.',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isSaving ? 'Salvando...' : 'Salvar Regras',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveSettings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrizesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        Icons.add_circle_outline,
                        'Adicionar Prêmio da Raspadinha & Loja',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Cadastre os prêmios físicos e produtos oficiais que podem sair na raspadinha ou serem resgatados na loja com Tokens.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      _buildPrizeForm(),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront, color: Colors.purple, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Integração Shopisa (E-commerce)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sincroniza os produtos marcados como prêmio na loja Shopisa para a vitrine da Raspadinha do Gol.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _isSyncingShopisa ? null : _syncShopisaPrizes,
                        icon: _isSyncingShopisa
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.sync),
                        label: Text(_isSyncingShopisa ? 'Sincronizando...' : 'Sincronizar Shopisa'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        Icons.card_giftcard,
                        'Prêmios Cadastrados',
                      ),
                      const SizedBox(height: 24),
                      _buildPrizesList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncShopisaPrizes() async {
    setState(() => _isSyncingShopisa = true);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
          .httpsCallable('syncShopisaPrizes');
      final result = await callable.call();
      final data = result.data as Map<dynamic, dynamic>? ?? {};
      final count = data['count'] ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count prêmios sincronizados com a Shopisa com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sincronizar com a Shopisa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingShopisa = false);
    }
  }

  void _applyPreset({
    required String name,
    required String type,
    required String scope,
    required int tokenCost,
    required String imageUrl,
    required String prizeLink,
  }) {
    setState(() {
      _newPrizeNameCtrl.text = name;
      _newPrizeType = type;
      _newPrizeScope = scope;
      _newPrizeTokenCostCtrl.text = tokenCost.toString();
      _newPrizeImageCtrl.text = imageUrl;
      _newPrizeLinkCtrl.text = prizeLink;
      _selectedLeagueId = null;
      _selectedFixtureId = null;
      _fetchedMatches = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modelo "$name" aplicado! Clique em Adicionar Prêmio para confirmar.'),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generatePrizeWithAI() async {
    final apiKey = _geminiApiController.text;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configure a chave do Gemini nas Regras de Economia!')),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        data: {
          "contents": [{
            "parts": [{"text": "Gere um prêmio fictício muito criativo para um bolão de futebol ou raspadinha (ex: 'Camisa Autografada', 'Vale Ifood R\$ 100', '1 Ano de Cerveja'). Retorne APENAS um JSON no formato exato: {\"name\": \"Nome do Prêmio\", \"type\": \"produto\", \"value\": 100, \"imageUrl\": \"\"}"}]
          }],
          "generationConfig": {"responseMimeType": "application/json"}
        }
      );
      
      final text = response.data['candidates'][0]['content']['parts'][0]['text'];
      final jsonResponse = jsonDecode(text);
      
      _applyPreset(
        name: jsonResponse['name']?.toString() ?? 'Prêmio Surpresa',
        type: jsonResponse['type']?.toString() ?? 'produto',
        scope: 'global',
        tokenCost: 0,
        imageUrl: jsonResponse['imageUrl']?.toString() ?? '',
        prizeLink: '',
      );
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar prêmio com IA: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildPrizeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: Colors.amber, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Preenchimento Rápido (1 Clique)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.checkroom, size: 16, color: Colors.deepOrange),
                    label: const Text('Camisa Oficial'),
                    backgroundColor: Colors.white,
                    onPressed: () => _applyPreset(
                      name: 'Camisa Oficial do Seu Time',
                      type: 'produto',
                      scope: 'global',
                      tokenCost: 0,
                      imageUrl: 'https://images.unsplash.com/photo-1577212017184-80cc0da11082?auto=format&fit=crop&w=400&q=80',
                      prizeLink: '',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.sports_soccer, size: 16, color: Colors.blue),
                    label: const Text('Bola Oficial'),
                    backgroundColor: Colors.white,
                    onPressed: () => _applyPreset(
                      name: 'Bola de Futebol Oficial Campo/Society',
                      type: 'produto',
                      scope: 'global',
                      tokenCost: 0,
                      imageUrl: 'https://images.unsplash.com/photo-1614632537423-1e6c2e7e0aab?auto=format&fit=crop&w=400&q=80',
                      prizeLink: '',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.shopping_bag, size: 16, color: Colors.purple),
                    label: const Text('Vale Shopisa R\$ 50'),
                    backgroundColor: Colors.white,
                    onPressed: () => _applyPreset(
                      name: 'Vale Compras Shopisa R\$ 50,00',
                      type: 'produto',
                      scope: 'global',
                      tokenCost: 0,
                      imageUrl: '',
                      prizeLink: 'https://shopisa.com.br',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
                    label: const Text('Gerar com IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: AppTheme.primaryGreen,
                    onPressed: _isSaving ? null : _generatePrizeWithAI,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Escopo do Prêmio',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ChoiceChip(
              label: const Text(
                'Global / Loja',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              selected: _newPrizeScope == 'global',
              onSelected: (v) => setState(() {
                _newPrizeScope = 'global';
                _selectedLeagueId = null;
                _selectedFixtureId = null;
                _fetchedMatches = [];
              }),
              selectedColor: AppTheme.accentGold,
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            ChoiceChip(
              label: const Text(
                'Campeonato',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              selected: _newPrizeScope == 'league',
              onSelected: (v) => setState(() {
                _newPrizeScope = 'league';
                _selectedFixtureId = null;
              }),
              selectedColor: AppTheme.accentGold,
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            ChoiceChip(
              label: const Text(
                'Jogo Específico',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              selected: _newPrizeScope == 'match',
              onSelected: (v) => setState(() {
                _newPrizeScope = 'match';
                if (_selectedLeagueId != null)
                  _fetchMatchesForAdmin(_selectedLeagueId!);
              }),
              selectedColor: AppTheme.accentGold,
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ],
        ),

        if (_newPrizeScope == 'league' || _newPrizeScope == 'match') ...[
          const SizedBox(height: 20),
          _activeLeagues.isEmpty
              ? Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nenhum campeonato ativo no momento.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadSettings,
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                )
              : DropdownButtonFormField<int>(
                  key: ValueKey('league_${_selectedLeagueId ?? "none"}'),
                  decoration: InputDecoration(
                    labelText: 'Selecione o Campeonato',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialValue: _selectedLeagueId,
                  items: _activeLeagues
                      .map(
                        (l) =>
                            DropdownMenuItem(value: l.id, child: Text(l.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedLeagueId = val;
                      _selectedFixtureId = null;
                    });
                    if (_newPrizeScope == 'match' && val != null) {
                      _fetchMatchesForAdmin(val);
                    }
                  },
                ),
        ],
        if (_newPrizeScope == 'match') ...[
          const SizedBox(height: 16),
          _isFetchingMatches
              ? const CircularProgressIndicator()
              : _selectedLeagueId == null
              ? const Text(
                  'Selecione primeiro o campeonato para carregar as partidas.',
                  style: TextStyle(color: Colors.grey),
                )
              : _fetchedMatches.isEmpty
              ? const Text(
                  'Nenhuma partida encontrada hoje neste campeonato.',
                  style: TextStyle(color: Colors.orange),
                )
              : DropdownButtonFormField<int>(
                  key: ValueKey('fixture_${_selectedFixtureId ?? "none"}'),
                  decoration: InputDecoration(
                    labelText: 'Selecione a Partida de Hoje',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialValue: _selectedFixtureId,
                  items: _fetchedMatches
                      .map(
                        (m) => DropdownMenuItem<int>(
                          value: m['fixture']['id'],
                          child: Text(
                            '${_matchTime(m)} • ${m['teams']['home']['name']} x ${m['teams']['away']['name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFixtureId = val),
                ),
        ],
        const SizedBox(height: 32),
        const Text(
          'Tipo de Prêmio',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prêmio Físico / Produto / Parceiro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Prêmios 100% físicos (camisas oficiais, bolas, vestuário, calçados e vouchers Shopisa) entregues no endereço do vencedor.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Detalhes do Prêmio',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _newPrizeNameCtrl,
          label: 'Nome do Produto / Prêmio (Ex: Camisa Oficial)',
          hint: 'O que o usuário vai receber em casa?',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _newPrizeTokenCostCtrl,
          label: 'Custo na Loja (Tokens)',
          hint: 'Ex: 50000. 0 = Só na Sorte',
          keyboardType: TextInputType.number,
          helpText:
              'Preço se o usuário quiser COMPRAR este prêmio na loja usando os tokens acumulados (sem contar com a sorte).\nDeixe 0 se o prêmio só puder ser ganho raspando.',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _newPrizeImageCtrl,
          label: 'URL da Imagem do Prêmio (Opcional)',
          hint: 'https://site.com/foto.png',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _newPrizeLinkCtrl,
          label: 'URL do Link do Parceiro / Cupom (Opcional)',
          hint: 'Link da loja parceira (Ex: Shopisa, Centauro, Shopee)',
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            icon: _isSavingPrize
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add_circle, size: 24),
            label: Text(
              _isSavingPrize ? 'Salvando...' : 'Cadastrar Novo Prêmio',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isSavingPrize ? null : _saveNewPrize,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchMatchesForAdmin(int leagueId) async {
    setState(() {
      _isFetchingMatches = true;
      _fetchedMatches = [];
      _selectedFixtureId = null;
    });
    try {
      final service = ref.read(footballServiceProvider);
      final matches = await service.getMatchesForLeague(leagueId);
      if (mounted) setState(() => _fetchedMatches = matches);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao buscar jogos: $e')));
    } finally {
      if (mounted) setState(() => _isFetchingMatches = false);
    }
  }

  String _matchTime(dynamic match) {
    final rawDate = match['fixture']?['date']?.toString();
    final date = rawDate == null ? null : DateTime.tryParse(rawDate)?.toLocal();
    return date == null ? '--:--' : DateFormat('HH:mm').format(date);
  }

  Future<void> _saveNewPrize() async {
    final name = _newPrizeNameCtrl.text.trim();
    final tokenCost = int.tryParse(_newPrizeTokenCostCtrl.text.trim()) ?? 0;
    final image = _newPrizeImageCtrl.text.trim();
    final prizeLink = _newPrizeLinkCtrl.text.trim();
    LeagueInfo? selectedLeague;
    for (final league in _activeLeagues) {
      if (league.id == _selectedLeagueId) selectedLeague = league;
    }
    dynamic selectedMatch;
    for (final match in _fetchedMatches) {
      if (match['fixture']?['id'] == _selectedFixtureId) selectedMatch = match;
    }
    final matchLabel = selectedMatch == null
        ? null
        : '${selectedMatch['teams']['home']['name']} x ${selectedMatch['teams']['away']['name']}';

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o nome do prêmio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPrizeScope == 'league' && _selectedLeagueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um Campeonato.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPrizeScope == 'match' && _selectedFixtureId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma Partida.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingPrize = true);

    try {
      await FirebaseFirestore.instance.collection('prizes').add({
        'name': name,
        'type': _newPrizeType,
        'scope': _newPrizeScope,
        'leagueId': _newPrizeScope == 'global' ? null : _selectedLeagueId,
        'fixtureId': _newPrizeScope == 'match' ? _selectedFixtureId : null,
        'leagueName': selectedLeague?.name,
        'matchLabel': matchLabel,
        'token_cost': tokenCost,
        'image_url': image,
        'prize_link': prizeLink,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _newPrizeNameCtrl.clear();
      _newPrizeTokenCostCtrl.clear();
      _newPrizeImageCtrl.clear();
      _newPrizeLinkCtrl.clear();
      setState(() {
        _newPrizeScope = 'global';
        _selectedLeagueId = null;
        _selectedFixtureId = null;
        _fetchedMatches = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prêmio adicionado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSavingPrize = false);
    }
  }

  Future<void> _duplicatePrize(DocumentSnapshot doc) async {
    final prize = doc.data() as Map<String, dynamic>;
    try {
      final copy = Map<String, dynamic>.from(prize);
      copy['name'] = '${prize['name']} (Cópia)';
      copy['createdAt'] = FieldValue.serverTimestamp();
      copy['active'] = true;
      await FirebaseFirestore.instance.collection('prizes').add(copy);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prêmio duplicado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao duplicar prêmio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPrizesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prizes')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Text('Erro ao carregar prêmios.');

        final prizes = snapshot.data?.docs ?? [];
        if (prizes.isEmpty) return const Text('Nenhum prêmio cadastrado.');

        return SizedBox(
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: prizes.length,
            itemBuilder: (context, index) {
              final doc = prizes[index];
              final prize = doc.data() as Map<String, dynamic>;
              final active = prize['active'] ?? false;
              final isPix = prize['type'] == 'pix';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child:
                        prize['image_url'] != null &&
                            prize['image_url'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              prize['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                isPix ? Icons.pix : Icons.card_giftcard,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Icon(
                            isPix ? Icons.pix : Icons.card_giftcard,
                            color: Colors.grey,
                          ),
                  ),
                  title: Text(
                    prize['name'] ?? 'Sem nome',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  prize['scope'] == 'global'
                                      ? Icons.public
                                      : (prize['scope'] == 'league'
                                            ? Icons.emoji_events
                                            : Icons.sports_soccer),
                                  size: 16,
                                  color: AppTheme.accentGold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  prize['scope'] == 'global'
                                      ? 'Prêmio Global'
                                      : (prize['scope'] == 'league'
                                            ? prize['leagueName']?.toString() ??
                                                  'Liga ID: ${prize['leagueId']}'
                                            : prize['matchLabel']?.toString() ??
                                                  'Jogo ID: ${prize['fixtureId']}'),
                                  style: const TextStyle(
                                    color: AppTheme.accentGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (prize['provider'] == 'shopisa')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: Text(
                                  '🛍️ Shopisa (${prize['discount_percent'] ?? 100}% OFF)',
                                  style: TextStyle(
                                    color: Colors.purple.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            Text(
                              '${prize['token_cost'] ?? 0} tokens',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (prize['quantity'] != null)
                              Text(
                                'Estoque: ${prize['quantity']}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: active,
                          activeThumbColor: AppTheme.primaryGreen,
                          onChanged: (val) => FirebaseFirestore.instance
                              .collection('prizes')
                              .doc(doc.id)
                              .update({'active': val}),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        tooltip: 'Opções',
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditPrizeDialog(context, doc);
                          } else if (value == 'duplicate') {
                            _duplicatePrize(doc);
                          } else if (value == 'delete') {
                            _confirmDeletePrize(context, doc);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18),
                                SizedBox(width: 8),
                                Text('Editar Prêmio'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text('Duplicar Prêmio'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                SizedBox(width: 8),
                                Text('Excluir Prêmio'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showEditPrizeDialog(BuildContext context, DocumentSnapshot doc) {
    final prize = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: prize['name'] ?? '');
    final tokenCostCtrl = TextEditingController(
      text: (prize['token_cost'] ?? 0).toString(),
    );
    final imageCtrl = TextEditingController(text: prize['image_url'] ?? '');
    final linkCtrl = TextEditingController(text: prize['prize_link'] ?? '');
    bool isActive = prize['active'] == true;
    String scope = prize['scope']?.toString() ?? 'global';
    String type = prize['type']?.toString() ?? 'pix';

    int? selectedLeagueId = (prize['leagueId'] as num?)?.toInt();
    int? selectedFixtureId = (prize['fixtureId'] as num?)?.toInt();

    List<dynamic> fetchedEditMatches = [];
    bool isFetchingEditMatches = false;

    Future<void> loadEditMatches(
      int leagueId,
      StateSetter setDialogState,
    ) async {
      setDialogState(() {
        isFetchingEditMatches = true;
        fetchedEditMatches = [];
      });
      try {
        final service = ref.read(footballServiceProvider);
        final matches = await service.getMatchesForLeague(leagueId);
        setDialogState(() {
          fetchedEditMatches = matches;
        });
      } catch (_) {
      } finally {
        setDialogState(() {
          isFetchingEditMatches = false;
        });
      }
    }

    if (scope == 'match' && selectedLeagueId != null) {
      ref
          .read(footballServiceProvider)
          .getMatchesForLeague(selectedLeagueId)
          .then((matches) {
            fetchedEditMatches = matches;
          });
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.edit, color: AppTheme.accentGold),
                SizedBox(width: 8),
                Text('Editar Prêmio'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Onde este prêmio será exibido?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Global / Loja'),
                          selected: scope == 'global',
                          selectedColor: AppTheme.accentGold,
                          onSelected: (_) {
                            setDialogState(() {
                              scope = 'global';
                              selectedLeagueId = null;
                              selectedFixtureId = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Por Campeonato'),
                          selected: scope == 'league',
                          selectedColor: AppTheme.accentGold,
                          onSelected: (_) {
                            setDialogState(() {
                              scope = 'league';
                              selectedFixtureId = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Por Partida Específica'),
                          selected: scope == 'match',
                          selectedColor: AppTheme.accentGold,
                          onSelected: (_) {
                            setDialogState(() {
                              scope = 'match';
                            });
                            if (selectedLeagueId != null &&
                                fetchedEditMatches.isEmpty) {
                              loadEditMatches(selectedLeagueId!, setDialogState);
                            }
                          },
                        ),
                      ],
                    ),
                    if (scope == 'league' || scope == 'match') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Selecione o Campeonato',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        initialValue: selectedLeagueId,
                        items: _activeLeagues
                            .map(
                              (l) => DropdownMenuItem<int>(
                                value: l.id,
                                child: Text(l.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedLeagueId = val;
                            selectedFixtureId = null;
                          });
                          if (scope == 'match' && val != null) {
                            loadEditMatches(val, setDialogState);
                          }
                        },
                      ),
                    ],
                    if (scope == 'match') ...[
                      const SizedBox(height: 16),
                      isFetchingEditMatches
                          ? const Center(child: CircularProgressIndicator())
                          : selectedLeagueId == null
                              ? const Text(
                                  'Selecione primeiro o campeonato para ver as partidas.',
                                  style: TextStyle(color: Colors.grey),
                                )
                              : fetchedEditMatches.isEmpty
                                  ? const Text(
                                      'Nenhuma partida encontrada hoje neste campeonato.',
                                      style: TextStyle(color: Colors.orange),
                                    )
                                  : DropdownButtonFormField<int>(
                                      decoration: InputDecoration(
                                        labelText: 'Selecione a Partida de Hoje',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      initialValue: fetchedEditMatches.any(
                                        (m) =>
                                            m['fixture']?['id'] ==
                                            selectedFixtureId,
                                      )
                                          ? selectedFixtureId
                                          : null,
                                      items: fetchedEditMatches
                                          .map(
                                            (m) => DropdownMenuItem<int>(
                                              value: m['fixture']['id'],
                                              child: Text(
                                                '${_matchTime(m)} • ${m['teams']['home']['name']} x ${m['teams']['away']['name']}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setDialogState(
                                        () => selectedFixtureId = val,
                                      ),
                                    ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Tipo do Prêmio',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('PIX / Dinheiro'),
                          selected: type == 'pix',
                          selectedColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: type == 'pix' ? Colors.white : Colors.black,
                          ),
                          onSelected: (_) => setDialogState(() => type = 'pix'),
                        ),
                        ChoiceChip(
                          label: const Text('Produto / Cupom'),
                          selected: type == 'produto',
                          selectedColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: type == 'produto' ? Colors.white : Colors.black,
                          ),
                          onSelected: (_) => setDialogState(() => type = 'produto'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Prêmio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tokenCostCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Custo em Tokens (ou Pontos)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL da Imagem / Foto do Prêmio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link Externo (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Ativo para resgate'),
                      value: isActive,
                      activeThumbColor: AppTheme.primaryGreen,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  final newTokens =
                      int.tryParse(tokenCostCtrl.text.trim()) ?? 0;
                  final newImage = imageCtrl.text.trim();
                  final newLink = linkCtrl.text.trim();

                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha o nome do prêmio.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (scope == 'league' && selectedLeagueId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione o campeonato.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (scope == 'match' && selectedFixtureId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione a partida.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  LeagueInfo? selectedLeague;
                  for (final l in _activeLeagues) {
                    if (l.id == selectedLeagueId) selectedLeague = l;
                  }

                  dynamic selectedMatch;
                  for (final m in fetchedEditMatches) {
                    if (m['fixture']?['id'] == selectedFixtureId) selectedMatch = m;
                  }

                  final matchLabel = selectedMatch == null
                      ? (prize['matchLabel'] ?? prize['match_label'])
                      : '${selectedMatch['teams']['home']['name']} x ${selectedMatch['teams']['away']['name']}';

                  final leagueName = scope == 'global'
                      ? null
                      : (selectedLeague?.name ??
                          prize['leagueName'] ??
                          prize['league_name']);

                  await doc.reference.update({
                    'name': newName,
                    'token_cost': newTokens,
                    'image_url': newImage,
                    'prize_link': newLink,
                    'active': isActive,
                    'type': type,
                    'scope': scope,
                    'leagueId': scope == 'global' ? null : selectedLeagueId,
                    'leagueName': leagueName,
                    'league_name': leagueName,
                    'fixtureId': scope == 'match' ? selectedFixtureId : null,
                    'matchLabel': scope == 'match' ? matchLabel : null,
                    'match_label': scope == 'match' ? matchLabel : null,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prêmio atualizado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Salvar Alterações'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeletePrize(BuildContext context, DocumentSnapshot doc) {
    final prize = doc.data() as Map<String, dynamic>;
    final prizeName = prize['name'] ?? 'este prêmio';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Excluir Prêmio'),
          ],
        ),
        content: Text('Tem certeza que deseja excluir "$prizeName"? Esta ação não poderá ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await doc.reference.delete();
              if (context.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prêmio excluído!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? helpText,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (helpText != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  color: Colors.blueGrey,
                  size: 18,
                ),
                tooltip: helpText,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRedemptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('redemptions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return const Center(
            child: Text('Erro ao carregar histórico de resgates.'),
          );

        final redemptions = snapshot.data?.docs ?? [];
        if (redemptions.isEmpty)
          return const Center(child: Text('Nenhum resgate solicitado.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: redemptions.length,
          itemBuilder: (context, index) {
            final doc = redemptions[index];
            final data = doc.data() as Map<String, dynamic>;
            final isPix = data['type'] == 'pix';
            final status = data['status'] ?? 'pendente';

            Color statusColor = Colors.orange;
            if (status == 'enviado' || status == 'concluido')
              statusColor = Colors.green;
            if (status == 'rejeitado') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: Icon(
                  isPix ? Icons.pix : Icons.card_giftcard,
                  color: isPix ? Colors.teal : AppTheme.primaryGreen,
                  size: 36,
                ),
                title: Text(
                  isPix
                      ? 'Saque PIX - R\$ ${data['valueInReais']?.toStringAsFixed(2) ?? '0.00'}'
                      : 'Resgate Físico - ${data['prizeName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Solicitado por: ${data['userName'] ?? 'Desconhecido'}\nStatus: ${status.toUpperCase()}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custo em Tokens: ${data['cost'] ?? data['tokensCost'] ?? 0}',
                        ),
                        Text('E-mail: ${data['userEmail'] ?? 'Não informado'}'),
                        if (isPix)
                          Text(
                            'Chave PIX: ${data['pixKey'] ?? 'Não informada'}',
                          ),
                        if (!isPix)
                          Text(
                            'Telefone: ${data['userPhone'] ?? 'Não informado'}',
                          ),
                        if (!isPix)
                          Text('CPF: ${data['userCpf'] ?? 'Não informado'}'),
                        if (data['rewardCode'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Código Shopisa: ${data['rewardCode']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade800,
                              ),
                            ),
                          ),
                        if (data['claimUrl'] != null && data['claimUrl'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.purple.shade700,
                                side: BorderSide(color: Colors.purple.shade300),
                              ),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Abrir Link de Resgate Shopisa'),
                              onPressed: () => launchUrl(
                                Uri.parse(data['claimUrl']),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (status == 'pendente')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Marcar como Enviado',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('redemptions')
                                      .doc(doc.id)
                                      .update({
                                        'status': isPix
                                            ? 'concluido'
                                            : 'enviado',
                                      });
                                },
                              ),
                            if (status == 'pendente')
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Rejeitar'),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('redemptions')
                                      .doc(doc.id)
                                      .update({'status': 'rejeitado'});
                                },
                              ),
                          ],
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
    );
  }

  Widget _buildSponsorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.add_business,
            'Novo Patrocinador / Parceiro',
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _newSponsorNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Patrocinador',
                      hintText: 'Ex: Nike, Cervejaria X, Banco Y',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newSponsorLogoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL da Logomarca (Imagem)',
                      hintText: 'https://exemplo.com/logo.png',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newSponsorLinkCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Link de Destino / Site (Opcional)',
                      hintText: 'https://sitepatrocinador.com.br',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newSponsorOrderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ordem de Exibição (0, 1, 2...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        foregroundColor: AppTheme.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _isSavingSponsor
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _isSavingSponsor
                            ? 'SALVANDO...'
                            : 'CADASTRAR PATROCINADOR',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSavingSponsor ? null : _saveNewSponsor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(
            Icons.handshake,
            'Patrocinadores Cadastrados',
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sponsors')
                .orderBy('order', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Erro: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('Nenhum patrocinador cadastrado ainda.'),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Sem Nome';
                  final logoUrl = data['logoUrl'] ?? data['image_url'] ?? '';
                  final siteUrl = data['siteUrl'] ?? data['site_url'] ?? '';
                  final isActive = data['active'] == true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              )
                            : const Icon(Icons.business),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        siteUrl.isNotEmpty ? siteUrl : 'Sem link externo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: siteUrl.isNotEmpty
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (val) {
                              doc.reference.update({'active': val});
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showEditSponsorDialog(context, doc);
                              } else if (val == 'delete') {
                                doc.reference.delete();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewSponsor() async {
    final name = _newSponsorNameCtrl.text.trim();
    final logo = _newSponsorLogoCtrl.text.trim();
    final link = _newSponsorLinkCtrl.text.trim();
    final order = int.tryParse(_newSponsorOrderCtrl.text.trim()) ?? 0;

    if (name.isEmpty || logo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o Nome e a URL da Logomarca.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingSponsor = true);

    try {
      await FirebaseFirestore.instance.collection('sponsors').add({
        'name': name,
        'logoUrl': logo,
        'image_url': logo,
        'siteUrl': link,
        'site_url': link,
        'order': order,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _newSponsorNameCtrl.clear();
      _newSponsorLogoCtrl.clear();
      _newSponsorLinkCtrl.clear();
      _newSponsorOrderCtrl.text = '0';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patrocinador cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSponsor = false);
    }
  }

  void _showEditSponsorDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final logoCtrl = TextEditingController(
      text: data['logoUrl'] ?? data['image_url'] ?? '',
    );
    final linkCtrl = TextEditingController(
      text: data['siteUrl'] ?? data['site_url'] ?? '',
    );
    final orderCtrl = TextEditingController(
      text: (data['order'] ?? 0).toString(),
    );
    bool isActive = data['active'] == true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.edit, color: AppTheme.accentGold),
                SizedBox(width: 8),
                Text('Editar Patrocinador'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Patrocinador',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: logoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL da Logomarca (Imagem)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Link de Destino / Site (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ordem de Exibição',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Ativo para exibição'),
                    value: isActive,
                    activeThumbColor: AppTheme.primaryGreen,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  final newLogo = logoCtrl.text.trim();
                  final newLink = linkCtrl.text.trim();
                  final newOrder = int.tryParse(orderCtrl.text.trim()) ?? 0;

                  await doc.reference.update({
                    'name': newName,
                    'logoUrl': newLogo,
                    'image_url': newLogo,
                    'siteUrl': newLink,
                    'site_url': newLink,
                    'order': newOrder,
                    'active': isActive,
                  });

                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Patrocinador atualizado!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Salvar Alterações'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return StatefulBuilder(
      builder: (context, setUsersState) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Erro ao carregar torcedores: ${snapshot.error}', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final totalUsers = docs.length;

            final query = _userSearchQuery.trim().toLowerCase();
            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final name = (data['name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              final phone = (data['phone'] ?? '').toString().toLowerCase();
              final cpf = (data['cpf'] ?? '').toString().toLowerCase();
              final team = (data['favorite_team_name'] ?? data['favoriteTeamName'] ?? '').toString().toLowerCase();
              return name.contains(query) ||
                  email.contains(query) ||
                  phone.contains(query) ||
                  cpf.contains(query) ||
                  team.contains(query);
            }).toList();

            // Total de tokens e saldo real na lista filtrada
            int totalFilteredTokens = 0;
            double totalFilteredReal = 0.0;
            for (var d in filteredDocs) {
              final data = d.data() as Map<String, dynamic>? ?? {};
              totalFilteredTokens += (data['tokens'] as num?)?.toInt() ?? 0;
              totalFilteredReal += (data['real_balance'] as num?)?.toDouble() ?? 0.0;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Search
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.people_alt, color: Colors.blue, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Torcedores Cadastrados',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        Text(
                                          'Total: $totalUsers torcedores • Exibindo: ${filteredDocs.length}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _userSearchCtrl,
                                onChanged: (val) {
                                  setUsersState(() {
                                    _userSearchQuery = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nome, e-mail, telefone, CPF ou time...',
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: _userSearchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _userSearchCtrl.clear();
                                            setUsersState(() {
                                              _userSearchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metrics Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.monetization_on, color: Colors.blue, size: 22),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Moedas em Circulação', style: TextStyle(fontSize: 11, color: Colors.blue)),
                                      Text(
                                        NumberFormat('#,###', 'pt_BR').format(totalFilteredTokens),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet, color: Colors.teal, size: 22),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Saldo Real (R\$)', style: TextStyle(fontSize: 11, color: Colors.teal)),
                                      Text(
                                        'R\$ ${totalFilteredReal.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Users List
                      if (filteredDocs.isEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.person_search, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _userSearchQuery.isEmpty
                                      ? 'Nenhum torcedor cadastrado ainda.'
                                      : 'Nenhum torcedor encontrado para "$_userSearchQuery".',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDocs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            final name = (data['name'] ?? '').toString();
                            final email = (data['email'] ?? '').toString();
                            final phone = (data['phone'] ?? '').toString();
                            final cpf = (data['cpf'] ?? '').toString();
                            final role = (data['role'] ?? 'user').toString().toLowerCase();
                            final isAdmin = role == 'admin';
                            final tokens = (data['tokens'] as num?)?.toInt() ?? 0;
                            final realBalance = (data['real_balance'] as num?)?.toDouble() ?? 0.0;
                            final favoriteTeam = (data['favorite_team_name'] ?? data['favoriteTeamName'] ?? '').toString();

                            final initialLetter = name.isNotEmpty
                                ? name[0].toUpperCase()
                                : (email.isNotEmpty ? email[0].toUpperCase() : '?');

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isAdmin ? Colors.amber.shade400 : Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: isAdmin ? Colors.amber.shade700 : AppTheme.primaryGreen,
                                          child: Text(
                                            initialLetter,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      name.isNotEmpty ? name : 'Torcedor (Sem nome)',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isAdmin) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber.shade100,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Colors.amber.shade600),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.workspace_premium, size: 12, color: Colors.amber.shade900),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            'ADMIN',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.amber.shade900,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                email.isNotEmpty ? email : 'UID: ${doc.id}',
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.shade600),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${NumberFormat('#,###', 'pt_BR').format(tokens)} moedas',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.teal.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.account_balance_wallet, size: 14, color: Colors.teal),
                                              const SizedBox(width: 4),
                                              Text(
                                                'R\$ ${realBalance.toStringAsFixed(2)}',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal.shade900),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (favoriteTeam.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.green.shade300),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.sports_soccer, size: 14, color: Colors.green),
                                                const SizedBox(width: 4),
                                                Text(
                                                  favoriteTeam,
                                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.green.shade900),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (phone.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.phone, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  phone,
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (cpf.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.badge, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'CPF: $cpf',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.add_circle_outline, size: 16),
                                          label: const Text('Ajustar Saldo'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.teal.shade800,
                                            side: BorderSide(color: Colors.teal.shade400),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () => _showEditUserTokensDialog(
                                            context,
                                            doc.id,
                                            name.isNotEmpty ? name : email,
                                            tokens,
                                            realBalance,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          icon: const Icon(Icons.info_outline, size: 16),
                                          label: const Text('Detalhes'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.grey.shade700,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () => _showUserDetailsDialog(context, doc.id, data),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUserTokensDialog(
    BuildContext context,
    String uid,
    String userName,
    int currentTokens,
    double currentRealBalance,
  ) {
    final tokensCtrl = TextEditingController(text: '$currentTokens');
    final realCtrl = TextEditingController(text: currentRealBalance.toStringAsFixed(2));
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ajustar Saldo: $userName',
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Moedas (Tokens):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: tokensCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on, color: Colors.amber),
                      labelText: 'Saldo em Moedas',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('+100'),
                        onPressed: () {
                          final cur = int.tryParse(tokensCtrl.text) ?? currentTokens;
                          tokensCtrl.text = '${cur + 100}';
                        },
                      ),
                      ActionChip(
                        label: const Text('+500'),
                        onPressed: () {
                          final cur = int.tryParse(tokensCtrl.text) ?? currentTokens;
                          tokensCtrl.text = '${cur + 500}';
                        },
                      ),
                      ActionChip(
                        label: const Text('+1.000'),
                        onPressed: () {
                          final cur = int.tryParse(tokensCtrl.text) ?? currentTokens;
                          tokensCtrl.text = '${cur + 1000}';
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Saldo Real em Reais (R\$):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: realCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money, color: Colors.teal),
                      labelText: 'Saldo Real (R\$)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final newTokens = int.tryParse(tokensCtrl.text.trim()) ?? currentTokens;
                        final newReal = double.tryParse(realCtrl.text.trim().replaceAll(',', '.')) ?? currentRealBalance;

                        setDialogState(() => isSaving = true);
                        try {
                          await FirebaseFirestore.instance.collection('users').doc(uid).update({
                            'tokens': newTokens,
                            'real_balance': newReal,
                          });

                          // Registrar transação de auditoria
                          await FirebaseFirestore.instance.collection('token_transactions').add({
                            'uid': uid,
                            'amount': newTokens - currentTokens,
                            'type': 'admin_manual_adjustment',
                            'description': 'Ajuste manual pelo painel administrativo',
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saldo do torcedor atualizado com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Detalhes do Torcedor'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserDetailRow('UID', uid),
              _buildUserDetailRow('Nome', (data['name'] ?? 'Não informado').toString()),
              _buildUserDetailRow('E-mail', (data['email'] ?? 'Não informado').toString()),
              _buildUserDetailRow('Função (Role)', (data['role'] ?? 'user').toString()),
              _buildUserDetailRow('Telefone', (data['phone'] ?? 'Não informado').toString()),
              _buildUserDetailRow('CPF', (data['cpf'] ?? 'Não informado').toString()),
              _buildUserDetailRow('Time do Coração', (data['favorite_team_name'] ?? data['favoriteTeamName'] ?? 'Nenhum').toString()),
              _buildUserDetailRow('Moedas (Tokens)', '${data['tokens'] ?? 0}'),
              _buildUserDetailRow('Saldo Real (R\$)', 'R\$ ${(data['real_balance'] ?? 0.0).toString()}'),
              _buildUserDetailRow('Notificações WhatsApp', (data['wants_whatsapp_notifications'] == true) ? 'Sim' : 'Não'),
              if (data['watching_home_team'] != null)
                _buildUserDetailRow('Assistindo', '${data['watching_home_team']} x ${data['watching_away_team']}'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTicketsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Erro ao carregar chamados: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final tickets = snapshot.data?.docs ?? [];
        if (tickets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum chamado de suporte recebido ainda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mensagens enviadas pelo formulário do site aparecerão aqui em tempo real.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final doc = tickets[index];
            final data = doc.data() as Map<String, dynamic>;
            final nome = (data['nome'] ?? 'Sem nome').toString();
            final email = (data['email'] ?? 'Sem e-mail').toString();
            final descricao = (data['descricao'] ?? '').toString();
            final status = (data['status'] ?? 'aberto').toString().toLowerCase();
            final createdAt = data['createdAt'] != null && data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : null;
            final dateStr = createdAt != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
                : 'Data recente';

            final isAberto = status == 'aberto';
            final Color statusColor = isAberto ? Colors.orange.shade800 : Colors.green.shade700;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: isAberto ? Colors.orange.shade50 : Colors.green.shade50,
                  child: Icon(
                    isAberto ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
                    color: statusColor,
                  ),
                ),
                title: Text(
                  nome,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  '$email • $dateStr',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isAberto ? 'ABERTO' : 'RESOLVIDO',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mensagem do Torcedor:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SelectableText(
                            descricao.isNotEmpty ? descricao : '(Sem descrição)',
                            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.email_outlined, size: 16),
                              label: const Text('Responder por E-mail'),
                              onPressed: () async {
                                final uri = Uri(
                                  scheme: 'mailto',
                                  path: email,
                                  query: 'subject=Suporte Raspadinha do Gol - Atendimento',
                                );
                                try {
                                  await launchUrl(uri);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('E-mail: $email')),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAberto ? Colors.green.shade700 : Colors.orange.shade800,
                                foregroundColor: Colors.white,
                              ),
                              icon: Icon(isAberto ? Icons.check_circle : Icons.replay, size: 16),
                              label: Text(isAberto ? 'Marcar como Resolvido' : 'Reabrir Chamado'),
                              onPressed: () async {
                                await doc.reference.update({
                                  'status': isAberto ? 'resolvido' : 'aberto',
                                  'resolvedAt': isAberto ? FieldValue.serverTimestamp() : null,
                                });
                              },
                            ),
                          ],
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
    );
  }
}

