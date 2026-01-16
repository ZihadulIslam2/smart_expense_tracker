import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_expense_tracker/core/init/appwrite_client.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/services/notification_service.dart';
import 'package:smart_expense_tracker/features/auth/login_screen.dart';
import 'package:smart_expense_tracker/features/auth/register_screen.dart';
import 'package:smart_expense_tracker/features/home/home_screen.dart';
import 'package:smart_expense_tracker/features/dashboard/dashboard_screen.dart';
import 'package:smart_expense_tracker/features/education/education_screen.dart';
import 'package:smart_expense_tracker/features/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Appwrite
  AppwriteClient.init();
  await AppwriteClient.checkServerHealth();

  // Initialize notifications
  try {
    await NotificationService().initialize();
    print('[MAIN] Notification service initialized');
  } catch (e) {
    print('[MAIN] Error initializing notifications: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/education': (context) => const EducationScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
