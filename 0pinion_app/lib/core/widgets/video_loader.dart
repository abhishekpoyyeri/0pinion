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
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/loading.gif',
        fit: BoxFit.contain,
      ),
    );
  }
}
