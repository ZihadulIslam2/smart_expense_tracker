import 'package:appwrite/appwrite.dart';
import '../core/init/appwrite_client.dart';

class AuthService {
  late final Account account;

  AuthService() {
    account = Account(AppwriteClient.client);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } on AppwriteException catch (e) {
      // Handle specific Appwrite errors
      throw _handleAppwriteException(e);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } on AppwriteException catch (e) {
      // Handle specific Appwrite errors
      throw _handleAppwriteException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  Future<dynamic> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null;
    }
  }

  // Helper method to handle Appwrite exceptions
  String _handleAppwriteException(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Invalid credentials. Please check your email and password.';
      case 404:
        return 'User not found. Please register first.';
      case 409:
        return 'An account with this email already exists.';
      case 429:
        return 'Too many requests. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
