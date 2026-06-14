import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final TextEditingController _pixKeyController = TextEditingController();

  void _requestWithdraw() {
    final user = ref.read(currentUserProvider);
    if (user == null || user.balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo insuficiente para saque.')),
      );
      return;
    }

    if (_pixKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe sua chave PIX.')),
      );
      return;
    }

    // Aqui integraria com a API real de pagamento para enviar o PIX
    // Zerar saldo simulado:
    ref.read(currentUserProvider.notifier).state = user.copyWith(balance: 0.0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saque Solicitado!'),
        content: const Text('O valor será depositado na sua conta em instantes.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sacar Prêmios')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Saldo Disponível:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${user?.balance.toStringAsFixed(2) ?? '0.00'}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 48),
            const Text('Informe sua chave PIX para receber o prêmio:'),
            const SizedBox(height: 12),
            TextField(
              controller: _pixKeyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Chave PIX (CPF, Telefone, E-mail)',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _requestWithdraw,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Solicitar Saque'),
            ),
          ],
        ),
      ),
    );
  }
}
