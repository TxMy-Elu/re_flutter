/*import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bucket = 'Ressources';

class SupabaseService {
  static final _client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://pcabklncvqwqrlhnrwda.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYWJrbG5jdnF3cXJsaG5yd2RhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0OTY4MTEsImV4cCI6MjA5NDA3MjgxMX0.nipbRAwZMbiDU3OkFtzZhAx-1Yj0mApHNLRYxwLYHB8',
    );
  }

  /// Upload un fichier et retourne son URL publique
  static Future<String> uploadFile(File file) async {
    final filename = file.path.split('/').last.split('\\').last;
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage.from(_bucket).upload(path, file);

    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Upload depuis des bytes (Web / Android content URI)
  static Future<String> uploadBytes(List<int> bytes, String filename) async {
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage
        .from(_bucket)
        .uploadBinary(path, bytes as Uint8List);

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
*/