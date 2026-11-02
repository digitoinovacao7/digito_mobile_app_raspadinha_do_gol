import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../services/db_service.dart';

class BolaoScreen extends ConsumerStatefulWidget {
  const BolaoScreen({super.key});

  @override
  ConsumerState<BolaoScreen> createState() => _BolaoScreenState();
}

class _BolaoScreenState extends ConsumerState<BolaoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _dbService = DbService();

  // Form Controllers
  final _nameCtrl = TextEditingController();
  final _entryFeeCtrl = TextEditingController(text: '10,00');
  final _organizerPixKeyCtrl = TextEditingController();
  final _organizerPixNameCtrl = TextEditingController();
  int _creatorFee = 0;
  final int _platformFee = 0;
  final _matchTeamsCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _category = 'amigos'; // 'amigos' ou 'bar'
  String _activationMethod = 'pix'; // 'pix' ou 'tokens'
  static const double _bolaoActivationFeeReal = 4.90;
  static const int _bolaoActivationFeeTokens = 2500;
  bool _isCreating = false;
  DateTime? _matchDateTime;
  int _deadlineMinutes = 30;

  // Football API States
  int? _selectedLeagueId;
  int? _selectedFixtureId;
  bool _isFetchingMatches = false;
  List<dynamic> _fetchedMatches = [];
  List<dynamic> _activeLeagues = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _searchCtrl.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeagues();
    });
  }

  double _parseEntryFee(String raw) {
    final cleaned = raw.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _formatBrl(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> _loadLeagues() async {
    try {
      final service = ref.read(footballServiceProvider);
      final leagues = await service.getCombinedLeagues();
      if (mounted) setState(() => _activeLeagues = leagues);
    } catch (e) {
      debugPrint('Erro ao carregar ligas: $e');
    }
  }

  Future<void> _fetchMatchesForBolao(int leagueId, StateSetter setModalState) async {
    setModalState(() {
      _isFetchingMatches = true;
      _fetchedMatches = [];
      _selectedFixtureId = null;
    });
    try {
      final service = ref.read(footballServiceProvider);
      final matches = await service.getMatchesForLeague(leagueId);
      if (mounted) {
        setModalState(() => _fetchedMatches = matches);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar jogos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setModalState(() => _isFetchingMatches = false);
      }
    }
  }

  String _matchTime(dynamic match) {
    final rawDate = match['fixture']?['date']?.toString();
    final date = rawDate == null ? null : DateTime.tryParse(rawDate)?.toLocal();
    return date == null ? '--:--' : DateFormat('HH:mm').format(date);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _entryFeeCtrl.dispose();
    _organizerPixKeyCtrl.dispose();
    _organizerPixNameCtrl.dispose();
    _matchTeamsCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showActivationPixModal({
    required BuildContext parentContext,
    required String bolaoName,
    required Map<String, dynamic> bolaoData,
  }) async {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _dbService.createBolaoActivationPix(
              bolaoName: bolaoName,
              amount: _bolaoActivationFeeReal,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B2214),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.accentGold),
                        SizedBox(height: 16),
                        Text(
                          'Gerando Pix de Ativação no Mercado Pago...',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B2214),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.amberAccent, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Aviso de Ativação',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Não foi possível conectar à API do Mercado Pago (${snapshot.error}). Deseja ativar a sala mesmo assim?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final docRef = await _firestore.collection('boloes').add({
                            ...bolaoData,
                            'activationFeePaid': true,
                            'activationMethod': 'fallback_pix',
                          });
                          if (parentContext.mounted) {
                            _shareBolao(
                              bolaoId: docRef.id,
                              name: bolaoName,
                              entryFee: bolaoData['entryFee'],
                              prize: bolaoData['prize'],
                              organizerPixKey: bolaoData['organizerPixKey'],
                              organizerPixName: bolaoData['organizerPixName'],
                            );
                          }
                        },
                        child: const Text('ATIVAR SALA DO BOLÃO', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }

              final pixData = snapshot.data!;
              final qrCode = pixData['qrCode'] as String? ?? '';
              final qrCodeBase64 = pixData['qrCodeBase64'] as String?;
              final paymentId = pixData['paymentId'];
              final activationId = pixData['activationId'] as String? ?? '';
              bool isChecking = false;

              return StatefulBuilder(
                builder: (context, setInnerState) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B2214),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(top: BorderSide(color: AppTheme.accentGold, width: 2)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pix, color: Colors.tealAccent, size: 26),
                              SizedBox(width: 8),
                              Text(
                                'Taxa de Ativação da Sala',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Valor: R\$ 4,90 (Mercado Pago)',
                            style: TextStyle(color: AppTheme.accentGold, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pague o Pix abaixo para ativar sua sala oficial com ranking em tempo real e apuração automática:',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 16),

                          if (qrCodeBase64 != null && qrCodeBase64.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.memory(
                                base64Decode(qrCodeBase64),
                                width: 170,
                                height: 170,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          if (qrCode.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                children: [
                                  const Text('Código Pix Copia e Cola:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    qrCode,
                                    maxLines: 2,
                                    style: const TextStyle(color: AppTheme.accentGold, fontSize: 10.5, fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.accentGold,
                                        side: const BorderSide(color: AppTheme.accentGold),
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: qrCode));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: AppTheme.primaryGreen,
                                            content: Text('Código Pix Copia e Cola copiado!'),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('COPIAR CÓDIGO PIX'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: isChecking
                                  ? null
                                  : () async {
                                      setInnerState(() => isChecking = true);
                                      try {
                                        if (paymentId != null) {
                                          await _dbService.checkBolaoActivationPixStatus(
                                            paymentId: paymentId is int ? paymentId : int.tryParse(paymentId.toString()) ?? 0,
                                            activationId: activationId,
                                          );
                                        }

                                        if (ctx.mounted) Navigator.pop(ctx);
                                        final docRef = await _firestore.collection('boloes').add({
                                          ...bolaoData,
                                          'activationFeePaid': true,
                                          'activationPaymentId': paymentId,
                                          'activationMethod': 'pix',
                                        });

                                        if (parentContext.mounted) {
                                          _shareBolao(
                                            bolaoId: docRef.id,
                                            name: bolaoName,
                                            entryFee: bolaoData['entryFee'],
                                            prize: bolaoData['prize'],
                                            organizerPixKey: bolaoData['organizerPixKey'],
                                            organizerPixName: bolaoData['organizerPixName'],
                                          );
                                        }
                                      } catch (e) {
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        final docRef = await _firestore.collection('boloes').add({
                                          ...bolaoData,
                                          'activationFeePaid': true,
                                          'activationMethod': 'pix',
                                        });
                                        if (parentContext.mounted) {
                                          _shareBolao(
                                            bolaoId: docRef.id,
                                            name: bolaoName,
                                            entryFee: bolaoData['entryFee'],
                                            prize: bolaoData['prize'],
                                            organizerPixKey: bolaoData['organizerPixKey'],
                                            organizerPixName: bolaoData['organizerPixName'],
                                          );
                                        }
                                      } finally {
                                        setInnerState(() => isChecking = false);
                                      }
                                    },
                              child: isChecking
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'JÁ PAGUEI! ATIVAR SALA DO BOLÃO ✅',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateBolaoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final entryVal = _parseEntryFee(_entryFeeCtrl.text);
          final isFreeBolao = entryVal <= 0;
          final winnerPct = 100 - _platformFee - _creatorFee;
          final simPot10 = entryVal * 10;
          final simWinner10 = simPot10 * (winnerPct / 100);
          final simCreator10 = simPot10 * (_creatorFee / 100);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0B2214),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppTheme.accentGold, width: 2),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.emoji_events, color: AppTheme.accentGold, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Criar Novo Bolão do Gol ⚽',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Crie uma disputa de palpites entre amigos ou para movimentar o seu bar/restaurante.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Categoria: Amigos ou Bar
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _category = 'amigos'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _category == 'amigos'
                                    ? AppTheme.primaryGreen
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _category == 'amigos'
                                      ? AppTheme.accentGold
                                      : Colors.transparent,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.groups, color: Colors.white),
                                  SizedBox(height: 4),
                                  Text(
                                    'Galera & Amigos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _category = 'bar'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _category == 'bar'
                                    ? AppTheme.primaryGreen
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _category == 'bar'
                                      ? AppTheme.accentGold
                                      : Colors.transparent,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.sports_bar, color: Colors.white),
                                  SizedBox(height: 4),
                                  Text(
                                    'Bar / Estabelecimento',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nome
                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nome do Bolão',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: _category == 'amigos'
                            ? 'ex: Bolão dos Parças da Quarta'
                            : 'ex: Bolão do Bar do Zé - Brasileirão',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Valor Rápido (Chips) + Campo Valor da Entrada
                    const Text(
                      '💰 Valor da Entrada por Participante',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['0,00', '5,00', '10,00', '20,00', '50,00'].map((preset) {
                        final isSelected = _entryFeeCtrl.text.trim() == preset;
                        return ChoiceChip(
                          label: Text(preset == '0,00' ? 'Grátis' : 'R\$ $preset'),
                          selected: isSelected,
                          selectedColor: AppTheme.accentGold,
                          backgroundColor: Colors.black38,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              _entryFeeCtrl.text = preset;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _entryFeeCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ou digite outro valor (Pix)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixText: 'R\$ ',
                        prefixStyle: const TextStyle(color: AppTheme.accentGold),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Divisão do Prêmio + Simulador de Pote
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏆 Divisão do Prêmio (Pote Total)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sua Comissão de Anfitrião (Organizador/Bar)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              DropdownButton<int>(
                                value: _creatorFee,
                                dropdownColor: const Color(0xFF1E3626),
                                style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
                                underline: const SizedBox(),
                                items: [0, 5, 10, 15, 20].map((fee) {
                                  return DropdownMenuItem<int>(
                                    value: fee,
                                    child: Text('$fee%'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => _creatorFee = val);
                                  }
                                },
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Prêmio de quem Cravar o Placar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('$winnerPct%', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          if (!isFreeBolao) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📊 Simulação com 10 Participantes:',
                                    style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Pote Total Arrecadado: R\$ ${_formatBrl(simPot10)}\n'
                                    '• Vencedor recebe no Pix: R\$ ${_formatBrl(simWinner10)}\n'
                                    '• Sua comissão de anfitrião: R\$ ${_formatBrl(simCreator10)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Chave Pix do Organizador para receber as cotas
                    if (!isFreeBolao) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.pix, color: Colors.tealAccent, size: 22),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '🔑 Sua Chave Pix (Recebimento das Cotas)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Os participantes transferem as cotas direto para o seu Pix. Ao fim do jogo, você transfere o prêmio para quem cravou o placar!',
                              style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _organizerPixKeyCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Sua Chave Pix (CPF, Celular, E-mail ou Aleatória)',
                                labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                prefixIcon: const Icon(Icons.vpn_key, color: AppTheme.accentGold, size: 18),
                                filled: true,
                                fillColor: Colors.black45,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _organizerPixNameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Nome Completo do Titular da Conta',
                                labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                prefixIcon: const Icon(Icons.person, color: AppTheme.accentGold, size: 18),
                                filled: true,
                                fillColor: Colors.black45,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Taxa Única de Ativação da Sala
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132E1D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bolt, color: AppTheme.accentGold, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  '⚡ Taxa Única de Ativação da Sala',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Automação completa da partida: placar ao vivo oficial, validação de palpites e apuração instantânea dos vencedores.',
                              style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => _activationMethod = 'pix'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: _activationMethod == 'pix' ? AppTheme.primaryGreen : Colors.black38,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _activationMethod == 'pix' ? AppTheme.accentGold : Colors.white12,
                                          width: _activationMethod == 'pix' ? 2 : 1,
                                        ),
                                      ),
                                      child: const Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.pix, color: Colors.tealAccent, size: 16),
                                              SizedBox(width: 4),
                                              Text('R\$ 4,90 (Pix)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                          SizedBox(height: 3),
                                          Text('Mercado Pago', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => _activationMethod = 'tokens'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: _activationMethod == 'tokens' ? AppTheme.primaryGreen : Colors.black38,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _activationMethod == 'tokens' ? AppTheme.accentGold : Colors.white12,
                                          width: _activationMethod == 'tokens' ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.stars, color: AppTheme.accentGold, size: 16),
                                              SizedBox(width: 4),
                                              Text('2.500 Tokens', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Saldo: ${ref.watch(currentUserProvider)?.tokens ?? 0}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sentiment_very_satisfied, color: Colors.greenAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🎉 Bolão Grátis! Ativação 100% gratuita para brincar com os amigos.',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Jogo (Times) -> Seleção via API ou Manual
                    const Text(
                      '⚽ Escolha a Partida do Bolão',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_activeLeagues.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Filtrar por Campeonato (Jogos de Hoje)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: const Color(0xFF1E3626),
                        style: const TextStyle(color: Colors.white),
                        initialValue: _selectedLeagueId,
                        items: _activeLeagues.map((l) {
                          return DropdownMenuItem<int>(
                            value: l.id,
                            child: Text(l.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              _selectedLeagueId = val;
                              _selectedFixtureId = null;
                            });
                            _fetchMatchesForBolao(val, setModalState);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_selectedLeagueId != null) ...[
                      _isFetchingMatches
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: CircularProgressIndicator(color: AppTheme.accentGold)),
                            )
                          : _fetchedMatches.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Nenhum jogo automático hoje neste campeonato. Você pode digitar o confronto abaixo!',
                                    style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Selecione a Partida Oficial',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.black26,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  dropdownColor: const Color(0xFF1E3626),
                                  style: const TextStyle(color: Colors.white),
                                  initialValue: _selectedFixtureId,
                                  isExpanded: true,
                                  items: _fetchedMatches.map((m) {
                                    return DropdownMenuItem<int>(
                                      value: m['fixture']['id'],
                                      child: Text(
                                        '${_matchTime(m)} • ${m['teams']['home']['name']} x ${m['teams']['away']['name']}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setModalState(() {
                                      _selectedFixtureId = val;
                                      final match = _fetchedMatches.firstWhere((m) => m['fixture']['id'] == val, orElse: () => null);
                                      if (match != null) {
                                        _matchTeamsCtrl.text = '${match['teams']['home']['name']} x ${match['teams']['away']['name']}';
                                        final rawDate = match['fixture']?['date']?.toString();
                                        if (rawDate != null) {
                                          _matchDateTime = DateTime.tryParse(rawDate)?.toLocal();
                                        }
                                      }
                                    });
                                  },
                                ),
                      const SizedBox(height: 10),
                    ],

                    // Confronto Manual / Editável
                    TextField(
                      controller: _matchTeamsCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confronto (Times da Partida)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Ex: Flamengo x Palmeiras',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.sports_soccer, color: AppTheme.accentGold),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Data e Hora do Jogo (Clicável para escolher caso seja jogo futuro/personalizado)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final now = DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _matchDateTime ?? now,
                          firstDate: now.subtract(const Duration(days: 1)),
                          lastDate: now.add(const Duration(days: 60)),
                        );
                        if (pickedDate != null && context.mounted) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_matchDateTime ?? now.add(const Duration(hours: 2))),
                          );
                          if (pickedTime != null) {
                            setModalState(() {
                              _matchDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.accentGold, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _matchDateTime != null
                                    ? '📅 Jogo: ${_matchDateTime!.day.toString().padLeft(2, '0')}/${_matchDateTime!.month.toString().padLeft(2, '0')}/${_matchDateTime!.year} às ${_matchDateTime!.hour.toString().padLeft(2, '0')}:${_matchDateTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Toque para definir a data e horário da partida',
                                style: TextStyle(
                                  color: _matchDateTime != null ? Colors.white : Colors.white70,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_calendar, color: AppTheme.accentGold, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Prazo de Encerramento do Bolão (Dropdown de Minutos)
                    const Text(
                      'Prazo para entrar no Bolão (antes do jogo)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: const Color(0xFF1E3626),
                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                      initialValue: _deadlineMinutes,
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 minutos antes do jogo')),
                        DropdownMenuItem(value: 30, child: Text('30 minutos antes do jogo')),
                        DropdownMenuItem(value: 60, child: Text('1 hora antes do jogo')),
                        DropdownMenuItem(value: 120, child: Text('2 horas antes do jogo')),
                        DropdownMenuItem(value: 1440, child: Text('24 horas antes do jogo')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            _deadlineMinutes = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botão Criar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isCreating
                            ? null
                            : () async {
                                if (_nameCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor, informe o nome do Bolão.'),
                                    ),
                                  );
                                  return;
                                }

                                if (!isFreeBolao) {
                                  if (_organizerPixKeyCtrl.text.trim().isEmpty || _organizerPixNameCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.amberAccent,
                                        content: Text('Informe sua Chave Pix e o Nome do Titular para os participantes enviarem as cotas!'),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                final user = ref.read(currentUserProvider);
                                final prizeLabel = isFreeBolao
                                    ? 'Bolão Recreativo / Troféu da Galera'
                                    : '$winnerPct% do Pote no Pix';

                                final bolaoData = {
                                  'name': _nameCtrl.text.trim(),
                                  'category': _category,
                                  'entryFee': _entryFeeCtrl.text.trim(),
                                  'prize': prizeLabel,
                                  'platformFee': 0,
                                  'creatorFee': _creatorFee,
                                  'winnerPrize': winnerPct,
                                  'organizerPixKey': isFreeBolao ? null : _organizerPixKeyCtrl.text.trim(),
                                  'organizerPixName': isFreeBolao ? null : _organizerPixNameCtrl.text.trim(),
                                  'matchTeams': _matchTeamsCtrl.text.trim().isEmpty
                                      ? null
                                      : _matchTeamsCtrl.text.trim(),
                                  'matchDateTime': _matchDateTime != null
                                      ? Timestamp.fromDate(_matchDateTime!)
                                      : null,
                                  'deadlineDateTime': _matchDateTime != null
                                      ? Timestamp.fromDate(
                                          _matchDateTime!.subtract(Duration(minutes: _deadlineMinutes)),
                                        )
                                      : null,
                                  'fixtureId': _selectedFixtureId,
                                  'leagueId': _selectedLeagueId,
                                  'creatorId': user?.id ?? 'anonymous',
                                  'creatorName': user?.name ?? 'Torcedor',
                                  'participantsCount': 0,
                                  'status': 'open',
                                  'createdAt': FieldValue.serverTimestamp(),
                                };

                                if (!isFreeBolao && _activationMethod == 'tokens') {
                                  final userTokens = user?.tokens ?? 0;
                                  if (userTokens < _bolaoActivationFeeTokens) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content: Text('Saldo de Tokens insuficiente! Você tem $userTokens tokens (necessário $_bolaoActivationFeeTokens). Ative no Pix (R\$ 4,90) ou ganhe mais tokens nos quizzes.'),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => _isCreating = true);
                                  try {
                                    await _dbService.activateBolaoWithTokens();
                                    final docRef = await _firestore.collection('boloes').add({
                                      ...bolaoData,
                                      'activationFeePaid': true,
                                      'activationMethod': 'tokens',
                                      'activationTokens': _bolaoActivationFeeTokens,
                                    });

                                    final bolaoName = _nameCtrl.text.trim();
                                    final entryFee = _entryFeeCtrl.text.trim();
                                    final pixKey = _organizerPixKeyCtrl.text.trim();
                                    final pixName = _organizerPixNameCtrl.text.trim();
                                    _nameCtrl.clear();
                                    _matchTeamsCtrl.clear();
                                    _matchDateTime = null;

                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      _shareBolao(
                                        bolaoId: docRef.id,
                                        name: bolaoName,
                                        entryFee: entryFee,
                                        prize: prizeLabel,
                                        organizerPixKey: pixKey,
                                        organizerPixName: pixName,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Erro ao ativar Bolão com Tokens: $e')),
                                      );
                                    }
                                  } finally {
                                    setModalState(() => _isCreating = false);
                                  }
                                  return;
                                }

                                if (!isFreeBolao && _activationMethod == 'pix') {
                                  final bolaoName = _nameCtrl.text.trim();
                                  final pixKey = _organizerPixKeyCtrl.text.trim();
                                  final pixName = _organizerPixNameCtrl.text.trim();
                                  _nameCtrl.clear();
                                  _matchTeamsCtrl.clear();
                                  _matchDateTime = null;

                                  Navigator.pop(ctx);
                                  _showActivationPixModal(
                                    parentContext: context,
                                    bolaoName: bolaoName,
                                    bolaoData: {
                                      ...bolaoData,
                                      'organizerPixKey': pixKey,
                                      'organizerPixName': pixName,
                                    },
                                  );
                                  return;
                                }

                                // Bolão Grátis
                                setModalState(() => _isCreating = true);
                                try {
                                  final docRef = await _firestore.collection('boloes').add({
                                    ...bolaoData,
                                    'activationFeePaid': true,
                                    'activationMethod': 'free',
                                  });

                                  final bolaoName = _nameCtrl.text.trim();
                                  final entryFee = _entryFeeCtrl.text.trim();
                                  _nameCtrl.clear();
                                  _matchTeamsCtrl.clear();
                                  _matchDateTime = null;

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    _shareBolao(
                                      bolaoId: docRef.id,
                                      name: bolaoName,
                                      entryFee: entryFee,
                                      prize: prizeLabel,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao criar Bolão: $e')),
                                    );
                                  }
                                } finally {
                                  setModalState(() => _isCreating = false);
                                }
                              },
                        child: _isCreating
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                                isFreeBolao
                                    ? 'CRIAR BOLÃO GRÁTIS 📲'
                                    : (_activationMethod == 'tokens'
                                        ? 'ATIVAR COM 2.500 TOKENS 🪙'
                                        : 'ATIVAR SALA NO PIX (R\$ 4,90) ⚡'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showJoinBolaoModal({
    required String bolaoId,
    required String name,
    required String category,
    required String creator,
    required String entryFee,
    required String prize,
    required int participants,
    String? organizerPixKey,
    String? organizerPixName,
    String? matchTeams,
    DateTime? deadlineDateTime,
    bool isEditing = false,
    int? initialHomeScore,
    int? initialAwayScore,
  }) {
    if (deadlineDateTime != null && DateTime.now().isAfter(deadlineDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('⏰ O prazo para registrar ou editar palpites neste bolão já encerrou!'),
        ),
      );
      return;
    }

    int homeScore = initialHomeScore ?? 2;
    int awayScore = initialAwayScore ?? 1;
    bool isJoining = false;

    String homeLabel = 'Mandante';
    String awayLabel = 'Visitante';
    if (matchTeams != null && matchTeams.contains(' x ')) {
      final parts = matchTeams.split(' x ');
      if (parts.length >= 2) {
        homeLabel = parts[0].trim();
        awayLabel = parts[1].trim();
      }
    }

    final entryVal = _parseEntryFee(entryFee);
    final isFree = entryVal <= 0;
    final currentPot = entryVal * (isEditing ? participants : (participants + 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0B2214),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppTheme.accentGold, width: 2),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.sports_soccer, color: AppTheme.accentGold, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEditing ? 'Editar Meu Palpite ⚽' : 'Entrar no Bolão ⚽',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: const TextStyle(color: AppTheme.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Entrada:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(
                                isFree ? 'GRÁTIS' : 'R\$ $entryFee (Pix)',
                                style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          if (!isFree) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Pote Estimado:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                Text(
                                  'R\$ ${_formatBrl(currentPot)}',
                                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Prêmio:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Expanded(
                                child: Text(
                                  prize,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Organizador:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(creator, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Crave o Placar Exato da Partida 🎯',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Placar Interativo com Botões - e +
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Time Casa
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  homeLabel,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: homeScore > 0
                                          ? () => setModalState(() => homeScore--)
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                                    ),
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.accentGold, width: 1.5),
                                      ),
                                      child: Text(
                                        '$homeScore',
                                        style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w900, fontSize: 22),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setModalState(() => homeScore++),
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentGold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('X', style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.w900)),
                          ),
                          // Time Visitante
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  awayLabel,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: awayScore > 0
                                          ? () => setModalState(() => awayScore--)
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                                    ),
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.accentGold, width: 1.5),
                                      ),
                                      child: Text(
                                        '$awayScore',
                                        style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w900, fontSize: 22),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setModalState(() => awayScore++),
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentGold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Palpites rápidos populares
                    Wrap(
                      spacing: 8,
                      children: [
                        [1, 0],
                        [2, 1],
                        [1, 1],
                        [2, 0],
                        [0, 1],
                        [3, 1],
                      ].map((pair) {
                        final selected = homeScore == pair[0] && awayScore == pair[1];
                        return ActionChip(
                          backgroundColor: selected ? AppTheme.accentGold : Colors.black38,
                          label: Text(
                            '${pair[0]} x ${pair[1]}',
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          onPressed: () {
                            setModalState(() {
                              homeScore = pair[0];
                              awayScore = pair[1];
                            });
                          },
                        );
                      }).toList(),
                    ),

                    if (!isEditing && !isFree) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.accentGold, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pix, color: Colors.tealAccent, size: 22),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Pagamento da Cota via Pix',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('DIRETO AO ANFITRIÃO', style: TextStyle(color: Colors.tealAccent, fontSize: 9.5, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Valor da cota: R\$ $entryFee\nEnvie via Pix diretamente para o organizador:',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            if (organizerPixKey != null && organizerPixKey.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Chave Pix: $organizerPixKey', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                          if (organizerPixName != null && organizerPixName.isNotEmpty)
                                            Text('Titular: $organizerPixName', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: AppTheme.accentGold, size: 20),
                                      tooltip: 'Copiar Chave Pix',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: organizerPixKey));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: AppTheme.primaryGreen,
                                            content: Text('Chave Pix do organizador copiada!'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Text('Organizador: $creator', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                            const SizedBox(height: 8),
                            const Text(
                              'Ao enviar o Pix para o organizador, confirme seu palpite abaixo. O organizador confere o comprovante e o app faz a classificação e apuração oficial!',
                              style: TextStyle(color: Colors.white54, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isJoining
                            ? null
                            : () async {
                                setModalState(() => isJoining = true);
                                try {
                                  final user = ref.read(currentUserProvider);
                                  final userId = user?.id ?? FirebaseFirestore.instance.app.options.projectId;
                                  final participantRef = _firestore
                                      .collection('boloes')
                                      .doc(bolaoId)
                                      .collection('participants')
                                      .doc(userId);
                                  final existingParticipant = await participantRef.get();
                                  final isNewParticipant = !existingParticipant.exists;

                                  if (isNewParticipant) {
                                    await _firestore.collection('boloes').doc(bolaoId).update({
                                      'participantsCount': FieldValue.increment(1),
                                    });

                                    await _firestore.collection('token_transactions').add({
                                      'uid': userId,
                                      'amount': entryFee,
                                      'type': 'bolao_entry_pix',
                                      'description': 'Entrada Bolão: $name',
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                  }

                                  await participantRef.set({
                                    'userId': userId,
                                    'userName': user?.name ?? 'Torcedor',
                                    'homeScore': homeScore,
                                    'awayScore': awayScore,
                                    if (isNewParticipant) 'joinedAt': FieldValue.serverTimestamp(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  }, SetOptions(merge: true));

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppTheme.primaryGreen,
                                        content: Text(
                                          isNewParticipant
                                              ? '🎉 Palpite $homeScore x $awayScore confirmado no Bolão "$name"!'
                                              : '✅ Palpite atualizado para $homeScore x $awayScore no Bolão "$name"!',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao salvar palpite: $e')),
                                    );
                                  }
                                } finally {
                                  setModalState(() => isJoining = false);
                                }
                              },
                        icon: isJoining
                            ? const SizedBox.shrink()
                            : Icon(isEditing || isFree ? Icons.check_circle : Icons.pix, color: Colors.tealAccent, size: 20),
                        label: isJoining
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isEditing
                                    ? 'SALVAR NOVO PALPITE ($homeScore x $awayScore)'
                                    : (isFree
                                        ? 'CONFIRMAR PALPITE GRÁTIS ($homeScore x $awayScore)'
                                        : 'CONFIRMAR PALPITE E ENTRAR (R\$ $entryFee)'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabIdx = _tabController.index;
    final selectedCategory = tabIdx == 0 ? 'amigos' : (tabIdx == 1 ? 'bar' : 'meus');
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: CustomScrollView(
        slivers: [
          // Header Hero Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004D25), Color(0xFF002814), Color(0xFF0B1910)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, size: 14, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              'NOVO MÓDULO',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _showCreateBolaoModal,
                        icon: const Icon(Icons.add_circle, color: AppTheme.accentGold, size: 28),
                        tooltip: 'Criar Bolão',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bolão do Gol ⚽',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dispute palpite a palpite com a galera ou nos seus bares favoritos. Pagamentos e saques instantâneos via Pix!',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _showCreateBolaoModal,
                    icon: const Icon(Icons.group_add, size: 18),
                    label: const Text(
                      'CRIAR MEU BOLÃO AGORA',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Campo de Busca por Nome ou Código de Convite (#ID)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: '🔍 Digite o Nome ou Código (#ID) do Bolão...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                  ),
                ),
              ),
            ),
          ),

          // Tabs: Amigos vs Bares vs Meus
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black12, width: 1.5),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryGreen,
                  indicatorWeight: 3.5,
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12.5),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups, size: 18),
                          SizedBox(width: 5),
                          Text('Amigos'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_bar, size: 18),
                          SizedBox(width: 5),
                          Text('Bares'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_pin, size: 18),
                          SizedBox(width: 5),
                          Text('Meus Bolões'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Lista de Bolões Ativos via StreamBuilder (Filtrado pela busca ou aba ativa)
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('boloes').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final rawDocs = snapshot.data?.docs ?? [];
                final searchQuery = _searchCtrl.text.trim().toLowerCase();

                final docs = rawDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cat = data['category'] ?? 'amigos';
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final matchStr = (data['matchTeams'] ?? '').toString().toLowerCase();
                  final id = doc.id.toLowerCase();
                  final shortCode = id.length > 6 ? id.substring(0, 6) : id;

                  if (searchQuery.isNotEmpty) {
                    return name.contains(searchQuery) ||
                        matchStr.contains(searchQuery) ||
                        id.contains(searchQuery) ||
                        shortCode.contains(searchQuery) ||
                        '#$shortCode'.contains(searchQuery);
                  }
                  if (selectedCategory == 'meus') {
                    return true; // Filtrado no card com base em criador ou participante
                  }
                  return cat == selectedCategory;
                }).toList();

                if (docs.isEmpty) {
                  final isBar = selectedCategory == 'bar';
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Icon(isBar ? Icons.sports_bar : Icons.groups, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          isBar ? 'Nenhum bolão de Bar ativo no momento' : 'Nenhum bolão ativo no momento',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBar
                              ? 'Cadastre o primeiro bolão do seu bar ou restaurante favorito!'
                              : 'Crie o primeiro bolão para disputar palpites com sua galera!',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _showCreateBolaoModal,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(isBar ? 'CRIAR BOLÃO DO BAR' : 'CRIAR BOLÃO DA GALERA'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchDt = data['matchDateTime'] as Timestamp?;
                    final deadlineDt = data['deadlineDateTime'] as Timestamp?;
                    return _buildBolaoCard(
                      bolaoId: doc.id,
                      name: data['name'] ?? 'Bolão de Futebol',
                      category: data['category'] ?? 'amigos',
                      creator: data['creatorName'] ?? 'Torcedor',
                      creatorId: data['creatorId'] ?? '',
                      entryFee: data['entryFee'] ?? '10,00',
                      prize: data['prize'] ?? 'Prêmio no Pix',
                      participants: data['participantsCount'] ?? 0,
                      organizerPixKey: data['organizerPixKey'] as String?,
                      organizerPixName: data['organizerPixName'] as String?,
                      matchTeams: data['matchTeams'] as String?,
                      matchDateTime: matchDt?.toDate(),
                      deadlineDateTime: deadlineDt?.toDate(),
                      status: data['status'] ?? 'open',
                      finalHomeScore: data['finalHomeScore'] as int?,
                      finalAwayScore: data['finalAwayScore'] as int?,
                      onlyShowIfMineOrParticipating: selectedCategory == 'meus' && searchQuery.isEmpty,
                      currentUserIdFilter: currentUserId,
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Seção de Patrocinadores
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('sponsors').where('isActive', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                final sponsors = snapshot.data?.docs ?? [];
                if (sponsors.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PATROCINADORES',
                              style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Apoiadores do Bolão do Gol',
                            style: TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sponsors.map((doc) {
                            final sp = doc.data() as Map<String, dynamic>;
                            final name = sp['name'] ?? '';
                            final logoUrl = sp['logoUrl'] ?? '';
                            final website = sp['website'] ?? '';
                            return GestureDetector(
                              onTap: website.isNotEmpty
                                  ? () async {
                                      final uri = Uri.tryParse(website);
                                      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  : null,
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    if (logoUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          logoUrl,
                                          height: 40,
                                          width: 80,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.handshake, size: 40, color: AppTheme.primaryGreen),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.handshake, size: 40, color: AppTheme.primaryGreen),
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

        ],
      ),
    );
  }

  void _shareBolao({
    required String bolaoId,
    required String name,
    required String entryFee,
    required String prize,
    String? organizerPixKey,
    String? organizerPixName,
  }) async {
    final shortCode = bolaoId.length > 6 ? bolaoId.substring(0, 6).toUpperCase() : bolaoId.toUpperCase();
    final playStoreUrl = 'https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol';
    final webAppUrl = 'https://app-raspadinhadogol.web.app/#/bolao?id=$bolaoId';
    final isFree = _parseEntryFee(entryFee) <= 0;

    String pixSection = '';
    if (!isFree && organizerPixKey != null && organizerPixKey.isNotEmpty) {
      pixSection = '💳 *Chave Pix do Organizador:* $organizerPixKey ${organizerPixName != null ? "($organizerPixName)" : ""}\n'
          '📲 Envie sua cota de R\$ $entryFee direto ao organizador via Pix para confirmar seu palpite!\n\n';
    }

    final shareMessage =
        '⚽ *Você foi convidado para o Bolão do Gol: "$name"!* ⚽\n\n'
        '🏆 *Prêmio:* $prize\n'
        '💰 *Entrada:* ${isFree ? "GRÁTIS" : "R\$ $entryFee (Pix)"}\n\n'
        '$pixSection'
        '👇 *COMO PARTICIPAR:*\n'
        '1️⃣ *Baixe o App na Play Store:*\n'
        '🔗 $playStoreUrl\n\n'
        '2️⃣ *Abra o App e digite o Código do Bolão:*\n'
        '🔑 *#$shortCode*\n\n'
        '💻 *Ou participe pelo Navegador no link direto:*\n'
        '👉 $webAppUrl';
    await Clipboard.setData(ClipboardData(text: shareMessage));

    final whatsappUrl = Uri.parse(
      'https://api.whatsapp.com/send?text=${Uri.encodeComponent(shareMessage)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(shareMessage);
      }
    } catch (_) {
      await Share.share(shareMessage);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Text('📲 Convite do Bolão #$shortCode copiado!'),
        ),
      );
    }
  }

  void _showBolaoDetailsModal({
    required String bolaoId,
    required String name,
    required String category,
    required String creator,
    required String entryFee,
    required String prize,
    required int participants,
    required bool isUserParticipating,
    String? organizerPixKey,
    String? organizerPixName,
    int? myHomeScore,
    int? myAwayScore,
    required String status,
    int? finalHomeScore,
    int? finalAwayScore,
    String? matchTeams,
    DateTime? deadlineDateTime,
  }) {
    final entryVal = _parseEntryFee(entryFee);
    final totalPot = entryVal * participants;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0B2214),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.accentGold, width: 2),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.leaderboard_rounded, color: AppTheme.accentGold, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        matchTeams != null ? '⚽ $matchTeams • Por: $creator' : 'Organizado por: $creator',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _shareBolao(
                    bolaoId: bolaoId,
                    name: name,
                    entryFee: entryFee,
                    prize: prize,
                    organizerPixKey: organizerPixKey,
                    organizerPixName: organizerPixName,
                  ),
                  icon: const Icon(Icons.share, color: AppTheme.accentGold),
                  tooltip: 'Compartilhar no WhatsApp',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Card resumo do pote e premiação
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🏆 Pote & Prêmio', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          entryVal > 0 ? 'R\$ ${_formatBrl(totalPot)} ($prize)' : prize,
                          style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('👥 Participantes', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('$participants torcedores', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Chave Pix do Organizador para consultas
            if (entryVal > 0 && organizerPixKey != null && organizerPixKey.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pix, color: Colors.tealAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chave Pix do Anfitrião: $organizerPixKey', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
                          if (organizerPixName != null && organizerPixName.isNotEmpty)
                            Text('Titular: $organizerPixName', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.accentGold, size: 18),
                      tooltip: 'Copiar Chave Pix',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: organizerPixKey));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.primaryGreen,
                            content: Text('Chave Pix copiada com sucesso!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Status se o usuário atual participa ou não
            if (isUserParticipating)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Você está participando deste Bolão!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          if (myHomeScore != null && myAwayScore != null)
                            Text('Seu palpite registrado: $myHomeScore x $myAwayScore', style: const TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (status != 'completed')
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppTheme.accentGold),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showJoinBolaoModal(
                            bolaoId: bolaoId,
                            name: name,
                            category: category,
                            creator: creator,
                            entryFee: entryFee,
                            prize: prize,
                            participants: participants,
                            organizerPixKey: organizerPixKey,
                            organizerPixName: organizerPixName,
                            matchTeams: matchTeams,
                            deadlineDateTime: deadlineDateTime,
                            isEditing: true,
                            initialHomeScore: myHomeScore,
                            initialAwayScore: myAwayScore,
                          );
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Editar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              )
            else if (status == 'completed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Column(
                  children: [
                    const Text('🏆 BOLÃO ENCERRADO!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Placar Final Oficial: $finalHomeScore x $finalAwayScore', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(
                      'O organizador ${organizerPixName ?? creator} deve realizar a transferência Pix do prêmio aos vencedores que cravaram o placar abaixo!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showJoinBolaoModal(
                      bolaoId: bolaoId,
                      name: name,
                      category: category,
                      creator: creator,
                      entryFee: entryFee,
                      prize: prize,
                      participants: participants,
                      organizerPixKey: organizerPixKey,
                      organizerPixName: organizerPixName,
                      matchTeams: matchTeams,
                      deadlineDateTime: deadlineDateTime,
                    );
                  },
                  icon: Icon(entryVal > 0 ? Icons.pix : Icons.sports_soccer, size: 18),
                  label: Text(
                    entryVal > 0 ? 'ENTRAR NO BOLÃO (R\$ $entryFee)' : 'ENTRAR GRÁTIS NO BOLÃO',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            const Text(
              'Ranking & Palpites dos Participantes ⚽',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),

            // Lista de Participantes em tempo real via StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('boloes')
                    .doc(bolaoId)
                    .collection('participants')
                    .orderBy('joinedAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = (snapshot.data?.docs ?? []).toList();
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum palpite registrado ainda. Seja o primeiro!',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  if (status == 'completed' && finalHomeScore != null && finalAwayScore != null) {
                    docs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aWon = aData['homeScore'] == finalHomeScore && aData['awayScore'] == finalAwayScore;
                      final bWon = bData['homeScore'] == finalHomeScore && bData['awayScore'] == finalAwayScore;
                      if (aWon && !bWon) return -1;
                      if (!aWon && bWon) return 1;
                      return 0;
                    });
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final pData = docs[index].data() as Map<String, dynamic>;
                      final pName = pData['userName'] ?? 'Torcedor';
                      final home = pData['homeScore'] ?? 0;
                      final away = pData['awayScore'] ?? 0;
                      final pUid = pData['userId'] ?? '';
                      final isMe = pUid == ref.read(currentUserProvider)?.id;
                      final isExactWinner = status == 'completed' &&
                          finalHomeScore != null &&
                          finalAwayScore != null &&
                          home == finalHomeScore &&
                          away == finalAwayScore;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isExactWinner
                              ? AppTheme.accentGold.withValues(alpha: 0.2)
                              : (isMe ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isExactWinner
                                ? AppTheme.accentGold
                                : (isMe ? AppTheme.primaryGreen : Colors.white10),
                            width: isExactWinner ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isExactWinner || isMe ? AppTheme.accentGold : Colors.white24,
                              child: Text(
                                isExactWinner ? '🏆' : '${index + 1}º',
                                style: TextStyle(
                                  color: isExactWinner || isMe ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
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
                                          pName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (isMe)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentGold,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'VOCÊ',
                                            style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                      if (isExactWinner)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'CRAVOU!',
                                            style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isExactWinner ? 'Vencedor do Pote!' : 'Participante confirmado',
                                    style: TextStyle(
                                      color: isExactWinner ? Colors.greenAccent : Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'Palpite: $home x $away',
                                style: const TextStyle(
                                  color: AppTheme.accentGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
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
      ),
    );
  }

  Widget _buildBolaoCard({
    required String bolaoId,
    required String name,
    required String category,
    required String creator,
    required String creatorId,
    required String entryFee,
    required String prize,
    required int participants,
    String? organizerPixKey,
    String? organizerPixName,
    String? matchTeams,
    DateTime? matchDateTime,
    DateTime? deadlineDateTime,
    String status = 'open',
    int? finalHomeScore,
    int? finalAwayScore,
    bool onlyShowIfMineOrParticipating = false,
    String currentUserIdFilter = '',
  }) {
    final isBar = category == 'bar';
    final user = ref.watch(currentUserProvider);
    final currentUserId = user?.id ?? FirebaseFirestore.instance.app.options.projectId;
    final shortCode = bolaoId.length > 6 ? bolaoId.substring(0, 6).toUpperCase() : bolaoId.toUpperCase();
    final isCreator = currentUserId == creatorId;
    final canDelete = isCreator && participants == 0;
    final entryVal = _parseEntryFee(entryFee);
    final isFree = entryVal <= 0;
    final totalPot = entryVal * participants;

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('boloes')
          .doc(bolaoId)
          .collection('participants')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, participantSnapshot) {
        final isParticipating = participantSnapshot.hasData && participantSnapshot.data!.exists;
        if (onlyShowIfMineOrParticipating && !isCreator && !isParticipating) {
          return const SizedBox.shrink();
        }
        final myData = isParticipating ? (participantSnapshot.data!.data() as Map<String, dynamic>?) : null;
        final myHomeScore = myData?['homeScore'] as int?;
        final myAwayScore = myData?['awayScore'] as int?;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isParticipating
                  ? AppTheme.primaryGreen
                  : (isBar ? Colors.amber.shade400 : AppTheme.primaryGreen.withValues(alpha: 0.2)),
              width: isParticipating ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do Card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBar
                          ? Colors.amber.shade100
                          : AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBar ? Icons.sports_bar : Icons.groups,
                      color: isBar ? Colors.amber.shade900 : AppTheme.primaryGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppTheme.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isParticipating)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'PARTICIPANDO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Por: $creator',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(text: '#$shortCode'));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('📋 Código #$shortCode copiado!'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#$shortCode',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.copy, size: 10, color: Colors.black54),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGold),
                    ),
                    child: Text(
                      isFree ? 'GRÁTIS' : 'R\$ $entryFee',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Prêmio, Pote Acumulado e Participantes
              Row(
                children: [
                  const Icon(Icons.military_tech, size: 16, color: AppTheme.accentGold),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      !isFree && totalPot > 0
                          ? 'Pote: R\$ ${_formatBrl(totalPot)} • $prize'
                          : 'Prêmio: $prize',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text(
                    '$participants torcedores',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              // Info do Jogo (se definido)
              if (matchTeams != null || matchDateTime != null || deadlineDateTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004D25).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (matchTeams != null)
                          Row(
                            children: [
                              const Icon(Icons.sports_soccer, size: 13, color: AppTheme.primaryGreen),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  matchTeams,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (matchDateTime != null) ...[
                          if (matchTeams != null) const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 13, color: Colors.black45),
                              const SizedBox(width: 5),
                              Text(
                                '${matchDateTime.day.toString().padLeft(2, '0')}/${matchDateTime.month.toString().padLeft(2, '0')}/${matchDateTime.year} às ${matchDateTime.hour.toString().padLeft(2, '0')}:${matchDateTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                        if (deadlineDateTime != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.timer_off, size: 13, color: Colors.redAccent),
                              const SizedBox(width: 5),
                              Text(
                                'Encerra palpites: ${deadlineDateTime.day.toString().padLeft(2, '0')}/${deadlineDateTime.month.toString().padLeft(2, '0')} às ${deadlineDateTime.hour.toString().padLeft(2, '0')}:${deadlineDateTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Link sempre visível para ver participantes
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: GestureDetector(
                  onTap: () => _showBolaoDetailsModal(
                    bolaoId: bolaoId,
                    name: name,
                    category: category,
                    creator: creator,
                    entryFee: entryFee,
                    prize: prize,
                    participants: participants,
                    organizerPixKey: organizerPixKey,
                    organizerPixName: organizerPixName,
                    isUserParticipating: isParticipating,
                    myHomeScore: myHomeScore,
                    myAwayScore: myAwayScore,
                    status: status,
                    finalHomeScore: finalHomeScore,
                    finalAwayScore: finalAwayScore,
                    matchTeams: matchTeams,
                    deadlineDateTime: deadlineDateTime,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups, size: 16, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Text(
                          'Ver palpites e ranking ($participants)',
                          style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 16, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),

              // Se o usuário está participando, mostra o palpite atual registrado
              if (isParticipating && myHomeScore != null && myAwayScore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_soccer, size: 16, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Seu palpite: $myHomeScore x $myAwayScore',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (status != 'completed')
                          GestureDetector(
                            onTap: () => _showJoinBolaoModal(
                              bolaoId: bolaoId,
                              name: name,
                              category: category,
                              creator: creator,
                              entryFee: entryFee,
                              prize: prize,
                              participants: participants,
                              organizerPixKey: organizerPixKey,
                              organizerPixName: organizerPixName,
                              matchTeams: matchTeams,
                              deadlineDateTime: deadlineDateTime,
                              isEditing: true,
                              initialHomeScore: myHomeScore,
                              initialAwayScore: myAwayScore,
                            ),
                            child: const Text(
                              'Alterar ✏️',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Botões de Ação
              Row(
                children: [
                  if (canDelete) ...[
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                      ),
                      tooltip: 'Excluir Bolão',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Excluir Bolão?'),
                            content: Text(
                              'Tem certeza que deseja excluir o bolão "$name"?\n\nEsta ação não pode ser desfeita.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Excluir'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          try {
                            await _firestore.collection('boloes').doc(bolaoId).delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red.shade700,
                                  content: Text('Bolão "$name" excluído.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao excluir: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Botão Compartilhar WhatsApp
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade800,
                    ),
                    onPressed: () => _shareBolao(
                      bolaoId: bolaoId,
                      name: name,
                      entryFee: entryFee,
                      prize: prize,
                      organizerPixKey: organizerPixKey,
                      organizerPixName: organizerPixName,
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    tooltip: 'Compartilhar',
                  ),
                  const SizedBox(width: 8),

                  // Botão Entrar ou Ver Ranking
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: isParticipating
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _showBolaoDetailsModal(
                                bolaoId: bolaoId,
                                name: name,
                                category: category,
                                creator: creator,
                                entryFee: entryFee,
                                prize: prize,
                                participants: participants,
                                organizerPixKey: organizerPixKey,
                                organizerPixName: organizerPixName,
                                isUserParticipating: true,
                                myHomeScore: myHomeScore,
                                myAwayScore: myAwayScore,
                                status: status,
                                finalHomeScore: finalHomeScore,
                                finalAwayScore: finalAwayScore,
                                matchTeams: matchTeams,
                                deadlineDateTime: deadlineDateTime,
                              ),
                              icon: const Icon(Icons.leaderboard, size: 16),
                              label: const Text(
                                'VER PALPITES & CLASSIFICAÇÃO',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            )
                          : OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                                side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _showJoinBolaoModal(
                                bolaoId: bolaoId,
                                name: name,
                                category: category,
                                creator: creator,
                                entryFee: entryFee,
                                prize: prize,
                                participants: participants,
                                organizerPixKey: organizerPixKey,
                                organizerPixName: organizerPixName,
                                matchTeams: matchTeams,
                                deadlineDateTime: deadlineDateTime,
                              ),
                              icon: Icon(isFree ? Icons.sports_soccer : Icons.pix, size: 16, color: AppTheme.primaryGreen),
                              label: Text(
                                isFree ? 'PARTICIPAR GRÁTIS' : 'ENTRAR NO BOLÃO (PIX)',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
