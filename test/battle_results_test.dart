import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/battle/widget/battle_game_over_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 400.0, 430.0]) {
    for (final count in [1, 2, 3, 4, 6]) {
      for (final large in [false, true]) {
        testWidgets('$width px, $count players, large=$large', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 642);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var exits = 0;
          var replays = 0;
          final players = List.generate(
            count,
            (i) => ScoreboardEntry(
              rank: large && i < 2 ? 1 : i + 1,
              userId: '$i',
              firstName: 'Alexandra Muhammadyusuf $i',
              score: 10 - i,
              sumDelayMs: 0,
              answers: const [
                BattleRoundAnswer(
                  round: 1,
                  word: 'Discover',
                  correctOptionIndex: 0,
                  correct: true,
                  delayMs: 1400,
                ),
              ],
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(large ? 'uz' : 'en'),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 642),
                  textScaler: TextScaler.linear(large ? 1.8 : 1),
                ),
                child: Scaffold(
                  body: BattleGameOverView(
                    state: BattleState(
                      phase: BattlePhase.gameOver,
                      myUserId: '${count - 1}',
                      scoreboard: players,
                    ),
                    onPlayAgain: () => replays++,
                    onExit: () => exits++,
                  ),
                ),
              ),
            ),
          );
          for (final ms in [0, 80, 160, 240, 420]) {
            await tester.pump(Duration(milliseconds: ms));
            expect(tester.takeException(), isNull);
            final panel = tester.getRect(
              find.byKey(const ValueKey('podium-panel')),
            );
            for (final player in players.take(3)) {
              final rect = tester.getRect(find.text(player.firstName));
              expect(rect.left, greaterThanOrEqualTo(panel.left));
              expect(rect.right, lessThanOrEqualTo(panel.right));
              expect(rect.top, greaterThanOrEqualTo(panel.top));
              expect(rect.bottom, lessThanOrEqualTo(panel.bottom));
            }
          }
          for (final player in players) {
            expect(find.text(player.firstName), findsOneWidget);
          }
          await tester.ensureVisible(find.byType(ExpansionTile));
          await tester.tap(find.byType(ExpansionTile));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Discover'));
          expect(find.text('Discover').hitTestable(), findsOneWidget);
          await tester.tap(find.byType(OutlinedButton));
          await tester.tap(find.byType(FilledButton));
          expect(exits, 1);
          expect(replays, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
