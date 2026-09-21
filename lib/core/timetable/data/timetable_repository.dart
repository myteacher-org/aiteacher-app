import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:ai_teacher/core/timetable/data/timetable_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.watch(dioProvider));
});

class TimetableRepository {
  TimetableRepository(this._dio);

  final Dio _dio;

  /// Mentors currently bookable (have at least one future open slot).
  /// The backend returns a bare JSON array here (unlike the other list
  /// endpoints, which wrap in `{"slots": [...]}`).
  Future<List<BookableMentor>> listMentors() async {
    final response = await _dio.get<List<dynamic>>('timetable/mentors');
    final raw = response.data ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(BookableMentor.fromJson)
        .toList();
  }

  Future<List<BookableSlot>> listMentorSlots(String mentorId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'mentors/$mentorId/slots',
    );
    final raw = (response.data?['slots'] as List?) ?? [];
    return raw.cast<Map<String, dynamic>>().map(BookableSlot.fromJson).toList();
  }

  Future<BookingResult> bookSlot(String slotId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'timetable/slots/$slotId/book',
    );
    return BookingResult.fromJson(response.data!);
  }

  Future<void> cancelBooking(String slotId) async {
    await _dio.post<void>('timetable/slots/$slotId/cancel');
  }

  /// Booked lessons where the caller is a party. `scope` is `upcoming` or
  /// `past` — "past" is derived server-side, never a stored status.
  Future<List<UpcomingLesson>> myLessons({required String scope}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'timetable/my-lessons',
      queryParameters: {'scope': scope},
    );
    final raw = (response.data?['slots'] as List?) ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(UpcomingLesson.fromJson)
        .toList();
  }
}
