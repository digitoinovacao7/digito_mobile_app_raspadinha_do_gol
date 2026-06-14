import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Desbloquear Raspadinha')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pix, size: 80, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                'Nova Tentativa!',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sua jogada gratuita já foi utilizada neste evento.\nPara desbloquear uma nova raspadinha agora mesmo, realize o pagamento de R\$ 1,00.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: const Column(
                  children: [
                    Text('Chave PIX Copia e Cola', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    SelectableText(
                      '00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-426655440000',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Simula pagamento aprovado
                  ref.read(freePlaysProvider.notifier).state = 1;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pagamento confirmado! Jogada liberada.')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Já paguei! (Simular)'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
