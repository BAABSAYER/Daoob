#!/bin/bash

echo "Adding Arabic localization support to the DAOOB app..."

# Navigate to the Flutter project
cd eventora_app

# Add the required dependencies
flutter pub add flutter_localizations
flutter pub add intl
flutter pub add flutter_localization

# Create the l10n folder and configuration
mkdir -p lib/l10n

# Create the AppLocalizations class
cat > lib/l10n/app_localizations.dart << 'EOF'
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('ar', ''), // Arabic
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static Locale localeResolutionCallback(
      Locale? locale, Iterable<Locale> supportedLocales) {
    // Check if the current device locale is supported
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale!.languageCode) {
        return supportedLocale;
      }
    }
    // If the locale of the device is not supported, use the first one
    // (English, in this case).
    return supportedLocales.first;
  }

  // Load the language JSON file from the "lang" folder
  Future<bool> load() async {
    String jsonString = await rootBundle
        .loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  // This delegate instance will never change (it doesn't even have fields!)
  // It can provide a constant constructor.
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
EOF

# Create language files directory
mkdir -p assets/lang

# Create English language file
cat > assets/lang/en.json << 'EOF'
{
  "app_name": "DAOOB",
  "app_subtitle": "Event Management Platform",
  "welcome": "Welcome",
  "welcome_back": "Welcome back!",
  "login": "Login",
  "register": "Register",
  "username": "Username",
  "password": "Password",
  "email": "Email",
  "full_name": "Full Name",
  "phone": "Phone",
  "create_account": "Create Account",
  "sign_up_to_get_started": "Sign up to get started with DAOOB",
  "dont_have_account": "Don't have an account?",
  "already_have_account": "Already have an account?",
  "home": "Home",
  "bookings": "Bookings",
  "messages": "Messages",
  "profile": "Profile",
  "logout": "Logout",
  "offline_mode": "Offline Mode",
  "online_mode": "Online Mode",
  "connecting": "Connecting...",
  "connected_to_server": "Connected to server",
  "ready_offline_mode": "Ready (Offline Mode)",
  "initializing": "Initializing...",
  "initializing_services": "Initializing services...",
  "error": "Error",
  "demo_accounts": "Demo Accounts:",
  "client": "Client",
  "vendor": "Vendor",
  "registration_coming_soon": "Registration Coming Soon",
  "registration_message": "We're still working on the registration process. For now, please use the demo accounts from the login screen.",
  "go_to_login": "Go to Login",
  "enter_username": "Enter your username",
  "enter_password": "Enter your password",
  "please_enter_username": "Please enter your username",
  "please_enter_password": "Please enter your password",
  "current_user": "Current User",
  "name": "Name",
  "user_type": "User Type",
  "find_vendors": "Find the Perfect Vendors",
  "find_vendors_desc": "Discover top-rated event vendors for any occasion, from venues to catering and entertainment.",
  "plan_with_ease": "Plan with Ease",
  "plan_with_ease_desc": "Organize your event schedule, manage bookings, and keep track of all your event details in one place.",
  "collaborate": "Collaborate in Real-Time",
  "collaborate_desc": "Communicate directly with vendors, share ideas, and finalize details through our built-in messaging.",
  "next": "Next",
  "get_started": "Get Started",
  "skip": "Skip"
}
EOF

# Create Arabic language file
cat > assets/lang/ar.json << 'EOF'
{
  "app_name": "داوب",
  "app_subtitle": "منصة إدارة الفعاليات",
  "welcome": "مرحباً",
  "welcome_back": "مرحباً بعودتك!",
  "login": "تسجيل الدخول",
  "register": "تسجيل جديد",
  "username": "اسم المستخدم",
  "password": "كلمة المرور",
  "email": "البريد الإلكتروني",
  "full_name": "الاسم الكامل",
  "phone": "الهاتف",
  "create_account": "إنشاء حساب",
  "sign_up_to_get_started": "سجل للبدء مع داوب",
  "dont_have_account": "ليس لديك حساب؟",
  "already_have_account": "لديك حساب بالفعل؟",
  "home": "الرئيسية",
  "bookings": "الحجوزات",
  "messages": "الرسائل",
  "profile": "الملف الشخصي",
  "logout": "تسجيل الخروج",
  "offline_mode": "وضع عدم الاتصال",
  "online_mode": "وضع الاتصال",
  "connecting": "جاري الاتصال...",
  "connected_to_server": "متصل بالخادم",
  "ready_offline_mode": "جاهز (وضع عدم الاتصال)",
  "initializing": "جاري التهيئة...",
  "initializing_services": "جاري تهيئة الخدمات...",
  "error": "خطأ",
  "demo_accounts": "حسابات تجريبية:",
  "client": "عميل",
  "vendor": "مزود خدمة",
  "registration_coming_soon": "التسجيل قريباً",
  "registration_message": "ما زلنا نعمل على عملية التسجيل. في الوقت الحالي، يرجى استخدام الحسابات التجريبية من شاشة تسجيل الدخول.",
  "go_to_login": "الذهاب لتسجيل الدخول",
  "enter_username": "أدخل اسم المستخدم",
  "enter_password": "أدخل كلمة المرور",
  "please_enter_username": "الرجاء إدخال اسم المستخدم",
  "please_enter_password": "الرجاء إدخال كلمة المرور",
  "current_user": "المستخدم الحالي",
  "name": "الاسم",
  "user_type": "نوع المستخدم",
  "find_vendors": "ابحث عن أفضل مزودي الخدمات",
  "find_vendors_desc": "اكتشف مزودي خدمات الفعاليات الأعلى تقييماً لأي مناسبة، من الأماكن إلى خدمات تقديم الطعام والترفيه.",
  "plan_with_ease": "خطط بسهولة",
  "plan_with_ease_desc": "نظم جدول فعالياتك، وأدر الحجوزات، وتابع جميع تفاصيل فعاليتك في مكان واحد.",
  "collaborate": "تعاون في الوقت الفعلي",
  "collaborate_desc": "تواصل مباشرة مع مزودي الخدمات، وشارك الأفكار، وضع اللمسات الأخيرة على التفاصيل من خلال المراسلة المدمجة.",
  "next": "التالي",
  "get_started": "ابدأ الآن",
  "skip": "تخطي"
}
EOF

# Update pubspec.yaml to include the language assets
cat >> pubspec.yaml << 'EOL'
  assets:
    - assets/lang/
EOL

# Create the language provider
cat > lib/l10n/language_provider.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static final LanguageProvider _instance = LanguageProvider._internal();
  factory LanguageProvider() => _instance;
  LanguageProvider._internal();

  Locale _currentLocale = Locale('en');
  Locale get currentLocale => _currentLocale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language');
    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners();
  }

  bool get isArabic => _currentLocale.languageCode == 'ar';
}
EOF

