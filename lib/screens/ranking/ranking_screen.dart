import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/themes.dart';
import '../../constants/advance_themes.dart';
import '../../models/tile_data.dart';
import '../../providers/tiles_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../providers/sheet_provider.dart';
import '../../constants/sheet_definitions.dart';
import '../../widgets/resolved_image.dart';
import '../../widgets/sheet_tab_bar.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  ThemeDefinition? _getThemeDefinition(String id) {
    final ow = kThemes.where((t) => t.id == id).toList();
    if (ow.isNotEmpty) return ow.first;
    final adv = kAdvanceThemes.where((t) => t.id == id).toList();
    if (adv.isNotEmpty) return adv.first;
    if (id.startsWith('my_select_')) {
      final index = int.tryParse(id.replaceFirst('my_select_', '')) ?? 0;
      return ThemeDefinition.mySelect(index, 'My Select ${index + 1}');
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetId = ref.watch(currentSheetProvider);
    final isUnlocked = ref.watch(sheetUnlockedProvider(sheetId));

    if (!isUnlocked) {
      final sheet = kDefaultSheets.firstWhere((s) => s.id == sheetId);
      final requiredSheetId = sheet.unlockRequiredSheetId ?? 'open_water';
      final requiredSheetName = kDefaultSheets.firstWhere((s) => s.id == requiredSheetId).name;
      final requiredBingos = sheet.unlockRequiredBingos ?? 3;

      return Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A1A),
          title: const Text('ランキング', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

    final ranking = ref.watch(rankingProvider(sheetId));
    final tiles = ref.watch(tilesProvider(sheetId));

    final rankedIds = ranking.where((id) {
      final tile = tiles[id];
      return tile?.isKing == true;
    }).toList();

    final provisionalIds = ranking.where((id) {
      final tile = tiles[id];
      return tile?.isProvisional == true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: const Text(
          'ランキング',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RankingGalleryScreen(
                    rankedIds: rankedIds,
                    tiles: tiles,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SheetTabBar(),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: rankedIds.isEmpty && provisionalIds.isEmpty
                ? const Center(
                    child: Text(
                      '写真を登録するとランキングが表示されます',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    onReorder: (oldIndex, newIndex) {
                if (oldIndex < rankedIds.length && newIndex <= rankedIds.length) {
                  final allRanking = ref.read(rankingProvider(sheetId));
                  final kingOldIndex = allRanking.indexOf(rankedIds[oldIndex]);
                  int kingNewIndex;
                  if (newIndex >= rankedIds.length) {
                    kingNewIndex = allRanking.indexOf(rankedIds[rankedIds.length - 1]) + 1;
                  } else {
                    kingNewIndex = allRanking.indexOf(rankedIds[newIndex]);
                  }
                  ref.read(rankingProvider(sheetId).notifier).reorder(kingOldIndex, kingNewIndex);
                }
              },
              itemCount: rankedIds.length + (provisionalIds.isNotEmpty ? provisionalIds.length + 1 : 0),
              itemBuilder: (context, index) {
                if (provisionalIds.isNotEmpty && index == rankedIds.length) {
                  return const _SectionDivider(key: ValueKey('divider'), label: '仮登録中');
                }

                final isProvisional = index > rankedIds.length;
                final id = isProvisional
                    ? provisionalIds[index - rankedIds.length - 1]
                    : rankedIds[index];
                final tile = tiles[id];
                final theme = _getThemeDefinition(id);
                if (theme == null) return const SizedBox.shrink(key: ValueKey('unknown'));
                final rank = isProvisional ? null : index + 1;

                return _RankingCard(
                  key: ValueKey(id),
                  rank: rank,
                  theme: theme,
                  tile: tile,
                  isDraggable: !isProvisional,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RankingGalleryScreen(
                          rankedIds: rankedIds,
                          tiles: tiles,
                        ),
                      ),
                    );
                  },
                );
              },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ),
          const Expanded(child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final int? rank;
  final ThemeDefinition theme;
  final TileData? tile;
  final bool isDraggable;
  final VoidCallback onTap;

  const _RankingCard({
    super.key,
    required this.rank,
    required this.theme,
    required this.tile,
    required this.isDraggable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photo = tile?.currentBest;
    final isKing = tile?.isKing == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isKing ? const Color(0xFF00B4D8).withOpacity(0.3) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: rank != null
                  ? Text(
                      '$rank',
                      style: TextStyle(
                        color: rank! <= 3 ? const Color(0xFFFFD700) : Colors.white54,
                        fontSize: rank! <= 3 ? 20 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : const Icon(Icons.hourglass_empty, color: Colors.white24, size: 18),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: photo != null
                  ? ResolvedImage(
                      fileName: photo.fileName,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.white12,
                      child: const Icon(Icons.image, color: Colors.white24),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (photo?.title.isNotEmpty == true)
                    Text(
                      photo!.title,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  if (photo?.location.isNotEmpty == true)
                    Text(
                      photo!.location,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (isDraggable)
              const Icon(Icons.drag_handle, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreviewDialog extends StatelessWidget {
  final ThemeDefinition theme;
  final TileData tile;

  const _PhotoPreviewDialog({required this.theme, required this.tile});

  @override
  Widget build(BuildContext context) {
    final photo = tile.currentBest!;
    return Dialog(
      backgroundColor: const Color(0xFF0A0A1A),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: ResolvedImage(
              fileName: photo.fileName,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(theme.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (photo.title.isNotEmpty)
                  Text(photo.title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                if (photo.location.isNotEmpty)
                  Text(photo.location, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }
}

class RankingGalleryScreen extends StatelessWidget {
  final List<String> rankedIds;
  final Map<String, TileData> tiles;

  const RankingGalleryScreen({
    super.key,
    required this.rankedIds,
    required this.tiles,
  });

  ThemeDefinition? _getThemeDefinition(String id) {
    final ow = kThemes.where((t) => t.id == id).toList();
    if (ow.isNotEmpty) return ow.first;
    final adv = kAdvanceThemes.where((t) => t.id == id).toList();
    if (adv.isNotEmpty) return adv.first;
    if (id.startsWith('my_select_')) {
      final index = int.tryParse(id.replaceFirst('my_select_', '')) ?? 0;
      return ThemeDefinition.mySelect(index, 'My Select ${index + 1}');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('ランキング一覧', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rankedIds.length,
        itemBuilder: (context, index) {
          final id = rankedIds[index];
          final tile = tiles[id];
          final theme = _getThemeDefinition(id);
          if (theme == null) return const SizedBox.shrink();
          final photo = tile?.currentBest;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${index + 1}位',
                      style: TextStyle(
                        color: index < 3 ? const Color(0xFFFFD700) : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(theme.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                if (photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ResolvedImage(
                      fileName: photo.fileName,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                if (photo?.title.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(photo!.title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
