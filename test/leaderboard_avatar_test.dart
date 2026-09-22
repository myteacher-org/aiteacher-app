import 'package:ai_teacher/core/leaderboard/data/leaderboard_entry.dart';
import 'package:ai_teacher/ui/leaderboard/widget/leaderboard_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leaderboard accepts the profile avatar field from the API', () {
    final entry = LeaderboardEntry.fromJson(const {
      'userId': 'me',
      'fullName': 'Test User',
      'avatar': 'avatar/me.jpg',
      'score': 42,
      'rank': 1,
      'streakDays': 3,
      'isMe': true,
    });

    expect(entry.avatarUrl, 'avatar/me.jpg');
  });

  testWidgets('relative leaderboard avatar paths use the production CDN', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LeaderboardAvatar(
            userId: 'me',
            fullName: 'Test User',
            avatarUrl: 'avatar/me.jpg',
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as NetworkImage;
    expect(provider.url, 'https://ai.myteacher.uz/public/avatar/me.jpg');
  });
}
