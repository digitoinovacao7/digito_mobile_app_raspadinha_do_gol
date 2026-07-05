import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/game_provider.dart';
import '../core/theme.dart';
import '../models/league_info.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _apiFootballController = TextEditingController();
  final _footballDataController = TextEditingController();
  String _activeFootballApi = 'api_football';
  final _mercadoPagoController = TextEditingController();
  final _zApiController = TextEditingController();
  final _geminiApiController = TextEditingController();
  final _scratchcardCostController = TextEditingController();
  final _quizRewardController = TextEditingController();
  final _dailyQuizLimitController = TextEditingController();
  final _globalWinChanceController = TextEditingController();
  final _pinnacleUsernameController = TextEditingController();
  final _pinnaclePasswordController = TextEditingController();
  final _geminiTestContextController = TextEditingController();

  final _newPrizeNameCtrl = TextEditingController();
  final _newPrizeImageCtrl = TextEditingController();
  final _newPrizeTokenCostCtrl = TextEditingController();
  final _newPrizeLinkCtrl = TextEditingController();
  String _newPrizeType = 'pix'; // 'produto' ou 'pix'
  String _newPrizeScope = 'league'; // 'league', 'match'
  int? _selectedLeagueId;
  int? _selectedFixtureId;
  List<dynamic> _fetchedMatches = [];
  bool _isFetchingMatches = false;
  List<LeagueInfo> _activeLeagues = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingPrize = false;
  bool _isAnalyzing = false;
  String? _pinnacleBalance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final docSnap = await FirebaseFirestore.instance.collection('settings').doc('general').get();

      if (docSnap.exists) {
        final data = docSnap.data() ?? {};
        
        final apiKeys = (data['api_keys'] as Map<String, dynamic>?) ?? {};
        
        _apiFootballController.text = apiKeys['api_football']?.toString() ?? data['api_football_key']?.toString() ?? data['api_football']?.toString() ?? '';
        _footballDataController.text = apiKeys['football_data']?.toString() ?? data['football_data_key']?.toString() ?? data['football_data']?.toString() ?? '';
        _activeFootballApi = data['active_football_api']?.toString() ?? 'api_football';
        _mercadoPagoController.text = apiKeys['mercado_pago']?.toString() ?? data['mercado_pago_key']?.toString() ?? data['mercado_pago']?.toString() ?? '';
        _zApiController.text = apiKeys['z_api']?.toString() ?? data['z_api_key']?.toString() ?? data['z_api']?.toString() ?? '';
        _geminiApiController.text = apiKeys['gemini']?.toString() ?? data['gemini_api_key']?.toString() ?? data['gemini_key']?.toString() ?? data['gemini']?.toString() ?? '';

        if (data.containsKey('economy')) {
          final economy = data['economy'] as Map<String, dynamic>;
          _scratchcardCostController.text = economy['scratchcard_token_cost']?.toString() ?? '1000';
          _quizRewardController.text = economy['quiz_reward']?.toString() ?? '250';
          _dailyQuizLimitController.text = economy['daily_quiz_limit']?.toString() ?? '3';
        }

        if (data.containsKey('prize_rules')) {
          _globalWinChanceController.text = data['prize_rules']['global_win_chance']?.toString() ?? '10';
        }
        
        if (data.containsKey('pinnacle')) {
          _pinnacleUsernameController.text = data['pinnacle']['username'] ?? '';
          _pinnaclePasswordController.text = data['pinnacle']['password'] ?? '';
        }
      }
      
      // Load leagues for the dropdowns
      final service = ref.read(footballServiceProvider);
      final leagues = await service.getActiveLeaguesForToday();
      if (mounted) {
        _activeLeagues = leagues;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar configurações: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _apiFootballController.dispose();
    _footballDataController.dispose();
    _mercadoPagoController.dispose();
    _zApiController.dispose();
    _geminiApiController.dispose();
    _scratchcardCostController.dispose();
    _quizRewardController.dispose();
    _dailyQuizLimitController.dispose();
    _globalWinChanceController.dispose();
    _pinnacleUsernameController.dispose();
    _pinnaclePasswordController.dispose();
    _geminiTestContextController.dispose();
    _newPrizeNameCtrl.dispose();
    _newPrizeImageCtrl.dispose();
    _newPrizeTokenCostCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('settings').doc('general').set({
        'active_football_api': _activeFootballApi,
        'api_keys': {
          'api_football': _apiFootballController.text,
          'football_data': _footballDataController.text,
          'mercado_pago': _mercadoPagoController.text,
          'z_api': _zApiController.text,
          'gemini': _geminiApiController.text,
        },
        'economy': {
          'scratchcard_token_cost': int.tryParse(_scratchcardCostController.text) ?? 1000,
          'quiz_reward': int.tryParse(_quizRewardController.text) ?? 250,
          'daily_quiz_limit': int.tryParse(_dailyQuizLimitController.text) ?? 3,
        },
        'prize_rules': {
          'global_win_chance': int.tryParse(_globalWinChanceController.text) ?? 10,
        },
        'pinnacle': {
          'username': _pinnacleUsernameController.text,
          'password': _pinnaclePasswordController.text,
        }
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações salvas!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Administrativo'),
          backgroundColor: AppTheme.primaryGreen,
          bottom: const TabBar(
            indicatorColor: AppTheme.accentGold,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.stars), text: 'Regras e Prêmios'),
              Tab(icon: Icon(Icons.api), text: 'Integrações'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Resgates'),
              Tab(icon: Icon(Icons.smart_toy), text: 'Robô Pinnacle'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildPrizesTab(),
                  _buildIntegrationsTab(),
                  _buildRedemptionsTab(),
                  _buildPinnacleBotTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildPinnacleBotTab() {
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.smart_toy, 'Status do Robô Pinnacle'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            const Text('Status: Desconectado / Aguardando Teste', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _testPinnacleConnection,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Testar Conexão / Ver Saldo'),
                            )
                          ],
                        ),
                      ),
                      if (_pinnacleBalance != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text('Saldo Disponível: R\$ $_pinnacleBalance', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                        ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(Icons.settings, 'Configurações de Aposta Automática'),
                      const SizedBox(height: 16),
                      const Text('Defina as regras de quanto o robô deve apostar a cada sinal gerado.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: TextEditingController(text: '5.00'),
                        label: 'Gestão de Banca (%)',
                        hint: 'Ex: 5.00',
                        keyboardType: TextInputType.number,
                        helpText: 'Porcentagem do saldo total da Pinnacle que será apostada em cada sinal.',
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Ativar Trading Automático'),
                        subtitle: const Text('Se ativo, o robô irá colocar apostas reais na Pinnacle usando o saldo da conta Master.'),
                        value: false,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve: Ativação requer validação de saldo Pinnacle.')));
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(Icons.psychology, 'Analista de Apostas (Gemini IA)'),
                      const SizedBox(height: 16),
                      const Text('Cole o contexto de um jogo abaixo e peça para a Inteligência Artificial analisar se vale a pena apostar.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _geminiTestContextController,
                        label: 'Contexto do Jogo (Ex: Flamengo 0x1 Vasco, 75 min, 80% posse...)',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                          onPressed: _isAnalyzing ? null : _testGeminiAnalysis,
                          icon: _isAnalyzing 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Icon(Icons.analytics),
                          label: Text(_isAnalyzing ? 'Analisando...' : 'Pedir Análise ao Gemini'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.list_alt, 'Últimas Operações (Logs)'),
                      const SizedBox(height: 16),
                      _buildPinnacleLogsList(),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.api, 'Provedor de Futebol ao Vivo'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _activeFootballApi,
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGreen),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() => _activeFootballApi = newValue);
                            },
                            items: const [
                              DropdownMenuItem(value: 'api_football', child: Text('API-Football (Recomendado/Produção)')),
                              DropdownMenuItem(value: 'football_data', child: Text('Football-Data.org (Testes/Gratuito)')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(Icons.vpn_key, 'Chaves de Integração'),
                      const SizedBox(height: 24),
                      if (_activeFootballApi == 'api_football') ...[
                        _buildTextField(
                          controller: _apiFootballController,
                          label: 'Chave API-Football',
                          hint: 'Usada caso API-Football esteja ativa',
                          helpText: 'Obtenha em dashboard.api-football.com.',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton.icon(
                            onPressed: () => launchUrl(Uri.parse('https://dashboard.api-football.com/'), mode: LaunchMode.externalApplication),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Obter Chave no Dashboard da API-Football'),
                            style: TextButton.styleFrom(foregroundColor: Colors.blue, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_activeFootballApi == 'football_data') ...[
                        _buildTextField(
                          controller: _footballDataController,
                          label: 'Chave Football-Data.org',
                          hint: 'Usada caso Football-Data esteja ativa',
                          helpText: 'Obtenha em api.football-data.org.',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton.icon(
                            onPressed: () => launchUrl(Uri.parse('https://www.football-data.org/'), mode: LaunchMode.externalApplication),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Obter Chave no Football-Data.org'),
                            style: TextButton.styleFrom(foregroundColor: Colors.blue, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(
                        controller: _geminiApiController,
                        label: 'Chave Gemini (Google IA)',
                        hint: 'Usada para gerar os Quizzes do jogo',
                        helpText: 'Chave da API do Google Gemini. Necessária para a Inteligência Artificial gerar perguntas sobre futebol em tempo real. Obtenha no Google AI Studio.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _mercadoPagoController,
                        label: 'Chave Mercado Pago',
                        hint: 'Usada para disparar PIX automaticamente (Futuro)',
                        helpText: 'Chave da API do Mercado Pago. Servirá para realizar o pagamento automático via PIX aos usuários (em breve).',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _zApiController,
                        label: 'Chave Z-API',
                        hint: 'Usada para notificações via WhatsApp',
                        helpText: 'Chave de instância da Z-API. Necessária para enviar comprovantes e notificações de premiação diretamente no WhatsApp do ganhador.',
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(Icons.smart_toy, 'Robô de Apostas (Pinnacle)'),
                      const SizedBox(height: 8),
                      const Text('Configuração da conta Master (Admin) para o Robô da Pinnacle operar.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _pinnacleUsernameController,
                        label: 'Client ID (Usuário) Pinnacle',
                        hint: 'Ex: AC123456',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _pinnaclePasswordController,
                        label: 'Senha da Pinnacle',
                        hint: 'Sua senha da Pinnacle',
                        obscureText: true,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Salvando...' : 'Salvar Configurações'),
        onPressed: _isSaving ? null : _saveSettings,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.monetization_on, 'Regra de Economia'),
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
                        helpText: 'Tokens descontados do saldo do usuário para raspar 1 vez.\nSugestão: 1000 (Assim o usuário precisa acertar 4 quizzes para ter o direito de jogar).',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _quizRewardController,
                        label: 'Prêmio por Acerto',
                        hint: 'Ex: 100',
                        keyboardType: TextInputType.number,
                        helpText: 'Tokens ganhos DE GRAÇA ao acertar a pergunta da IA durante o jogo ao vivo.\nSugestão: 100 (Gera dopamina de ganho rápido).',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _globalWinChanceController,
                        label: 'Chance de Vitória (%)',
                        hint: 'Ex: 10',
                        keyboardType: TextInputType.number,
                        helpText: 'A probabilidade global (RNG) de qualquer raspadinha ser premiada.\nEx: 10 significa que 10% das jogadas ganharão um dos prêmios ativos.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _dailyQuizLimitController,
                        label: 'Limite Diário de Quizzes',
                        hint: 'Ex: 3',
                        keyboardType: TextInputType.number,
                        helpText: 'Quantidade máxima de quizzes que um usuário pode gerar por dia (para controle de custos da API do Gemini).',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Salvando...' : 'Salvar Regras', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          onPressed: _isSaving ? null : _saveSettings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.add_circle_outline, 'Adicionar Prêmio da Raspadinha'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Cadastre os prêmios (PIX ou Físicos) que podem sair quando o usuário raspar a cartela e tirar 3 figuras iguais.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextButton.icon(
                          onPressed: () => launchUrl(Uri.parse('https://dashboard.api-football.com/'), mode: LaunchMode.externalApplication),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Consultar IDs no Dashboard da API-Football'),
                          style: TextButton.styleFrom(foregroundColor: Colors.blue),
                        ),
                      ),
                      _buildPrizeForm(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.card_giftcard, 'Prêmios Cadastrados'),
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

  Widget _buildPrizeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escopo do Prêmio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [

            ChoiceChip(
              label: const Text('Campeonato', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _newPrizeScope == 'league',
              onSelected: (v) => setState(() { _newPrizeScope = 'league'; _selectedFixtureId = null; }),
              selectedColor: AppTheme.accentGold,
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            ChoiceChip(
              label: const Text('Jogo Específico', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _newPrizeScope == 'match',
              onSelected: (v) => setState(() { _newPrizeScope = 'match'; if (_selectedLeagueId != null) _fetchMatchesForAdmin(_selectedLeagueId!); }),
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
                    const Expanded(child: Text('Nenhum campeonato ativo no momento.', style: TextStyle(color: Colors.red))),
                    TextButton(onPressed: _loadSettings, child: const Text('Tentar Novamente')),
                  ],
                )
              : DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Selecione o Campeonato', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  value: _selectedLeagueId,
                  items: _activeLeagues.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                  onChanged: (val) {
                    setState(() { _selectedLeagueId = val; _selectedFixtureId = null; });
                    if (_newPrizeScope == 'match' && val != null) _fetchMatchesForAdmin(val);
                  },
                ),
        ],
        if (_newPrizeScope == 'match') ...[
          const SizedBox(height: 16),
          _isFetchingMatches
              ? const CircularProgressIndicator()
              : DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Selecione a Partida de Hoje', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  value: _selectedFixtureId,
                  items: _fetchedMatches.map((m) => DropdownMenuItem<int>(value: m['fixture']['id'], child: Text('${m['teams']['home']['name']} x ${m['teams']['away']['name']}'))).toList(),
                  onChanged: (val) => setState(() => _selectedFixtureId = val),
                ),
        ],
        const SizedBox(height: 32),
        const Text('Tipo de Prêmio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _newPrizeType = 'pix'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _newPrizeType == 'pix' ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
                    border: Border.all(color: _newPrizeType == 'pix' ? AppTheme.primaryGreen : Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.pix, color: _newPrizeType == 'pix' ? AppTheme.primaryGreen : Colors.grey, size: 36),
                      const SizedBox(height: 12),
                      Text('Saque PIX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _newPrizeType == 'pix' ? AppTheme.primaryGreen : Colors.grey.shade700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _newPrizeType = 'produto'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _newPrizeType == 'produto' ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
                    border: Border.all(color: _newPrizeType == 'produto' ? AppTheme.primaryGreen : Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.card_giftcard, color: _newPrizeType == 'produto' ? AppTheme.primaryGreen : Colors.grey, size: 36),
                      const SizedBox(height: 12),
                      Text('Produto / Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _newPrizeType == 'produto' ? AppTheme.primaryGreen : Colors.grey.shade700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Detalhes do Prêmio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _newPrizeNameCtrl,
          label: _newPrizeType == 'pix' ? 'Valor do PIX a ser pago (Ex: R\$ 50,00)' : 'Nome do Produto (Ex: Camisa)',
          hint: _newPrizeType == 'pix' ? 'Ex: 50,00' : 'O que o usuário vai ganhar?',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _newPrizeTokenCostCtrl,
          label: 'Custo na Loja (Tokens)',
          hint: 'Ex: 50000. 0 = Só na Sorte',
          keyboardType: TextInputType.number,
          helpText: 'Preço se o usuário quiser COMPRAR este prêmio na loja usando os tokens acumulados (sem contar com a sorte).\nDeixe 0 se o prêmio só puder ser ganho raspando.',
        ),
        if (_newPrizeType == 'produto') ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _newPrizeImageCtrl,
            label: 'URL da Imagem (Opcional)',
            hint: 'https://site.com/foto.png',
          ),
        ],
        if (_newPrizeType == 'produto') ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _newPrizeLinkCtrl,
            label: 'URL do Link Afiliado / Cupom (Opcional)',
            hint: 'Link de indicação (Ex: Shopee, Betano, etc)',
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            icon: _isSavingPrize
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add_circle, size: 24),
            label: Text(_isSavingPrize ? 'Salvando...' : 'Cadastrar Novo Prêmio', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _isSavingPrize ? null : _saveNewPrize,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchMatchesForAdmin(int leagueId) async {
    setState(() { _isFetchingMatches = true; _fetchedMatches = []; _selectedFixtureId = null; });
    try {
      final service = ref.read(footballServiceProvider);
      final matches = await service.getMatchesForLeague(leagueId);
      if (mounted) setState(() => _fetchedMatches = matches);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar jogos: $e')));
    } finally {
      if (mounted) setState(() => _isFetchingMatches = false);
    }
  }

  Future<void> _saveNewPrize() async {
    final name = _newPrizeNameCtrl.text.trim();
    final tokenCost = int.tryParse(_newPrizeTokenCostCtrl.text.trim()) ?? 0;
    final image = _newPrizeImageCtrl.text.trim();
    final prizeLink = _newPrizeLinkCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o nome do prêmio.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_newPrizeScope == 'league' && _selectedLeagueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um Campeonato.'), backgroundColor: Colors.red));
      return;
    }

    if (_newPrizeScope == 'match' && _selectedFixtureId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma Partida.'), backgroundColor: Colors.red));
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
      setState(() { _newPrizeScope = 'league'; _selectedLeagueId = null; _selectedFixtureId = null; _fetchedMatches = []; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prêmio adicionado com sucesso!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isSavingPrize = false);
    }
  }

  Widget _buildPrizesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('prizes').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: prize['image_url'] != null && prize['image_url'].toString().isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(prize['image_url'], fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(isPix ? Icons.pix : Icons.card_giftcard, color: Colors.grey)))
                      : Icon(isPix ? Icons.pix : Icons.card_giftcard, color: Colors.grey),
                ),
                title: Text(prize['name'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(prize['scope'] == 'global' ? Icons.public : (prize['scope'] == 'league' ? Icons.emoji_events : Icons.sports_soccer), size: 16, color: AppTheme.accentGold),
                          const SizedBox(width: 4),
                          Text(
                            prize['scope'] == 'global' ? 'Prêmio Global' : (prize['scope'] == 'league' ? 'Liga ID: ${prize['leagueId']}' : 'Jogo ID: ${prize['fixtureId']}'),
                            style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Switch(
                  value: active,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (val) => FirebaseFirestore.instance.collection('prizes').doc(doc.id).update({'active': val}),
                ),
              ),
            );
          },
        ),
      );
      },
    );
  }

  Future<void> _testPinnacleConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testando conexão com Pinnacle...')));
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('pinnacleGetBalance');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Falha desconhecida ao consultar a Pinnacle.');
      }

      final balance = data['balance']?.toString();
      if (balance == null || balance.isEmpty || balance == 'null') {
        throw Exception('A Pinnacle não retornou o saldo disponível.');
      }

      if (mounted) {
        setState(() {
          _pinnacleBalance = balance;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conexão OK! Saldo: \$ $_pinnacleBalance'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao conectar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _testGeminiAnalysis() async {
    final contextText = _geminiTestContextController.text.trim();
    if (contextText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira o contexto do jogo primeiro.')));
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('analyzeMatchAndBetPinnacle');
      final result = await callable.call({
        'matchContext': contextText,
        'marketId': '1.123456', // ID fake para teste
        'selectionId': '12345', // ID fake para teste
        'stakePercentage': 5.0, // 5% do saldo
      });
      
      final decision = result.data['decision'];
      final String msg = decision['apostar'] == true 
          ? 'Aposta Aceita! Tipo: ${decision['tipo']} | Odd: ${decision['odd_sugerida']}\nMotivo: ${decision['justificativa']}'
          : 'Aposta Recusada.\nMotivo: ${decision['justificativa']}';
          
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(decision['apostar'] == true ? Icons.check_circle : Icons.cancel, color: decision['apostar'] == true ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                const Text('Decisão da IA'),
              ],
            ),
            content: Text(msg),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na IA: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Widget _buildPinnacleLogsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pinnacle_logs').orderBy('createdAt', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Text('Erro ao carregar logs.', style: TextStyle(color: Colors.red));
        
        final logs = snapshot.data?.docs ?? [];
        if (logs.isEmpty) return const Text('Nenhuma operação registrada ainda.', style: TextStyle(color: Colors.grey));
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final doc = logs[index];
            final data = doc.data() as Map<String, dynamic>;
            final decision = data['decision'] as Map<String, dynamic>? ?? {};
            final bool apostou = decision['apostar'] == true;
            final status = data['status'] ?? 'UNKNOWN';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(apostou ? Icons.check_circle : Icons.do_not_disturb_on, color: apostou ? Colors.green : Colors.grey),
                title: Text(apostou ? 'APOSTA: ${decision['tipo']} | Odd: ${decision['odd_sugerida']}' : 'Análise Recusada', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Motivo: ${decision['justificativa'] ?? 'Sem justificativa'}'),
                    const SizedBox(height: 4),
                    Text('Status: $status', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, String? hint, TextInputType? keyboardType, String? helpText, int maxLines = 1, bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (helpText != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.blueGrey, size: 18),
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
          controller: controller, keyboardType: keyboardType, obscureText: obscureText, maxLines: obscureText ? 1 : maxLines,
          decoration: InputDecoration(
            hintText: hint, filled: true, fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildRedemptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('redemptions').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text('Erro ao carregar histórico de resgates.'));

        final redemptions = snapshot.data?.docs ?? [];
        if (redemptions.isEmpty) return const Center(child: Text('Nenhum resgate solicitado.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: redemptions.length,
          itemBuilder: (context, index) {
            final doc = redemptions[index];
            final data = doc.data() as Map<String, dynamic>;
            final isPix = data['type'] == 'pix';
            final status = data['status'] ?? 'pendente';
            
            Color statusColor = Colors.orange;
            if (status == 'enviado' || status == 'concluido') statusColor = Colors.green;
            if (status == 'rejeitado') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: Icon(isPix ? Icons.pix : Icons.card_giftcard, color: isPix ? Colors.teal : AppTheme.primaryGreen, size: 36),
                title: Text(
                  isPix ? 'Saque PIX - R\$ ${data['valueInReais']?.toStringAsFixed(2) ?? '0.00'}' : 'Resgate Físico - ${data['prizeName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Solicitado por: ${data['userName'] ?? 'Desconhecido'}\nStatus: ${status.toUpperCase()}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Custo em Tokens: ${data['cost'] ?? data['tokensCost'] ?? 0}'),
                        Text('E-mail: ${data['userEmail'] ?? 'Não informado'}'),
                        if (isPix) Text('Chave PIX: ${data['pixKey'] ?? 'Não informada'}'),
                        if (!isPix) Text('Telefone: ${data['userPhone'] ?? 'Não informado'}'),
                        if (!isPix) Text('CPF: ${data['userCpf'] ?? 'Não informado'}'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (status == 'pendente')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                                label: const Text('Marcar como Enviado', style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('redemptions').doc(doc.id).update({'status': isPix ? 'concluido' : 'enviado'});
                                },
                              ),
                            if (status == 'pendente')
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Rejeitar'),
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('redemptions').doc(doc.id).update({'status': 'rejeitado'});
                                },
                              ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
