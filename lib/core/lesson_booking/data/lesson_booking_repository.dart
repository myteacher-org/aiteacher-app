import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lessonBookingRepositoryProvider = Provider<LessonBookingRepository>((
  ref,
) {
  return LessonBookingRepository(ref.watch(dioProvider));
});

/// O'quvchining lesson.myteacher.uz dagi darsi — sinov yoki doimiy.
class StudentLesson {
  const StudentLesson({
    required this.id,
    required this.startsAt,
    required this.durationMin,
    required this.isTrial,
    this.mentorName,
  });

  factory StudentLesson.fromJson(Map<String, dynamic> json) => StudentLesson(
    id: json['id'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
    durationMin: (json['durationMin'] as num?)?.toInt() ?? 60,
    isTrial: json['isTrial'] == true,
    mentorName: json['mentorName'] as String?,
  );

  final String id;
  final DateTime startsAt;
  final int durationMin;
  final bool isTrial;
  final String? mentorName;

  /// Backend bilan bir xil: boshlanishdan 10 daqiqa oldin ochiladi,
  /// tugagach 10 daqiqa ichida yopiladi.
  DateTime get opensAt => startsAt.subtract(const Duration(minutes: 10));
  DateTime get closesAt => startsAt.add(Duration(minutes: durationMin + 10));

  bool isJoinable(DateTime now) =>
      !now.isBefore(opensAt) && now.isBefore(closesAt);
}

class LessonBookingRepository {
  LessonBookingRepository(this._dio);

  final Dio _dio;

  /// Kelgusi darslar (eng yaqini birinchi). Sinov darslari telefon raqami
  /// bo'yicha o'quvchiga bog'lanadi — havola yuborish shart emas.
  Future<List<StudentLesson>> myLessons() async {
    final response = await _dio.get<List<dynamic>>('lesson-booking/my');
    final raw = response.data ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(StudentLesson.fromJson)
        .toList();
  }

  /// Darsga kirish havolasi — imzolangan token bilan, parol so'ramaydi.
  Future<String> entryUrl(String lessonId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'lesson-booking/$lessonId/entry',
    );
    return response.data!['url'] as String;
  }
}
