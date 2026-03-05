import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_db_service.dart';
import 'core/app_config.dart';
import 'core/service_registration.dart';
import 'core/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration service
  ConfigService.initialize();
  LoggerService.ml('Application environment: ${ConfigService.instance.environment}');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Register and initialize ML services
  registerServices();
  final servicesReady = await initializeServices();
  
  if (!servicesReady) {
    LoggerService.error('Failed to initialize ML services. App may have limited functionality.');
  }
  
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemBarDark);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const ChestSenseApp());
}

class ChestSenseApp extends StatelessWidget {
  const ChestSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAuthService>(
          create: (_) => FirebaseAuthService(),
          lazy: false,
        ),
        Provider<FirebaseDbService>(
          create: (_) => FirebaseDbService(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'Medical Image Analyzer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}
