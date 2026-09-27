import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/purchases/presentation/purchases_controller.dart';
import 'package:ai_teacher/core/speaking/data/speaking_repository.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/shared/widget/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final _currentOfferingProvider = FutureProvider.autoDispose<Offering?>((ref) {
  return ref.read(purchasesControllerProvider.notifier).currentOffering();
});

const _termsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const _privacyUrl = 'https://www.myteacher.uz/docs/privacy_policy.html';

/// Purchase sheet for extra AI speaking conversations. Packages and their
/// localized store prices come from the RevenueCat "current" offering. After
/// a completed purchase the bought minutes are added through the API.
class ExtendLimitSheet extends ConsumerStatefulWidget {
  const ExtendLimitSheet({super.key});

  /// Returns true when the user completed a purchase. Returns false without
  /// showing anything while RevenueCat is not configured.
  static Future<bool> show(BuildContext context, WidgetRef ref) async {
    if (!ref.read(purchasesControllerProvider.notifier).isEnabled) {
      return false;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ExtendLimitSheet(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<ExtendLimitSheet> createState() => _ExtendLimitSheetState();
}

class _ExtendLimitSheetState extends ConsumerState<ExtendLimitSheet> {
  Package? _selected;
  bool _busy = false;

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Minutes a package grants: the offering's `minutes` metadata when set in
  /// the RevenueCat dashboard, otherwise the first number in the product or
  /// offering identifier (e.g. `10_min_speaking` → 10).
  static int? _minutesFor(Offering offering, Package package) {
    final fromMetadata = offering.metadata['minutes'];
    if (fromMetadata is num) return fromMetadata.toInt();
    if (fromMetadata is String) return int.tryParse(fromMetadata);
    for (final id in [package.storeProduct.identifier, offering.identifier]) {
      final match = RegExp(r'\d+').firstMatch(id);
      if (match != null) return int.parse(match.group(0)!);
    }
    return null;
  }

  /// Sends the bought minutes to the API, retrying a few times since the
  /// store has already charged the user at this point.
  Future<bool> _creditMinutes(int minutes) async {
    final repo = ref.read(speakingRepositoryProvider);
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await repo.addSpeakingMinutes(minutes);
        return true;
      } catch (e) {
        debugPrint('addSpeakingMinutes failed (attempt ${attempt + 1}): $e');
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
      }
    }
    return false;
  }

  Future<void> _onPurchase(Offering offering, Package package) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final minutes = _minutesFor(offering, package);
    if (minutes == null) {
      debugPrint('No minutes configured for package ${package.identifier}');
      _showMessage(l10n.purchaseFailedMessage);
      return;
    }
    setState(() => _busy = true);
    try {
      final purchased = await ref
          .read(purchasesControllerProvider.notifier)
          .purchase(package);
      if (!mounted) return;
      if (purchased) {
        final credited = await _creditMinutes(minutes);
        if (!mounted) return;
        if (!credited) _showMessage(l10n.purchaseCreditFailedMessage);
        Navigator.of(context).pop(credited);
        return;
      }
    } on PlatformException catch (_) {
      if (mounted) _showMessage(l10n.purchaseFailedMessage);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offering = ref.watch(_currentOfferingProvider);
    final packages = offering.valueOrNull?.availablePackages ?? const [];
    final currentOffering = offering.valueOrNull;
    final packageTitle = currentOffering?.serverDescription ?? '';
    final selected = _selected ?? (packages.isEmpty ? null : packages.first);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: const Color(0xFF94A3B8),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_comment_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.purchaseSheetTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.purchaseSheetSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            offering.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _LoadError(
                onRetry: () => ref.invalidate(_currentOfferingProvider),
              ),
              data: (value) => packages.isEmpty
                  ? _LoadError(
                      onRetry: () => ref.invalidate(_currentOfferingProvider),
                    )
                  : Column(
                      children: [
                        for (final package in packages) ...[
                          _PackageTile(
                            package: package,
                            title: packageTitle.isNotEmpty
                                ? packageTitle
                                : package.storeProduct.title,
                            selected: package == selected,
                            onTap: _busy
                                ? null
                                : () => setState(() => _selected = package),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: _busy
                  ? l10n.purchaseProcessingLabel
                  : l10n.purchaseBuyButton,
              enabled: !_busy && selected != null,
              onPressed: () {
                if (currentOffering != null && selected != null) {
                  _onPurchase(currentOffering, selected);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LinkText(label: l10n.purchaseTermsLabel, url: _termsUrl),
                const Text(
                  '  ·  ',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                _LinkText(label: l10n.purchasePrivacyLabel, url: _privacyUrl),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final Package package;
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF0FDFA) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : const Color(0xFFCBD5E1),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                package.storeProduct.priceString,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
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

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            l10n.purchaseLoadError,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
