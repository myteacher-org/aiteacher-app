import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/core/speaking/data/assessment.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/speaking/widget/report_coach_card.dart';
import 'package:ai_teacher/ui/speaking/widget/report_monthly_plan_card.dart';
import 'package:ai_teacher/ui/speaking/widget/report_next_session_cta.dart';
import 'package:ai_teacher/ui/speaking/widget/report_roadmap_levels_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportRoadmapPage extends StatelessWidget {
  const ReportRoadmapPage({super.key, required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tips = assessment.coachTips;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        ReportRoadmapLevelsCard(
          currentLevel: assessment.cefrLevel,
          targetLevel: assessment.roadmap.targetLevel,
          activeVocabSize: assessment.vocabularyDetail.activeSizeEstimate,
          estimatedDuration: assessment.roadmap.estimatedDuration,
        ),
        ReportMonthlyPlanCard(
          focusAreas: assessment.roadmap.focusAreas,
          targetLevel: assessment.roadmap.targetLevel,
          currentLevel: assessment.cefrLevel,
        ),
        ReportCoachCard(
          tips: tips,
          subtitle: l10n.speakingScreenRoadmapCoachSubtitle(tips.length),
        ),
        ReportNextSessionCta(
          onStart: () => context.goNamed(AppRoute.speaking.name),
        ),
      ],
    );
  }
}
