import 'package:flutter/material.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.statusColor(label);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.18 : 0.14)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFEAF0F6)),
          border: Border.all(
            color: selected
                ? color
                : (isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          AppColors.statusLabel(label),
          style: TextStyle(
            color: selected ? color : (isDark ? Colors.white : const Color(0xFF475569)),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

const List<String> kStatuts = ['nouveau', 'accepte', 'refuse', 'a_recontacter'];