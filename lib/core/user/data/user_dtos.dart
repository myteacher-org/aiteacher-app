class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    this.avatar,
    this.referralCode,
    this.activeSubscription,
    this.student,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String? avatar;

  /// User's own referral code that others can use at sign-up.
  final String? referralCode;
  final ActiveSubscription? activeSubscription;

  /// Student-specific onboarding + skill snapshot. Null for non-students.
  final StudentProfile? student;

  String get fullName => '$firstName $lastName'.trim();

  String get initial =>
      firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : '?';

  /// Demo accounts used for store review. Real users always sign up with a
  /// phone number, so an account that carries an email and no phone is a
  /// demo one. All payment UI is hidden for these accounts — read it through
  /// `isDemoAccountProvider` rather than re-deriving it in the UI.
  bool get isDemo {
    final hasPhone = phoneNumber.trim().isNotEmpty;
    final hasEmail = email?.trim().isNotEmpty ?? false;
    // The legacy demo account predates the email-only rule and still signs
    // in with this reserved phone number.
    return (!hasPhone && hasEmail) || phoneNumber.endsWith('990000000');
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final sub = json['activeSubscription'];
    final stu = json['student'];
    return User(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      referralCode: json['referralCode'] as String?,
      activeSubscription: sub is Map<String, dynamic>
          ? ActiveSubscription.fromJson(sub)
          : null,
      student: stu is Map<String, dynamic>
          ? StudentProfile.fromJson(stu)
          : null,
    );
  }
}

/// CEFR ladder used for self-assessed skill levels on the user profile.
enum CefrLevel {
  a0,
  a1,
  b1,
  b2,
  c1;

  static CefrLevel fromApi(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'a1':
        return CefrLevel.a1;
      case 'b1':
        return CefrLevel.b1;
      case 'b2':
        return CefrLevel.b2;
      case 'c1':
        return CefrLevel.c1;
      case 'a0':
      default:
        return CefrLevel.a0;
    }
  }

  /// 0..1 placement on the radar; A0 sits just above the center so the dot
  /// is still visible.
  double get fraction => switch (this) {
    CefrLevel.a0 => 0.1,
    CefrLevel.a1 => 0.3,
    CefrLevel.b1 => 0.55,
    CefrLevel.b2 => 0.8,
    CefrLevel.c1 => 1.0,
  };

  String get label => switch (this) {
    CefrLevel.a0 => 'A0',
    CefrLevel.a1 => 'A1',
    CefrLevel.b1 => 'B1',
    CefrLevel.b2 => 'B2',
    CefrLevel.c1 => 'C1',
  };
}

class StudentProfile {
  const StudentProfile({
    required this.overall,
    required this.writing,
    required this.reading,
    required this.listening,
    required this.speaking,
    required this.fluency,
  });

  final CefrLevel overall;
  final CefrLevel writing;
  final CefrLevel reading;
  final CefrLevel listening;
  final CefrLevel speaking;
  final CefrLevel fluency;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      overall: CefrLevel.fromApi(json['level'] as String?),
      writing: CefrLevel.fromApi(json['writingLevel'] as String?),
      reading: CefrLevel.fromApi(json['readingLevel'] as String?),
      listening: CefrLevel.fromApi(json['listeningLevel'] as String?),
      speaking: CefrLevel.fromApi(json['speakingLevel'] as String?),
      fluency: CefrLevel.fromApi(json['fluencyLevel'] as String?),
    );
  }
}

class ActiveSubscription {
  const ActiveSubscription({
    required this.id,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final DateTime startDate;
  final DateTime endDate;

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      id: json['id'] as String? ?? '',
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
