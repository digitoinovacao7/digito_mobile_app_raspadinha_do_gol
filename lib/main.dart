import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // O usuário deverá rodar 'flutterfire configure' no terminal e importar o firebase_options.dart 
  // antes de poder rodar o app real na plataforma, por enquanto apenas inicializamos genericamente.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase App não configurado. Por favor rode `flutterfire configure`.');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raspadinha do Gol',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
