import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/themes.dart';
import '../../constants/advance_themes.dart';
import '../../constants/extra_sheet_themes.dart';
import '../../constants/sheet_definitions.dart';
import '../../constants/app_config.dart';
import '../../providers/tiles_provider.dart';
import '../../providers/bingo_provider.dart';
import '../../providers/sheet_provider.dart';
import '../../providers/my_select_provider.dart';
import '../../providers/purchased_sheets_provider.dart';
import '../../widgets/bingo_overlay.dart';
import '../../widgets/resolved_image.dart';
import '../detail/detail_screen.dart';
import '../my_select/my_select_settings_screen.dart';
import '../shop/sheet_shop_screen.dart';
import '../presentation/presentation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<int> _newBingoLines = [];
  bool _showBingo = false;
  List<int> _lastCompletedLines = [];
  bool _mySelectWelcomeShown = false;
  Set<int> _celebratedLines = {};

  @override
  void initState() {
    super.initState();
    _loadCelebratedLines();
  }

  Future<void> _loadCelebratedLines() async {
    final prefs = await SharedPreferences.getInstance();
    final lines = prefs.getStringList('celebrated_bingo_lines_${ref.read(currentSheetProvider)}') ?? [];
    setState(() {
      _celebratedLines = lines.map((e) => int.parse(e)).toSet();
    });
  }

  Future<void> _saveCelebratedLines(String sheetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'celebrated_bingo_lines_$sheetId',
      _celebratedLines.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _checkNewBingo(String sheetId) async {
    final currentLines = ref.read(completedBingoLinesProvider(sheetId));
    final newLines = currentLines
        .where((line) => !_celebratedLines.contains(line))
        .toList();
    setState(() {
      _lastCompletedLines = currentLines;
    });
    if (newLines.isNotEmpty) {
      _celebratedLines.addAll(newLines);
      _saveCelebratedLines(sheetId);
      setState(() {
        _newBingoLines = newLines;
        _showBingo = true;
      });
    }
    await _checkSheetUnlock(context, ref);
  }

  Future<void> _checkSheetUnlock(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final advanceUnlocked = ref.read(sheetUnlockedProvider('advance'));
    final shown = prefs.getBool('advance_unlock_shown') ?? false;
    if (advanceUnlocked && !shown) {
      await prefs.setBool('advance_unlock_shown', true);
      if (mounted) _showAdvanceUnlockDialog(context);
    }
  }

  void _showAdvanceUnlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('🎉 解放！', style: TextStyle(color: Colors.white)),
        content: const Text(
          'おめでとうございます！\nAdvancedが解放されました！\n\nより難しいテーマに挑戦しましょう。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }

  List<ThemeDefinition> _getThemes(String sheetId, List<ThemeDefinition> mySelectThemeDefs) {
    switch (sheetId) {
      case 'advance':
        return kAdvanceThemes;
      case 'my_select':
        return mySelectThemeDefs;
      default:
        return kExtraSheetThemesMap[sheetId] ?? kThemes;
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PresentationScreen(
                    sheetId: currentSheetId,
                    themes: themes,
                  ),
                ),
              );
            },
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
                            await _checkNewBingo(currentSheetId);
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
    final purchased = ref.watch(purchasedSheetsProvider);
    final purchasedExtraSheets = kExtraSheets
        .where((s) => AppConfig.isProUser || purchased.contains(s.id))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          // My Select説明文
          Consumer(
            builder: (context, ref, _) {
              final sheetId = ref.watch(currentSheetProvider);
              if (sheetId != 'my_select') return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  '上部の鉛筆マークから自分の好きなテーマを登録できます',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          // 上段：デフォルト3シート
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
          // 下段：購入済みシート + 追加ボタン（横スクロール）
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 購入済みシート
                ...purchasedExtraSheets.map((sheet) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildExtraSheetCard(ref, sheet.id, sheet.name, currentSheetId),
                )),
                // 追加スロット（ショップへ）
                ..._buildLockedSlots(context, ref, purchasedExtraSheets.length),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white12),
        ],
      ),
    );
  }

  List<Widget> _buildLockedSlots(BuildContext context, WidgetRef ref, int purchasedCount) {
    final slots = <Widget>[];
    // 最低3スロット表示、購入済みが3以上なら+1スロット
    final slotCount = purchasedCount < 3 ? 3 - purchasedCount : 1;
    for (int i = 0; i < slotCount; i++) {
      slots.add(Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _buildAddSlot(context),
      ));
    }
    return slots;
  }

  Widget _buildExtraSheetCard(WidgetRef ref, String sheetId, String name, String currentSheetId) {
    final isSelected = sheetId == currentSheetId;
    final completedCount = ref.watch(completedCountProvider(sheetId));

    return GestureDetector(
      onTap: () => ref.read(currentSheetProvider.notifier).state = sheetId,
      child: Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00B4D8).withOpacity(0.15) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00B4D8) : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$completedCount/25',
              style: TextStyle(
                color: isSelected ? const Color(0xFF00B4D8) : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00B4D8) : Colors.white54,
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
  }

  Widget _buildAddSlot(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SheetShopScreen()),
        );
      },
      child: Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white38),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('追加', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showMySelectWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('My Select', style: TextStyle(color: Colors.white)),
        content: const Text(
          '上部の鉛筆マークから自分の好きなテーマを登録して、自由にビンゴをつくれます。またほかのビンゴを購入することもできます。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }

  void _showLockedDialog(BuildContext context, String requiredSheetName, int requiredBingos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('ロック中', style: TextStyle(color: Colors.white)),
        content: Text(
          'まだロックされています。$requiredSheetNameのビンゴを$requiredBingos個以上揃えると解放されます。',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndShowMySelectWelcome(BuildContext context) async {
    if (_mySelectWelcomeShown) return;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('my_select_welcome_shown') ?? false;
    if (!shown) {
      _mySelectWelcomeShown = true;
      await prefs.setBool('my_select_welcome_shown', true);
      if (context.mounted) _showMySelectWelcomeDialog(context);
    }
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
            if (sheetId == 'my_select') {
              _checkAndShowMySelectWelcome(context);
            }
          } else {
            _showLockedDialog(context, requiredSheetName, requiredBingos ?? 3);
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
