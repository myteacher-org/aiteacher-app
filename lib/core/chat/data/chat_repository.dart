import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:ai_teacher/core/chat/data/chat_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioProvider));
});

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<List<ChatRoom>> listRooms() async {
    final response = await _dio.get<List<dynamic>>('chat/rooms');
    final items = response.data ?? const [];
    return items
        .whereType<Map>()
        .map((e) => ChatRoom.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<ChatMessage>> listMessages(
    String roomId, {
    int limit = 50,
    DateTime? before,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (before != null) query['before'] = before.toUtc().toIso8601String();
    final response = await _dio.get<List<dynamic>>(
      'chat/rooms/$roomId/messages',
      queryParameters: query,
    );
    final items = response.data ?? const [];
    return items
        .whereType<Map>()
        .map((e) => ChatMessage.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// REST send — the only path that can carry a file (sockets can't). Also
  /// usable for text-only as a fallback when the socket isn't connected.
  /// At least one of [text]/[filePath] must be given, per the API contract.
  Future<ChatMessage> sendMessage(
    String roomId, {
    String? text,
    String? filePath,
    String? fileName,
  }) async {
    MultipartFile? attachment;
    if (filePath != null) {
      // Infer Content-Type from the display filename rather than the
      // on-device path: some file providers (notably iOS document-picker
      // sources) hand back a temp path with no extension, which would
      // otherwise upload as application/octet-stream regardless of the
      // file's real type.
      final mimeType = lookupMimeType(fileName ?? filePath);
      attachment = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
    }
    final form = FormData.fromMap({
      if (text != null && text.isNotEmpty) 'text': text,
      'file': ?attachment,
    });
    final response = await _dio.post<Map<String, dynamic>>(
      'chat/rooms/$roomId/messages',
      data: form,
    );
    return ChatMessage.fromJson(response.data ?? const {});
  }
}
