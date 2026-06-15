import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _apiFootballController = TextEditingController();
  final _mercadoPagoController = TextEditingController();
  final _zApiController = TextEditingController();
  final _prizeValueController = TextEditingController();
  final _prizeQuantityController = TextEditingController();
  final _batchSizeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('system_config')
          .doc('general')
          .get();

      if (docSnap.exists) {
        final data = docSnap.data() ?? {};
        
        if (data.containsKey('api_keys')) {
          final apiKeys = data['api_keys'] as Map<String, dynamic>;
          _apiFootballController.text = apiKeys['api_football']?.toString() ?? '';
          _mercadoPagoController.text = apiKeys['mercado_pago']?.toString() ?? '';
          _zApiController.text = apiKeys['z_api']?.toString() ?? '';
        }

        if (data.containsKey('prize_rules')) {
          final prizeRules = data['prize_rules'] as Map<String, dynamic>;
          _prizeValueController.text = prizeRules['prize_value']?.toString() ?? '0';
          _prizeQuantityController.text = prizeRules['total_prizes']?.toString() ?? '0';
          _batchSizeController.text = prizeRules['batch_size']?.toString() ?? '0';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar configurações: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _apiFootballController.dispose();
    _mercadoPagoController.dispose();
    _zApiController.dispose();
    _prizeValueController.dispose();
    _prizeQuantityController.dispose();
    _batchSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('system_config')
          .doc('general')
          .set({
        'api_keys': {
          'api_football': _apiFootballController.text,
          'mercado_pago': _mercadoPagoController.text,
          'z_api': _zApiController.text,
        },
        'prize_rules': {
          'prize_value': double.tryParse(_prizeValueController.text) ?? 0.0,
          'total_prizes': int.tryParse(_prizeQuantityController.text) ?? 0,
          'batch_size': int.tryParse(_batchSizeController.text) ?? 0,
        }
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar as configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.api, 'Integrações (APIs)'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _apiFootballController,
                    label: 'Chave API-Football',
                    hint: 'Usada para consultar dados das partidas ao vivo',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _mercadoPagoController,
                    label: 'Chave Mercado Pago',
                    hint: 'Usada para recebimentos e pagamentos via PIX',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _zApiController,
                    label: 'Chave Z-API',
                    hint: 'Usada para disparos e notificações no WhatsApp',
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(Icons.card_giftcard, 'Regras de Premiação (Lotes)'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _prizeValueController,
                    label: 'Valor do Prêmio (R\$)',
                    hint: 'Ex: 50.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _prizeQuantityController,
                    label: 'Quantidade de Prêmios Ativos',
                    hint: 'Ex: 10',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _batchSizeController,
                    label: 'Tamanho do Lote (Probabilidade)',
                    hint: 'Ex: 100 (1 usuário premiado a cada 100 jogadas)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Salvando...' : 'Salvar Configurações'),
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ),
                ],
              ),
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryGreen),
        ),
      ),
    );
  }
}