import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';

/// 🔥 MAIN FUNCTION (Firebase INIT)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐ Firebase start
  await Firebase.initializeApp();


  runApp(const AuthentixApp());
}

class AuthentixApp extends StatelessWidget {
  const AuthentixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Authentix",

      // ⭐ PREMIUM GLOBAL THEME
      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFF0D1B2A),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.dark,
        ),

        // 🔥 GLOBAL BUTTON STYLE
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // 🔥 GLOBAL INPUT STYLE
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),

        // 🔥 SMOOTH PAGE TRANSITION
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
