import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/update_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/activity/activity_screen.dart';
import 'screens/ranking/ranking_screen.dart';

class MyBestApp extends StatelessWidget {
  const MyBestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Best',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006994),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ActivityScreen(),
    RankingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final result = await UpdateService.checkForUpdate();
    final appStoreUrl = result.appStoreUrl;
    if (!result.updateAvailable || appStoreUrl == null || !mounted) return;
    _showUpdateDialog(appStoreUrl);
  }

  void _showUpdateDialog(String appStoreUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('アップデートのお知らせ', style: TextStyle(color: Colors.white)),
        content: const Text(
          '新しいバージョンが利用可能です。より快適で安全にお使いいただくために、アップデートをお願いします。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('あとで', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.tryParse(appStoreUrl);
              if (uri == null) return;
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Failed to open App Store URL: $e');
              }
            },
            child: const Text('今すぐアップデート', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0A0A1A),
        selectedItemColor: const Color(0xFF00B4D8),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'アクティビティ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'ランキング',
          ),
        ],
      ),
    );
  }
}
