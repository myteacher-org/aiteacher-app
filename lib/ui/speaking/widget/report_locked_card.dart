import 'dart:ui';

import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/speaking/widget/unlock_report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a report card so the title row stays clear while the body content
/// is blurred behind a "Pro tarifda mavjud" overlay that opens the
/// subscription sheet on tap. Demo accounts keep the blur but the overlay is
/// inert, so no purchase sheet can be reached.
class ReportLockedCard extends ConsumerWidget {
  const ReportLockedCard({
    super.key,
    required this.child,
    this.conversationId,
    this.titleHeight = 64,
    this.horizontalPadding = 16,
    this.bottomPadding = 18,
    this.cardRadius = 16,
  });

  final Widget child;

  /// Conversation whose report is being unlocked. Forwarded into
  /// [UnlockReportSheet] so the resulting payment links back to it.
  final String? conversationId;

  /// Top offset (from the widget's top edge) above which content is left
  /// untouched. Tune per-card if the title row is taller than 64px.
  final double titleHeight;

  /// Outer padding the wrapped card uses; the blur band is inset by these
  /// values so its rounded corners line up with the card's own background.
  final double horizontalPadding;
  final double bottomPadding;
  final double cardRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(isDemoAccountProvider);
    return Stack(
      children: [
        child,
        Positioned(
          left: horizontalPadding,
          right: horizontalPadding,
          top: titleHeight,
          bottom: bottomPadding,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(cardRadius),
              bottomRight: Radius.circular(cardRadius),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.white.withValues(alpha: 0.32),
                child: InkWell(
                  onTap: isDemo
                      ? null
                      : () => UnlockReportSheet.show(
                          context,
                          conversationId: conversationId,
                        ),
                  child: const Center(child: _ProLockPill()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProLockPill extends StatelessWidget {
  const _ProLockPill();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFFF5B700), size: 14),
          const SizedBox(width: 6),
          Text(
            l10n.speakingReportLockedCardOpenLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.primaryLight,
            size: 14,
          ),
        ],
      ),
    );
  }
}
