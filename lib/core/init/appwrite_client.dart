import 'package:appwrite/appwrite.dart';

class AppwriteClient {
  static Client client = Client();

  static void init() {
    client
        .setEndpoint(
          'https://fra.cloud.appwrite.io/v1',
        ) // e.g., https://cloud.appwrite.io/v1
        .setProject('696186f200091016180c'); // Project ID from STEP 1
  }
}
