import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // 現在のユーザーIDを取得
  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // 写真をStorageにアップロード
  static Future<String?> uploadPhoto({
    required String localPath,
    required String sheetId,
    required String themeId,
    required String fileName,
  }) async {
    if (_userId == null) return null;
    try {
      final file = File(localPath);
      if (!file.existsSync()) return null;

      final ref = _storage
          .ref()
          .child('users')
          .child(_userId!)
          .child('sheets')
          .child(sheetId)
          .child(themeId)
          .child(fileName);

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Storage upload error: $e');
      return null;
    }
  }

  // Storageから写真をダウンロードしてローカルに保存
  static Future<String?> downloadPhoto({
    required String downloadUrl,
    required String fileName,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/$fileName';
      final file = File(localPath);

      if (file.existsSync()) return localPath; // 既にローカルにある

      final ref = _storage.refFromURL(downloadUrl);
      await ref.writeToFile(file);
      return localPath;
    } catch (e) {
      debugPrint('Storage download error: $e');
      return null;
    }
  }

  // ユーザーの全写真を削除
  static Future<void> deleteAllPhotos() async {
    if (_userId == null) return;
    try {
      final ref = _storage.ref().child('users').child(_userId!);
      await _deleteFolder(ref);
    } catch (e) {
      debugPrint('Storage delete error: $e');
    }
  }

  static Future<void> _deleteFolder(Reference ref) async {
    try {
      final listResult = await ref.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
      for (final prefix in listResult.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (e) {
      debugPrint('Delete folder error: $e');
    }
  }
}
