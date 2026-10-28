import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:ai_teacher/core/notification/data/notification_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<List<UserNotification>> list({int limit = 30, String? before}) async {
    final params = <String, dynamic>{
      'limit': limit,
      'appName': 'student',
    };
    if (before != null) params['before'] = before;
    final response = await _dio.get<List<dynamic>>(
      'notifications',
      queryParameters: params,
    );
    return (response.data ?? [])
        .whereType<Map>()
        .map((e) => UserNotification.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<int> unreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'notifications/unread-count',
      queryParameters: {'appName': 'student'},
    );
    return (response.data?['count'] as num?)?.toInt() ?? 0;
  }

  Future<UserNotification> markRead(String id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      'notifications/$id/read',
    );
    return UserNotification.fromJson(response.data!);
  }

  Future<void> markAllRead() async {
    await _dio.patch<void>(
      'notifications/read-all',
      queryParameters: {'appName': 'student'},
    );
  }
}
