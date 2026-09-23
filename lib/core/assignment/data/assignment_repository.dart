import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:ai_teacher/core/assignment/data/assignment_dtos.dart';
import 'package:ai_teacher/core/assignment/data/active_lesson.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.watch(dioProvider));
});

class AssignmentRepository {
  AssignmentRepository(this._dio);

  final Dio _dio;

  Future<List<Assignment>> listMine() async {
    final response = await _dio.get<List<dynamic>>('assignments');
    final items = response.data ?? const [];
    return items
        .whereType<Map>()
        .map((e) => Assignment.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<MyMentor?> getMyMentor() async {
    final response = await _dio.get<Map<String, dynamic>?>(
      'assignments/my-mentor',
    );
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return MyMentor.fromJson(data);
  }

  Future<ActiveLesson?> getActiveLesson() async {
    final response = await _dio.get<Map<String, dynamic>?>(
      'lesson-booking/live/active',
    );
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return ActiveLesson.fromJson(data);
  }
}
