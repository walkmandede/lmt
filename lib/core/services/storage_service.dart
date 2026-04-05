import 'dart:math';
import 'dart:typed_data';
import 'package:lmt/core/constants/app_functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final storage = Supabase.instance.client.storage;

  Future<String> uploadImage({
    required String circuitId,
    required Uint8List bytes,
    String folder = 'misc',
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r1 = Random().nextInt(10000);
    final r2 = Random().nextInt(10000);
    final r3 = Random().nextInt(10000);

    final path = '$folder/$circuitId/$ts$r1$r2$r3.jpg';
    superPrint(path);
    superPrint(bytes.length);
    await storage
        .from('site-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return storage.from('site-images').getPublicUrl(path);
  }
}
