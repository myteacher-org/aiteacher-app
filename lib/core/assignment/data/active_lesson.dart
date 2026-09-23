class ActiveLesson {
  const ActiveLesson({
    required this.id,
    required this.mentorUserId,
    required this.url,
    required this.expiresAt,
  });

  final String id;
  final String mentorUserId;
  final String url;
  final DateTime expiresAt;

  factory ActiveLesson.fromJson(Map<String, dynamic> json) => ActiveLesson(
    id: json['id'] as String,
    mentorUserId: json['mentorUserId'] as String,
    url: json['url'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}
