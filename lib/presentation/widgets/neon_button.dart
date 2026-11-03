import 'package:flutter/material.dart';

/// Тактильная кнопка с неоновым свечением и пружинной анимацией нажатия
class NeonButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget? child;
  final String? text;
  final IconData? icon;
  final Color primaryColor;
  final Color? textColor;
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const NeonButton({
    super.key,
    required this.onTap,
    this.child,
    this.text,
    this.icon,
    this.primaryColor = const Color(0xFF00FF66),
    this.textColor,
    this.width = double.infinity,
    this.height = 54.0,
    this.borderRadius = 16.0,
    this.isCircle = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _animController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _animController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.isCircle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.primaryColor,
                Color.lerp(widget.primaryColor, Colors.black, 0.28)!,
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.85),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.45),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.child ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.textColor ?? Colors.black,
                        size: 26,
                      ),
                      if (widget.text != null) const SizedBox(width: 8),
                    ],
                    if (widget.text != null)
                      Text(
                        widget.text!,
                        style: TextStyle(
                          color: widget.textColor ?? Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          shadows: widget.textColor == Colors.white
                              ? const [Shadow(color: Colors.black, blurRadius: 4)]
                              : null,
                        ),
                      ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

