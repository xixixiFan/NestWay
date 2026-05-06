import 'package:flutter/material.dart';

class CountdownOverlay extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const CountdownOverlay({
    super.key,
    required this.seconds,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentSeconds = 3;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.seconds;
    _controller = AnimationController(
      duration: Duration(seconds: widget.seconds),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCancelled) {
        widget.onComplete();
      }
    });

    _controller.forward();
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = widget.seconds; i > 0; i--) {
      if (_isCancelled) break;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && !_isCancelled) {
        setState(() {
          _currentSeconds = i - 1;
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
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: 1 - _animation.value,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B6B),
                          ),
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_currentSeconds',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '松开取消',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                '持续按住按钮',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '三路求助正在准备中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
