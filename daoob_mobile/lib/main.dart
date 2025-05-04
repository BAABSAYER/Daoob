import 'package:flutter/material.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:provider/provider.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/screens/splash_screen.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/screens/login_screen.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/screens/home_screen.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/screens/register_screen.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/screens/categories_screen.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/screens/custom_event_screen.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/services/auth_service.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/services/booking_service.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/l10n/language_provider.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";
import 'package:daoob_mobile/providers/event_provider.dart';
import "package:daoob_mobile/screens/vendors_screen.dart";

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BookingService()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return MaterialApp(
      title: 'DAOOB',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A3DE8),
          primary: const Color(0xFF6A3DE8),
          secondary: const Color(0xFF5735B5),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF333333)),
          displayMedium: TextStyle(color: Color(0xFF333333)),
          displaySmall: TextStyle(color: Color(0xFF333333)),
          headlineMedium: TextStyle(color: Color(0xFF333333)),
          headlineSmall: TextStyle(color: Color(0xFF333333)),
          titleLarge: TextStyle(color: Color(0xFF333333)),
          titleMedium: TextStyle(color: Color(0xFF333333)),
          titleSmall: TextStyle(color: Color(0xFF333333)),
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF333333)),
          bodySmall: TextStyle(color: Color(0xFF666666)),
          labelLarge: TextStyle(color: Color(0xFF333333)),
          labelSmall: TextStyle(color: Color(0xFF666666)),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        "/vendors": (context) => VendorsScreen(categoryId: ModalRoute.of(context)!.settings.arguments as String),
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/custom-event': (context) => const CustomEventScreen(),
      },
    );
  }
}
