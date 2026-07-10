import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tile_data.dart';
import 'image_service.dart';

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

  // ユーザーの全写真情報を取得（複数端末同期用）
  static Future<Map<String, String>> fetchAllPhotoUrls() async {
    if (_userId == null) return {};
    try {
      final result = <String, String>{};
      final ref = _storage.ref().child('users').child(_userId!);
      await _fetchUrls(ref, result, '');
      return result;
    } catch (e) {
      debugPrint('Fetch photo urls error: $e');
      return {};
    }
  }

  static Future<void> _fetchUrls(
    Reference ref,
    Map<String, String> result,
    String prefix,
  ) async {
    final listResult = await ref.listAll();
    for (final item in listResult.items) {
      final url = await item.getDownloadURL();
      result[item.name] = url;
    }
    for (final prefixRef in listResult.prefixes) {
      await _fetchUrls(prefixRef, result, prefix);
    }
  }

  // ローカルの全写真をStorageにアップロード
  static Future<void> uploadAllLocalPhotos({
    required Map<String, Map<String, TileData>> allSheetTiles,
    Function(int done, int total)? onProgress,
  }) async {
    if (_userId == null) return;

    // アップロード対象の写真を収集
    final targets = <Map<String, String>>[];
    for (final entry in allSheetTiles.entries) {
      final sheetId = entry.key;
      for (final tileEntry in entry.value.entries) {
        final themeId = tileEntry.key;
        final tile = tileEntry.value;
        if (tile.currentBest != null) {
          targets.add({
            'sheetId': sheetId,
            'themeId': themeId,
            'fileName': tile.currentBest!.fileName,
          });
        }
        for (final history in tile.history) {
          targets.add({
            'sheetId': sheetId,
            'themeId': themeId,
            'fileName': history.fileName,
          });
        }
      }
    }

    int done = 0;
    for (final target in targets) {
      try {
        final localPath = await ImageService.resolveImagePath(target['fileName']!);
        if (File(localPath).existsSync()) {
          await uploadPhoto(
            localPath: localPath,
            sheetId: target['sheetId']!,
            themeId: target['themeId']!,
            fileName: target['fileName']!,
          );
        }
      } catch (e) {
        debugPrint('Batch upload error: $e');
      }
      done++;
      onProgress?.call(done, targets.length);
    }
  }

  // 特定ファイルのダウンロードURLを取得
  static Future<String?> getDownloadUrl({
    required String sheetId,
    required String fileName,
  }) async {
    if (_userId == null) return null;
    try {
      // ファイル名からthemeIdを復元（fileName形式: {themeId}_{uuid}.jpg）
      // themeId自体に'_'を含む場合があるため、末尾のuuid部分のみを取り除く
      final parts = fileName.split('_');
      final themeId = parts.length > 1
          ? parts.sublist(0, parts.length - 1).join('_')
          : parts.first;
      final ref = _storage
          .ref()
          .child('users')
          .child(_userId!)
          .child('sheets')
          .child(sheetId)
          .child(themeId)
          .child(fileName);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Get download url error: $e');
      return null;
    }
  }
}
