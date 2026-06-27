import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/themes.dart';
import '../../providers/tiles_provider.dart';
import '../../providers/bingo_provider.dart';
import '../../widgets/bingo_overlay.dart';
import '../../widgets/resolved_image.dart';
import '../detail/detail_screen.dart';
import '../activity/activity_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<int> _newBingoLines = [];
  bool _showBingo = false;

  void _checkNewBingo() {
    final currentLines = ref.read(completedBingoLinesProvider);
    final notifier = ref.read(tilesProvider.notifier);
    final newLines = notifier.getNewlyCompletedLines(currentLines);
    if (newLines.isNotEmpty) {
      setState(() {
        _newBingoLines = newLines;
        _showBingo = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiles = ref.watch(tilesProvider);
    final completedCount = ref.watch(completedCountProvider);
    final completedLines = ref.watch(completedBingoLinesProvider);

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
          IconButton(
            icon: const Icon(Icons.slideshow, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityScreen()),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedCount / 25 完成',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
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
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: kThemes.length,
                      itemBuilder: (context, index) {
                        final theme = kThemes[index];
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
                                ),
                              ),
                            );
                            _checkNewBingo();
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
                                        ResolvedImage(
                                          fileName: fileName,
                                          fit: BoxFit.cover,
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
                    if (completedLines.isNotEmpty)
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: BingoLinePainter(
                            completedLines: completedLines,
                            padding: 8,
                            spacing: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_showBingo)
            BingoOverlay(
              newBingoLines: _newBingoLines,
              onComplete: () => setState(() => _showBingo = false),
            ),
        ],
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
