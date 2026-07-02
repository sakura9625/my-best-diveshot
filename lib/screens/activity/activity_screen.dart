import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/themes.dart';
import '../../models/tile_data.dart';
import '../../models/best_photo.dart';
import '../../providers/tiles_provider.dart';
import '../../providers/bingo_provider.dart';
import '../../providers/sheet_provider.dart';
import '../../constants/sheet_definitions.dart';
import '../../widgets/resolved_image.dart';
import '../../widgets/sheet_tab_bar.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetId = ref.watch(currentSheetProvider);
    final isUnlocked = ref.watch(sheetUnlockedProvider(sheetId));
    debugPrint('ActivityScreen: sheetId=$sheetId, isUnlocked=$isUnlocked');
    if (sheetId == 'advance') {
      final owBingo = ref.watch(bingoCountProvider('open_water'));
      debugPrint('ActivityScreen: OW bingo count=$owBingo');
    }

    if (!isUnlocked) {
      final sheet = kDefaultSheets.firstWhere((s) => s.id == sheetId);
      final requiredSheetId = sheet.unlockRequiredSheetId ?? 'open_water';
      final requiredSheetName = kDefaultSheets.firstWhere((s) => s.id == requiredSheetId).name;
      final requiredBingos = sheet.unlockRequiredBingos ?? 3;

      return Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A1A),
          title: const Text('アクティビティ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            const SheetTabBar(),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.white24, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'まだロックされています',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$requiredSheetNameのビンゴを$requiredBingos個以上揃えると解放されます',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final tiles = ref.watch(tilesProvider(sheetId));
    final bingoLines = ref.watch(completedBingoLinesProvider(sheetId));
    final kingTiles = tiles.values.where((t) => t.isKing).toList();
    final provisionalTiles = tiles.values.where((t) => t.isProvisional).toList();
    final emptyCount = 25 - tiles.values.where((t) => t.hasPhoto).length;
    final isComplete = kingTiles.length == 25;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'アクティビティ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SheetTabBar(),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('📊 ステータス'),
                const SizedBox(height: 8),
                _buildStatusGrid(kingTiles.length, provisionalTiles.length, emptyCount, tiles),
                const SizedBox(height: 24),

                _buildSectionTitle('🎯 ビンゴ'),
                const SizedBox(height: 8),
                _buildBingoSection(bingoLines, isComplete, tiles),
                const SizedBox(height: 24),

                _buildSectionTitle('👑 王者ストーリー'),
                const SizedBox(height: 8),
                _buildTwoColumnGrid(_buildKingStories(tiles, kingTiles)),
                const SizedBox(height: 24),

                _buildSectionTitle('⚔️ 激戦・記録'),
                const SizedBox(height: 8),
                _buildTwoColumnGrid(_buildBattleStats(tiles)),
                const SizedBox(height: 24),

                _buildSectionTitle('📅 撮影記録'),
                const SizedBox(height: 8),
                _buildTwoColumnGrid(_buildShotStats(tiles)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatusGrid(int kingCount, int provisionalCount, int emptyCount, Map<String, TileData> tiles) {
    final totalCrownCount = tiles.values
        .map((t) => (t.currentBest?.crownCount ?? 0) + t.history.length)
        .fold(0, (a, b) => a + b);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard('王者登録数', '$kingCount / 25', const Color(0xFF00B4D8)),
        _buildStatCard('仮登録中', '$provisionalCount テーマ', Colors.white38),
        _buildStatCard('未登録', '$emptyCount テーマ', Colors.white24),
        _buildStatCard('王者認定総数', '$totalCrownCount 回', const Color(0xFFFFD700)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBingoSection(List<int> bingoLines, bool isComplete, Map<String, TileData> tiles) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _BingoGridPainter(
                    bingoLines: bingoLines,
                    tiles: tiles,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
                border: isComplete
                    ? Border.all(color: const Color(0xFFFFD700), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isComplete ? 'コンプリート' : '現在のビンゴ',
                    style: TextStyle(
                      color: isComplete ? const Color(0xFFFFD700) : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  isComplete
                      ? const Text('🏆', style: TextStyle(fontSize: 40))
                      : Text(
                          '${bingoLines.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnGrid(List<Widget> items) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: items[i]),
              const SizedBox(width: 8),
              Expanded(child: i + 1 < items.length ? items[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  List<Widget> _buildKingStories(Map<String, TileData> tiles, List<TileData> kingTiles) {
    final widgets = <Widget>[];
    final now = DateTime.now();

    TileData? newestKing;
    for (final t in kingTiles) {
      if (t.currentBest?.crownedAt != null) {
        if (newestKing == null ||
            t.currentBest!.crownedAt!.isAfter(newestKing.currentBest!.crownedAt!)) {
          newestKing = t;
        }
      }
    }
    widgets.add(newestKing != null
        ? _buildKingStoryCard('最新の王者', newestKing, subtitle: _formatDate(newestKing.currentBest?.crownedAt))
        : _buildEmptyCard('最新の王者', 'まだ王者がいません'));

    TileData? oldestKing;
    for (final t in kingTiles) {
      if (t.currentBest?.crownedAt != null) {
        if (oldestKing == null ||
            t.currentBest!.crownedAt!.isBefore(oldestKing.currentBest!.crownedAt!)) {
          oldestKing = t;
        }
      }
    }
    widgets.add(oldestKing != null
        ? _buildKingStoryCard('最古の王者', oldestKing, subtitle: '在位 ${now.difference(oldestKing.currentBest!.crownedAt!).inDays} 日')
        : _buildEmptyCard('最古の王者', 'まだ王者がいません'));

    final ironKings = kingTiles.where((t) {
      if (t.currentBest?.crownedAt == null) return false;
      return now.difference(t.currentBest!.crownedAt!).inDays >= 365;
    }).toList();
    if (ironKings.isNotEmpty) {
      ironKings.sort((a, b) => a.currentBest!.crownedAt!.compareTo(b.currentBest!.crownedAt!));
      final days = now.difference(ironKings.first.currentBest!.crownedAt!).inDays;
      widgets.add(_buildKingStoryCard('🛡️ 鉄壁の王者', ironKings.first, subtitle: '在位 $days 日（1年以上）'));
    } else {
      widgets.add(_buildEmptyCard('🛡️ 鉄壁の王者', '1年以上在位した王者はまだいません'));
    }

    TileData? defenseKing;
    int maxRestore = 0;
    for (final t in tiles.values) {
      final restoreCount = t.history.where((h) => h.isRestored).length +
          (t.currentBest?.isRestored == true ? 1 : 0);
      if (restoreCount >= 3 && restoreCount > maxRestore) {
        maxRestore = restoreCount;
        defenseKing = t;
      }
    }
    widgets.add(defenseKing != null
        ? _buildKingStoryCard('🔄 防衛王', defenseKing, subtitle: '$maxRestore 回復活')
        : _buildEmptyCard('🔄 防衛王', '3回以上復活した王者はまだいません'));

    BestPhoto? longestReign;
    String? longestThemeName;
    for (final t in tiles.values) {
      final allPhotos = [...t.history, if (t.currentBest != null) t.currentBest!];
      for (final p in allPhotos) {
        if (p.crownedAt != null) {
          if (longestReign == null || p.crownedAt!.isBefore(longestReign.crownedAt!)) {
            longestReign = p;
            longestThemeName = kThemes.firstWhere((th) => th.id == t.themeId).name;
          }
        }
      }
    }
    if (longestReign != null && longestThemeName != null) {
      final days = now.difference(longestReign.crownedAt!).inDays;
      widgets.add(_buildPhotoCard('最長の歴代王者', longestReign, longestThemeName!, '在位 $days 日'));
    } else {
      widgets.add(_buildEmptyCard('最長の歴代王者', 'まだ記録がありません'));
    }

    BestPhoto? shortestReign;
    String? shortestThemeName;
    for (final t in tiles.values) {
      for (final p in t.history) {
        if (p.crownedAt != null) {
          if (shortestReign == null || p.crownedAt!.isAfter(shortestReign.crownedAt!)) {
            shortestReign = p;
            shortestThemeName = kThemes.firstWhere((th) => th.id == t.themeId).name;
          }
        }
      }
    }
    if (shortestReign != null && shortestThemeName != null) {
      final days = now.difference(shortestReign.crownedAt!).inDays;
      widgets.add(_buildPhotoCard('最短の歴代王者', shortestReign, shortestThemeName!, '在位 $days 日'));
    } else {
      widgets.add(_buildEmptyCard('最短の歴代王者', 'まだ歴代王者がいません'));
    }

    return widgets;
  }

  List<Widget> _buildBattleStats(Map<String, TileData> tiles) {
    final widgets = <Widget>[];
    final now = DateTime.now();

    final hotThemes = <String, int>{};
    for (final t in tiles.values) {
      int count = 0;
      for (final h in t.history) {
        if (h.crownedAt != null && now.difference(h.crownedAt!).inDays <= 90) count++;
      }
      if (t.currentBest?.crownedAt != null &&
          now.difference(t.currentBest!.crownedAt!).inDays <= 90) count++;
      if (count >= 5) hotThemes[t.themeId] = count;
    }
    if (hotThemes.isNotEmpty) {
      final sorted = hotThemes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final themeName = kThemes.firstWhere((th) => th.id == sorted.first.key).name;
      widgets.add(_buildInfoCard('🔥 激戦テーマ', themeName, '直近90日で ${sorted.first.value} 回交代'));
    } else {
      widgets.add(_buildEmptyCard('🔥 激戦テーマ', '直近90日で5回以上交代したテーマはありません'));
    }

    String? restoreTheme;
    int maxRestore = 0;
    for (final t in tiles.values) {
      final count = t.history.where((h) => h.isRestored).length +
          (t.currentBest?.isRestored == true ? 1 : 0);
      if (count > maxRestore) {
        maxRestore = count;
        restoreTheme = t.themeId;
      }
    }
    if (restoreTheme != null && maxRestore > 0) {
      final themeName = kThemes.firstWhere((th) => th.id == restoreTheme).name;
      widgets.add(_buildInfoCard('⚔️ 王者奪還', themeName, '$maxRestore 回復活'));
    } else {
      widgets.add(_buildEmptyCard('⚔️ 王者奪還', 'まだ復活した王者はいません'));
    }

    String? mostChanged;
    int maxChanges = 0;
    for (final t in tiles.values) {
      if (t.history.length > maxChanges) {
        maxChanges = t.history.length;
        mostChanged = t.themeId;
      }
    }
    if (mostChanged != null && maxChanges > 0) {
      final themeName = kThemes.firstWhere((th) => th.id == mostChanged).name;
      widgets.add(_buildInfoCard('🔄 交代が多いテーマ', themeName, '$maxChanges 回交代'));
    } else {
      widgets.add(_buildEmptyCard('🔄 交代が多いテーマ', 'まだ交代記録がありません'));
    }

    final stableThemes = tiles.values.where((t) => t.isKing && t.history.isEmpty).toList();
    if (stableThemes.isNotEmpty) {
      final themeName = kThemes.firstWhere((th) => th.id == stableThemes.first.themeId).name;
      widgets.add(_buildInfoCard('🏰 交代が少ないテーマ', themeName, '一度も交代なし'));
    } else {
      widgets.add(_buildEmptyCard('🏰 交代が少ないテーマ', 'まだ記録がありません'));
    }

    return widgets;
  }

  List<Widget> _buildShotStats(Map<String, TileData> tiles) {
    final widgets = <Widget>[];
    final allPhotos = <BestPhoto>[];

    for (final t in tiles.values) {
      if (t.currentBest != null) allPhotos.add(t.currentBest!);
      allPhotos.addAll(t.history);
    }

    final photosWithDate = allPhotos.where((p) => p.shotDate != null).toList();

    if (photosWithDate.isNotEmpty) {
      photosWithDate.sort((a, b) => a.shotDate!.compareTo(b.shotDate!));
      widgets.add(_buildInfoCard('📷 最古の撮影日', _formatDate(photosWithDate.first.shotDate), ''));
      widgets.add(_buildInfoCard('📷 最新の撮影日', _formatDate(photosWithDate.last.shotDate), ''));
    } else {
      widgets.add(_buildEmptyCard('📷 最古の撮影日', 'EXIFデータのある写真がありません'));
      widgets.add(_buildEmptyCard('📷 最新の撮影日', 'EXIFデータのある写真がありません'));
    }

    final locations = allPhotos.map((p) => p.location).where((l) => l.isNotEmpty).toSet();
    widgets.add(_buildInfoCard('📍 撮影場所', '${locations.length} カ所', ''));

    if (locations.isNotEmpty) {
      final locationCount = <String, int>{};
      for (final p in allPhotos) {
        if (p.location.isNotEmpty) {
          locationCount[p.location] = (locationCount[p.location] ?? 0) + 1;
        }
      }
      final sorted = locationCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      widgets.add(_buildInfoCard('🌊 最多撮影地', sorted.first.key, '${sorted.first.value} 枚'));
    } else {
      widgets.add(_buildEmptyCard('🌊 最多撮影地', '撮影場所を登録してください'));
    }

    return widgets;
  }

  Widget _buildKingStoryCard(String label, TileData tile, {String? subtitle}) {
    final photo = tile.currentBest;
    final themeName = kThemes.firstWhere((th) => th.id == tile.themeId).name;
    return _buildPhotoCard(label, photo!, themeName, subtitle ?? '');
  }

  Widget _buildPhotoCard(String label, BestPhoto photo, String themeName, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ResolvedImage(
                  fileName: photo.fileName,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 40,
                    height: 40,
                    color: Colors.white12,
                    child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(themeName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String label, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '不明';
    return DateFormat('yyyy年M月d日').format(date);
  }
}

class _BingoGridPainter extends CustomPainter {
  final List<int> bingoLines;
  final Map<String, TileData> tiles;

  _BingoGridPainter({required this.bingoLines, required this.tiles});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / 5;
    final cellH = size.height / 5;

    final bgPaint = Paint()
      ..color = const Color(0xFF0D0D1F)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final kingPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < kThemes.length; i++) {
      final tile = tiles[kThemes[i].id];
      if (tile?.isKing == true) {
        final col = i % 5;
        final row = i ~/ 5;
        canvas.drawRect(
          Rect.fromLTWH(col * cellW + 1, row * cellH + 1, cellW - 2, cellH - 2),
          kingPaint,
        );
      }
    }

    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 5; i++) {
      canvas.drawLine(Offset(i * cellW, 0), Offset(i * cellW, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * cellH), Offset(size.width, i * cellH), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset cellCenter(int index) {
      final col = index % 5;
      final row = index ~/ 5;
      return Offset(col * cellW + cellW / 2, row * cellH + cellH / 2);
    }

    for (final lineIndex in bingoLines) {
      final line = kBingoLines[lineIndex];
      canvas.drawLine(cellCenter(line.first), cellCenter(line.last), linePaint);
    }
  }

  @override
  bool shouldRepaint(_BingoGridPainter oldDelegate) =>
      oldDelegate.bingoLines != bingoLines || oldDelegate.tiles != tiles;
}
