import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  ImageService._();

  static final instance = ImageService._();

  Future<String> copyIntoAppStorage(File source) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(join(documents.path, 'wishbox', 'images'));
    await folder.create(recursive: true);
    final extension = extensionOf(source.path);
    final filename = '${DateTime.now().microsecondsSinceEpoch}$extension';
    return source.copy(join(folder.path, filename)).then((file) => file.path);
  }

  Future<void> deleteIfPresent(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }

  String extensionOf(String filePath) {
    final value = extension(filePath);
    return value.isEmpty ? '.jpg' : value.toLowerCase();
  }
}
