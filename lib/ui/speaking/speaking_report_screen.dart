import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/core/speaking/data/assessment.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/speaking/report_grammar_page.dart';
import 'package:ai_teacher/ui/speaking/report_overview_page.dart';
import 'package:ai_teacher/ui/speaking/report_roadmap_page.dart';
import 'package:ai_teacher/ui/speaking/report_vocab_page.dart';
import 'package:ai_teacher/ui/speaking/widget/report_hero_card.dart';
import 'package:ai_teacher/ui/speaking/widget/report_top_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SpeakingReportScreen extends StatelessWidget {
  const SpeakingReportScreen({super.key, required this.assessment});

  final Assessment assessment;

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
                ReportHeroCard(assessment: assessment),
                _SegmentedTabBar(labels: tabLabels),
                Expanded(
                  child: TabBarView(
                    children: [
                      ReportOverviewPage(assessment: assessment),
                      ReportVocabPage(assessment: assessment),
                      ReportGrammarPage(assessment: assessment),
                      ReportRoadmapPage(assessment: assessment),
                    ],
                  ),
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
