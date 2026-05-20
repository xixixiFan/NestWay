import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class VideoPlayerDialog extends StatefulWidget {
  final String videoPath;

  const VideoPlayerDialog({
    super.key,
    required this.videoPath,
  });

  static Future<void> show(BuildContext context, String videoPath) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return VideoPlayerDialog(videoPath: videoPath);
      },
    );
  }

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '视频加载失败';
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('🎬 开始初始化视频: ${widget.videoPath}');
      
      // 验证视频文件是否存在于assets中
      try {
        await rootBundle.load(widget.videoPath);
        print('✅ 视频文件存在于assets中');
      } catch (e) {
        print('❌ 视频文件不存在: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = '视频文件不存在\n请联系开发者';
          });
        }
        return;
      }

      _controller = VideoPlayerController.asset(
        widget.videoPath,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // 添加错误监听
      _controller.addListener(() {
        if (_controller.value.hasError) {
          print('❌ 视频播放错误: ${_controller.value.errorDescription}');
          if (mounted && !_hasError) {
            setState(() {
              _hasError = true;
              _errorMessage = '视频播放出错\n${_controller.value.errorDescription ?? ""}';
            });
          }
        }
      });

      await _controller.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        await _controller.setLooping(true);
        await _controller.play();
        print('✅ 视频初始化成功并开始播放');
      }
    } catch (e, stackTrace) {
      print('❌ 视频初始化失败: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '视频加载失败\n错误: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _retryInitialize() async {
    if (_retryCount >= _maxRetries) {
      setState(() {
        _errorMessage = '多次重试失败\n请检查网络或重启应用';
      });
      return;
    }

    _retryCount++;
    print('🔄 重试加载视频 (第 $_retryCount 次)');
    
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });

    await Future.delayed(const Duration(seconds: 1));
    await _initializeVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          if (_isInitialized) ...[
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
            // 播放/暂停控制
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (!_isInitialized && !_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _retryCount > 0 ? '正在重试... ($_retryCount/$_maxRetries)' : '正在加载视频...',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (_retryCount < _maxRetries) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _retryInitialize,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
