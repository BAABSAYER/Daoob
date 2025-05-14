import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/config/api_config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.getTranslations();
    
    // Check if user is logged in
    if (authService.user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(translations['notLoggedIn'] ?? 'Please log in to view your profile', 
                 style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(translations['login'] ?? 'Log In'),
            ),
          ],
        ),
      );
    }
    
    final user = authService.user!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(translations['profile'] ?? 'My Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              color: Theme.of(context).primaryColor,
              width: double.infinity,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 70, color: Color(0xFF6A3DE8)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name ?? user.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileSection(context, translations),
            const SizedBox(height: 16),
            _buildSettingsSection(context, translations, languageProvider),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await authService.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(translations['logout'] ?? 'Log Out'),
                ),
              ),
            ),
            // API Config Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Divider(),
                  Text(
                    'API: ${ApiConfig.baseUrl}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Environment: ${ApiConfig.currentEnvironment == ApiConfig.ENV_LOCAL ? 'Local' : 
                      ApiConfig.currentEnvironment == ApiConfig.ENV_REPLIT ? 'Replit' : 'Production'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileSection(BuildContext context, Map<String, String> translations) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user!;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translations['personalInfo'] ?? 'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, translations['email'] ?? 'Email', user.email),
            if (user.phone != null)
              _buildInfoRow(Icons.phone, translations['phone'] ?? 'Phone', user.phone!),
            _buildInfoRow(
              Icons.person, 
              translations['accountType'] ?? 'Account Type', 
              user.userType.toUpperCase()
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsSection(
    BuildContext context, 
    Map<String, String> translations, 
    LanguageProvider languageProvider
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translations['settings'] ?? 'Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(translations['language'] ?? 'Language'),
              trailing: DropdownButton<String>(
                value: languageProvider.currentLanguage,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    languageProvider.setLanguage(newValue);
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(translations['english'] ?? 'English'),
                  ),
                  DropdownMenuItem(
                    value: 'ar',
                    child: Text(translations['arabic'] ?? 'العربية'),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(translations['notifications'] ?? 'Notifications'),
              trailing: Switch(
                value: true, // Default to enabled
                onChanged: (bool value) {
                  // Handle notification settings
                },
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}