import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
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
      rethrow;
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
      rethrow;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  Future<bool> hasActiveSession() async {
    try {
      await account.get();
      return true;
    } on AppwriteException {
      return false;
    }
  }

  // NEW: Fetch current user info (name, email, etc.)
  Future<models.User?> getCurrentUser() async {
    try {
      final user = await account.get();
      return user;
    } on AppwriteException {
      return null;
    }
  }
}
