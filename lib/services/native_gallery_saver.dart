import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class NativeGallerySaver {
  /// Saves an image file to the gallery (Android & iOS)
  static Future<bool> saveImage(File file) async {
    try {
      // Request storage permission (Android only)
      if (!kIsWeb && Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) return false;
      }

      Directory? directory;

      if (Platform.isAndroid) {
        // Android: Pictures directory
        directory = await getExternalStorageDirectory();
        String newPath = '';
        List<String> paths = directory!.path.split('/');
        for (int x = 1; x < paths.length; x++) {
          String folder = paths[x];
          if (folder != 'Android') {
            newPath += '/$folder';
          } else {
            break;
          }
        }
        newPath = '$newPath/Pictures';
        directory = Directory(newPath);
      } else if (Platform.isIOS) {
        // iOS: documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (!(await directory!.exists())) {
        await directory.create(recursive: true);
      }

      String filePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';

      await file.copy(filePath);

      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }
}
