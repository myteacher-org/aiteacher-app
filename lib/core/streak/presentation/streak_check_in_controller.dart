import 'package:ai_teacher/app/data/cache_service.dart';
import 'package:ai_teacher/core/streak/data/streak_dtos.dart';
import 'package:ai_teacher/core/streak/data/streak_repository.dart';
import 'package:ai_teacher/core/streak/presentation/streak_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped flag that prevents the daily check-in from firing more
/// than once per app launch (or login). Invalidate the provider on logout
/// so the next sign-in re-triggers it.
final streakCheckInProvider = NotifierProvider<StreakCheckInController, bool>(
  StreakCheckInController.new,
);

class StreakCheckInController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Returns the freshly checked-in [WeeklyStreak] on success, or `null` if
  /// today's check-in already happened (this session, or on an earlier
  /// launch the same day) or the call failed.
  ///
  /// The session flag alone only stops duplicate calls within one app run —
  /// it does nothing on the next cold start, so the bonus would otherwise
  /// be re-awarded every time the app is reopened on a day already checked
  /// in, since the endpoint isn't guaranteed to dedupe that itself. Track
  /// the last successful date locally so a later launch the same day is a
  /// no-op regardless of backend behavior.
  Future<WeeklyStreak?> runIfNeeded() async {
    if (state) return null;
    final cache = ref.read(cacheServiceProvider);
    final today = _todayKey();
    if (cache.lastStreakCheckInDate == today) {
      state = true;
      return null;
    }
    state = true;
    try {
      final updated = await ref.read(streakRepositoryProvider).checkIn();
      await cache.setLastStreakCheckInDate(today);
      ref.invalidate(weeklyStreakProvider);
      return updated;
    } catch (e) {
      debugPrint('streak check-in failed: $e');
      state = false;
      return null;
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
