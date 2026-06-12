import 'package:flutter/material.dart';

class VideoLoader extends StatelessWidget {
  final double width;
  final double height;

  const VideoLoader({
    super.key,
    this.width = 120,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    Widget image = Image.asset(
      'assets/loading.gif',
      fit: BoxFit.contain,
    );

    if (isLightMode) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]),
        child: image,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: image,
    );
  }
}
