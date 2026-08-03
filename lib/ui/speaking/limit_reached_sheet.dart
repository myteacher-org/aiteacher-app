import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/speaking/data/speaking_repository.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/profile/payment_types_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LimitSheetAction { addonPurchased, wantsSubscribe }

class LimitReachedSheet extends ConsumerStatefulWidget {
  const LimitReachedSheet({
    super.key,
    this.addonPrice = 5000,
    this.addonGrant = 3,
  });

  final int addonPrice;
  final int addonGrant;

  static Future<LimitSheetAction?> show(
    BuildContext context, {
    int addonPrice = 5000,
    int addonGrant = 3,
  }) {
    return showModalBottomSheet<LimitSheetAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isDismissible: true,
      builder: (_) =>
          LimitReachedSheet(addonPrice: addonPrice, addonGrant: addonGrant),
    );
  }

  @override
  ConsumerState<LimitReachedSheet> createState() => _LimitReachedSheetState();
}

class _LimitReachedSheetState extends ConsumerState<LimitReachedSheet> {
  bool _purchasing = false;

  Future<void> _onAddonTap() async {
    if (_purchasing) return;
    final l10n = AppLocalizations.of(context);
    final paymentId = await PaymentTypesSheet.show(
      context,
      amount: widget.addonPrice,
      title: l10n.speakingScreenAddonPurchaseTitle(widget.addonGrant),
    );
    if (!mounted || paymentId == null) return;
    setState(() => _purchasing = true);
    try {
      await ref
          .read(speakingRepositoryProvider)
          .purchaseConversationAddon(paymentId);
      if (!mounted) return;
      Navigator.of(context).pop(LimitSheetAction.addonPurchased);
    } catch (_) {
      if (!mounted) return;
      setState(() => _purchasing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.speakingScreenPaymentFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Demo accounts see why they were stopped, but get no way to pay out of it.
    final isDemo = ref.watch(isDemoAccountProvider);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2DED7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Hero(),
                      const SizedBox(height: 24),
                      Text(
                        l10n.speakingScreenLimitTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.speakingScreenLimitSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        l10n.speakingScreenPlanFeaturesLabel,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _BenefitTile(
                        emoji: '♾️',
                        title: l10n.speakingScreenBenefitUnlimitedTitle,
                        subtitle: l10n.speakingScreenBenefitUnlimitedSubtitle,
                      ),
                      const SizedBox(height: 10),
                      _BenefitTile(
                        emoji: '📊',
                        title: l10n.speakingScreenBenefitReportsTitle,
                        subtitle: l10n.speakingScreenBenefitReportsSubtitle,
                      ),
                      const SizedBox(height: 10),
                      _BenefitTile(
                        emoji: '👨‍🏫',
                        title: l10n.speakingScreenBenefitMentorTitle,
                        subtitle: l10n.speakingScreenBenefitMentorSubtitle,
                      ),
                      const SizedBox(height: 10),
                      _BenefitTile(
                        emoji: '🚀',
                        title: l10n.speakingScreenBenefitResultTitle,
                        subtitle: l10n.speakingScreenBenefitResultSubtitle,
                      ),
                      const SizedBox(height: 22),
                      _SocialProof(),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Column(
                    children: [
                      if (!isDemo) ...[
                        _AddonButton(
                          addonPrice: widget.addonPrice,
                          addonGrant: widget.addonGrant,
                          loading: _purchasing,
                          onTap: _onAddonTap,
                        ),
                        const SizedBox(height: 10),
                        _SubscribeButton(
                          onTap: () => Navigator.of(
                            context,
                          ).pop(LimitSheetAction.wantsSubscribe),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _DismissAction(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5B700).withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Text('🚀', style: TextStyle(fontSize: 44)),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProof extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFEF3C7), width: 1),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.speakingScreenSocialProof,
              style: const TextStyle(
                color: Color(0xFF8A6D3B),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddonButton extends StatelessWidget {
  const _AddonButton({
    required this.addonPrice,
    required this.addonGrant,
    required this.loading,
    required this.onTap,
  });

  final int addonPrice;
  final int addonGrant;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n.speakingScreenAddonButtonLabel(
                      _formatPrice(addonPrice),
                      addonGrant,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      final thousands = price ~/ 1000;
      final remainder = price % 1000;
      if (remainder == 0) return '$thousands 000';
      return '$price';
    }
    return '$price';
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.speakingScreenSubscribeButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissAction extends StatelessWidget {
  const _DismissAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6B7280),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        l10n.speakingScreenDismissLater,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
