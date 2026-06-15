import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/db_service.dart';
import '../core/theme.dart';
import 'home_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DbService _dbService = DbService();
  
  // API Keys Controllers
  final TextEditingController _apiFootballController = TextEditingController();
  final TextEditingController _mercadoPagoController = TextEditingController();
  final TextEditingController _zApiController = TextEditingController();

  // Prize Rules Controllers
  final TextEditingController _prizeValueController = TextEditingController();
  final TextEditingController _totalPrizesController = TextEditingController();
  final TextEditingController _batchSizeController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final keys = await _dbService.getApiKeys();
    final rules = await _dbService.getPrizeRules();

    setState(() {
      _apiFootballController.text = keys['api_football'] ?? '';
      _mercadoPagoController.text = keys['mercado_pago'] ?? '';
      _zApiController.text = keys['z_api'] ?? '';

      _prizeValueController.text = (rules['prize_value'] ?? 0.0).toString();
      _totalPrizesController.text = (rules['total_prizes'] ?? 0).toString();
      _batchSizeController.text = (rules['batch_size'] ?? 0).toString();

      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    
    await _dbService.saveApiKeys({
      'api_football': _apiFootballController.text,
      'mercado_pago': _mercadoPagoController.text,
      'z_api': _zApiController.text,
    });

    await _dbService.savePrizeRules({
      'prize_value': double.tryParse(_prizeValueController.text) ?? 0.0,
      'total_prizes': int.tryParse(_totalPrizesController.text) ?? 0,
      'batch_size': int.tryParse(_batchSizeController.text) ?? 0,
    });

    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.videogame_asset),
            tooltip: 'Ir para o App (Home)',
            onPressed: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const HomeScreen())
              );
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader(Icons.api, 'Integrações (APIs)'),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'API-Football',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final url = Uri.parse('https://dashboard.api-football.com/login/');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Pegar chave aqui'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiFootballController,
                          decoration: _inputDecoration('Cole a chave da API-Football', Icons.sports_soccer),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Mercado Pago',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _mercadoPagoController,
                          decoration: _inputDecoration('Access Token de Produção', Icons.payment),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'WhatsApp (Z-API)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _zApiController,
                          decoration: _inputDecoration('URL Completa da Instância', Icons.message),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(Icons.settings_suggest, 'Regras de Premiação (Lotes)'),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withOpacity(0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ex: Lote de 100 com 10 prêmios significa que a cada 100 jogadas, exatamente 10 bilhetes serão premiados.',
                                  style: TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _prizeValueController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration('Valor do Prêmio (R\$)', Icons.monetization_on),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _totalPrizesController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Quantidade Total de Prêmios', Icons.emoji_events),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _batchSizeController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Tamanho do Lote (Ex: 100)', Icons.group),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Configurações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
