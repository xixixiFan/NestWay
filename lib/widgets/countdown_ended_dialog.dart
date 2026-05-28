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
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0D0D0), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：图标 + 标题 + 关闭
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('i', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '超时未响应',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onClose();
                  },
                  child: const Icon(Icons.close, size: 20, color: Colors.black87),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 说明文字
            const Text(
              '已自动发送短信给您的紧急联系人，如您已安全，可点击下面的按钮向紧急联系人发送解释短信。',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.6),
            ),

            const SizedBox(height: 20),

            // 发送按钮（深色圆角）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onSendExplanation();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('发送解释短信', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
