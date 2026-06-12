import 'dart:math';
import 'package:flutter/material.dart';

/// Geometric monochrome avatar generator
/// Generates a deterministic pattern from a seed integer
class AvatarWidget extends StatelessWidget {
  final int seed;
  final double size;

  const AvatarWidget({
    super.key,
    required this.seed,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: CustomPaint(
          size: Size(size, size),
          painter: _AvatarPainter(
            seed: seed,
            foreground: isDark ? Colors.black : Colors.white,
            background: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final int seed;
  final Color foreground;
  final Color background;

  _AvatarPainter({
    required this.seed,
    required this.foreground,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()..color = foreground;
    final cellSize = size.width / 5;

    // Generate a 5x5 grid, mirrored horizontally for symmetry
    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 3; x++) {
        if (random.nextBool()) {
          // Draw on left side
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            paint,
          );
          // Mirror on right side
          if (x < 2) {
            canvas.drawRect(
              Rect.fromLTWH(
                (4 - x) * cellSize, y * cellSize, cellSize, cellSize,
              ),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
