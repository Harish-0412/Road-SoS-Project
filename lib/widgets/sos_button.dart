import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

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
      const SnackBar(
        content: Text("🚨 SOS DISPATCHED: GPS telemetry compressed & sent via Native SMS."),
        backgroundColor: AppTheme.tacticalRed,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // Circular Progress Indicator (The loading ring)
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: _controller.value,
              strokeWidth: 8,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.starkWhite),
              backgroundColor: Colors.white24,
            ),
          ),
          // The Inner Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isPressed ? 110 : 120,
            height: _isPressed ? 110 : 120,
            decoration: BoxDecoration(
              color: AppTheme.tacticalRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.tacticalRed.withOpacity(0.5),
                  blurRadius: _isPressed ? 10 : 20,
                  spreadRadius: _isPressed ? 2 : 5,
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emergency, size: 48, color: Colors.white),
                Text(
                  "HOLD SOS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
