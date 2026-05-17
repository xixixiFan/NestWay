import 'package:flutter/material.dart';
import 'video_player_dialog.dart';

class CallSimulateDialog extends StatelessWidget {
  const CallSimulateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const CallSimulateDialog();
      },
    );
  }

  Future<void> _acceptCall(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!navigator.mounted) return;
    VideoPlayerDialog.show(navigator.context, 'assets/attention_video.mp4');
  }

  void _rejectCall(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF5A5A5A),
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE0E0E0),
              radius: 50,
              child: Icon(
                Icons.person,
                color: Color(0xFF757575),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '朋友',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '邀请你视频通话...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _acceptCall(context),
                  borderRadius: BorderRadius.circular(48),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.all(Radius.circular(48)),
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 64),
                InkWell(
                  onTap: () => _rejectCall(context),
                  borderRadius: BorderRadius.circular(48),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF44336),
                      borderRadius: BorderRadius.all(Radius.circular(48)),
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
