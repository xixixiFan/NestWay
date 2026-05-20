import 'package:flutter/material.dart';

class CountdownEndedDialog extends StatelessWidget {
  final VoidCallback onSendExplanation;
  final VoidCallback onClose;

  const CountdownEndedDialog({
    super.key,
    required this.onSendExplanation,
    required this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onSendExplanation,
    required VoidCallback onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CountdownEndedDialog(
        onSendExplanation: onSendExplanation,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '超时未响应',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '已自动发送短信给您的紧急联系人，如您已安全，可点击下面向紧急联系人发送解释短信。',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE066),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onSendExplanation();
                },
                child: const Text(
                  '发送安全解释短信',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
