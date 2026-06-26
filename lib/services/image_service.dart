import 'dart:io';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  static Future<String> getAppDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<String> resolveImagePath(String fileNameOrPath) async {
    if (!fileNameOrPath.contains('/')) {
      final dir = await getAppDocDir();
      return '$dir/$fileNameOrPath';
    }
    final fileName = fileNameOrPath.split('/').last;
    final dir = await getAppDocDir();
    return '$dir/$fileName';
  }

  static Future<DateTime?> extractShotDate(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final data = await readExifFromBytes(bytes);
      if (data.isEmpty) return null;

      final dateStr = data['EXIF DateTimeOriginal']?.printable ??
          data['Image DateTime']?.printable;
      if (dateStr == null) return null;

      // EXIF日付形式: "2025:03:15 10:30:00"
      final parts = dateStr.split(' ');
      if (parts.isEmpty) return null;
      final dateParts = parts[0].split(':');
      if (dateParts.length < 3) return null;

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
    } catch (e) {
      debugPrint('EXIF read error: $e');
      return null;
    }
  }

  static Future<ImagePickResult?> pickFromGallery(String themeId) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final shotDate = await extractShotDate(picked.path);
    final fileName = await _saveImage(picked.path, themeId);
    return ImagePickResult(fileName: fileName, shotDate: shotDate);
  }

  static Future<ImagePickResult?> pickFromFiles(String themeId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.first.path;
    if (path == null) return null;

    final shotDate = await extractShotDate(path);
    final fileName = await _saveImage(path, themeId);
    return ImagePickResult(fileName: fileName, shotDate: shotDate);
  }

  static Future<String> _saveImage(String sourcePath, String themeId) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${themeId}_${_uuid.v4()}.jpg';
    final destPath = '${dir.path}/$fileName';
    await File(sourcePath).copy(destPath);
    return fileName;
  }
}

class ImagePickResult {
  final String fileName;
  final DateTime? shotDate;
  const ImagePickResult({required this.fileName, required this.shotDate});
}
