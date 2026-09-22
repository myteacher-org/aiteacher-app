import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scoreboard parses another player avatar from game_over', () {
    final entry = ScoreboardEntry.fromJson(const {
      'rank': 2,
      'userId': 'friend',
      'firstName': 'Friend',
      'avatar': 'avatar/friend.jpg',
      'score': 8,
      'sumDelayMs': 1200,
      'answers': <Object>[],
    });

    expect(entry.avatar, 'avatar/friend.jpg');
  });

  test('scoreboard accepts avatarUrl and nested user payloads', () {
    final direct = ScoreboardEntry.fromJson(const {
      'avatarUrl': 'avatar/direct.jpg',
    });
    final nested = ScoreboardEntry.fromJson(const {
      'user': {'avatar': 'avatar/nested.jpg'},
    });

    expect(direct.avatar, 'avatar/direct.jpg');
    expect(nested.avatar, 'avatar/nested.jpg');
  });

  test('lobby player keeps avatar while its score changes', () {
    final player = LobbyPlayer.fromJson(const {
      'userId': 'friend',
      'firstName': 'Friend',
      'avatar': 'avatar/friend.jpg',
    });

    expect(player.withScore(5).avatar, 'avatar/friend.jpg');
  });
}
