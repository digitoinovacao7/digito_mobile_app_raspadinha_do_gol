import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  final int tokensPerReal;

  const WithdrawScreen({Key? key, required this.tokensPerReal}) : super(key: key);

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final TextEditingController _pixKeyController = TextEditingController();

  Future<void> _requestWithdraw() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.tokens < widget.tokensPerReal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mínimo para saque é de ${widget.tokensPerReal} Tokens.')),
      );
      return;
    }

    if (_pixKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe sua chave PIX.')),
      );
      return;
    }

    final double withdrawValue = user.tokens / widget.tokensPerReal;

    try {
      final dbService = DbService();
      await dbService.redeemPrize(user.id, user.tokens, {
        'userId': user.id,
        'userName': user.name,
        'userEmail': user.email,
        'pixKey': _pixKeyController.text,
        'tokensCost': user.tokens,
        'valueInReais': withdrawValue,
        'type': 'pix',
        'status': 'pendente', // pendente, enviado, rejeitado
      }, 'Saque PIX');

      // Zerar saldo simulado:
      ref.read(currentUserProvider.notifier).state = user.copyWith(tokens: 0);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Saque Solicitado!'),
            content: Text('O valor de R\$ ${withdrawValue.toStringAsFixed(2)} será depositado na sua conta via PIX em instantes.'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao solicitar saque: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final int currentTokens = user?.tokens ?? 0;
    final double valueInReais = currentTokens / widget.tokensPerReal;

    return Scaffold(
      appBar: AppBar(title: const Text('Sacar via PIX')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Seus Tokens:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '🟡 $currentTokens',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.amber[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Valor em Reais (${widget.tokensPerReal} Tokens = R\$ 1,00):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'R\$ ${valueInReais.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const Text('Informe sua chave PIX para receber o valor:'),
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
              onPressed: currentTokens >= widget.tokensPerReal ? _requestWithdraw : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Solicitar Saque PIX'),
            ),
          ],
        ),
      ),
    );
  }
}
