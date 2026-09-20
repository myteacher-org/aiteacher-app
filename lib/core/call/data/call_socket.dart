import 'dart:async';

import 'package:ai_teacher/app/data/network_config.dart';
import 'package:ai_teacher/core/auth/data/auth_session.dart';
import 'package:ai_teacher/core/call/data/call_dtos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final callSocketProvider = Provider<CallSocket>((ref) {
  final socket = CallSocket(ref.watch(authSessionProvider));
  ref.onDispose(socket.dispose);
  return socket;
});

class CallSocketException implements Exception {
  CallSocketException(this.code, [this.details]);

  final String code;
  final Object? details;

  @override
  String toString() => 'CallSocketException($code)';
}

class CallSocket {
  CallSocket(this._session);

  final AuthSession _session;
  io.Socket? _socket;
  final StreamController<CallEvent> _events =
      StreamController<CallEvent>.broadcast();

  Stream<CallEvent> get events => _events.stream;

  bool get connected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = _session.accessToken;
    if (token == null || token.isEmpty) {
      throw CallSocketException('no_token');
    }
    _socket?.dispose();

    final socket = io.io(
      '${NetworkConfig.hostUrl}/call',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    socket.on('connect', (_) => debugPrint('call socket connected'));
    socket.on(
      'disconnect',
      (reason) => debugPrint('call socket disconnected: $reason'),
    );
    socket.on('connect_error', (err) {
      debugPrint('call socket connect_error: $err');
    });

    socket.on('incoming-call', (data) => _dispatchIncoming(data));
    socket.on(
      'call-accepted',
      (data) => _dispatchSimple(data, (id) => CallAcceptedEvent(id)),
    );
    socket.on(
      'call-declined',
      (data) => _dispatchSimple(data, (id) => CallDeclinedEvent(id)),
    );
    socket.on('call-ended', (data) => _dispatchEnded(data));

    socket.connect();
    _socket = socket;
  }

  Future<void> accept(String callId) => _emitAck('accept', {'callId': callId});

  Future<void> decline(String callId) =>
      _emitAck('decline', {'callId': callId});

  Future<void> hangup(String callId, {String? reason}) =>
      _emitAck('hangup', {'callId': callId, 'reason': ?reason});

  Future<void> _emitAck(String event, Map<String, dynamic> payload) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw CallSocketException('not_connected');
    }
    final completer = Completer<void>();
    socket.emitWithAck(
      event,
      payload,
      ack: (response) {
        if (response is Map &&
            response.containsKey('error') &&
            response['error'] is String) {
          completer.completeError(
            CallSocketException(response['error'] as String, response),
          );
          return;
        }
        completer.complete();
      },
    );
    return completer.future;
  }

  void _dispatchIncoming(dynamic raw) {
    if (raw is! Map) return;
    final m = raw.cast<String, dynamic>();
    _events.add(
      IncomingCallEvent(
        callId: m['callId'] as String? ?? '',
        assignmentId: m['assignmentId'] as String? ?? '',
        callerId: m['callerId'] as String? ?? '',
      ),
    );
  }

  void _dispatchSimple(dynamic raw, CallEvent Function(String id) build) {
    if (raw is! Map) return;
    final m = raw.cast<String, dynamic>();
    _events.add(build(m['callId'] as String? ?? ''));
  }

  void _dispatchEnded(dynamic raw) {
    if (raw is! Map) return;
    final m = raw.cast<String, dynamic>();
    _events.add(
      CallEndedEvent(
        callId: m['callId'] as String? ?? '',
        reason: m['reason'] as String?,
      ),
    );
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    if (!_events.isClosed) _events.close();
  }
}
