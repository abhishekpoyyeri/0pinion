import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'loading_gif_widget.dart';

class AnimatedRefreshWidget extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const AnimatedRefreshWidget({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      builder: (
        BuildContext context,
        Widget child,
        IndicatorController controller,
      ) {
        return Stack(
          children: <Widget>[
            AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, _) {
                return Transform.translate(
                  offset: Offset(0.0, controller.value * 120),
                  child: child,
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: controller,
                builder: (BuildContext context, _) {
                  return Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: controller.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: controller.value.clamp(0.0, 1.0),
                        child: const ClipOval(
                          child: LoadingGifWidget(width: 80, height: 80),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
