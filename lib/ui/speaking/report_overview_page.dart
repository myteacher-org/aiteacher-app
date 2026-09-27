import 'package:ai_teacher/core/speaking/data/assessment.dart';
import 'package:ai_teacher/ui/speaking/widget/report_feedback_card.dart';
import 'package:ai_teacher/ui/speaking/widget/report_fluency_card.dart';
import 'package:ai_teacher/ui/speaking/widget/report_radar_card.dart';
import 'package:ai_teacher/ui/speaking/widget/report_response_chart.dart';
import 'package:ai_teacher/ui/speaking/widget/report_score_grid.dart';
import 'package:flutter/material.dart';

class ReportOverviewPage extends StatelessWidget {
  const ReportOverviewPage({super.key, required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        ReportFeedbackCard(feedback: assessment.feedback),
        ReportRadarCard(skills: assessment.skills),
        ReportScoreGrid(skills: assessment.skills),
        ReportFluencyCard(
          fluency: assessment.fluencyDetail,
          overall: assessment.skills.fluency,
        ),
        const ReportResponseChart(),
      ],
    );
  }
}
