import '../../core/constants/game_constants.dart';

typedef PhysicsStepCallback = void Function(double dt);
typedef RenderStepCallback = void Function(double alpha);

/// Фиксированный детерминированный таймер игрового цикла
class FixedTimestepGameTicker {
  double _accumulator = 0.0;
  static const double fixedDt = GameConstants.fixedDeltaTime;
  static const double maxFrameTime = 0.25; // Защита от спирали смерти при лагах

  /// Обновление времени с детерминированным шагом
  void update(
    double rawDeltaSeconds, {
    required PhysicsStepCallback onPhysicsStep,
    required RenderStepCallback onRenderStep,
  }) {
    // Ограничиваем максимальное время кадра
    final frameTime = rawDeltaSeconds.clamp(0.0, maxFrameTime);
    _accumulator += frameTime;

    while (_accumulator >= fixedDt) {
      onPhysicsStep(fixedDt);
      _accumulator -= fixedDt;
    }

    // Коэффициент интерполяции для сглаживания графики между тиками физики
    final alpha = _accumulator / fixedDt;
    onRenderStep(alpha);
  }

  void reset() {
    _accumulator = 0.0;
  }
}
