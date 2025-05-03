#!/bin/bash

echo "Creating and building the DAOOB Flutter app..."

# Navigate to the project directory
cd flutter_project_download

# Make the scripts executable
chmod +x create_flutter_project.sh
chmod +x setup_app_icon.sh
chmod +x create_services.sh

# Create the Flutter project
./create_flutter_project.sh

# Create auth, API services and other core files
./create_services.sh

# Create main app files
cd eventora_app

# Create app_wrapper.dart
cat > lib/screens/app_wrapper.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/services/auth_service.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  
  final List<NavigationItem> _tabs = [
    NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      screen: _PlaceholderScreen(title: 'Home'),
    ),
    NavigationItem(
      label: 'Bookings',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      screen: _PlaceholderScreen(title: 'Bookings'),
    ),
    NavigationItem(
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      screen: _PlaceholderScreen(title: 'Messages'),
    ),
    NavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      screen: _PlaceholderScreen(title: 'Profile'),
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex].screen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: _tabs.map((tab) {
          return BottomNavigationBarItem(
            icon: Icon(tab.icon),
            activeIcon: Icon(tab.selectedIcon),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  
  NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const _PlaceholderScreen({
    Key? key,
    required this.title,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (title == 'Profile')
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await authService.logout();
                Navigator.of(context).pushReplacementNamed('/auth');
              },
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authService.isOfflineMode
                  ? 'Running in Offline Mode'
                  : 'Connected to API',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            if (authService.currentUser != null) ...[
              const SizedBox(height: 32),
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _UserInfoRow(
                        label: 'Name',
                        value: authService.currentUser!.fullName,
                      ),
                      _UserInfoRow(
                        label: 'Email',
                        value: authService.currentUser!.email,
                      ),
                      _UserInfoRow(
                        label: 'User Type',
                        value: authService.currentUser!.userType,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _UserInfoRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
EOF

# Create login screen
cat > lib/screens/auth/login_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/services/auth_service.dart';
import 'package:eventora_app/widgets/app_button.dart';
import 'package:eventora_app/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onRegisterPressed;
  
  const LoginScreen({
    Key? key,
    required this.onRegisterPressed,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isSubmitting = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    final success = await _authService.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    
    setState(() {
      _isSubmitting = false;
      if (!success) {
        _errorMessage = _authService.errorMessage;
      }
    });
    
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // App name
                  Text(
                    'DAOOB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Welcome back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  // Username field
                  AppTextField(
                    label: 'Username',
                    hint: 'Enter your username',
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password field
                  AppPasswordField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login button
                  AppButton(
                    text: 'Login',
                    isLoading: _isSubmitting,
                    onPressed: _login,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onRegisterPressed,
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // For demonstration purposes - credentials hint
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.infoColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demo Accounts:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.infoColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Client: demouser / password\nVendor: demovendor / password',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
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
EOF

# Create auth page that contains both login and register screens
cat > lib/screens/auth/auth_page.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/screens/auth/login_screen.dart';
import 'package:eventora_app/screens/auth/register_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _showLogin = true;
  
  void _toggleAuthMode() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return _showLogin
        ? LoginScreen(onRegisterPressed: _toggleAuthMode)
        : RegisterScreen(onLoginPressed: _toggleAuthMode);
  }
}
EOF

# Create register screen (simplified, just a placeholder)
cat > lib/screens/auth/register_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/widgets/app_button.dart';
import 'package:eventora_app/widgets/app_text_field.dart';

class RegisterScreen extends StatelessWidget {
  final VoidCallback onLoginPressed;
  
  const RegisterScreen({
    Key? key,
    required this.onLoginPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: onLoginPressed,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Sign up to get started with DAOOB',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // For simplicity, show a "Coming Soon" message
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.infoColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction,
                      size: 64,
                      color: AppTheme.infoColor,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Registration Coming Soon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'We\'re still working on the registration process. For now, please use the demo accounts from the login screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    AppButton(
                      text: 'Go to Login',
                      onPressed: onLoginPressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOF

# Create main.dart
cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/screens/splash_screen.dart';
import 'package:eventora_app/screens/app_wrapper.dart';
import 'package:eventora_app/screens/auth/auth_page.dart';
import 'package:eventora_app/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAOOB',
      theme: AppTheme.getTheme(),
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

# Update the app icon
cd ..
./setup_app_icon.sh

# Fix permissions
chmod +x create_and_build_app.sh

# Go back to the Flutter project
cd eventora_app

# Add the missing packages
flutter pub add shared_preferences
flutter pub add http
flutter pub add flutter_launcher_icons

echo "Creating a release APK for your Android device..."
flutter build apk --release

echo "======================================================="
echo "APK build complete! You can find your APK at:"
echo "eventora_app/build/app/outputs/flutter-apk/app-release.apk"
echo "======================================================="
echo "Upload this APK to your device to install the DAOOB app."
echo ""
echo "For development, you can run the app with Flutter directly:"
echo "cd eventora_app && flutter run"