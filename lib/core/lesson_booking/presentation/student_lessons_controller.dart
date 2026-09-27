import 'package:ai_teacher/core/lesson_booking/data/lesson_booking_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O'quvchining kelgusi jonli darslari (sinov va doimiy).
final studentLessonsProvider = FutureProvider<List<StudentLesson>>((ref) {
  return ref.watch(lessonBookingRepositoryProvider).myLessons();
});

/// Eng yaqin dars — Home'dagi karta uchun.
final nextStudentLessonProvider = Provider<StudentLesson?>((ref) {
  final list = ref.watch(studentLessonsProvider).valueOrNull;
  if (list == null || list.isEmpty) return null;
  final sorted = [...list]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return sorted.first;
});
