import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cpfController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _cpfController = TextEditingController(text: user?.cpf ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final updatedUser = user.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          cpf: _cpfController.text.trim(),
        );

        await DbService().updateUserProfile(updatedUser);
        ref.read(currentUserProvider.notifier).state = updatedUser;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil atualizado com sucesso!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: $e')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Mantenha seus dados atualizados para garantir o resgate dos prêmios.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone (WhatsApp)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Informe seu telefone' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Informe seu CPF' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Salvar Alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
