# How to Add Offline Mode Toggle and Booking System

After running the build script, you'll need to make these manual adjustments:

## 1. Add dependencies to pubspec.yaml

Open `daoob_mobile/pubspec.yaml` and add these dependencies:

```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.1
```

Run `flutter pub get` to install them.

## 2. Replace the login_screen.dart file

Copy the contents of `login_screen.dart` from this package and replace the file at `daoob_mobile/lib/screens/login_screen.dart`.

## 3. Ensure BookingService is registered

In your `main.dart` file, add the BookingService to the providers:

```dart
ChangeNotifierProvider(create: (context) => BookingService()),
```

## 4. Add Arabic Translation

Make sure to create an Arabic translation file at `assets/lang/ar.json` with:

```json
{
  "app_name": "دؤوب",
  "login": "تسجيل الدخول",
  "register": "تسجيل",
  "email": "البريد الإلكتروني",
  "password": "كلمة المرور",
  "offline_mode": "وضع عدم الاتصال"
}
```

## 5. Rebuild the app

Run `flutter build apk` to rebuild with your changes.
