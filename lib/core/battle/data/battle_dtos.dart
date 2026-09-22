import 'package:flutter/foundation.dart';

enum BattlePhase { idle, queuing, playing, gameOver }

@immutable
class LobbyPlayer {
  const LobbyPlayer({
    required this.userId,
    required this.firstName,
    this.avatar,
    this.score = 0,
  });

  final String userId;
  final String firstName;
  final String? avatar;
  final int score;

  LobbyPlayer withScore(int score) => LobbyPlayer(
    userId: userId,
    firstName: firstName,
    avatar: avatar,
    score: score,
  );

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) {
    return LobbyPlayer(
      userId: json['userId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      avatar: _readAvatar(json),
    );
  }
}

@immutable
class LobbyJoinedPayload {
  const LobbyJoinedPayload({
    required this.lobbyId,
    required this.players,
    required this.maxPlayers,
    required this.waitSeconds,
  });

  final String lobbyId;
  final List<LobbyPlayer> players;
  final int maxPlayers;
  final int waitSeconds;
}

@immutable
class GameStartingPayload {
  const GameStartingPayload({
    required this.players,
    required this.totalRounds,
    required this.roundSeconds,
  });

  final List<LobbyPlayer> players;
  final int totalRounds;
  final int roundSeconds;
}

@immutable
class RoundStartPayload {
  const RoundStartPayload({
    required this.round,
    required this.total,
    required this.word,
    required this.options,
    required this.timeSeconds,
  });

  final int round;
  final int total;
  final String word;
  final List<String> options;
  final int timeSeconds;
}

@immutable
class RoundAnswerResult {
  const RoundAnswerResult({
    required this.round,
    required this.correct,
    required this.correctOptionIndex,
    required this.delayMs,
  });

  final int round;
  final bool correct;
  final int correctOptionIndex;
  final int delayMs;
}

@immutable
class PlayerRoundResult {
  const PlayerRoundResult({
    required this.userId,
    required this.firstName,
    required this.correct,
    required this.score,
    this.selectedOptionIndex,
    this.delayMs,
  });

  final String userId;
  final String firstName;
  final int? selectedOptionIndex;
  final bool correct;
  final int score;
  final int? delayMs;
}

@immutable
class RoundEndData {
  const RoundEndData({
    required this.round,
    required this.total,
    required this.correctOptionIndex,
    required this.correctTranslation,
    required this.playerResults,
    required this.standings,
  });

  final int round;
  final int total;
  final int correctOptionIndex;
  final String correctTranslation;
  final List<PlayerRoundResult> playerResults;
  final List<RoundStanding> standings;
}

@immutable
class BattleRoundAnswer {
  const BattleRoundAnswer({
    required this.round,
    required this.word,
    required this.correctOptionIndex,
    required this.correct,
    this.selectedOptionIndex,
    this.delayMs,
  });

  final int round;
  final String word;
  final int? selectedOptionIndex;
  final int correctOptionIndex;
  final bool correct;
  final int? delayMs;

  factory BattleRoundAnswer.fromJson(Map<String, dynamic> json) {
    return BattleRoundAnswer(
      round: (json['round'] as num?)?.toInt() ?? 0,
      word: json['word'] as String? ?? '',
      selectedOptionIndex: (json['selectedOptionIndex'] as num?)?.toInt(),
      correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt() ?? 0,
      correct: json['correct'] as bool? ?? false,
      delayMs: (json['delayMs'] as num?)?.toInt(),
    );
  }
}

@immutable
class ScoreboardEntry {
  const ScoreboardEntry({
    required this.rank,
    required this.userId,
    required this.firstName,
    required this.score,
    required this.sumDelayMs,
    required this.answers,
    this.avatar,
  });

  final int rank;
  final String userId;
  final String firstName;
  final String? avatar;
  final int score;
  final int sumDelayMs;
  final List<BattleRoundAnswer> answers;

