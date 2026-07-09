import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/migration_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '設定',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // アカウントセクション
          const Text(
            'アカウント',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          authState.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('エラー', style: TextStyle(color: Colors.white54)),
            data: (user) => user == null
                ? _buildSignInCard(context, ref)
                : _buildSignedInCard(context, ref, user.email ?? user.uid),
          ),
          const SizedBox(height: 24),

          // DiveCloudセクション
          const Text(
            'DiveCloud',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'DiveCloudは写真をクラウドに保存し、複数端末での同期ができます。\n\n（Firebase Storage連携は近日公開予定）',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appleでサインインすると、機種変更時にデータを引き継げます。',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _signIn(context, ref),
              icon: const Icon(Icons.apple, color: Colors.black),
              label: const Text(
                'Appleでサインイン',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInCard(BuildContext context, WidgetRef ref, String identifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00B4D8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00B4D8), size: 18),
              const SizedBox(width: 8),
              const Text('サインイン済み', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            identifier,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _signOut(context, ref),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('サインアウト', style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _deleteAccount(context, ref),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.withOpacity(0.5)),
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('アカウントを削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    try {
      final result = await AuthService.signInWithApple(context);
      if (result != null && context.mounted) {
        await MigrationService.migrateToAppleId();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('サインインしました'),
            backgroundColor: Color(0xFF00B4D8),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('サインインに失敗しました。もう一度お試しください。'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('サインアウト', style: TextStyle(color: Colors.white)),
        content: const Text(
          'サインアウトするとローカルデータで動作します。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('サインアウト', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.signOut();
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('アカウントを削除', style: TextStyle(color: Colors.red)),
        content: const Text(
          '⚠️ この操作は取り消せません。\n\nすべてのデータ（王者写真・ビンゴ記録・購入済みシート）が完全に削除されます。\n\nよろしいですか？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除する', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    // 再認証が必要な場合があるため再度Appleサインイン
    final reauth = await AuthService.signInWithApple(context);
    if (reauth == null) return;
    if (!context.mounted) return;

    final success = await AuthService.deleteAccount();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アカウントを削除しました'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('削除に失敗しました。もう一度お試しください。'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
