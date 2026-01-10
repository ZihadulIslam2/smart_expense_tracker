import 'package:flutter/material.dart';
import 'package:smart_expense_tracker/core/init/appwrite_client.dart';
import 'package:smart_expense_tracker/features/auth/login_screen.dart';
import 'package:smart_expense_tracker/features/auth/register_screen.dart';
import 'package:smart_expense_tracker/features/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppwriteClient.init();
  await AppwriteClient.checkServerHealth();
  // Optionally check current user session (will error if not logged in)
  // await AppwriteClient.checkCurrentUser();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
