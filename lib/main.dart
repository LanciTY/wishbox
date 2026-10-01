import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WishboxApp());
}

class WishboxApp extends StatelessWidget {
  const WishboxApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '灵感盒子',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9B7E6B),
            brightness: Brightness.light,
            surface: const Color(0xFFFFFBF7),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F4EF),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8F4EF),
            foregroundColor: Color(0xFF372D27),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: TextStyle(
              color: Color(0xFF372D27),
              fontSize: 20,
              height: 1.1,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: Color(0xFFECE3DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: Color(0xFF9B7E6B), width: 1.4),
            ),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFECE3DB)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF4B3D35)),
            padding: const EdgeInsets.symmetric(horizontal: 5),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 2,
            shape: StadiumBorder(),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        home: const HomeScreen(),
      );
}
