class BookableMentor {
  const BookableMentor({
    required this.mentorId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.avatar,
    this.bio,
    this.openSlotsCount = 0,
    this.nextAvailableAt,
  });

  final String mentorId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? avatar;
  final String? bio;
  final int openSlotsCount;
  final DateTime? nextAvailableAt;

  factory BookableMentor.fromJson(Map<String, dynamic> json) {
    final first = json['firstName'] as String? ?? '';
    final last = json['lastName'] as String? ?? '';
    final full = (json['fullName'] as String?)?.trim();
    return BookableMentor(
      mentorId: json['mentorId']?.toString() ?? json['id']?.toString() ?? '',
      firstName: first,
      lastName: last,
      fullName: (full == null || full.isEmpty) ? '$first $last'.trim() : full,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      openSlotsCount: (json['openSlotsCount'] as num?)?.toInt() ?? 0,
      nextAvailableAt: json['nextAvailableAt'] is String
          ? DateTime.tryParse(json['nextAvailableAt'] as String)
          : null,
    );
  }
}

class BookableSlot {
  const BookableSlot({
    required this.id,
    required this.startsAt,
    required this.durationMin,
  });

  final String id;
  final DateTime startsAt;
  final int durationMin;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMin));

  factory BookableSlot.fromJson(Map<String, dynamic> json) {
    return BookableSlot(
      id: json['id']?.toString() ?? '',
      startsAt:
          DateTime.tryParse(json['startsAt'] as String? ?? '') ??
          DateTime.now(),
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 30,
    );
  }
}

class BookingResult {
  const BookingResult({
    required this.assignmentId,
    this.chatRoomId,
    required this.slot,
    required this.mentor,
    this.isNewAssignment = false,
  });

  final String assignmentId;
  final String? chatRoomId;
  final BookableSlot slot;
  final BookableMentor mentor;
  final bool isNewAssignment;

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    return BookingResult(
      assignmentId: json['assignmentId']?.toString() ?? '',
      chatRoomId: json['chatRoomId']?.toString(),
      slot: BookableSlot.fromJson(
        (json['slot'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      mentor: BookableMentor.fromJson(
        (json['mentor'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      isNewAssignment: json['isNewAssignment'] as bool? ?? false,
    );
  }
}

/// A confirmed lesson from the student's side — same slot shape as
/// [BookableSlot], with the assignment id and mentor embedded.
class UpcomingLesson {
  const UpcomingLesson({
    required this.id,
    required this.startsAt,
    required this.durationMin,
    required this.assignmentId,
    required this.mentor,
  });

  final String id;
  final DateTime startsAt;
  final int durationMin;
  final String assignmentId;
  final BookableMentor mentor;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMin));

  factory UpcomingLesson.fromJson(Map<String, dynamic> json) {
    return UpcomingLesson(
      id: json['id']?.toString() ?? '',
      startsAt:
          DateTime.tryParse(json['startsAt'] as String? ?? '') ??
          DateTime.now(),
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 30,
      assignmentId: json['assignmentId']?.toString() ?? '',
      mentor: BookableMentor.fromJson(
        (json['mentor'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
