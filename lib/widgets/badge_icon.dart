import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int badge;
  final Color? iconColor;
  final Color badgeColor;
  final double size;
  final EdgeInsets badgePadding;
  final TextStyle? textStyle;

  const BadgeIcon({
    super.key,
    required this.icon,
    required this.badge,
    this.iconColor,
    this.badgeColor = Colors.red,
    this.size = 24,
    this.badgePadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: iconColor, size: size),
        if (badge > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: badgePadding,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.toString(),
                style: textStyle ?? const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
