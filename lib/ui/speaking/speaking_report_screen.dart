import 'dart:async';

import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/speaking/data/assessment.dart';
import 'package:ai_teacher/core/speaking/data/speaking_repository.dart';
import 'package:ai_teacher/core/speaking/presentation/pending_report_payment.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/profile/subscription_details_sheet.dart';
import 'package:ai_teacher/ui/speaking/report_grammar_page.dart';
import 'package:ai_teacher/ui/speaking/report_overview_page.dart';
import 'package:ai_teacher/ui/speaking/report_roadmap_page.dart';
import 'package:ai_teacher/ui/speaking/report_vocab_page.dart';
import 'package:ai_teacher/ui/speaking/widget/report_hero_card.dart';
import 'package:ai_teacher/ui/speaking/widget/report_top_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpeakingReportScreen extends ConsumerStatefulWidget {
  const SpeakingReportScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  ConsumerState<SpeakingReportScreen> createState() =>
      _SpeakingReportScreenState();
}

class _SpeakingReportScreenState extends ConsumerState<SpeakingReportScreen> {
  late Assessment _assessment = widget.assessment;
  Timer? _pollTimer;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    // If we returned to this screen with a pending payment armed (e.g.
    // user came back via deep link after Click/Payme), check immediately
    // and then start polling until the payment lands.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingReportPaymentProvider);
      if (pending != null &&
          pending.conversationId == _assessment.conversationId) {
        _checkOnce();
        _startPolling();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkOnce(),
    );
  }

  Future<void> _checkOnce() async {
    if (_polling) return;
    final conversationId = _assessment.conversationId;
    if (conversationId == null || conversationId.isEmpty) return;
    _polling = true;
    try {
      final status = await ref
          .read(speakingRepositoryProvider)
          .getConversationPaymentStatus(conversationId);
      if (!mounted) return;
      if (status.isPaid) {
        await _onPaymentSuccess(conversationId);
      }
    } catch (e) {
      debugPrint('payment status poll failed: $e');
    } finally {
      _polling = false;
    }
  }

  Future<void> _onPaymentSuccess(String conversationId) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    // Try to pull the freshly-unlocked report; fall back to flipping the
    // gate flag locally if the server hasn't materialized one yet.
    Assessment? refreshed;
    try {
      refreshed = await ref
          .read(speakingRepositoryProvider)
          .getConversationReport(conversationId);
    } catch (e) {
      debugPrint('refresh report failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _assessment =
          refreshed ?? _assessment.copyWith(isFullReportAvailable: true);
    });
    ref.read(pendingReportPaymentProvider.notifier).clear();
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.speakingScreenPaymentSuccess)),
      );
  }

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.main.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabLabels = [
      l10n.speakingScreenTabOverview,
      l10n.speakingScreenTabVocabulary,
      l10n.speakingScreenTabGrammar,
      l10n.speakingScreenTabRoadmap,
    ];
    final user = ref.watch(currentUserProvider).valueOrNull;
    final showUpsell =
        user?.activeSubscription == null && !ref.watch(isDemoAccountProvider);
    final pending = ref.watch(pendingReportPaymentProvider);
    final isWaiting =
        pending != null &&
        pending.conversationId == _assessment.conversationId &&
        !_assessment.isFullReportAvailable;

    // Drive the polling lifecycle off the provider so an arming from
    // another screen (or a deep-link return) starts the timer here.
    ref.listen<PendingReportPayment?>(pendingReportPaymentProvider, (
      prev,
      next,
    ) {
      final convo = _assessment.conversationId;
      if (convo == null) return;
      if (next != null && next.conversationId == convo) {
        _checkOnce();
        _startPolling();
      } else if (next == null) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFECEAE3),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFECEAE3),
        body: SafeArea(
          bottom: false,
          child: DefaultTabController(
            length: tabLabels.length,
            child: Column(
              children: [
                ReportTopNav(onBack: () => _onBack(context), onShare: () {}),
                ReportHeroCard(assessment: _assessment),
                if (isWaiting) const _PaymentWaitBanner(),
                _SegmentedTabBar(labels: tabLabels),
                Expanded(
                  child: TabBarView(
                    children: [
                      ReportOverviewPage(assessment: _assessment),
                      ReportVocabPage(assessment: _assessment),
                      ReportGrammarPage(assessment: _assessment),
                      ReportRoadmapPage(assessment: _assessment),
                    ],
                  ),
                ),
                if (showUpsell && !_assessment.isFullReportAvailable)
                  const _UnlimitedReportsCta(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentWaitBanner extends StatelessWidget {
  const _PaymentWaitBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(Color(0xFFB45309)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.speakingScreenPaymentChecking,
                    style: const TextStyle(
                      color: Color(0xFF7C2D12),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.speakingScreenPaymentAutoUnlock,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlimitedReportsCta extends StatelessWidget {
  const _UnlimitedReportsCta();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => SubscriptionDetailsSheet.show(context),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.speakingScreenUnlimitedReportsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.speakingScreenUnlimitedReportsSubtitle,
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
    );
  }
}

class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          isScrollable: false,
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: const Color(0xFF1A1A1A),
          unselectedLabelColor: const Color(0xFF6B6860),
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          tabs: [for (final label in labels) Tab(text: label, height: 36)],
        ),
      ),
    );
  }
}
