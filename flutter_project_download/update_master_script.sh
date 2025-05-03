#!/bin/bash

echo "Updating the master script to include Arabic localization..."

# Update the create_and_build_app.sh script to include localization
cat > create_and_build_app.sh.new << 'EOF'
#!/bin/bash

echo "Creating and building the DAOOB Flutter app with Arabic localization..."

# Navigate to the project directory
cd flutter_project_download

# Make the scripts executable
chmod +x create_flutter_project.sh
chmod +x setup_app_icon.sh
chmod +x create_services.sh
chmod +x add_localization.sh

# Create the Flutter project
./create_flutter_project.sh

# Create auth, API services and other core files
./create_services.sh

# Add Arabic localization support
./add_localization.sh

# Create main app files
cd eventora_app

# Create app_wrapper.dart
cat > lib/screens/app_wrapper.dart << 'EOF2'
import 'package:flutter/material.dart';
import 'package:eventora_app/l10n/app_localizations.dart';
import 'package:eventora_app/widgets/language_selector.dart';
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
    // Use AppLocalizations to translate tab labels
    final localizations = AppLocalizations.of(context);
    
    // Update tab labels with translated text
    _tabs[0] = _tabs[0].copyWith(
      label: localizations.translate('home'),
    );
    _tabs[1] = _tabs[1].copyWith(
      label: localizations.translate('bookings'),
    );
    _tabs[2] = _tabs[2].copyWith(
      label: localizations.translate('messages'),
    );
    _tabs[3] = _tabs[3].copyWith(
      label: localizations.translate('profile'),
    );
    
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
  
  // Create a copy with updated values
  NavigationItem copyWith({
    String? label,
    IconData? icon,
    IconData? selectedIcon,
    Widget? screen,
  }) {
    return NavigationItem(
      label: label ?? this.label,
      icon: icon ?? this.icon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      screen: screen ?? this.screen,
    );
  }
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
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate(title.toLowerCase())),
        actions: [
          if (title == 'Profile') {
            IconButton(
              icon: Icon(Icons.language),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(localizations.translate('change_language')),
                    content: LanguageSelector(),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(localizations.translate('close')),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await authService.logout();
                Navigator.of(context).pushReplacementNamed('/auth');
              },
            ),
          }
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
              localizations.translate(title.toLowerCase()),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authService.isOfflineMode
                  ? localizations.translate('ready_offline_mode')
                  : localizations.translate('connected_to_server'),
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
                        localizations.translate('current_user'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _UserInfoRow(
                        label: localizations.translate('name'),
                        value: authService.currentUser!.fullName,
                      ),
                      _UserInfoRow(
                        label: localizations.translate('email'),
                        value: authService.currentUser!.email,
                      ),
                      _UserInfoRow(
                        label: localizations.translate('user_type'),
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
EOF2

# Create login screen with localization
cat > lib/screens/auth/login_screen.dart << 'EOF2'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/services/auth_service.dart';
import 'package:eventora_app/widgets/app_button.dart';
import 'package:eventora_app/widgets/app_text_field.dart';
import 'package:eventora_app/l10n/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context);
    
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
                    localizations.translate('app_name'),
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
                    localizations.translate('welcome_back'),
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
                    label: localizations.translate('username'),
                    hint: localizations.translate('enter_username'),
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('please_enter_username');
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password field
                  AppPasswordField(
                    label: localizations.translate('password'),
                    hint: localizations.translate('enter_password'),
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('please_enter_password');
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login button
                  AppButton(
                    text: localizations.translate('login'),
                    isLoading: _isSubmitting,
                    onPressed: _login,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localizations.translate('dont_have_account'),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onRegisterPressed,
                        child: Text(
                          localizations.translate('register'),
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
                          localizations.translate('demo_accounts'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.infoColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${localizations.translate('client')}: demouser / password\n${localizations.translate('vendor')}: demovendor / password',
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
EOF2

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
flutter pub add flutter_localizations
flutter pub add intl
flutter pub add flutter_localization

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
EOF

# Replace the original script with the updated one
mv create_and_build_app.sh.new create_and_build_app.sh
chmod +x create_and_build_app.sh

echo "The master script has been updated to include Arabic localization."
echo "When you run create_and_build_app.sh, it will now create an app with:"
echo "1. Full Arabic language support"
echo "2. Language switcher in the profile section"
echo "3. Automatic RTL layout support for Arabic"
echo "4. Persistence of language preference between app launches"