  factory ScoreboardEntry.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as List? ?? const [];
    return ScoreboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      avatar: _readAvatar(json),
      score: (json['score'] as num?)?.toInt() ?? 0,
      sumDelayMs: (json['sumDelayMs'] as num?)?.toInt() ?? 0,
      answers: rawAnswers
          .map(
            (e) =>
                BattleRoundAnswer.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

String? _readAvatar(Map<String, dynamic> json) {
  final direct = json['avatar'] ?? json['avatarUrl'];
  if (direct is String && direct.trim().isNotEmpty) return direct.trim();
  final user = json['user'];
  if (user is Map) {
    final nested = user['avatar'] ?? user['avatarUrl'];
    if (nested is String && nested.trim().isNotEmpty) return nested.trim();
  }
  return null;
}

@immutable
class PlayerAnsweredPayload {
  const PlayerAnsweredPayload({
    required this.userId,
    required this.firstName,
    required this.round,
    required this.optionIndex,
    required this.correct,
    required this.delayMs,
    required this.score,
  });

  final String userId;
  final String firstName;
  final int round;
  final int optionIndex;
  final bool correct;
  final int delayMs;
  final int score;
}

@immutable
class RoundStanding {
  const RoundStanding({
    required this.rank,
    required this.userId,
    required this.firstName,
    required this.score,
  });

  final int rank;
  final String userId;
  final String firstName;
  final int score;
}

const Object _sentinel = Object();

@immutable
class BattleState {
  const BattleState({
    required this.phase,
    this.myUserId,
    this.lobbyId,
    this.lobbyPlayers = const [],
    this.lobbyTick,
    this.currentRound,
    this.totalRounds,
    this.roundTick,
    this.word,
    this.options = const [],
    this.selectedOptionIndex,
    this.roundAnswerResult,
    this.roundEnd,
    this.roundPlayerAnswers = const [],
    this.scoreboard = const [],
    this.error,
  });

  final BattlePhase phase;
  final String? myUserId;
  final String? lobbyId;
  final List<LobbyPlayer> lobbyPlayers;

  /// Remaining seconds in the lobby countdown (from lobby_tick).
  final int? lobbyTick;
  final int? currentRound;
  final int? totalRounds;

  /// Remaining seconds in the current round (from round_tick).
  final int? roundTick;
  final String? word;
  final List<String> options;
  final int? selectedOptionIndex;
  final RoundAnswerResult? roundAnswerResult;
  final RoundEndData? roundEnd;

  /// Other players' answer choices for the current round.
  final List<PlayerAnsweredPayload> roundPlayerAnswers;
  final List<ScoreboardEntry> scoreboard;
  final String? error;

  static const initial = BattleState(phase: BattlePhase.idle);

  BattleState copyWith({
    BattlePhase? phase,
    Object? myUserId = _sentinel,
    Object? lobbyId = _sentinel,
    List<LobbyPlayer>? lobbyPlayers,
    Object? lobbyTick = _sentinel,
    Object? currentRound = _sentinel,
    Object? totalRounds = _sentinel,
    Object? roundTick = _sentinel,
    Object? word = _sentinel,
    List<String>? options,
    Object? selectedOptionIndex = _sentinel,
    Object? roundAnswerResult = _sentinel,
    Object? roundEnd = _sentinel,
    List<PlayerAnsweredPayload>? roundPlayerAnswers,
    List<ScoreboardEntry>? scoreboard,
    Object? error = _sentinel,
  }) {
    return BattleState(
      phase: phase ?? this.phase,
      myUserId: identical(myUserId, _sentinel)
          ? this.myUserId
          : myUserId as String?,
      lobbyId: identical(lobbyId, _sentinel)
          ? this.lobbyId
          : lobbyId as String?,
      lobbyPlayers: lobbyPlayers ?? this.lobbyPlayers,
      lobbyTick: identical(lobbyTick, _sentinel)
          ? this.lobbyTick
          : lobbyTick as int?,
      currentRound: identical(currentRound, _sentinel)
          ? this.currentRound
          : currentRound as int?,
      totalRounds: identical(totalRounds, _sentinel)
          ? this.totalRounds
          : totalRounds as int?,
      roundTick: identical(roundTick, _sentinel)
          ? this.roundTick
          : roundTick as int?,
      word: identical(word, _sentinel) ? this.word : word as String?,
      options: options ?? this.options,
      selectedOptionIndex: identical(selectedOptionIndex, _sentinel)
          ? this.selectedOptionIndex
          : selectedOptionIndex as int?,
      roundAnswerResult: identical(roundAnswerResult, _sentinel)
          ? this.roundAnswerResult
          : roundAnswerResult as RoundAnswerResult?,
      roundEnd: identical(roundEnd, _sentinel)
          ? this.roundEnd
          : roundEnd as RoundEndData?,
      roundPlayerAnswers: roundPlayerAnswers ?? this.roundPlayerAnswers,
      scoreboard: scoreboard ?? this.scoreboard,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}
