import 'package:flutter/material.dart';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _redirectIfLoggedIn();
  }

  Future<void> _redirectIfLoggedIn() async {
    final alreadyLoggedIn = await _authService.hasActiveSession();
    if (alreadyLoggedIn && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validation
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password cannot be empty')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(email: email, password: password);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful')));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network.'),
          backgroundColor: Colors.red,
        ),
      );
    } on AppwriteException catch (e) {
      if (e.type == 'user_session_already_exists') {
        // Treat as success: session is active
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Already logged in')));
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      // Show Appwrite message directly
      final msg = e.message ?? 'Login failed';
      // Helpful hints for common cases
      if (e.type == 'user_email_not_verified') {
        // Your project may require email verification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not verified. Please verify your email in Appwrite.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else if (msg.contains('Invalid Origin')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid Origin. Add your Android app in Appwrite → Platforms.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
      print('Appwrite ${e.code} • ${e.type} • ${e.message}');
    } catch (e) {
      // All other errors
      print('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _validateAndLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
