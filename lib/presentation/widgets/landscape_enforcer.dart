import 'package:flutter/material.dart';
import '../../data/game_storage.dart';

/// Виджет-обертка, гарантирующий, что игра всегда отображается
/// в горизонтальном ландшафтном режиме (Landscape).
///
/// По умолчанию сцена ориентирована в landscapeLeft (quarterTurns: 3).
/// Если пользователь предпочитает обратный поворот (landscapeRight),
/// в настройках можно переключить на 180 градусов (quarterTurns: 1).
class LandscapeEnforcer extends StatelessWidget {
  final Widget child;

  const LandscapeEnforcer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameStorage.instance,
      builder: (context, _) {
        final turns = GameStorage.instance.flipLandscape ? 1 : 3;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isVertical = constraints.maxHeight > constraints.maxWidth;

            if (isVertical) {
              final landscapeWidth = constraints.maxHeight;
              final landscapeHeight = constraints.maxWidth;
              final mediaQuery = MediaQuery.of(context);
              final p = mediaQuery.padding;

              // При повороте пересчитываем отступы SafeArea:
              // Для quarterTurns: 3 (поворот на 90 градусов против часовой стрелки):
              // top -> left, right -> top, bottom -> right, left -> bottom
              // Для quarterTurns: 1 (поворот на 90 градусов по часовой стрелке):
              // top -> right, right -> bottom, bottom -> left, left -> top
              final rotatedPadding = turns == 3
                  ? EdgeInsets.only(
                      top: p.right,
                      right: p.bottom,
                      bottom: p.left,
                      left: p.top,
                    )
                  : EdgeInsets.only(
                      top: p.left,
                      right: p.top,
                      bottom: p.right,
                      left: p.bottom,
                    );
              final rotatedInsets = turns == 3
                  ? EdgeInsets.only(
                      top: mediaQuery.viewInsets.right,
                      right: mediaQuery.viewInsets.bottom,
                      bottom: mediaQuery.viewInsets.left,
                      left: mediaQuery.viewInsets.top,
                    )
                  : EdgeInsets.only(
                      top: mediaQuery.viewInsets.left,
                      right: mediaQuery.viewInsets.top,
                      bottom: mediaQuery.viewInsets.right,
                      left: mediaQuery.viewInsets.bottom,
                    );

              return RotatedBox(
                quarterTurns: turns,
                child: MediaQuery(
                  data: mediaQuery.copyWith(
                    size: Size(landscapeWidth, landscapeHeight),
                    padding: rotatedPadding,
                    viewPadding: rotatedPadding,
                    viewInsets: rotatedInsets,
                  ),
                  child: SizedBox(
                    width: landscapeWidth,
                    height: landscapeHeight,
                    child: child,
                  ),
                ),
              );
            }

            return child;
          },
        );
      },
    );
  }
}
