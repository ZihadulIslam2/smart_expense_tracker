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
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
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
}
