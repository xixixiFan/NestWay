import 'package:flutter/material.dart';

class RiskCard extends StatelessWidget {
  final Color color;
  final String title;
  final String desc;
  final VoidCallback? onTap;
  final IconData? icon;

  const RiskCard({
    super.key,
    required this.color,
    required this.title,
    required this.desc,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(110),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: color,
            width: 4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        size: 36,
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.circle,
                        size: 36,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
