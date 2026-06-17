import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/game_provider.dart';
import '../core/theme.dart';
import '../models/league_info.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

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
  final _tokensToRealRateController = TextEditingController();

  final _newPrizeNameCtrl = TextEditingController();
  final _newPrizeOddsCtrl = TextEditingController();
  final _newPrizeImageCtrl = TextEditingController();
  final _newPrizeTokenCostCtrl = TextEditingController();
  final _newPrizeLinkCtrl = TextEditingController();
  String _newPrizeType = 'produto'; // 'produto' ou 'pix'
  String _newPrizeScope = 'global'; // 'global', 'league', 'match'
  int? _selectedLeagueId;
  int? _selectedFixtureId;
  List<dynamic> _fetchedMatches = [];
  bool _isFetchingMatches = false;
  List<LeagueInfo> _activeLeagues = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingPrize = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final docSnap = await FirebaseFirestore.instance.collection('system_config').doc('general').get();

      if (docSnap.exists) {
        final data = docSnap.data() ?? {};
        
        if (data.containsKey('api_keys')) {
          final apiKeys = data['api_keys'] as Map<String, dynamic>;
          _apiFootballController.text = apiKeys['api_football']?.toString() ?? '';
          _mercadoPagoController.text = apiKeys['mercado_pago']?.toString() ?? '';
          _zApiController.text = apiKeys['z_api']?.toString() ?? '';
          _geminiApiController.text = apiKeys['gemini']?.toString() ?? '';
        }

        if (data.containsKey('economy')) {
          final economy = data['economy'] as Map<String, dynamic>;
          _scratchcardCostController.text = economy['scratchcard_token_cost']?.toString() ?? '1000';
          _quizRewardController.text = economy['quiz_reward']?.toString() ?? '250';
          _tokensToRealRateController.text = economy['tokens_per_real']?.toString() ?? '100';
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
    _mercadoPagoController.dispose();
    _zApiController.dispose();
    _geminiApiController.dispose();
    _scratchcardCostController.dispose();
    _quizRewardController.dispose();
    _tokensToRealRateController.dispose();
    _newPrizeNameCtrl.dispose();
    _newPrizeOddsCtrl.dispose();
    _newPrizeImageCtrl.dispose();
    _newPrizeTokenCostCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('system_config').doc('general').set({
        'api_keys': {
          'api_football': _apiFootballController.text,
          'mercado_pago': _mercadoPagoController.text,
          'z_api': _zApiController.text,
          'gemini': _geminiApiController.text,
        },
        'economy': {
          'scratchcard_token_cost': int.tryParse(_scratchcardCostController.text) ?? 1000,
          'quiz_reward': int.tryParse(_quizRewardController.text) ?? 250,
          'tokens_per_real': int.tryParse(_tokensToRealRateController.text) ?? 100,
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
      length: 3,
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
              Tab(icon: Icon(Icons.api), text: 'Integrações'),
              Tab(icon: Icon(Icons.stars), text: 'Regras e Prêmios'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Resgates'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildIntegrationsTab(),
                  _buildPrizesTab(),
                  _buildRedemptionsTab(),
                ],
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
                      _buildSectionHeader(Icons.api, 'Chaves de Integração'),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _apiFootballController,
                        label: 'Chave API-Football',
                        hint: 'Usada para consultar jogos ao vivo',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _geminiApiController,
                        label: 'Chave Gemini (Google IA)',
                        hint: 'Usada para gerar os Quizzes do jogo',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _mercadoPagoController,
                        label: 'Chave Mercado Pago',
                        hint: 'Usada para disparar PIX automaticamente (Futuro)',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _zApiController,
                        label: 'Chave Z-API',
                        hint: 'Usada para notificações via WhatsApp',
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
                          'Defina quantos Tokens são necessários para liberar 1 Raspadinha, quantos Tokens o usuário ganha a cada acerto no Quiz, e a conversão de PIX.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _scratchcardCostController,
                              label: 'Custo da Raspadinha',
                              hint: 'Ex: 1000',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              controller: _quizRewardController,
                              label: 'Prêmio por Acerto',
                              hint: 'Ex: 250',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              controller: _tokensToRealRateController,
                              label: 'Tokens para R\$ 1,00',
                              hint: 'Ex: 100',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
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
                              label: Text(_isSaving ? 'Salvando...' : 'Salvar Regras'),
                              onPressed: _isSaving ? null : _saveSettings,
                            ),
                          ),
                        ],
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
          children: [
            ChoiceChip(
              label: const Text('Global', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _newPrizeScope == 'global',
              onSelected: (v) => setState(() { _newPrizeScope = 'global'; _selectedLeagueId = null; _selectedFixtureId = null; }),
              selectedColor: AppTheme.accentGold,
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
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
              ? const CircularProgressIndicator()
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
                      Text('Produto Físico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _newPrizeType == 'produto' ? AppTheme.primaryGreen : Colors.grey.shade700)),
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
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _newPrizeOddsCtrl,
                label: 'Probabilidade (1 a cada X)',
                hint: 'Ex: 1000',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _newPrizeTokenCostCtrl,
                label: 'Custo na Loja (Tokens)',
                hint: '0 = Só Raspadinha',
                keyboardType: TextInputType.number,
              ),
            ),
            if (_newPrizeType == 'produto') ...[
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _newPrizeImageCtrl,
                  label: 'URL da Imagem (Opcional)',
                  hint: 'https://site.com/foto.png',
                ),
              ),
            ],
          ],
        ),
        if (_newPrizeType == 'produto') ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _newPrizeLinkCtrl,
            label: 'URL do Prêmio/Cupom (Opcional)',
            hint: 'Link que o usuário acessa para resgatar o voucher',
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
    final odds = int.tryParse(_newPrizeOddsCtrl.text.trim()) ?? 0;
    final tokenCost = int.tryParse(_newPrizeTokenCostCtrl.text.trim()) ?? 0;
    final image = _newPrizeImageCtrl.text.trim();
    final prizeLink = _newPrizeLinkCtrl.text.trim();

    if (name.isEmpty || odds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o nome e uma probabilidade válida (> 0).'), backgroundColor: Colors.red),
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
        'odds': odds,
        'token_cost': tokenCost,
        'image_url': image,
        'prize_link': prizeLink,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _newPrizeNameCtrl.clear();
      _newPrizeOddsCtrl.clear();
      _newPrizeTokenCostCtrl.clear();
      _newPrizeImageCtrl.clear();
      _newPrizeLinkCtrl.clear();
      setState(() { _newPrizeScope = 'global'; _selectedLeagueId = null; _selectedFixtureId = null; _fetchedMatches = []; });
      
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
                          const Icon(Icons.casino, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Sai 1 a cada ${prize['odds']} raspadinhas', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 4),
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, String? hint, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label, hintText: hint, filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
      ),
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