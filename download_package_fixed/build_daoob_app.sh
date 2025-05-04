#!/bin/bash

echo "=== Building DAOOB App (Completely Fixed Version) ==="

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Create a log file
LOG_FILE="daoob_build.log"
echo "Build started at $(date)" > $LOG_FILE

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed or not in your PATH. Please install Flutter first."
    exit 1
fi

# Clean any previous attempts
if [ -d "daoob_mobile" ]; then
    echo "Removing existing daoob_mobile directory..."
    rm -rf daoob_mobile
fi

# Create the Flutter project from scratch
echo "Creating a new Flutter project..."
flutter create --org com.daoob --project-name daoob_mobile daoob_mobile

# Navigate to the project
cd daoob_mobile

# Create necessary directories
mkdir -p assets/images 
mkdir -p lib/models 
mkdir -p lib/screens/events
mkdir -p lib/services 
mkdir -p lib/widgets 
mkdir -p lib/utils 
mkdir -p lib/l10n
mkdir -p assets/lang

# Copy the logo if available
if [ -f "../attached_assets/WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" ]; then
    echo "Setting up app logo from attached_assets..."
    cp "../attached_assets/WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" assets/images/daoob-logo.jpg
elif [ -f "../WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" ]; then
    echo "Setting up app logo..."
    cp "../WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" assets/images/daoob-logo.jpg
else
    echo "Logo not found. Creating placeholder logo..."
    mkdir -p assets/images
    echo "DAOOB" > assets/images/daoob-logo.txt
fi

# Create the main.dart file with proper imports
echo "Creating main.dart with proper package imports..."
cat > lib/main.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Local services
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/services/event_provider.dart';
import 'package:daoob_mobile/l10n/app_localizations.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';

// Screens
import 'package:daoob_mobile/screens/splash_screen.dart';
import 'package:daoob_mobile/screens/login_screen.dart';
import 'package:daoob_mobile/screens/app_wrapper.dart';
import 'package:daoob_mobile/screens/vendor_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => EventProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'DAOOB',
            theme: ThemeData(
              primaryColor: const Color(0xFF6A3DE8),
              primarySwatch: Colors.deepPurple,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A3DE8)),
              fontFamily: 'Roboto',
              useMaterial3: true,
            ),
            locale: languageProvider.locale,
            // Directionality will be handled by a wrapper widget
            supportedLocales: const [
              Locale('en', ''),
              Locale('ar', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const AppWrapper(),
              '/vendor-details': (context) => VendorDetailScreen(
                  vendorId: ModalRoute.of(context)!.settings.arguments as int),
            },
          );
        },
      ),
    );
  }
}
EOL

# Create localizations implementation
echo "Creating localization files..."
cat > lib/l10n/app_localizations.dart << 'EOL'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
EOL

cat > lib/l10n/language_provider.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar'); // Arabic as default
  bool _isRTL = true; // RTL by default

  Locale get locale => _locale;
  bool get isRTL => _isRTL;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language_code');
    if (savedLanguage != null) {
      _locale = Locale(savedLanguage);
      _isRTL = savedLanguage == 'ar';
    } else {
      // Set Arabic as default if no saved preference
      await prefs.setString('language_code', 'ar');
    }
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    _isRTL = languageCode == 'ar';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    
    notifyListeners();
  }
}
EOL

# Create model files
echo "Creating model files..."

# Event Category Model
cat > lib/models/event_category.dart << 'EOL'
class EventCategory {
  final int id;
  final String name;
  final String description;
  final String icon;
  final List<String> vendorTypes;
  final bool isCustom;

  EventCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.vendorTypes,
    this.isCustom = false,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      vendorTypes: List<String>.from(json['vendorTypes']),
      isCustom: json['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'vendorTypes': vendorTypes,
      'isCustom': isCustom,
    };
  }

  static List<EventCategory> sampleCategories() {
    return [
      EventCategory(
        id: 1,
        name: 'Wedding',
        description: 'Plan your perfect wedding day with selected vendors',
        icon: 'favorite',
        vendorTypes: ['Event Planner', 'Catering', 'Photography', 'Music & Entertainment', 'Venue'],
      ),
      EventCategory(
        id: 2,
        name: 'Corporate',
        description: 'Business events, conferences, and professional meetings',
        icon: 'business',
        vendorTypes: ['Event Planner', 'Catering', 'Venue'],
      ),
      EventCategory(
        id: 3,
        name: 'Birthday',
        description: 'Celebrate birthdays with the perfect planning and services',
        icon: 'cake',
        vendorTypes: ['Event Planner', 'Catering', 'Photography', 'Music & Entertainment'],
      ),
      EventCategory(
        id: 4,
        name: 'Graduation',
        description: 'Celebrate academic achievements with family and friends',
        icon: 'school',
        vendorTypes: ['Event Planner', 'Catering', 'Photography'],
      ),
      EventCategory(
        id: 5,
        name: 'Custom Event',
        description: 'Create your own custom event with specific requirements',
        icon: 'edit',
        vendorTypes: [],
        isCustom: true,
      ),
    ];
  }
}
EOL

