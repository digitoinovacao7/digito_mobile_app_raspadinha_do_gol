import 'package:flutter/material.dart';
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
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  'Configurações de API',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _apiFootballController,
                  decoration: const InputDecoration(
                    labelText: 'Chave API-Football',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _mercadoPagoController,
                  decoration: const InputDecoration(
                    labelText: 'Chave Mercado Pago',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _zApiController,
                  decoration: const InputDecoration(
                    labelText: 'Chave Z-API',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Regras de Premiação (Lotes)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ex: Lote de 100 com 10 prêmios significa que a cada 100 jogadas, 1 prêmio sairá.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _prizeValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor do Prêmio (R\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _totalPrizesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade Total de Prêmios',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _batchSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tamanho do Lote (Ex: 100)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Salvar Tudo', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }
}
