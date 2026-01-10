import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;

class AppwriteClient {
  static final Client client = Client();

  static void init() {
    client
        .setEndpoint(
          'https://fra.cloud.appwrite.io/v1',
        ) // e.g., https://cloud.appwrite.io/v1
        .setProject('696186f200091016180c'); // Project ID

    print(
      '[Appwrite] Initialized with endpoint: https://fra.cloud.appwrite.io/v1',
    );
  }

  /// Checks Appwrite server health and logs success or error to console.
  static Future<void> checkServerHealth() async {
    final endpoint = 'https://fra.cloud.appwrite.io/v1/health';
    try {
      final uri = Uri.parse(endpoint);
      final response = await http.get(uri);
      final body = response.body;

      if (response.statusCode == 200) {
        print('[Appwrite] Health OK: $body');
      } else {
        print(
          '[Appwrite] Health check error: HTTP ${response.statusCode} → $body',
        );
      }
    } catch (e) {
      print('[Appwrite] Health check failed: $e');
    }
  }

  /// Optionally checks current user session. Will fail if not authenticated.
  static Future<void> checkCurrentUser() async {
    try {
      final account = Account(client);
      final user = await account.get();
      print('[Appwrite] Logged-in user: $user');
    } on AppwriteException catch (e) {
      print(
        '[Appwrite] No active session or error: ${e.message} (code: ${e.code})',
      );
    } catch (e) {
      print('[Appwrite] Unexpected error while fetching user: $e');
    }
  }
}
