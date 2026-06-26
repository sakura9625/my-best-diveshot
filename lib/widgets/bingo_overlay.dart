import 'package:flutter/material.dart';

class BingoOverlay extends StatefulWidget {
  final List<int> newBingoLines;
  final VoidCallback onComplete;

  const BingoOverlay({
    super.key,
    required this.newBingoLines,
    required this.onComplete,
  });

  @override
  State<BingoOverlay> createState() => _BingoOverlayState();
}

class _BingoOverlayState extends State<BingoOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _confettiController;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
    _confettiController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _controller.value < 0.7
            ? _fadeIn.value
            : _fadeOut.value;
        return Opacity(
          opacity: opacity,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🎉',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BINGO!',
                    style: TextStyle(
                      color: const Color(0xFF00B4D8),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00B4D8).withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.newBingoLines.length}本のビンゴ達成！',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ConfettiWidget(controller: _confettiController),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiWidget extends StatelessWidget {
  final AnimationController controller;

  const _ConfettiWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 200),
          painter: _ConfettiPainter(progress: controller.value),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static const colors = [
    Color(0xFF00B4D8),
    Color(0xFFFF6B6B),
    Color(0xFFFFE66D),
    Color(0xFF4ECDC4),
    Color(0xFFFF8B94),
  ];

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = [
      [0.1, 0.2, 0], [0.3, 0.5, 1], [0.5, 0.1, 2],
      [0.7, 0.4, 3], [0.9, 0.3, 4], [0.2, 0.7, 0],
      [0.4, 0.6, 1], [0.6, 0.8, 2], [0.8, 0.2, 3],
      [0.15, 0.9, 4], [0.45, 0.3, 0], [0.75, 0.7, 1],
      [0.25, 0.4, 2], [0.55, 0.6, 3], [0.85, 0.1, 4],
    ];

    for (final item in random) {
      final x = item[0] * size.width;
      final startY = -20.0;
      final endY = size.height * 1.2;
      final y = startY + (endY - startY) * progress;
      final colorIndex = item[2].toInt();
      final paint = Paint()
        ..color = colors[colorIndex % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y + item[1] * 50), 4, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
