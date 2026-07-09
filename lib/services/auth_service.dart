import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/material.dart';
import 'storage_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ランダムなnonceを生成
  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // nonceをSHA256でハッシュ化
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Appleでサインイン
  // TODO: DEBUG - remove before release
  static Future<UserCredential?> signInWithApple(BuildContext context) async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // TODO: DEBUG - remove before release
    final token = appleCredential.identityToken ?? '';
    String payload = 'token is null or empty';
    if (token.contains('.')) {
      payload = utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1])));
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // TODO: DEBUG - remove before release
    try {
      return await _auth.signInWithCredential(oauthCredential);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) rethrow;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('FirebaseAuthException (DEBUG)'),
          content: SingleChildScrollView(
            child: SelectableText(
              'code: ${e.code}\n\nmessage: ${e.message}\n\npayload: $payload',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      rethrow;
    }
  }

  // サインアウト
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // 現在のユーザーID（Apple IDまたはデバイスID）
  static String? get userId => _auth.currentUser?.uid;

  // アカウント削除（Firebaseユーザー＋Firestoreデータ）
  static Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final uid = user.uid;
      final db = FirebaseFirestore.instance;

      // Firestoreデータを削除
      await _deleteCollection(db.collection('users').doc(uid).collection('tiles'));
      await _deleteCollection(db.collection('users').doc(uid).collection('settings'));

      // sheetsコレクション内のtilesも削除
      final sheetsSnapshot = await db.collection('users').doc(uid).collection('sheets').get();
      for (final sheetDoc in sheetsSnapshot.docs) {
        await _deleteCollection(sheetDoc.reference.collection('tiles'));
        await sheetDoc.reference.delete();
      }

      // ユーザードキュメント削除
      await db.collection('users').doc(uid).delete();

      // Storageデータを削除
      await StorageService.deleteAllPhotos();

      // Firebaseアカウント削除
      await user.delete();

      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }

  static Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
