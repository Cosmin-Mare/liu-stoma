import 'package:flutter/material.dart';

class TeethBackground extends StatelessWidget {
  final Widget child;
  final double vignetteRadius;

  const TeethBackground({
    super.key,
    required this.child,
    this.vignetteRadius = 2.3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double designWidth = 1200;
        final double width = constraints.maxWidth;

        // Scale background elements based on window width
        final double scale = (width / designWidth).clamp(0.5, 1.8);

        final double tileSize = 75 * scale; // a bit bigger teeth
        final double spacing = 100 * scale; // more space between them

        final double horizStep = tileSize + spacing;
        final double vertStep = tileSize * 0.75 + spacing;

        final int cols = (constraints.maxWidth / horizStep).ceil() + 2;

        // Start a bit above the visible area (half a tooth) and extend below
        // so the pattern feels vertically centered with no bottom gap.
        final double startY = -tileSize * 0.5;
        final int rows =
            ((constraints.maxHeight - startY) / vertStep).ceil() + 1;

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  // Vignette effect: bright center, darker edges
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.2),
                    radius: vignetteRadius,
                    colors: const [
                      Color.fromARGB(255, 255, 255, 255), // light center
                      Color.fromARGB(0, 0, 0, 0), // darker corners
                    ],
                    stops: const [.2, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.1, // less opacity
                  child: Stack(
                    children: [
                      for (int row = 0; row < rows; row++)
                        for (int col = 0; col < cols; col++)
                          Positioned(
                            left: col * horizStep +
                                (row.isOdd ? horizStep / 2 : 0),
                            top: startY + row * vertStep,
                            child: SizedBox(
                              width: tileSize,
                              height: tileSize,
                              child: Image.asset('assets/tooth.png'),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}


