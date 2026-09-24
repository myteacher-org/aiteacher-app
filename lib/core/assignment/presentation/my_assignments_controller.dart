import 'package:ai_teacher/core/assignment/data/assignment_dtos.dart';
import 'package:ai_teacher/core/assignment/data/active_lesson.dart';
import 'package:ai_teacher/core/assignment/data/assignment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myAssignmentsProvider = FutureProvider<List<Assignment>>((ref) {
  return ref.watch(assignmentRepositoryProvider).listMine();
});

final myMentorProvider = FutureProvider<MyMentor?>((ref) {
  return ref.watch(assignmentRepositoryProvider).getMyMentor();
});

final activeLessonProvider = FutureProvider<ActiveLesson?>((ref) {
  return ref.watch(assignmentRepositoryProvider).getActiveLesson();
});
