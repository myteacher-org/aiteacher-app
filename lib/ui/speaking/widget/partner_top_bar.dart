import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PartnerTopBar extends StatelessWidget {
  const PartnerTopBar({
    super.key,
    required this.timerLabel,
    required this.onBack,
    this.topUpLabel,
    this.onTopUp,
  });

  final String timerLabel;
  final VoidCallback onBack;

  /// Label and callback for the "buy minutes" button. The button is hidden
  /// when [onTopUp] is null (e.g. purchases are not configured).
  final String? topUpLabel;
  final VoidCallback? onTopUp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF6B7A9F),
                      size: 26,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (onTopUp != null)
                _TopUpButton(label: topUpLabel ?? '', onTap: onTopUp!),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              timerLabel,
              style: const TextStyle(
                color: Color(0xFF0D1B4B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUpButton extends StatelessWidget {
  const _TopUpButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
