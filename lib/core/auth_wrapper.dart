import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_layout.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Usuário autenticado no Firebase, agora vamos buscar os dados no Firestore
          return _AppUserLoader(uid: user.uid);
        } else {
          // Não autenticado, vai pro login
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro de autenticação: $err'))),
    );
  }
}

class _AppUserLoader extends ConsumerWidget {
  final String uid;
  const _AppUserLoader({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserFutureProvider(uid));

    return appUserAsync.when(
      data: (appUser) {
        if (appUser != null) {
          // Atualiza o currentUserProvider para os outros componentes usarem
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final current = ref.read(currentUserProvider);
            if (current?.id != appUser.id || current?.tokens != appUser.tokens) {
               ref.read(currentUserProvider.notifier).state = appUser;
            }
          });

          // Todos os usuários acessam o MainLayout no app. Admin usa a plataforma web.
          return const MainLayout();
        } else {
          // Usuário no Firebase mas não encontrado no Firestore (banco deletado?)
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Usuário não encontrado no banco de dados.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    child: const Text('Sair'),
                  )
                ],
              ),
            ),
          );
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro ao carregar dados do perfil: $err'))),
    );
  }
}
