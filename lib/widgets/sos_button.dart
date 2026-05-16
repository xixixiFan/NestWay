import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SosButton extends StatefulWidget {
  final double size;
  final VoidCallback onTriggered;
  final String text;

  const SosButton({
    super.key,
    this.size = 160,
    required this.onTriggered,
    this.text = '长按求助',
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> {
  bool _isPressed = false;
  bool _showCountdown = false;

  void _onLongPressStart(LongPressStartDetails details) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isPressed = true;
      _showCountdown = true;
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isPressed = false;
      _showCountdown = false;
    });
  }

  void _onCountdownComplete() {
    setState(() {
      _showCountdown = false;
    });
    HapticFeedback.heavyImpact();
    widget.onTriggered();
  }

  void _onCountdownCancel() {
    setState(() {
      _isPressed = false;
      _showCountdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          onLongPressCancel: () {
            setState(() {
              _isPressed = false;
              _showCountdown = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _isPressed
                  ? const Color(0xFFFFE066).withValues(alpha: 0.8)
                  : const Color(0xFFFFE066),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isPressed ? 0.15 : 0.1),
                  blurRadius: _isPressed ? 15 : 10,
                  offset: Offset(0, _isPressed ? 6 : 4),
                ),
              ],
            ),
            transform: _isPressed
                ? (Matrix4.identity()..scaleByDouble(0.95, 0.95, 1.0, 1.0))
                : Matrix4.identity(),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sos,
                    size: 36,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showCountdown)
          Positioned.fill(
            child: _CountdownCircle(
              key: UniqueKey(),
              onComplete: _onCountdownComplete,
              onCancel: _onCountdownCancel,
            ),
          ),
      ],
    );
  }
}

class _CountdownCircle extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _CountdownCircle({
    super.key,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<_CountdownCircle> createState() => _CountdownCircleState();
}

class _CountdownCircleState extends State<_CountdownCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _countdown = 3;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCancelled) {
        widget.onComplete();
      }
    });

    _startCountdown();
    _controller.forward();
  }

  void _startCountdown() async {
    for (int i = 3; i > 0; i--) {
      if (_isCancelled) break;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && !_isCancelled) {
        setState(() {
          _countdown = i - 1;
        });
      }
    }
  }

  void _cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _controller.stop();
    widget.onCancel();
  }

  @override
  void dispose() {
    _isCancelled = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressUp: _cancel,
      onPanEnd: (_) => _cancel(),
      onTapUp: (_) => _cancel(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: 1 - _controller.value,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B6B),
                          ),
                        );
                      },
                    ),
                  ),
                  Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '松开取消',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
