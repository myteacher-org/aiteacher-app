import 'package:ai_teacher/core/leaderboard/data/leaderboard_entry.dart';
import 'package:ai_teacher/core/leaderboard/data/leaderboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardRepositoryProvider).getCohort();
});
