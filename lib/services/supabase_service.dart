/*import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bucket = 'Ressources';

class SupabaseService {
  static final _client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://pcabklncvqwqrlhnrwda.supabase.co',
      anonKey:
          'SUPABASE_ANON_KEY_HERE',
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