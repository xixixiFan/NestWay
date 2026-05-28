import 'package:flutter/material.dart';

/// 护送流程调试面板 — 正式发布前应移除或条件编译。
///
/// 使用方式：在页面 body 外层包一个 Stack，底部加上 [EscortDebugFloatingButton]。
///
/// 定时器加速：[EscortDebug.skipTimer] 返回跳过的秒数，页面定时器每次 tick
/// 调用此方法即可。

class EscortDebug {
  static bool enabled = true;
  static int speedMultiplier = 15; // 1 秒真实 = 15 秒模拟

  /// 对于周期性定时器 (1s tick)，每次 tick 返回跳过的秒数（含自身这 1 秒）
  static int skipTimer() => enabled ? speedMultiplier : 1;
}

class EscortDebugFloatingButton extends StatelessWidget {
  final Widget child;
  final List<DebugAction> actions;

  const EscortDebugFloatingButton({
    super.key,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (!EscortDebug.enabled) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 12,
          bottom: 100,
          child: GestureDetector(
            onTap: () => _showPanel(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  void _showPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Color(0xFFFFE066), size: 18),
                const SizedBox(width: 8),
                Text(
                  '调试面板 · ${EscortDebug.speedMultiplier}x 加速',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, color: Colors.white38, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        a.onTap();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D3F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(a.icon, color: a.color, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.label,
                                style:
                                    const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white24, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class DebugAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DebugAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// 快捷构建 action 列表的辅助方法
List<DebugAction> debugActions(
  Map<String, VoidCallback> items, {
  IconData icon = Icons.play_arrow,
  Color color = Colors.white70,
}) {
  return items.entries
      .map((e) => DebugAction(
            label: e.key,
            icon: icon,
            color: color,
            onTap: e.value,
          ))
      .toList();
}
