import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:ai_teacher/core/leaderboard/data/leaderboard_entry.dart';
import 'package:ai_teacher/core/leaderboard/data/leaderboard_not_ranked_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(ref.watch(dioProvider));
});

class LeaderboardRepository {
  LeaderboardRepository(this._dio);

  final Dio _dio;

  /// Top 50 of the caller's CEFR cohort for the trailing 7 days, plus the
  /// caller's own row (appended last if outside the top 50). Scores are
  /// cached from a nightly recompute — never live.
  Future<List<LeaderboardEntry>> getCohort() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        'leaderboard',
        queryParameters: const {'scope': 'cohort', 'window': '7d'},
      );
      final items = response.data ?? const [];
      return items
          .whereType<Map>()
          .map((e) => LeaderboardEntry.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final body = e.response?.data;
        final message = body is Map ? body['message'] as String? : null;
        throw LeaderboardNotRankedException(
          message ?? 'Reyting hali hisoblanmagan.',
        );
      }
      rethrow;
    }
  }
}
