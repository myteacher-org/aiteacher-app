enum CallStatus {
  ringing,
  inCall,
  ended,
  missed,
  declined;

  static CallStatus fromApi(String? raw) {
    switch (raw) {
      case 'ringing':
        return CallStatus.ringing;
      case 'in_call':
        return CallStatus.inCall;
      case 'ended':
        return CallStatus.ended;
      case 'missed':
        return CallStatus.missed;
      case 'declined':
        return CallStatus.declined;
      default:
        return CallStatus.ended;
    }
  }
}

class Call {
  const Call({
    required this.id,
    required this.assignmentId,
    required this.callerId,
    required this.calleeId,
    required this.status,
    this.acceptedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String assignmentId;
  final String callerId;
  final String calleeId;
  final CallStatus status;
  final DateTime? acceptedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Call.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullable(dynamic v) =>
        v is String ? DateTime.tryParse(v) : null;
    return Call(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignmentId'] as String? ?? '',
      callerId: json['callerId'] as String? ?? '',
      calleeId: json['calleeId'] as String? ?? '',
      status: CallStatus.fromApi(json['status'] as String?),
      acceptedAt: parseNullable(json['acceptedAt']),
      endedAt: parseNullable(json['endedAt']),
      createdAt:
          parseNullable(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          parseNullable(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

sealed class CallEvent {
  const CallEvent(this.callId);

  final String callId;
}

class IncomingCallEvent extends CallEvent {
  const IncomingCallEvent({
    required String callId,
    required this.assignmentId,
    required this.callerId,
  }) : super(callId);
  final String assignmentId;
  final String callerId;
}

class CallAcceptedEvent extends CallEvent {
  const CallAcceptedEvent(super.callId);
}

class CallDeclinedEvent extends CallEvent {
  const CallDeclinedEvent(super.callId);
}

class CallEndedEvent extends CallEvent {
  const CallEndedEvent({required String callId, this.reason}) : super(callId);
  final String? reason;
}

/// A short-lived LiveKit room-join token, minted by the backend once a call
/// has been accepted. The media path connects to [url]/[roomName] using
/// this token instead of exchanging SDP/ICE directly with the peer.
class LiveKitToken {
  const LiveKitToken({
    required this.token,
    required this.url,
    required this.roomName,
  });

  final String token;
  final String url;
  final String roomName;

  factory LiveKitToken.fromJson(Map<String, dynamic> json) {
    return LiveKitToken(
      token: json['token'] as String? ?? '',
      url: json['url'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
    );
  }
}
