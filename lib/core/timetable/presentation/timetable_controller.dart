import 'package:ai_teacher/core/assignment/presentation/my_assignments_controller.dart';
import 'package:ai_teacher/core/timetable/data/timetable_dtos.dart';
import 'package:ai_teacher/core/timetable/data/timetable_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookableMentorsProvider = FutureProvider<List<BookableMentor>>((ref) {
  return ref.watch(timetableRepositoryProvider).listMentors();
});

final mentorSlotsProvider = FutureProvider.family<List<BookableSlot>, String>((
  ref,
  mentorId,
) {
  return ref.watch(timetableRepositoryProvider).listMentorSlots(mentorId);
});

final upcomingLessonsProvider = FutureProvider<List<UpcomingLesson>>((ref) {
  return ref.watch(timetableRepositoryProvider).myLessons(scope: 'upcoming');
});

class BookSlotNotifier extends AsyncNotifier<BookingResult?> {
  @override
  Future<BookingResult?> build() async => null;

  Future<BookingResult?> book(String slotId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(timetableRepositoryProvider).bookSlot(slotId),
    );
    state = result;
    if (result.hasValue) {
      ref.invalidate(myMentorProvider);
      ref.invalidate(myAssignmentsProvider);
      ref.invalidate(upcomingLessonsProvider);
    }
    return result.valueOrNull;
  }

  /// Resets after a failed attempt so the confirm screen can retry cleanly.
  void reset() => state = const AsyncData(null);
}

final bookSlotProvider = AsyncNotifierProvider<BookSlotNotifier, BookingResult?>(
  BookSlotNotifier.new,
);

/// The soonest upcoming booked lesson, if any — used by [MyMentorCard] to
/// show a "next lesson" row without a separate network call.
final nextUpcomingLessonProvider = Provider<UpcomingLesson?>((ref) {
  final lessons = ref.watch(upcomingLessonsProvider).valueOrNull;
  if (lessons == null || lessons.isEmpty) return null;
  final sorted = [...lessons]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return sorted.first;
});
