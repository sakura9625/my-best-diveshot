import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/themes.dart';
import '../../constants/advance_themes.dart';
import '../../constants/sheet_definitions.dart';
import '../../providers/tiles_provider.dart';
import '../../providers/bingo_provider.dart';
import '../../providers/sheet_provider.dart';
import '../../providers/my_select_provider.dart';
import '../../widgets/bingo_overlay.dart';
import '../../widgets/resolved_image.dart';
import '../detail/detail_screen.dart';
import '../my_select/my_select_settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<int> _newBingoLines = [];
  bool _showBingo = false;
  List<int> _lastCompletedLines = [];

  void _checkNewBingo(String sheetId) {
    final currentLines = ref.read(completedBingoLinesProvider(sheetId));
    final notifier = ref.read(tilesProvider(sheetId).notifier);
    final newLines = notifier.getNewlyCompletedLines(currentLines);
    setState(() {
      _lastCompletedLines = currentLines;
    });
    if (newLines.isNotEmpty) {
      setState(() {
        _newBingoLines = newLines;
        _showBingo = true;
      });
    }
  }

  List<ThemeDefinition> _getThemes(String sheetId, List<ThemeDefinition> mySelectThemeDefs) {
    switch (sheetId) {
      case 'advance':
        return kAdvanceThemes;
      case 'my_select':
        return mySelectThemeDefs;
      default:
        return kThemes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSheetId = ref.watch(currentSheetProvider);
    final tiles = ref.watch(tilesProvider(currentSheetId));
    final completedCount = ref.watch(completedCountProvider(currentSheetId));
    final completedLines = ref.watch(completedBingoLinesProvider(currentSheetId));
    final mySelectThemeDefs = ref.watch(mySelectThemeDefinitionsProvider);
    final themes = _getThemes(currentSheetId, mySelectThemeDefs);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: const Text(
          'My Best',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final sheetId = ref.watch(currentSheetProvider);
              if (sheetId != 'my_select') return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MySelectSettingsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.slideshow, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedCount / 25 完成',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: completedCount / 25,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B4D8)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GridView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: themes.length,
                      itemBuilder: (context, index) {
                        final theme = themes[index];
                        final tile = tiles[theme.id];
                        final hasPhoto = tile?.hasPhoto ?? false;
                        final fileName = tile?.currentBest?.fileName;

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  theme: theme,
                                  initialIndex: index,
                                  sheetId: currentSheetId,
                                  themes: themes,
                                ),
                              ),
                            );
                            _checkNewBingo(currentSheetId);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: tile?.isKing == true
                                    ? const Color(0xFF00B4D8)
                                    : tile?.isProvisional == true
                                        ? Colors.white38
                                        : Colors.white12,
                              ),
                            ),
                            child: hasPhoto && fileName != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ColorFiltered(
                                          colorFilter: tile?.isKing == true
                                              ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                                              : const ColorFilter.matrix([
                                                  0.2126, 0.7152, 0.0722, 0, 0,
                                                  0.2126, 0.7152, 0.0722, 0, 0,
                                                  0.2126, 0.7152, 0.0722, 0, 0,
                                                  0,      0,      0,      1, 0,
                                                ]),
                                          child: ResolvedImage(
                                            fileName: fileName,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            color: Colors.black54,
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Text(
                                              theme.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/fish-solid-full.svg',
                                        width: 22,
                                        height: 22,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white38,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        theme.name,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 9,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                    if (_lastCompletedLines.isNotEmpty && !_showBingo)
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: BingoLinePainter(
                            completedLines: _lastCompletedLines,
                            padding: 8,
                            spacing: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildSheetSelector(context, ref),
            ],
          ),
          if (_showBingo)
            BingoOverlay(
              newBingoLines: _newBingoLines,
              onComplete: () => setState(() {
                _showBingo = false;
                _newBingoLines = [];
                _lastCompletedLines = [];
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildSheetSelector(BuildContext context, WidgetRef ref) {
    final currentSheetId = ref.watch(currentSheetProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              _buildSheetCard(ref, 'open_water', 'Open Water', currentSheetId),
              const SizedBox(width: 8),
              _buildSheetCard(ref, 'advance', 'Advanced', currentSheetId),
              const SizedBox(width: 8),
              _buildSheetCard(ref, 'my_select', 'My Select', currentSheetId),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLockedSlot(),
              const SizedBox(width: 8),
              _buildLockedSlot(),
              const SizedBox(width: 8),
              _buildLockedSlot(),
            ],
          ),
          // My Select説明文
          Consumer(
            builder: (context, ref, _) {
              final sheetId = ref.watch(currentSheetProvider);
              if (sheetId != 'my_select') return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(
                  '上部の鉛筆マークから自分の好きなテーマを登録できます',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white12),
        ],
      ),
    );
  }

  Widget _buildSheetCard(WidgetRef ref, String sheetId, String name, String currentSheetId) {
    final isSelected = sheetId == currentSheetId;
    final isUnlocked = ref.watch(sheetUnlockedProvider(sheetId));
    final completedCount = ref.watch(completedCountProvider(sheetId));
    final sheet = kDefaultSheets.firstWhere((s) => s.id == sheetId);
    final requiredBingos = sheet.unlockRequiredBingos;
    final requiredSheetId = sheet.unlockRequiredSheetId ?? 'open_water';
    final currentBingoCount = ref.watch(bingoCountProvider(requiredSheetId));
    final requiredSheetName = kDefaultSheets.firstWhere((s) => s.id == requiredSheetId).name;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isUnlocked) {
            ref.read(currentSheetProvider.notifier).state = sheetId;
          }
        },
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00B4D8).withOpacity(0.15) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00B4D8) : Colors.white12,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: isUnlocked
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$completedCount/25',
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00B4D8) : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00B4D8) : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, color: Colors.white38, size: 14),
                    const SizedBox(height: 2),
                    Text(
                      '$requiredSheetName',
                      style: const TextStyle(color: Colors.white24, fontSize: 9),
                    ),
                    Text(
                      '$currentBingoCount/${requiredBingos}ビンゴ',
                      style: const TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                    Text(name, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLockedSlot() {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+', style: TextStyle(color: Colors.white24, fontSize: 18)),
            Text('?', style: TextStyle(color: Colors.white24, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class BingoLinePainter extends CustomPainter {
  final List<int> completedLines;
  final double padding;
  final double spacing;

  BingoLinePainter({
    required this.completedLines,
    required this.padding,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final cellWidth = (size.width - padding * 2 - spacing * 4) / 5;
    final cellHeight = (size.height - padding * 2 - spacing * 4) / 5;

    Offset cellCenter(int index) {
      final col = index % 5;
      final row = index ~/ 5;
      final x = padding + col * (cellWidth + spacing) + cellWidth / 2;
      final y = padding + row * (cellHeight + spacing) + cellHeight / 2;
      return Offset(x, y);
    }

    for (final lineIndex in completedLines) {
      final line = kBingoLines[lineIndex];
      final start = cellCenter(line.first);
      final end = cellCenter(line.last);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(BingoLinePainter oldDelegate) =>
      oldDelegate.completedLines != completedLines;
}
