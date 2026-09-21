import 'package:ai_teacher/core/timetable/data/timetable_dtos.dart';

/// A scheduled lesson's call is joinable from 10 minutes before it starts
/// until 15 minutes past its nominal end (covers a running-long lesson
/// without losing the reconnect affordance mid-call). Mirrors the mentor
/// app's identical helper — kept as a plain function, not shared code,
/// since the two apps are separate packages.
bool isWithinCallWindow(UpcomingLesson lesson) {
  final now = DateTime.now();
  final opensAt = lesson.startsAt.subtract(const Duration(minutes: 10));
  final closesAt = lesson.endsAt.add(const Duration(minutes: 15));
  return now.isAfter(opensAt) && now.isBefore(closesAt);
}
