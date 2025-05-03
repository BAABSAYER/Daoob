import 'package:flutter/material.dart';
import 'package:eventora_app/screens/auth/login_screen.dart';
import 'package:eventora_app/screens/auth/register_screen.dart';
import 'package:eventora_app/screens/auth/forgot_password_screen.dart';
import 'package:eventora_app/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthScreenType {
  onboarding,
  login,
  register,
  forgotPassword,
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthScreenType _currentScreen = AuthScreenType.onboarding;
  bool _hasSeenOnboarding = false;
  
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }
  
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    setState(() {
      _hasSeenOnboarding = hasSeenOnboarding;
      _currentScreen = hasSeenOnboarding ? AuthScreenType.login : AuthScreenType.onboarding;
    });
  }
  
  void _setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    setState(() {
      _hasSeenOnboarding = true;
      _currentScreen = AuthScreenType.login;
    });
  }
  
  void _navigateToScreen(AuthScreenType screen) {
    setState(() {
      _currentScreen = screen;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AuthScreenType.onboarding:
        return OnboardingScreen(
          onComplete: _setOnboardingComplete,
          onSkip: _setOnboardingComplete,
        );
      
      case AuthScreenType.login:
        return LoginScreen(
          onRegisterTap: () => _navigateToScreen(AuthScreenType.register),
          onForgotPasswordTap: () => _navigateToScreen(AuthScreenType.forgotPassword),
        );
      
      case AuthScreenType.register:
        return RegisterScreen(
          onLoginTap: () => _navigateToScreen(AuthScreenType.login),
        );
      
      case AuthScreenType.forgotPassword:
        return ForgotPasswordScreen(
          onBackToLogin: () => _navigateToScreen(AuthScreenType.login),
        );
    }
  }
}