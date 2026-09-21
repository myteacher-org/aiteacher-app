import 'dart:async';

import 'package:ai_teacher/core/call/data/call_dtos.dart';
import 'package:ai_teacher/core/call/data/call_repository.dart';
import 'package:ai_teacher/core/call/data/call_socket.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

enum CallPhase {
  idle,
  incoming,
  outgoing,
  connecting,
  active,
  reconnecting,
  ended,
}

class CallState {
  const CallState({
    this.phase = CallPhase.idle,
    this.callId,
    this.assignmentId,
    this.callerId,
    this.calleeId,
    this.muted = false,
    this.speakerphone = false,
    this.elapsed = Duration.zero,
    this.endedReason,
    this.error,
  });

  final CallPhase phase;
  final String? callId;
  final String? assignmentId;
  final String? callerId;
  final String? calleeId;
  final bool muted;
  final bool speakerphone;
  final Duration elapsed;
  final String? endedReason;
  final String? error;

  bool get isIncomingForMe => phase == CallPhase.incoming;

  bool get isOutgoingForMe => phase == CallPhase.outgoing;

  bool get isLive =>
      phase == CallPhase.connecting ||
      phase == CallPhase.active ||
      phase == CallPhase.reconnecting;

  CallState copyWith({
    CallPhase? phase,
    String? callId,
    String? assignmentId,
    String? callerId,
    String? calleeId,
    bool? muted,
    bool? speakerphone,
    Duration? elapsed,
    Object? endedReason = _sentinel,
    Object? error = _sentinel,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      callId: callId ?? this.callId,
      assignmentId: assignmentId ?? this.assignmentId,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      muted: muted ?? this.muted,
      speakerphone: speakerphone ?? this.speakerphone,
      elapsed: elapsed ?? this.elapsed,
      endedReason: identical(endedReason, _sentinel)
          ? this.endedReason
          : endedReason as String?,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

const Object _sentinel = Object();

final callControllerProvider = NotifierProvider<CallController, CallState>(
  CallController.new,
);

class CallController extends Notifier<CallState> {
  StreamSubscription<CallEvent>? _eventsSub;
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _roomListener;
  Timer? _elapsedTimer;
  Timer? _retryTimer;
  DateTime? _activeAt;
  bool _isCaller = false;
  bool _socketStarted = false;
  int _retryCount = 0;

  static const _retryDelays = [2, 4, 8, 16, 30];

  @override
  CallState build() {
    ref.onDispose(_disposeAll);
    return const CallState();
  }

  /// Subscribe to the /call socket so we hear `incoming-call`. Call this once
  /// from a long-lived widget (e.g. the main shell) after the user is signed
  /// in. Retries with exponential backoff on failure.
  Future<void> ensureListening() async {
    if (_socketStarted) return;
    _socketStarted = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      final socket = ref.read(callSocketProvider);
      await socket.connect();
      _eventsSub = socket.events.listen(_handleEvent);
      _retryCount = 0;
    } catch (e) {
      _socketStarted = false;
      debugPrint('call socket connect failed: $e');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    final seconds = _retryDelays[_retryCount.clamp(0, _retryDelays.length - 1)];
    _retryCount++;
    debugPrint('call socket retry in ${seconds}s (attempt $_retryCount)');
    _retryTimer = Timer(Duration(seconds: seconds), () {
      _retryTimer = null;
      ensureListening();
    });
  }

  /// Caller-initiated call. Posts to `/calls`, the server fires
  /// `incoming-call` to the callee. We move into `outgoing` and wait for
  /// `call-accepted`.
  Future<void> startCall(String assignmentId) async {
    try {
      await ensureListening();
      final call = await ref.read(callRepositoryProvider).start(assignmentId);
      _isCaller = true;
      state = state.copyWith(
        phase: CallPhase.outgoing,
        callId: call.id,
        assignmentId: call.assignmentId,
        callerId: call.callerId,
        calleeId: call.calleeId,
        elapsed: Duration.zero,
        endedReason: null,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Qo\'ng\'iroqni boshlab bo\'lmadi');
      rethrow;
    }
  }

  Future<void> accept() async {
    final id = state.callId;
    if (id == null || state.phase != CallPhase.incoming) return;
    try {
      _isCaller = false;
      state = state.copyWith(phase: CallPhase.connecting, error: null);
      await ref.read(callSocketProvider).accept(id);
      await _connectRoom(id);
    } catch (e) {
      debugPrint('accept failed: $e');
      state = state.copyWith(
        phase: CallPhase.ended,
        endedReason: 'failed',
        error: 'Qabul qilinmadi',
      );
      await _closeRoom();
    }
  }

  Future<void> decline() async {
    final id = state.callId;
    if (id == null) return;
    try {
      await ref.read(callSocketProvider).decline(id);
    } catch (e) {
      debugPrint('decline failed: $e');
    }
    state = state.copyWith(phase: CallPhase.ended, endedReason: 'declined');
    await _closeRoom();
  }

  Future<void> hangup({String reason = 'hangup'}) async {
    final id = state.callId;
    if (id != null) {
      try {
        await ref.read(callSocketProvider).hangup(id, reason: reason);
      } catch (e) {
        debugPrint('hangup failed: $e');
      }
    }
    state = state.copyWith(phase: CallPhase.ended, endedReason: reason);
    _stopElapsedTimer();
    await _closeRoom();
  }

  void toggleMute() {
    final room = _room;
    if (room?.localParticipant == null) return;
    final next = !state.muted;
    room!.localParticipant!.setMicrophoneEnabled(!next);
    state = state.copyWith(muted: next);
  }

  void toggleSpeaker() {
    final next = !state.speakerphone;
    lk.AudioManager.instance.setSpeakerOutputPreferred(next, force: false);
    state = state.copyWith(speakerphone: next);
  }

  /// Reset back to idle so the screen can dismiss after `ended`.
  void reset() {
    state = const CallState();
  }

  Future<void> _handleEvent(CallEvent event) async {
    switch (event) {
      case IncomingCallEvent e:
        if (state.isLive || state.phase == CallPhase.incoming) {
          // Already in a call — auto-decline duplicate ring.
          try {
            await ref.read(callSocketProvider).decline(e.callId);
          } catch (_) {}
          return;
        }
        state = CallState(
          phase: CallPhase.incoming,
          callId: e.callId,
          assignmentId: e.assignmentId,
          callerId: e.callerId,
        );
      case CallAcceptedEvent _:
        if (!_isCaller) return;
        final id = state.callId;
        if (id == null) return;
        state = state.copyWith(phase: CallPhase.connecting);
        await _connectRoom(id);
      case CallDeclinedEvent _:
        state = state.copyWith(phase: CallPhase.ended, endedReason: 'declined');
        await _closeRoom();
      case CallEndedEvent e:
        state = state.copyWith(
          phase: CallPhase.ended,
          endedReason: e.reason ?? 'ended',
        );
        _stopElapsedTimer();
        await _closeRoom();
    }
  }

  /// Fetches a LiveKit room token for this call and joins the media room —
  /// this replaces the old manual RTCPeerConnection offer/answer/ICE dance;
  /// both parties just connect to the same server-relayed room.
  Future<void> _connectRoom(String callId) async {
    final tokenInfo = await ref
        .read(callRepositoryProvider)
        .getLiveKitToken(callId);

    final room = lk.Room();
    _room = room;
    _roomListener = room.createListener()
      ..on<lk.RoomDisconnectedEvent>((e) {
        debugPrint('livekit room disconnected: ${e.reason}');
        if (state.phase != CallPhase.ended) {
          state = state.copyWith(
            phase: CallPhase.ended,
            endedReason: 'connection_lost',
          );
          _stopElapsedTimer();
        }
      })
      ..on<lk.RoomReconnectingEvent>((_) {
        if (state.phase == CallPhase.active) {
          state = state.copyWith(phase: CallPhase.reconnecting);
        }
      })
      ..on<lk.RoomReconnectedEvent>((_) {
        if (state.phase == CallPhase.reconnecting) {
          state = state.copyWith(phase: CallPhase.active);
        }
      });

    await room.connect(tokenInfo.url, tokenInfo.token);
    await room.localParticipant?.setMicrophoneEnabled(true);

    _activeAt ??= DateTime.now();
    _startElapsedTimer();
    state = state.copyWith(phase: CallPhase.active);
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    final start = _activeAt ?? DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: DateTime.now().difference(start));
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  Future<void> _closeRoom() async {
    _stopElapsedTimer();
    _roomListener?.cancelAll();
    _roomListener = null;
    try {
      await _room?.disconnect();
    } catch (_) {}
    _room = null;
    _activeAt = null;
    _isCaller = false;
  }

  void _disposeAll() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _eventsSub?.cancel();
    _eventsSub = null;
    _stopElapsedTimer();
    _roomListener?.cancelAll();
    _room?.disconnect();
  }
}