# Create language selector widget
cat > lib/widgets/language_selector.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/l10n/language_provider.dart';
import 'package:eventora_app/l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = LanguageProvider();
    final isArabic = languageProvider.isArabic;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageOption(
            languageCode: 'en',
            label: 'English',
            isSelected: !isArabic,
            onTap: () => _changeLanguage(context, 'en'),
          ),
          Container(
            height: 20,
            width: 1,
            color: AppTheme.textLightColor,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _LanguageOption(
            languageCode: 'ar',
            label: 'العربية',
            isSelected: isArabic,
            onTap: () => _changeLanguage(context, 'ar'),
          ),
        ],
      ),
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) async {
    final languageProvider = LanguageProvider();
    await languageProvider.changeLanguage(languageCode);
    
    // Force the app to rebuild
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed('/');
  }
}

class _LanguageOption extends StatelessWidget {
  final String languageCode;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    Key? key,
    required this.languageCode,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? AppTheme.primaryColor 
                : AppTheme.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
EOF

# Update the main.dart file to support localization
cat > lib/main.dart.new << 'EOF'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/screens/splash_screen.dart';
import 'package:eventora_app/screens/app_wrapper.dart';
import 'package:eventora_app/screens/auth/auth_page.dart';
import 'package:eventora_app/services/auth_service.dart';
import 'package:eventora_app/l10n/app_localizations.dart';
import 'package:eventora_app/l10n/language_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize language provider
  final languageProvider = LanguageProvider();
  await languageProvider.init();
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  final AuthService _authService = AuthService();
  final LanguageProvider _languageProvider = LanguageProvider();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAOOB',
      theme: AppTheme.getTheme(),
      locale: _languageProvider.currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: AppLocalizations.localeResolutionCallback,
      home: _isInitialized 
          ? (_authService.isLoggedIn ? AppWrapper() : AuthPage())
          : SplashScreen(
              onInitComplete: () {
                setState(() {
                  _isInitialized = true;
                });
              },
            ),
      routes: {
        '/auth': (context) => AuthPage(),
        '/home': (context) => AppWrapper(),
      },
    );
  }
}
EOF

# Replace the main.dart file
mv lib/main.dart.new lib/main.dart

# Add language selector to the profile screen in app_wrapper.dart
sed -i 's/if (title == '\''Profile'\'')$/if (title == '\''Profile'\'') {/' lib/screens/app_wrapper.dart
sed -i 's/            ),$/            ),\n              IconButton(\n                icon: Icon(Icons.language),\n                onPressed: () {\n                  showDialog(\n                    context: context,\n                    builder: (context) => AlertDialog(\n                      title: Text(AppLocalizations.of(context).translate('\''change_language'\'')),\n                      content: LanguageSelector(),\n                      actions: [\n                        TextButton(\n                          onPressed: () => Navigator.of(context).pop(),\n                          child: Text(AppLocalizations.of(context).translate('\''close'\'')),\n                        ),\n                      ],\n                    ),\n                  );\n                },\n              ),\n            }/' lib/screens/app_wrapper.dart

# Update import in app_wrapper.dart
sed -i '1s/^/import '\''package:eventora_app\/l10n\/app_localizations.dart'\'';\nimport '\''package:eventora_app\/widgets\/language_selector.dart'\'';\n/' lib/screens/app_wrapper.dart

# Add new entries to the language files
echo '  "change_language": "Change Language",' >> assets/lang/en.json
echo '  "close": "Close"' >> assets/lang/en.json

echo '  "change_language": "تغيير اللغة",' >> assets/lang/ar.json
echo '  "close": "إغلاق"' >> assets/lang/ar.json

echo "Localization support for Arabic has been added successfully!"
echo "The app now supports switching between English and Arabic languages."
echo "A language selector has been added to the profile screen."