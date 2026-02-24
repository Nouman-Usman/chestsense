import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_db_service.dart';
import 'services/storage_service.dart';
import 'services/ml_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
        // Initialize auth service immediately (lazy: false) to ensure session is loaded
        Provider<FirebaseAuthService>(
          create: (_) => FirebaseAuthService(),
          lazy: false,
        ),
        Provider<FirebaseDbService>(
          create: (_) => FirebaseDbService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<MLService>(
          create: (_) => MLService(),
        ),
      ],
      child: MaterialApp(
        title: 'ChestSense',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}
