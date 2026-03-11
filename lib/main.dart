import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_db_service.dart';
import 'services/ml_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clear and limit image cache to reduce storage
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
  PaintingBinding.instance.imageCache.maximumSize = 50; // Limit cached images
  PaintingBinding.instance.imageCache.maximumSizeBytes = 10 << 20; // 10 MB max
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Disable Firestore persistence completely to reduce storage
  // App requires internet for ML backend anyway
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // No cache
  );
  
  final mlService = MLService();
  await mlService.initialize();
  
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemBarDark);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(ChestSenseApp(mlService: mlService));
}

class ChestSenseApp extends StatelessWidget {
  final MLService mlService;
  const ChestSenseApp({super.key, required this.mlService});

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
        ),
        Provider<MLService>.value(
          value: mlService,
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
