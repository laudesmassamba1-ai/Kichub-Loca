import 'package:image_picker/image_picker.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String bucketName = 'commerce-photos';

  static Future<String?> uploadCommercePhoto({required XFile file}) async {
    try {
      final bytes = await file.readAsBytes();
      final name = _basename(file.name);
      final extension =
          name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
      final safeExtension = {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(extension)
          ? extension
          : 'jpg';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(' ', '_')}';

      final contentType = switch (safeExtension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

      await SupabaseService.client.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      return SupabaseService.client.storage
          .from(bucketName)
          .getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  static String _basename(String path) {
    final index = path.lastIndexOf('/');
    return index >= 0 ? path.substring(index + 1) : path;
  }
}
