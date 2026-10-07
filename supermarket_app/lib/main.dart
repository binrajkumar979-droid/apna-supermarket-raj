import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/config/theme.dart';
import 'package:supermarket_app/features/auth/presentation/role_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init note: Provide google-services.json for live backend: $e");
  }

  runApp(
    const ProviderScope(
      child: ApnaSupermarketApp(),
    ),
  );
}

class ApnaSupermarketApp extends StatelessWidget {
  const ApnaSupermarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.storeName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleRouterScreen(),
    );
  }
}
