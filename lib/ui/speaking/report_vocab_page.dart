import 'package:ai_teacher/core/speaking/data/assessment.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/speaking/widget/report_coach_card.dart';
import 'package:ai_teacher/ui/speaking/widget/report_priority_words.dart';
import 'package:ai_teacher/ui/speaking/widget/report_vocab_chart.dart';
import 'package:ai_teacher/ui/speaking/widget/report_vocab_hero.dart';
import 'package:flutter/material.dart';

class ReportVocabPage extends StatelessWidget {
  const ReportVocabPage({super.key, required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tips = assessment.coachTips.take(2).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        ReportVocabHero(detail: assessment.vocabularyDetail),
        ReportPriorityWords(words: assessment.vocabularyDetail.priorityWords),
        ReportVocabChart(detail: assessment.vocabularyDetail),
        ReportCoachCard(
          tips: tips,
          subtitle: l10n.speakingScreenVocabCoachSubtitle,
        ),
      ],
    );
  }
}
