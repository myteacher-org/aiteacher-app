import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:ai_teacher/core/call/data/call_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(ref.watch(dioProvider));
});

class CallRepository {
  CallRepository(this._dio);

  final Dio _dio;

  Future<Call> start(String assignmentId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'calls',
      data: {'assignmentId': assignmentId},
    );
    return Call.fromJson(response.data ?? const {});
  }

  Future<List<Call>> listMine() async {
    final response = await _dio.get<List<dynamic>>('calls');
    final items = response.data ?? const [];
    return items
        .whereType<Map>()
        .map((e) => Call.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> rate(String callId, int rating) async {
    await _dio.patch<void>('calls/$callId/rate', data: {'rating': rating});
  }

  Future<LiveKitToken> getLiveKitToken(String callId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'calls/$callId/livekit-token',
    );
    return LiveKitToken.fromJson(response.data ?? const {});
  }
}
