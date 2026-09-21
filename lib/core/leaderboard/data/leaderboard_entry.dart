class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.score,
    required this.rank,
    required this.streakDays,
    required this.isMe,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final int score;
  final int rank;
  final int streakDays;
  final bool isMe;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      isMe: json['isMe'] as bool? ?? false,
    );
  }
}
