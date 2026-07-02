import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/themes.dart';
import '../../constants/advance_themes.dart';
import '../../constants/extra_sheet_themes.dart';
import '../../models/tile_data.dart';
import '../../models/best_photo.dart';
import '../../providers/tiles_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../providers/sheet_provider.dart';
import '../../widgets/resolved_image.dart';

class PresentationScreen extends ConsumerStatefulWidget {
  final String sheetId;
  final List<dynamic> themes;

  const PresentationScreen({
    super.key,
    required this.sheetId,
    required this.themes,
  });

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _getThemeName(String themeId) {
    for (final t in kThemes) {
      if (t.id == themeId) return t.name;
    }
    for (final t in kAdvanceThemes) {
      if (t.id == themeId) return t.name;
    }
    for (final themes in kExtraSheetThemesMap.values) {
      for (final t in themes) {
        if (t.id == themeId) return t.name;
      }
    }
    if (themeId.startsWith('my_select_')) {
      final index = int.tryParse(themeId.replaceFirst('my_select_', ''));
      if (index != null) return 'My Select ${index + 1}';
    }
    return themeId;
  }

  @override
  Widget build(BuildContext context) {
    final ranking = ref.watch(rankingProvider(widget.sheetId));
    final tiles = ref.watch(tilesProvider(widget.sheetId));

    final rankedIds = ranking.where((id) {
      final tile = tiles[id];
      return tile?.isKing == true;
    }).toList();

    if (rankedIds.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            '王者認定された写真がありません',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showUI = !_showUI),
        child: Stack(
          children: [
            // メインPageView
            PageView.builder(
              controller: _pageController,
              itemCount: rankedIds.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final id = rankedIds[index];
                final tile = tiles[id];
                final photo = tile?.currentBest;
                if (photo == null) return const SizedBox.shrink();

                return _buildPhotoPage(photo, id, index + 1, rankedIds.length);
              },
            ),
            // 上部UI（戻るボタン）
            if (_showUI)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            // ページインジケーター
            if (_showUI)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildPageIndicator(rankedIds.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPage(BestPhoto photo, String themeId, int rank, int total) {
    final themeName = _getThemeName(themeId);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 写真（フルスクリーン）
        ResolvedImage(
          fileName: photo.fileName,
          fit: BoxFit.contain,
        ),
        // 下部情報オーバーレイ
        if (_showUI)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                32,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // テーマ名
                  Text(
                    themeName,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // タイトル
                  if (photo.title.isNotEmpty)
                    Text(
                      photo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (photo.location.isNotEmpty || photo.divingMonth != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (photo.location.isNotEmpty) photo.location,
                        if (photo.divingMonth != null)
                          DateFormat('yyyy年M月').format(photo.divingMonth!),
                      ].join('　'),
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count.clamp(0, 25),
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: index == _currentPage ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: index == _currentPage
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
