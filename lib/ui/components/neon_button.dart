import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/neon_theme.dart';
import '../../game/managers/haptic_manager.dart';

/// A cyberpunk-styled button with neon glow effects
class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isEnabled;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.width,
    this.height,
    this.icon,
    this.isEnabled = true,
    this.isLoading = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? NeonTheme.primaryNeon;
    final isInteractive = widget.isEnabled && !widget.isLoading && widget.onPressed != null;

    return GestureDetector(
      onTapDown: isInteractive ? (_) => _onTapDown() : null,
      onTapUp: isInteractive ? (_) => _onTapUp() : null,
      onTapCancel: isInteractive ? () => _onTapCancel() : null,
      onTap: isInteractive ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * 0.05);
          final opacity = widget.isEnabled ? 1.0 : 0.5;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.width,
              height: widget.height ?? 50,
              decoration: BoxDecoration(
                color: _isPressed 
                    ? buttonColor.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: buttonColor.withOpacity(opacity),
                  width: 2,
                ),
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.3),
                          blurRadius: _isPressed ? 12 : 8,
                          spreadRadius: _isPressed ? 3 : 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            buttonColor.withOpacity(opacity),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: buttonColor.withOpacity(opacity),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: NeonTheme.buttonStyle.copyWith(
                              color: buttonColor.withOpacity(opacity),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    ).animate(target: widget.isEnabled ? 1 : 0)
        .shimmer(
          duration: 2000.ms,
          color: buttonColor.withOpacity(0.3),
        );
  }

  void _onTapDown() {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
    
    // Add haptic feedback for button press
    HapticManager().selectionClick();
  }

  void _onTapUp() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }
}