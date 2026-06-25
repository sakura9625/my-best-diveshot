import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  static Future<String?> pickFromGallery(String themeId) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _saveImage(picked.path, themeId);
  }

  static Future<String?> pickFromFiles(String themeId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.first.path;
    if (path == null) return null;
    return _saveImage(path, themeId);
  }

  static Future<String> _saveImage(String sourcePath, String themeId) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${themeId}_${_uuid.v4()}.jpg';
    final destPath = '${dir.path}/$fileName';
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
