import 'package:appwrite/appwrite.dart';
import '../core/init/appwrite_client.dart';

class AuthService {
  final Account _account = Account(AppwriteClient.client);

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } on AppwriteException catch (e) {
      throw e.message ?? 'Registration failed';
    } catch (e) {
      throw 'Something went wrong';
    }
  }
}
