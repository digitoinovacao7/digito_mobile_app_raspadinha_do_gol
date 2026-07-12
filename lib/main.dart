import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'core/theme.dart';
import 'core/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Erro ao inicializar Firebase: $e');
  }

  // Inicializar o SDK do Google Mobile Ads (apenas em iOS/Android)
  if (!kIsWeb) {
    MobileAds.instance.initialize();
    
    // Configurar canais de notificação para som em background
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const goalChannel = AndroidNotificationChannel(
      'match_goal',
      'Gols da Partida',
      description: 'Notificações sonoras de gols.',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('goal'),
      playSound: true,
    );
    
    const whistleChannel = AndroidNotificationChannel(
      'match_whistle',
      'Fim de Tempo',
      description: 'Notificações de intervalo.',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('whistle'),
      playSound: true,
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(goalChannel);
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(whistleChannel);
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
      home: const AuthWrapper(),
    );
  }
}
