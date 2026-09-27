import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trialRequestRepositoryProvider = Provider<TrialRequestRepository>((ref) {
  return TrialRequestRepository(ref.watch(dioProvider));
});

/// Bepul 1-1 sinov darsiga yozilish — ism va telefon akkauntdan (backend oladi).
class TrialRequestRepository {
  TrialRequestRepository(this._dio);

  final Dio _dio;

  /// `already: true` — shu raqamdan 7 kun ichida ochiq so'rov bor (yangisi ochilmadi).
  Future<({bool already})> request() async {
    final response = await _dio.post<Map<String, dynamic>>('leads/me/trial');
    return (already: response.data?['already'] == true);
  }

  /// O'quvchi sinov darsi vaqtini o'zi tanladi — shu vaqtda bo'sh ustozlarga so'rov
  /// ketadi. Bo'sh ustoz bo'lmasa ham qabul qilinadi (admin yechim topadi).
  Future<void> book(String startsAtIso) async {
    await _dio.post<Map<String, dynamic>>(
      'trial-requests/self',
      data: {'startsAt': startsAtIso},
    );
  }
}
