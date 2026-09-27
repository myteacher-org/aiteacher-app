class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.readyForAnalyze,
    required this.hasReport,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final bool readyForAnalyze;
  final bool hasReport;

  /// True when the learner can view the full report (active subscription or
  /// already paid for a one-time unlock). False = report exists but is gated
  /// behind the paywall.
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v) => v is String
        ? (DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0))
        : DateTime.fromMillisecondsSinceEpoch(0);
    return ConversationSummary(
      id: json['id'] as String? ?? '',
      readyForAnalyze: json['readyForAnalyze'] as bool? ?? false,
      hasReport: json['hasReport'] as bool? ?? false,
      createdAt: parse(json['createdAt']),
      updatedAt: parse(json['updatedAt']),
    );
  }
}
