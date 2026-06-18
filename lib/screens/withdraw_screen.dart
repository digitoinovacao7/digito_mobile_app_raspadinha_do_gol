import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _showOtpStep = false;
  
  @override
  void dispose() {
    _pixKeyController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

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
    
    // Check for phone number
    final phone = _phoneController.text.isNotEmpty ? _phoneController.text : user.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('É obrigatório informar um telefone com DDD (WhatsApp).')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbService = DbService();
      
      // Update phone if missing
      if (user.phone == null || user.phone!.isEmpty) {
        await dbService.updateUserProfile(user.copyWith(phone: phone));
        ref.read(currentUserProvider.notifier).state = user.copyWith(phone: phone);
      }
      
      await dbService.requestPixOtp(_pixKeyController.text, user.tokens, phone);

      setState(() {
        _showOtpStep = true;
      });
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código enviado! Verifique seu WhatsApp.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmOtp() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o código de 6 dígitos.')),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final dbService = DbService();
      await dbService.validatePixOtpAndWithdraw(_otpController.text);

      final double withdrawValue = user.tokens / widget.tokensPerReal;

      // Zerar saldo simulado no frontend:
      ref.read(currentUserProvider.notifier).state = user.copyWith(tokens: 0);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Saque Solicitado e Confirmado!', style: TextStyle(color: Colors.green)),
            content: Text('O valor de R\$ ${withdrawValue.toStringAsFixed(2)} será depositado na sua conta via PIX.'),
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
          SnackBar(content: Text('Erro ao validar código: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final int currentTokens = user?.tokens ?? 0;
    final double valueInReais = currentTokens / widget.tokensPerReal;
    final bool needsPhone = user?.phone == null || user!.phone!.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Sacar via PIX')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(24.0),
        child: _showOtpStep ? _buildOtpStep() : Column(
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
            if (needsPhone) ...[
              const SizedBox(height: 16),
              const Text('Precisamos do seu WhatsApp para enviar o código de segurança:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'WhatsApp (Ex: 11999999999)',
                  prefixText: '+55 ',
                ),
              ),
            ],
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

  Widget _buildOtpStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.security, size: 64, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Confirmação de Segurança',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Acabamos de enviar um código de 6 dígitos para o seu WhatsApp cadastrado. Digite-o abaixo para confirmar o seu saque.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '000000',
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _confirmOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Confirmar Código e Sacar'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _showOtpStep = false),
          child: const Text('Voltar e Editar Chave'),
        )
      ],
    );
  }
}