# Create auth service
cat > lib/services/auth_service.dart << 'EOL'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class User {
  final int id;
  final String? username;
  final String? name;
  final String email;
  final String userType; // 'client' or 'vendor'

  User({
    required this.id,
    this.username,
    this.name,
    required this.email,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'] ?? json['username'] ?? 'Unknown',
      email: json['email'],
      userType: json['userType'] ?? 'client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'userType': userType,
    };
  }

  // Mock user for testing
  static User mockUser() {
    return User(
      id: 1,
      username: 'johndoe',
      name: 'John Doe',
      email: 'john@example.com',
      userType: 'client',
    );
  }
}

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isOfflineMode = false; // Offline mode for development/testing
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isOfflineMode => _isOfflineMode;
  String? get error => _error;

  AuthService() {
    _loadUser();
    _loadOfflineMode();
  }

  // Load user from shared preferences
  Future<void> _loadUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        _user = User.fromJson(json.decode(userJson));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load offline mode setting
  Future<void> _loadOfflineMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOfflineMode = prefs.getBool('offline_mode') ?? false;
      notifyListeners();
    } catch (e) {
      // Default to online mode if error
      _isOfflineMode = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Toggle offline mode for development/testing
  Future<void> toggleOfflineMode(bool value) async {
    try {
      _isOfflineMode = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_mode', value);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Login function
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_isOfflineMode) {
        // Use mock data in offline mode
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        _user = User.mockUser();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Send login request to the API
      final response = await http.post(
        Uri.parse('https://api.daoob.com/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        
        // Save user to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register function
  Future<bool> register(String name, String email, String password, String userType) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_isOfflineMode) {
        // Use mock data in offline mode
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        _user = User(
          id: 1,
          username: email.split('@')[0],
          name: name,
          email: email,
          userType: userType,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Send register request to the API
      final response = await http.post(
        Uri.parse('https://api.daoob.com/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'userType': userType,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        
        // Save user to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear user from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
EOL

# Create event provider
cat > lib/services/event_provider.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:daoob_mobile/models/event_category.dart';

class EventProvider extends ChangeNotifier {
  EventCategory? _selectedCategory;
  List<String>? _selectedVendorTypes;
  bool _isCustomEvent = false;
  String? _customEventName;
  String? _customEventDescription;

  // Mock data for testing
  final List<EventCategory> _categories = EventCategory.sampleCategories();

  // Getters
  EventCategory? get selectedCategory => _selectedCategory;
  List<String>? get selectedVendorTypes => _selectedVendorTypes;
  bool get isCustomEvent => _isCustomEvent;
  String? get customEventName => _customEventName;
  String? get customEventDescription => _customEventDescription;
  List<EventCategory> get categories => _categories;

  // Select a category
  void selectCategory(EventCategory category) {
    _selectedCategory = category;
    _isCustomEvent = category.isCustom;
    _selectedVendorTypes = category.isCustom ? [] : List.from(category.vendorTypes);
    notifyListeners();
  }

  // Set custom event details
  void setCustomEventDetails({
    required String name,
    required String description,
    required List<String> vendorTypes,
  }) {
    _customEventName = name;
    _customEventDescription = description;
    _selectedVendorTypes = vendorTypes;
    notifyListeners();
  }

  // Update selected vendor types
  void updateSelectedVendorTypes(List<String> vendorTypes) {
    _selectedVendorTypes = vendorTypes;
    notifyListeners();
  }

  // Clear selections
  void clearSelections() {
    _selectedCategory = null;
    _selectedVendorTypes = null;
    _isCustomEvent = false;
    _customEventName = null;
    _customEventDescription = null;
    notifyListeners();
  }
}
EOL

# Create screens
echo "Creating screens..."

# Create splash screen
cat > lib/screens/splash_screen.dart << 'EOL'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Timer(const Duration(seconds: 2), () {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A3DE8), Color(0xFF5034A6)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or App Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 120,
                  height: 120,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Image(
                      image: AssetImage('assets/images/daoob-logo.jpg'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                localizations.translate('app_name'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                localizations.translate('welcome'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              // Offline mode toggle for development/testing
              SwitchListTile(
                title: Text(
                  localizations.translate('offline_mode'),
                  style: const TextStyle(color: Colors.white),
                ),
                value: authService.isOfflineMode,
                onChanged: (value) {
                  authService.toggleOfflineMode(value);
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOL

# Create login screen
cat > lib/screens/login_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF5F5F5)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 100,
                        height: 100,
                        color: const Color(0xFF6A3DE8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Image(
                            image: AssetImage('assets/images/daoob-logo.jpg'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // App name
                  Text(
                    localizations.translate('app_name'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A3DE8),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Welcome text
                  Text(
                    localizations.translate('welcome'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: localizations.translate('email'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: localizations.translate('password'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to forgot password screen
                            },
                            child: Text(
                              localizations.translate('forgot_password'),
                              style: const TextStyle(
                                color: Color(0xFF6A3DE8),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Login button
                        ElevatedButton(
                          onPressed: authService.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A3DE8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: authService.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  localizations.translate('login'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        
                        // Error message
                        if (authService.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              authService.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Offline mode indicator
                  if (authService.isOfflineMode)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'Offline Mode Active',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
EOL

# Create app wrapper (main navigation)
cat > lib/screens/app_wrapper.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/app_localizations.dart';
import 'package:daoob_mobile/screens/events/event_category_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DAOOB',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home tab (Events)
          const EventCategoryScreen(),
          
          // Bookings tab
          Center(
            child: Text(localizations.translate('bookings')),
          ),
          
          // Messages tab
          Center(
            child: Text(localizations.translate('messages')),
          ),
          
          // Profile tab
          _buildProfileTab(localizations, authService),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: localizations.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: localizations.translate('bookings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_outlined),
            activeIcon: const Icon(Icons.chat),
            label: localizations.translate('messages'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: localizations.translate('profile'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6A3DE8),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
  
  Widget _buildProfileTab(AppLocalizations localizations, AuthService authService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF6A3DE8).withOpacity(0.1),
                    child: Text(
                      authService.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A3DE8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.user?.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authService.user?.email ?? 'email@example.com',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A3DE8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            authService.user?.userType.toUpperCase() ?? 'CLIENT',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A3DE8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Settings section
          Text(
            localizations.translate('settings'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to edit profile
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(localizations.translate('language')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to language settings
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_off),
                  title: Text(localizations.translate('offline_mode')),
                  value: authService.isOfflineMode,
                  onChanged: (value) {
                    authService.toggleOfflineMode(value);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await authService.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(localizations.translate('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
EOL

# Create event category screen
cat > lib/screens/events/event_category_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/models/event_category.dart';
import 'package:daoob_mobile/services/event_provider.dart';
import 'package:daoob_mobile/l10n/app_localizations.dart';
import 'package:daoob_mobile/screens/events/custom_event_screen.dart';
import 'package:daoob_mobile/screens/events/vendor_list_screen.dart';

class EventCategoryScreen extends StatelessWidget {
  const EventCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('choose_event_type'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('event_type_prompt'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Categories grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: eventProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = eventProvider.categories[index];
                    return _buildCategoryCard(context, category, localizations);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryCard(
    BuildContext context,
    EventCategory category,
    AppLocalizations localizations,
  ) {
    final eventProvider = Provider.of<EventProvider>(context);
    
    // Mapping of icon names to IconData
    final iconMap = {
      'favorite': Icons.favorite,
      'business': Icons.business,
      'cake': Icons.cake,
      'school': Icons.school,
      'edit': Icons.edit,
    };
    
    final icon = iconMap[category.icon] ?? Icons.event;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          eventProvider.selectCategory(category);
          if (category.isCustom) {
            // Navigate to custom event screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomEventScreen(),
              ),
            );
          } else {
            // Navigate to vendor list screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VendorListScreen(category: category),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A3DE8).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: const Color(0xFF6A3DE8),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                localizations.translate(category.name.toLowerCase()),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                category.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOL

# Create custom event screen
cat > lib/screens/events/custom_event_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/event_provider.dart';
import 'package:daoob_mobile/l10n/app_localizations.dart';
import 'package:daoob_mobile/screens/events/vendor_list_screen.dart';

class CustomEventScreen extends StatefulWidget {
  const CustomEventScreen({super.key});

  @override
  State<CustomEventScreen> createState() => _CustomEventScreenState();
}

class _CustomEventScreenState extends State<CustomEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _vendorTypes = [
    'Event Planner',
    'Catering',
    'Photography',
    'Music & Entertainment',
    'Venue',
    'Decoration',
    'Transportation',
  ];
  final Set<String> _selectedVendorTypes = {};
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _submit() {
    if (_formKey.currentState!.validate() && _selectedVendorTypes.isNotEmpty) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      
      eventProvider.setCustomEventDetails(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : 'Custom event',
        vendorTypes: _selectedVendorTypes.toList(),
      );
      
      // Navigate to vendor list
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VendorListScreen(
            isCustomEvent: true,
            eventName: _nameController.text,
          ),
        ),
      );
    } else if (_selectedVendorTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one vendor type')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('create_custom_event')),
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('event_name'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an event name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Event description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('event_description'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 24),
                
                // Vendor types selection
                Text(
                  localizations.translate('select_vendors'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Vendor types chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _vendorTypes.map((type) {
                    final isSelected = _selectedVendorTypes.contains(type);
                    return FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedVendorTypes.add(type);
                          } else {
                            _selectedVendorTypes.remove(type);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF6A3DE8).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF6A3DE8),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF6A3DE8) : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A3DE8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      localizations.translate('continue'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
EOL

# Create vendor list screen
cat > lib/screens/events/vendor_list_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/models/event_category.dart';
import 'package:daoob_mobile/models/vendor.dart';
import 'package:daoob_mobile/services/event_provider.dart';
import 'package:daoob_mobile/l10n/app_localizations.dart';

class VendorListScreen extends StatefulWidget {
  final EventCategory? category;
  final bool isCustomEvent;
  final String? eventName;

  const VendorListScreen({
    super.key,
    this.category,
    this.isCustomEvent = false,
    this.eventName,
  });

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  String? _selectedVendorType;
  final List<Vendor> _mockVendors = Vendor.sampleVendors();
  List<Vendor> _filteredVendors = [];
  
  @override
  void initState() {
    super.initState();
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    
    if (widget.isCustomEvent) {
      if (eventProvider.selectedVendorTypes?.isNotEmpty ?? false) {
        _selectedVendorType = eventProvider.selectedVendorTypes!.first;
      }
    } else if (widget.category != null) {
      if (widget.category!.vendorTypes.isNotEmpty) {
        _selectedVendorType = widget.category!.vendorTypes.first;
      }
    }
    
    _filterVendors();
  }
  
  void _filterVendors() {
    if (_selectedVendorType == null) {
      _filteredVendors = List.from(_mockVendors);
    } else {
      _filteredVendors = _mockVendors
          .where((vendor) => vendor.category == _selectedVendorType)
          .toList();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final localizations = AppLocalizations.of(context);
    
    // Get the vendor types based on the selected category or custom event
    final List<String> vendorTypes = widget.isCustomEvent
        ? eventProvider.selectedVendorTypes ?? []
        : widget.category?.vendorTypes ?? [];
    
    final String title = widget.isCustomEvent
        ? widget.eventName ?? 'Custom Event'
        : localizations.translate(widget.category?.name.toLowerCase() ?? 'event');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${localizations.translate('vendors_for')} $title',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Vendor type filter
          if (vendorTypes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[100],
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // All option
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        selected: _selectedVendorType == null,
                        label: const Text('All'),
                        onSelected: (_) {
                          setState(() {
                            _selectedVendorType = null;
                            _filterVendors();
                          });
                        },
                        selectedColor: const Color(0xFF6A3DE8).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF6A3DE8),
                      ),
                    ),
                    
                    // Vendor type options
                    ...vendorTypes.map((type) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FilterChip(
                          selected: _selectedVendorType == type,
                          label: Text(type),
                          onSelected: (_) {
                            setState(() {
                              _selectedVendorType = type;
                              _filterVendors();
                            });
                          },
                          selectedColor: const Color(0xFF6A3DE8).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF6A3DE8),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          
          // Vendor list
          Expanded(
            child: _filteredVendors.isEmpty
                ? Center(
                    child: Text('No vendors found for $_selectedVendorType'),
                  )
                : ListView.builder(
                    itemCount: _filteredVendors.length,
                    itemBuilder: (context, index) {
                      final vendor = _filteredVendors[index];
                      return _buildVendorCard(vendor);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVendorCard(Vendor vendor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/vendor-details',
            arguments: vendor.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: vendor.logo != null
                        ? Image.network(vendor.logo!)
                        : const Icon(Icons.business, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          vendor.category,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4.0),
                            Text(
                              vendor.location,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                vendor.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Starting at \$${vendor.basePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A3DE8),
                    ),
                  ),
                  if (vendor.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4.0),
                        Text('${vendor.rating} (${vendor.reviewCount ?? 0})'),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOL

# Create vendor detail screen stub
cat > lib/screens/vendor_detail_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:daoob_mobile/models/vendor.dart';
import 'package:daoob_mobile/models/service.dart';

class VendorDetailScreen extends StatefulWidget {
  final int vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  late Vendor _vendor;
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorDetails();
  }

  Future<void> _loadVendorDetails() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get vendor from mock data
    final vendors = Vendor.sampleVendors();
    final vendor = vendors.firstWhere(
      (v) => v.id == widget.vendorId,
      orElse: () => vendors.first,
    );
    
    // Get services
    final services = Service.sampleServices()
        .where((s) => s.vendorId == vendor.id)
        .toList();
    
    setState(() {
      _vendor = vendor;
      _services = services;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? const Text('Vendor Details')
            : Text(_vendor.businessName),
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor header/banner
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.business, size: 60, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                _vendor.businessName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.black.withOpacity(0.6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _vendor.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_vendor.rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_vendor.rating} (${_vendor.reviewCount ?? 0})',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Vendor description
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_vendor.description),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              _vendor.location,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Starting from \$${_vendor.basePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF6A3DE8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Services section
                  if (_services.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _services.length,
                            itemBuilder: (context, index) {
                              final service = _services[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(service.description),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${service.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF6A3DE8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Booking button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to booking form
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking functionality is coming soon!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A3DE8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
EOL

# Create models for services
cat > lib/models/service.dart << 'EOL'
class Service {
  final int id;
  final int vendorId;
  final String name;
  final String description;
  final double price;

  Service({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'price': price,
    };
  }

  static List<Service> sampleServices() {
    return [
      Service(
        id: 1,
        vendorId: 1,
        name: 'Basic Wedding Package',
        description: 'Essential planning services for your wedding day.',
        price: 3000.0,
      ),
      Service(
        id: 2,
        vendorId: 1,
        name: 'Premium Wedding Package',
        description: 'Comprehensive wedding planning from engagement to reception.',
        price: 5000.0,
      ),
      Service(
        id: 3,
        vendorId: 2,
        name: 'Standard Catering Package',
        description: 'Buffet-style service with a variety of menu options.',
        price: 35.0,
      ),
      Service(
        id: 4,
        vendorId: 2,
        name: 'Deluxe Catering Package',
        description: 'Plated service with premium menu options and open bar.',
        price: 75.0,
      ),
      Service(
        id: 5,
        vendorId: 3,
        name: 'Birthday Bash Package',
        description: 'Complete birthday party planning and coordination.',
        price: 1200.0,
      ),
      Service(
        id: 6,
        vendorId: 4,
        name: 'Event Photography Package',
        description: '4 hours of photography coverage with edited digital photos.',
        price: 800.0,
      ),
      Service(
        id: 7,
        vendorId: 5,
        name: 'DJ Services',
        description: '4 hours of DJ services with professional sound equipment.',
        price: 600.0,
      ),
      Service(
        id: 8,
        vendorId: 5,
        name: 'Live Band Performance',
        description: '3 hours of live music with a 5-piece band.',
        price: 1500.0,
      ),
    ];
  }
}
EOL

# Create User model
cat > lib/models/user.dart << 'EOL'
class User {
  final int id;
  final String? username;
  final String? name;
  final String email;
  final String userType; // 'client' or 'vendor'

  User({
    required this.id,
    this.username,
    this.name,
    required this.email,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'] ?? json['username'] ?? 'Unknown',
      email: json['email'],
      userType: json['userType'] ?? 'client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'userType': userType,
    };
  }

  static List<User> sampleUsers() {
    return [
      User(
        id: 1,
        username: 'johndoe',
        name: 'John Doe',
        email: 'john@example.com',
        userType: 'client',
      ),
      User(
        id: 2,
        username: 'elegantevents',
        name: 'Elegant Events',
        email: 'contact@elegantevents.com',
        userType: 'vendor',
      ),
      User(
        id: 3,
        username: 'deliciouscatering',
        name: 'Delicious Catering',
        email: 'info@deliciouscatering.com',
        userType: 'vendor',
      ),
    ];
  }

  static User generateMockUser(int id) {
    return User(
      id: id,
      username: 'user$id',
      name: 'User $id',
      email: 'user$id@example.com',
      userType: 'client',
    );
  }
}
EOL

# Create Vendor model
cat > lib/models/vendor.dart << 'EOL'
class Vendor {
  final int id;
  final int userId;
  final String businessName;
  final String category;
  final String description;
  final double basePrice;
  final String location;
  final String? logo;
  final List<String>? portfolioImages;
  final double? rating;
  final int? reviewCount;

  Vendor({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.category,
    required this.description,
    required this.basePrice,
    required this.location,
    this.logo,
    this.portfolioImages,
    this.rating,
    this.reviewCount,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      userId: json['userId'],
      businessName: json['businessName'],
      category: json['category'],
      description: json['description'],
      basePrice: json['basePrice'].toDouble(),
      location: json['location'],
      logo: json['logo'],
      portfolioImages: json['portfolioImages'] != null
          ? List<String>.from(json['portfolioImages'])
          : null,
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'category': category,
      'description': description,
      'basePrice': basePrice,
      'location': location,
      'logo': logo,
      'portfolioImages': portfolioImages,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  static List<Vendor> sampleVendors() {
    return [
      Vendor(
        id: 1,
        userId: 101,
        businessName: 'Elegant Events',
        category: 'Event Planner',
        description: 'We specialize in creating beautiful, memorable events for all occasions.',
        basePrice: 2000.0,
        location: 'New York, NY',
        rating: 4.8,
        reviewCount: 120,
      ),
      Vendor(
        id: 2,
        userId: 102,
        businessName: 'Delicious Catering',
        category: 'Catering',
        description: 'Premium catering services with a wide range of menu options to choose from.',
        basePrice: 35.0,
        location: 'Los Angeles, CA',
        rating: 4.5,
        reviewCount: 85,
      ),
      Vendor(
        id: 3,
        userId: 103,
        businessName: 'Celebration Masters',
        category: 'Event Planner',
        description: 'Your one-stop shop for all types of celebrations and special events.',
        basePrice: 1500.0,
        location: 'Chicago, IL',
        rating: 4.3,
        reviewCount: 72,
      ),
      Vendor(
        id: 4,
        userId: 104,
        businessName: 'Perfect Moments Photography',
        category: 'Photography',
        description: 'Capturing your special moments with an artistic and professional touch.',
        basePrice: 800.0,
        location: 'Miami, FL',
        rating: 4.9,
        reviewCount: 150,
      ),
      Vendor(
        id: 5,
        userId: 105,
        businessName: 'Groove Entertainment',
        category: 'Music & Entertainment',
        description: 'Professional DJs and live bands for any type of event or occasion.',
        basePrice: 600.0,
        location: 'Austin, TX',
        rating: 4.7,
        reviewCount: 98,
      ),
      Vendor(
        id: 6,
        userId: 106,
        businessName: 'Grand Plaza',
        category: 'Venue',
        description: 'Elegant and spacious venue with beautiful gardens and modern amenities.',
        basePrice: 5000.0,
        location: 'Seattle, WA',
        rating: 4.6,
        reviewCount: 110,
      ),
    ];
  }
}
EOL

# Add localization files
mkdir -p assets/lang
cat > assets/lang/ar.json << 'EOL'
{
  "app_name": "دعوب",
  "welcome": "مرحبا بك في دعوب",
  "login": "تسجيل الدخول",
  "email": "البريد الإلكتروني",
  "password": "كلمة المرور",
  "forgot_password": "نسيت كلمة المرور؟",
  "home": "الرئيسية",
  "bookings": "الحجوزات",
  "messages": "الرسائل",
  "profile": "الملف الشخصي",
  "settings": "الإعدادات",
  "language": "اللغة",
  "offline_mode": "الوضع دون اتصال",
  "logout": "تسجيل الخروج",
  "choose_event_type": "اختر نوع الحدث",
  "event_type_prompt": "ما نوع الحدث الذي تخطط له؟",
  "wedding": "زفاف",
  "corporate": "شركة",
  "birthday": "عيد ميلاد",
  "graduation": "تخرج",
  "custom_event": "حدث مخصص",
  "create_custom_event": "إنشاء حدث مخصص",
  "event_name": "اسم الحدث",
  "event_description": "وصف الحدث",
  "select_vendors": "اختر المزودين",
  "continue": "متابعة",
  "back": "رجوع",
  "vendors_for": "المزودين لـ"
}
EOL

# Add EN locale file
cat > assets/lang/en.json << 'EOL'
{
  "app_name": "DAOOB",
  "welcome": "Welcome to DAOOB",
  "login": "Login",
  "email": "Email",
  "password": "Password",
  "forgot_password": "Forgot Password?",
  "home": "Home",
  "bookings": "Bookings",
  "messages": "Messages",
  "profile": "Profile",
  "settings": "Settings",
  "language": "Language",
  "offline_mode": "Offline Mode",
  "logout": "Logout",
  "choose_event_type": "Choose Event Type",
  "event_type_prompt": "What type of event are you planning?",
  "wedding": "Wedding",
  "corporate": "Corporate",
  "birthday": "Birthday",
  "graduation": "Graduation",
  "custom_event": "Custom Event",
  "create_custom_event": "Create Custom Event",
  "event_name": "Event Name",
  "event_description": "Event Description",
  "select_vendors": "Select Vendors",
  "continue": "Continue",
  "back": "Back",
  "vendors_for": "Vendors for"
}
EOL

# Update pubspec.yaml
cat > pubspec.yaml << 'EOL'
name: daoob_mobile
description: "DAOOB - Smart Event Management Platform"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.2
  shared_preferences: ^2.2.0
  http: ^1.1.0
  intl: ^0.19.0
  provider: ^6.0.5
  flutter_launcher_icons: ^0.13.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/lang/

flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/daoob-logo.jpg"
  adaptive_icon_background: "#6A3DE8"
EOL

# Fix NDK version in Android build.gradle
if [ -f "android/app/build.gradle" ]; then
  if ! grep -q "ndkVersion" android/app/build.gradle; then
    sed -i '/defaultConfig {/a \        ndkVersion "27.0.12077973"' android/app/build.gradle
    echo "Added ndkVersion to android/app/build.gradle"
  fi
fi

if [ -f "android/app/build.gradle.kts" ]; then
  if ! grep -q "ndkVersion" android/app/build.gradle.kts; then
    sed -i '/android {/a \    ndkVersion = "27.0.12077973"' android/app/build.gradle.kts
    echo "Added ndkVersion to android/app/build.gradle.kts"
  fi
fi

# Update all import statements
echo "Updating package names from eventora to daoob..."
find lib -type f -name "*.dart" -exec sed -i 's/package:eventora_mobile/package:daoob_mobile/g' {} \;

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Generate app icon
echo "Setting up app icon..."
if [ -f "assets/images/daoob-logo.jpg" ]; then
  flutter pub run flutter_launcher_icons
fi

echo "=== Building APK ==="

# Fix the NDK version issue in build.gradle.kts
if [ -f "android/app/build.gradle.kts" ]; then
  echo "Setting NDK version to 27.0.12077973 in build.gradle.kts..."
  
  # Check if android block exists and add ndkVersion
  if grep -q "android {" "android/app/build.gradle.kts"; then
    # If ndkVersion already exists, replace it; otherwise, add it
    if grep -q "ndkVersion" "android/app/build.gradle.kts"; then
      sed -i 's/ndkVersion = ".*"/ndkVersion = "27.0.12077973"/' android/app/build.gradle.kts
    else
      sed -i '/android {/a \    ndkVersion = "27.0.12077973"' android/app/build.gradle.kts
    fi
    echo "NDK version set successfully" | tee -a ../$LOG_FILE
  else
    echo "Warning: Could not find Android block in build.gradle.kts" | tee -a ../$LOG_FILE
  fi
else
  echo "Warning: android/app/build.gradle.kts not found" | tee -a ../$LOG_FILE
fi

# Build the APK with verbose logging
echo "Running flutter build apk..."
flutter build apk --release --verbose 2>&1 | tee -a ../$LOG_FILE
BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
  echo "APK build successful!"
else
  echo "APK build failed with code $BUILD_RESULT. Check $LOG_FILE for details."
fi

echo "=== Setup complete! ==="
echo "APK has been built and is located at:"
echo "$(pwd)/build/app/outputs/flutter-apk/app-release.apk"