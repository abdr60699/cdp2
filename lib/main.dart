import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'injection_container.dart' as di;
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(
    const ProviderScope(
      child: RealEstateApp(),
    ),
  );
}

class RealEstateApp extends StatelessWidget {
  const RealEstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Check Dream Property',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
  scaffoldBackgroundColor: const Color(0xFFF2F2F2), // Light gray background
  cardColor: Colors.white, // Default card color
  useMaterial3: false, // Disable Material 3 for stronger shadows
  textTheme: GoogleFonts.poppinsTextTheme(),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFFF6B00), // Orange
    background: Colors.white,
    surface: Colors.white, // Most important for cards
    onSurface: Colors.black,
  ),
  cardTheme:  CardTheme(
    color: Colors.white,
    elevation: 4,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    shadowColor: Colors.black.withOpacity(0.2), // Custom shadow
    surfaceTintColor: Colors.white, // Ensure no tint
  ),
),

      home: const HomePageWrapper(),
    );
  }
}
