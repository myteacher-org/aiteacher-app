import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrialBooking {
  const TrialBooking({
    required this.id,
    required this.startsAt,
    required this.durationMin,
    required this.mentorName,
  });

  final String id;
  final DateTime startsAt;
  final int durationMin;
  final String mentorName;

  DateTime get opensAt => startsAt.subtract(const Duration(minutes: 10));
  DateTime get closesAt => startsAt.add(Duration(minutes: durationMin + 10));

  factory TrialBooking.fromJson(Map<String, dynamic> json) => TrialBooking(
    id: json['id'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String),
    durationMin: (json['durationMin'] as num).toInt(),
    mentorName: json['mentorName'] as String? ?? '',
  );
}

final trialBookingRepositoryProvider = Provider<TrialBookingRepository>((ref) {
  return TrialBookingRepository(ref.watch(dioProvider));
});

final trialBookingProvider = FutureProvider.autoDispose<TrialBooking?>((ref) {
  return ref.watch(trialBookingRepositoryProvider).getUpcomingTrial();
});

class TrialBookingRepository {
  const TrialBookingRepository(this._dio);

  final Dio _dio;

  Future<TrialBooking?> getUpcomingTrial() async {
    final response = await _dio.get<List<dynamic>>('lesson-booking/my');
    final now = DateTime.now();
    final trials =
        (response.data ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .where((item) => item['isTrial'] == true)
            .map(TrialBooking.fromJson)
            .where((booking) => booking.closesAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return trials.isEmpty ? null : trials.first;
  }

  Future<String> getEntryUrl(String bookingId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'lesson-booking/$bookingId/entry',
    );
    final url = response.data?['url'] as String?;
    if (url == null || url.isEmpty) throw StateError('Dars havolasi topilmadi');
    return url;
  }
}
