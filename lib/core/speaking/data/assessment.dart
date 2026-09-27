class Assessment {
  const Assessment({
    required this.feedback,
    required this.overallScore,
    required this.cefrLevel,
    required this.durationSeconds,
    required this.skills,
    required this.fluencyDetail,
    required this.pronunciationDetail,
    required this.grammarDetail,
    required this.vocabularyDetail,
    required this.roadmap,
    required this.coachTips,
    this.audio,
    this.audioMimeType,
    this.conversationId,
  });

  final String feedback;
  final int overallScore;
  final String cefrLevel;
  final int durationSeconds;
  final AssessmentSkills skills;
  final FluencyDetail fluencyDetail;
  final PronunciationDetail pronunciationDetail;
  final GrammarDetail grammarDetail;
  final VocabularyDetail vocabularyDetail;
  final RoadmapPlan roadmap;
  final List<String> coachTips;
  final String? audio;
  final String? audioMimeType;

  /// Server conversation id this report belongs to.
  final String? conversationId;

  Assessment copyWith({String? conversationId}) {
    return Assessment(
      feedback: feedback,
      overallScore: overallScore,
      cefrLevel: cefrLevel,
      durationSeconds: durationSeconds,
      skills: skills,
      fluencyDetail: fluencyDetail,
      pronunciationDetail: pronunciationDetail,
      grammarDetail: grammarDetail,
      vocabularyDetail: vocabularyDetail,
      roadmap: roadmap,
      coachTips: coachTips,
      audio: audio,
      audioMimeType: audioMimeType,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      feedback: json['feedback'] as String? ?? '',
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      cefrLevel: json['cefrLevel'] as String? ?? 'B1',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      skills: AssessmentSkills.fromJson(
        (json['skills'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      fluencyDetail: FluencyDetail.fromJson(
        (json['fluencyDetail'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      pronunciationDetail: PronunciationDetail.fromJson(
        (json['pronunciationDetail'] as Map?)?.cast<String, dynamic>() ??
            const {},
      ),
      grammarDetail: GrammarDetail.fromJson(
        (json['grammarDetail'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      vocabularyDetail: VocabularyDetail.fromJson(
        (json['vocabularyDetail'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      roadmap: RoadmapPlan.fromJson(
        (json['roadmap'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      coachTips: ((json['coachTips'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      audio: json['audio'] as String?,
      audioMimeType: json['audioMimeType'] as String?,
      conversationId: json['conversationId'] as String?,
    );
  }
}

class AssessmentSkills {
  const AssessmentSkills({
    required this.speaking,
    required this.vocabulary,
    required this.grammar,
    required this.listening,
    required this.reading,
    required this.writing,
    required this.pronunciation,
    required this.fluency,
  });

  final int speaking;
  final int vocabulary;
  final int grammar;
  final int listening;
  final int reading;
  final int writing;
  final int pronunciation;
  final int fluency;

  factory AssessmentSkills.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return AssessmentSkills(
      speaking: read('speaking'),
      vocabulary: read('vocabulary'),
      grammar: read('grammar'),
      listening: read('listening'),
      reading: read('reading'),
      writing: read('writing'),
      pronunciation: read('pronunciation'),
      fluency: read('fluency'),
    );
  }
}

class FluencyDetail {
  const FluencyDetail({
    required this.speechRateWpm,
    required this.pauseControl,
    required this.clarity,
    required this.intonation,
    required this.lexicalDiversity,
  });

  final int speechRateWpm;
  final int pauseControl;
  final int clarity;
  final int intonation;
  final int lexicalDiversity;

  factory FluencyDetail.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return FluencyDetail(
      speechRateWpm: read('speechRateWpm'),
      pauseControl: read('pauseControl'),
      clarity: read('clarity'),
      intonation: read('intonation'),
      lexicalDiversity: read('lexicalDiversity'),
    );
  }
}

class PronunciationDetail {
  const PronunciationDetail({
    required this.strongAreas,
    required this.soundsToPractice,
  });

  final List<String> strongAreas;
  final List<String> soundsToPractice;

  factory PronunciationDetail.fromJson(Map<String, dynamic> json) {
    List<String> read(String key) => ((json[key] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(growable: false);
    return PronunciationDetail(
      strongAreas: read('strongAreas'),
      soundsToPractice: read('soundsToPractice'),
    );
  }
}

class GrammarDetail {
  const GrammarDetail({required this.errorsByCategory});

  final Map<String, int> errorsByCategory;

  factory GrammarDetail.fromJson(Map<String, dynamic> json) {
    final raw =
        (json['errorsByCategory'] as Map?)?.cast<String, dynamic>() ?? const {};
    return GrammarDetail(
      errorsByCategory: {
        for (final entry in raw.entries)
          entry.key: (entry.value as num?)?.toInt() ?? 0,
      },
    );
  }
}

class VocabularyDetail {
  const VocabularyDetail({
    required this.activeSizeEstimate,
    required this.nextLevel,
    required this.priorityWords,
  });

  final int activeSizeEstimate;
  final NextLevel nextLevel;
  final List<String> priorityWords;

  factory VocabularyDetail.fromJson(Map<String, dynamic> json) {
    return VocabularyDetail(
      activeSizeEstimate: (json['activeSizeEstimate'] as num?)?.toInt() ?? 0,
      nextLevel: NextLevel.fromJson(
        (json['nextLevel'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      priorityWords: ((json['priorityWords'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}

class NextLevel {
  const NextLevel({required this.level, required this.targetSize});

  final String level;
  final int targetSize;

  factory NextLevel.fromJson(Map<String, dynamic> json) {
    return NextLevel(
      level: json['level'] as String? ?? 'B2',
      targetSize: (json['targetSize'] as num?)?.toInt() ?? 6000,
    );
  }
}

class RoadmapPlan {
  const RoadmapPlan({
    required this.targetLevel,
    required this.estimatedDuration,
    required this.focusAreas,
  });

  final String targetLevel;
  final String estimatedDuration;
  final List<String> focusAreas;

  factory RoadmapPlan.fromJson(Map<String, dynamic> json) {
    return RoadmapPlan(
      targetLevel: json['targetLevel'] as String? ?? 'B2',
      estimatedDuration: json['estimatedDuration'] as String? ?? '',
      focusAreas: ((json['focusAreas'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}

const Assessment kSampleAssessment = Assessment(
  feedback:
      'Your speech is clear and confident overall, and your sentence '
      'structure is solid for an intermediate speaker.',
  overallScore: 62,
  cefrLevel: 'B1',
  durationSeconds: 555,
  skills: AssessmentSkills(
    speaking: 68,
    vocabulary: 54,
    grammar: 71,
    listening: 60,
    reading: 78,
    writing: 45,
    pronunciation: 74,
    fluency: 68,
  ),
  fluencyDetail: FluencyDetail(
    speechRateWpm: 127,
    pauseControl: 64,
    clarity: 72,
    intonation: 70,
    lexicalDiversity: 58,
  ),
  pronunciationDetail: PronunciationDetail(
    strongAreas: ['vowels', 'stress placement', 'intonation'],
    soundsToPractice: [
      '/θ/ th',
      '/v/ vs /w/',
      '/r/ sound',
      '/æ/ cat',
      '-ed endings',
    ],
  ),
  grammarDetail: GrammarDetail(
    errorsByCategory: {
      'tenses': 8,
      'articles': 5,
      'prepositions': 6,
      'wordOrder': 2,
      'conjunctions': 3,
      'conditionals': 7,
    },
  ),
  vocabularyDetail: VocabularyDetail(
    activeSizeEstimate: 3400,
    nextLevel: NextLevel(level: 'B2', targetSize: 6000),
    priorityWords: [
      'acquire',
      'analyze',
      'benefit',
      'challenge',
      'colleague',
      'commit',
      'consistent',
      'contrast',
      'dedicate',
      'despite',
      'efficient',
      'emphasize',
      'evaluate',
      'evidence',
      'generate',
      'impact',
      'implement',
      'negotiate',
    ],
  ),
  roadmap: RoadmapPlan(
    targetLevel: 'B2',
    estimatedDuration: 'approximately 4-6 months at 30 minutes daily',
    focusAreas: [
      'Speaking + Conditionals',
      'Speaking + Articles',
      'Vocabulary expansion to 6,000 active words',
      'Pronunciation: th and v/w drills',
      'Mock test under timed conditions',
    ],
  ),
  coachTips: [
    'Use spaced repetition to learn fifteen priority words a day from the B2 list — at that pace you reach the six thousand word target in about thirty five days.',
    'Listen to one TED Talk daily, first with subtitles and then without. Within a month your listening score should move from sixty to around eighty.',
    'Book three AI Speaking sessions per week and after each one drill the single grammar pattern you got wrong most often.',
    'Spend ten minutes a day journaling in English. It is the fastest way to lift your writing score because it strengthens grammar and vocabulary at the same time.',
    'Learn each new word inside three real sentences instead of in isolation — context-based recall is roughly four times stickier than flashcard recall.',
  ],
);
