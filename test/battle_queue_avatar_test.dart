import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/battle/widget/battle_queue_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('waiting lobby renders current and opponent profile images', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BattleQueueView(
            lobbyPlayers: const [
              LobbyPlayer(userId: 'me', firstName: 'Me'),
              LobbyPlayer(
                userId: 'friend',
                firstName: 'Friend',
                avatar: 'avatar/friend.jpg',
              ),
            ],
            myUserId: 'me',
            myAvatarPath: 'avatar/me.jpg',
            onCancel: _noop,
            onReact: _ignoreReaction,
            reactions: const Stream<PlayerReaction>.empty(),
          ),
        ),
      ),
    );
    await tester.pump();

    final urls = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as NetworkImage).url)
        .toList();
    expect(urls, contains('https://ai.myteacher.uz/public/avatar/me.jpg'));
    expect(urls, contains('https://ai.myteacher.uz/public/avatar/friend.jpg'));
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

void _ignoreReaction(String _) {}
