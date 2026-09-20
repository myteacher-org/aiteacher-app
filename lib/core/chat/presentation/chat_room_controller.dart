import 'dart:async';

import 'package:ai_teacher/core/auth/data/auth_session.dart';
import 'package:ai_teacher/core/chat/data/chat_dtos.dart';
import 'package:ai_teacher/core/chat/data/chat_repository.dart';
import 'package:ai_teacher/core/chat/data/chat_socket.dart';
import 'package:ai_teacher/core/chat/presentation/chat_unread_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatRoomState {
  const ChatRoomState({
    required this.loading,
    required this.sending,
    required this.messages,
    this.room,
    this.error,
    this.pendingAttachmentName,
  });

  final bool loading;
  final bool sending;
  final List<ChatMessage> messages;
  final ChatRoom? room;
  final String? error;

  /// Set while [ChatRoomController.sendAttachment] is uploading — lets the
  /// screen show a "Fayl yuborilmoqda…" indicator instead of leaving the
  /// user staring at nothing until the message suddenly appears.
  final String? pendingAttachmentName;

  static const ChatRoomState initial = ChatRoomState(
    loading: true,
    sending: false,
    messages: [],
  );

  ChatRoomState copyWith({
    bool? loading,
    bool? sending,
    List<ChatMessage>? messages,
    ChatRoom? room,
    Object? error = _sentinel,
    Object? pendingAttachmentName = _sentinel,
  }) {
    return ChatRoomState(
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      messages: messages ?? this.messages,
      room: room ?? this.room,
      error: identical(error, _sentinel) ? this.error : error as String?,
      pendingAttachmentName: identical(pendingAttachmentName, _sentinel)
          ? this.pendingAttachmentName
          : pendingAttachmentName as String?,
    );
  }
}

const Object _sentinel = Object();

final chatRoomControllerProvider =
    NotifierProvider.autoDispose<ChatRoomController, ChatRoomState>(
      ChatRoomController.new,
    );

class ChatRoomController extends AutoDisposeNotifier<ChatRoomState> {
  StreamSubscription<ChatMessage>? _sub;

  @override
  ChatRoomState build() {
    ref.onDispose(() {
      _sub?.cancel();
      ref.read(chatScreenActiveProvider.notifier).state = false;
    });
    Future.microtask(() {
      ref.read(chatUnreadProvider.notifier).state = false;
      ref.read(chatScreenActiveProvider.notifier).state = true;
      _initialize();
    });
    return ChatRoomState.initial;
  }

  Future<void> _initialize() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final rooms = await repo.listRooms();
      if (rooms.isEmpty) {
        state = state.copyWith(
          loading: false,
          error: "Suhbat xonasi topilmadi",
        );
        return;
      }
      final room = rooms.first;
      final history = await repo.listMessages(room.id);
      state = state.copyWith(
        loading: false,
        room: room,
        messages: history,
        error: null,
      );

      final socket = ref.read(chatSocketProvider);
      await socket.connect();
      _sub = socket.incoming.listen((msg) {
        if (msg.chatRoomId != room.id) return;
        if (state.messages.any((m) => m.id == msg.id)) return;
        state = state.copyWith(messages: [msg, ...state.messages]);
      });
    } catch (e, st) {
      debugPrint('chat room init failed: $e\n$st');
      state = state.copyWith(loading: false, error: "Suhbatni yuklab bo'lmadi");
    }
  }

  /// Text goes over the socket (the fast path the backend recommends),
  /// falling back to REST if the socket isn't connected.
  Future<bool> send(String text) async {
    final body = text.trim();
    final room = state.room;
    if (body.isEmpty || room == null) return false;
    state = state.copyWith(sending: true, error: null);
    try {
      final socket = ref.read(chatSocketProvider);
      final saved = socket.connected
          ? await socket.sendMessage(text: body, roomId: room.id)
          : await ref
                .read(chatRepositoryProvider)
                .sendMessage(room.id, text: body);
      if (!state.messages.any((m) => m.id == saved.id)) {
        state = state.copyWith(messages: [saved, ...state.messages]);
      }
      state = state.copyWith(sending: false);
      return true;
    } catch (e) {
      state = state.copyWith(sending: false, error: 'Yuborilmadi');
      return false;
    }
  }

  /// Files can't go over the socket — REST only, per the backend contract.
  Future<bool> sendAttachment(String filePath, String fileName) async {
    final room = state.room;
    if (room == null) return false;
    state = state.copyWith(
      sending: true,
      error: null,
      pendingAttachmentName: fileName,
    );
    try {
      final saved = await ref
          .read(chatRepositoryProvider)
          .sendMessage(room.id, filePath: filePath, fileName: fileName);
      if (!state.messages.any((m) => m.id == saved.id)) {
        state = state.copyWith(messages: [saved, ...state.messages]);
      }
      state = state.copyWith(sending: false, pendingAttachmentName: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        sending: false,
        error: 'Yuborilmadi',
        pendingAttachmentName: null,
      );
      return false;
    }
  }

  Future<void> retry() => _initialize();
}

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authSessionProvider).currentUserId;
});
