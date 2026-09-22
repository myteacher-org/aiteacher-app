// Standalone local preview: flutter run -t lib/battle_results_preview.dart
// No backend, authentication, or production route is initialized.
import 'package:flutter/material.dart';
import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/app/theme/app_theme.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/battle/widget/battle_game_over_view.dart';

void main() => runApp(const BattleResultsPreview());

class BattleResultsPreview extends StatefulWidget {
  const BattleResultsPreview({super.key});
  @override
  State<BattleResultsPreview> createState() => _PreviewState();
}

class _PreviewState extends State<BattleResultsPreview> {
  int count = 3, position = 1, replay = 0;
  bool ties = false, large = false, reduced = false, longNames = false;
  double width = 400;
  String language = 'en';
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: AppTheme.light,
    home: Builder(
      builder: (context) {
        final l = AppLocalizations.of(context);
        final entries = List.generate(
          count,
          (i) => ScoreboardEntry(
            rank: ties && i < 2 ? 1 : i + 1,
            userId: 'sample-$i',
            firstName: longNames
                ? 'Alexandra Muhammadyusuf ${i + 1}'
                : [
                    'Isfandiyor',
                    'Faxriyor',
                    'Malika',
                    'Aziza',
                    'Jasur',
                    'Sardor',
                  ][i],
            score: ties && i < 2 ? 10 : 10 - i,
            sumDelayMs: 1000 * i,
            answers: List.generate(
              3,
              (j) => BattleRoundAnswer(
                round: j + 1,
                word: ['Discover', 'Journey', 'Wonderful'][j],
                correctOptionIndex: 0,
                correct: j != 1,
                delayMs: 1400 + j * 500,
              ),
            ),
          ),
        );
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          l.battlePreviewTitle,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(l.battlePreviewPlayers),
                            DropdownButton<int>(
                              value: count,
                              items: List.generate(
                                6,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('${i + 1}'),
                                ),
                              ),
                              onChanged: (v) => setState(() {
                                count = v!;
                                position = position.clamp(1, count);
                                replay++;
                              }),
                            ),
                            Text(l.battlePreviewPlace),
                            DropdownButton<int>(
                              value: position,
                              items: List.generate(
                                count,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('${i + 1}'),
                                ),
                              ),
                              onChanged: (v) => setState(() {
                                position = v!;
                                replay++;
                              }),
                            ),
                            DropdownButton<double>(
                              value: width,
                              items: [320.0, 400.0, 430.0]
                                  .map(
                                    (w) => DropdownMenuItem(
                                      value: w,
                                      child: Text('${w.toInt()} px'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => width = v!),
                            ),
                            DropdownButton<String>(
                              value: language,
                              items: ['en', 'uz']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => language = v!),
                            ),
                            FilterChip(
                              label: Text(l.battlePreviewTies),
                              selected: ties,
                              onSelected: (v) => setState(() {
                                ties = v;
                                replay++;
                              }),
                            ),
                            FilterChip(
                              label: Text(l.battlePreviewLong),
                              selected: longNames,
                              onSelected: (v) => setState(() => longNames = v),
                            ),
                            FilterChip(
                              label: Text(l.battlePreviewLarge),
                              selected: large,
                              onSelected: (v) => setState(() => large = v),
                            ),
                            FilterChip(
                              label: Text(l.battlePreviewMotion),
                              selected: reduced,
                              onSelected: (v) => setState(() {
                                reduced = v;
                                replay++;
                              }),
                            ),
                            TextButton(
                              onPressed: () => setState(() => replay++),
                              child: Text(l.battlePreviewReplay),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: width,
                    height: 642,
                    margin: const EdgeInsets.only(bottom: 20),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(large ? 1.8 : 1),
                        disableAnimations: reduced,
                        padding: EdgeInsets.zero,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back_rounded, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l.battleTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: BattleGameOverView(
                              key: ValueKey(replay),
                              state: BattleState(
                                phase: BattlePhase.gameOver,
                                myUserId: 'sample-${position - 1}',
                                scoreboard: entries,
                              ),
                              onPlayAgain: () => setState(() => replay++),
                              onExit: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l.battlePreviewTitle),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
