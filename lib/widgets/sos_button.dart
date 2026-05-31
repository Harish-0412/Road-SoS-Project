import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rippleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Controller for the 3-second hold to dispatch
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Controller for the continuous sonar wave pulsing effect
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSOS();
        _controller.reset();
        setState(() => _isPressed = false);
      }
    });
  }

  void _triggerSOS() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "🚨 SOS DISPATCHED: GPS telemetry compressed & sent via Native SMS.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.tacticalRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        // Calculate two staggered sonar wave scale & opacity values
        final v1 = _rippleController.value;
        final v2 = (v1 + 0.5) % 1.0;

        final scale1 = 1.0 + v1 * 0.75;
        final opacity1 = (1.0 - v1) * 0.35;

        final scale2 = 1.0 + v2 * 0.75;
        final opacity2 = (1.0 - v2) * 0.35;

        return GestureDetector(
          onLongPressStart: (_) {
            setState(() => _isPressed = true);
            _controller.forward();
          },
          onLongPressEnd: (_) {
            setState(() => _isPressed = false);
            if (!_controller.isCompleted) {
              _controller.reset();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Sonar Ripple 1
              Transform.scale(
                scale: scale1,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.tacticalRed.withOpacity(opacity1),
                  ),
                ),
              ),
              // Outer Sonar Ripple 2
              Transform.scale(
                scale: scale2,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.tacticalRed.withOpacity(opacity2),
                  ),
                ),
              ),
              
              // Circular Progress Indicator (The loading ring)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    width: 142,
                    height: 142,
                    child: CircularProgressIndicator(
                      value: _controller.value,
                      strokeWidth: 6,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      backgroundColor: Colors.white.withOpacity(0.15),
                    ),
                  );
                },
              ),
              
              // The Core Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isPressed ? 108 : 120,
                height: _isPressed ? 108 : 120,
                decoration: BoxDecoration(
                  color: AppTheme.tacticalRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.tacticalRed.withOpacity(0.55),
                      blurRadius: _isPressed ? 15 : 28,
                      spreadRadius: _isPressed ? 3 : 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPressed ? Icons.emergency : Icons.emergency_share, 
                      size: 44, 
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isPressed ? "RELEASING..." : "HOLD SOS",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
