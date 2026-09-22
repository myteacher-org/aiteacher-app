import 'dart:async';

import 'package:ai_teacher/app/data/network_config.dart';
import 'package:ai_teacher/core/auth/data/auth_session.dart';
import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final battleSocketProvider = Provider.autoDispose<BattleSocket>((ref) {
  final socket = BattleSocket(ref.watch(authSessionProvider));
  ref.onDispose(socket.dispose);
  return socket;
});

class BattleSocket {
  BattleSocket(this._session);

  final AuthSession _session;
  io.Socket? _socket;

  final _queueJoined = StreamController<String>.broadcast();
  final _lobbyJoined = StreamController<LobbyJoinedPayload>.broadcast();
  final _playerJoined = StreamController<LobbyPlayer>.broadcast();
  final _playerLeft = StreamController<String>.broadcast();
  final _gameStarting = StreamController<GameStartingPayload>.broadcast();
  final _roundStart = StreamController<RoundStartPayload>.broadcast();
  final _roundAnswerResult = StreamController<RoundAnswerResult>.broadcast();
  final _lobbyTick = StreamController<int>.broadcast();
  final _roundTick = StreamController<int>.broadcast();
  final _playerAnswered = StreamController<PlayerAnsweredPayload>.broadcast();
  final _roundEnd = StreamController<RoundEndData>.broadcast();
  final _gameOver = StreamController<List<ScoreboardEntry>>.broadcast();
  final _playerReaction = StreamController<PlayerReaction>.broadcast();
  final _error = StreamController<String>.broadcast();

  Stream<String> get onQueueJoined => _queueJoined.stream;

  Stream<LobbyJoinedPayload> get onLobbyJoined => _lobbyJoined.stream;

  Stream<LobbyPlayer> get onPlayerJoined => _playerJoined.stream;

  Stream<String> get onPlayerLeft => _playerLeft.stream;

  Stream<GameStartingPayload> get onGameStarting => _gameStarting.stream;

  Stream<RoundStartPayload> get onRoundStart => _roundStart.stream;

  Stream<RoundAnswerResult> get onRoundAnswerResult =>
      _roundAnswerResult.stream;

  Stream<int> get onLobbyTick => _lobbyTick.stream;

  Stream<int> get onRoundTick => _roundTick.stream;

  Stream<PlayerAnsweredPayload> get onPlayerAnswered => _playerAnswered.stream;

  Stream<RoundEndData> get onRoundEnd => _roundEnd.stream;

  Stream<List<ScoreboardEntry>> get onGameOver => _gameOver.stream;

  Stream<PlayerReaction> get onPlayerReaction => _playerReaction.stream;

  Stream<String> get onError => _error.stream;

  void connect() {
    if (_socket?.connected == true) return;
    final token = _session.accessToken;
    if (token == null || token.isEmpty) return;
    _socket?.dispose();

    final socket = io.io(
      '${NetworkConfig.hostUrl}/battle',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    socket.on('connect', (_) => debugPrint('battle socket connected'));
    socket.on(
      'disconnect',
      (r) => debugPrint('battle socket disconnected: $r'),
    );
    socket.on('connect_error', (e) {
      debugPrint('battle connect error: $e');
      _error.add('Ulanishda xatolik');
    });

    socket.on('queue_joined', (data) {
      try {
        final d = _asMap(data);
        _queueJoined.add(d['lobbyId'] as String? ?? '');
      } catch (e) {
        debugPrint('queue_joined parse error: $e');
      }
    });

    socket.on('lobby_joined', (data) {
      try {
        final d = _asMap(data);
        final rawPlayers = d['players'] as List? ?? const [];
        _lobbyJoined.add(
          LobbyJoinedPayload(
            lobbyId: d['lobbyId'] as String? ?? '',
            players: rawPlayers
                .map(
                  (e) =>
                      LobbyPlayer.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList(),
            maxPlayers: (d['maxPlayers'] as num?)?.toInt() ?? 4,
            waitSeconds: (d['waitSeconds'] as num?)?.toInt() ?? 30,
          ),
        );
      } catch (e) {
        debugPrint('lobby_joined parse error: $e');
      }
    });

    socket.on('player_joined', (data) {
      try {
        _playerJoined.add(LobbyPlayer.fromJson(_asMap(data)));
      } catch (e) {
        debugPrint('player_joined parse error: $e');
      }
    });

    socket.on('player_left', (data) {
      try {
        _playerLeft.add(_asMap(data)['userId'] as String? ?? '');
      } catch (e) {
        debugPrint('player_left parse error: $e');
      }
    });

    socket.on('game_starting', (data) {
      try {
        final d = _asMap(data);
        final rawPlayers = d['players'] as List? ?? const [];
        _gameStarting.add(
          GameStartingPayload(
            players: rawPlayers
                .map(
                  (e) =>
                      LobbyPlayer.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList(),
            totalRounds: (d['totalRounds'] as num?)?.toInt() ?? 10,
            roundSeconds: (d['roundSeconds'] as num?)?.toInt() ?? 10,
          ),
        );
      } catch (e) {
        debugPrint('game_starting parse error: $e');
      }
    });

    socket.on('round_start', (data) {
      try {
        final d = _asMap(data);
        final rawOptions = d['options'] as List? ?? const [];
        _roundStart.add(
          RoundStartPayload(
            round: (d['round'] as num?)?.toInt() ?? 1,
            total: (d['total'] as num?)?.toInt() ?? 10,
            word: d['word'] as String? ?? '',
            options: rawOptions.map((e) => e.toString()).toList(),
            timeSeconds: (d['timeSeconds'] as num?)?.toInt() ?? 10,
          ),
        );
      } catch (e) {
        debugPrint('round_start parse error: $e');
      }
    });

    socket.on('round_answer_result', (data) {
      try {
        final d = _asMap(data);
        _roundAnswerResult.add(
          RoundAnswerResult(
            round: (d['round'] as num?)?.toInt() ?? 0,
            correct: d['correct'] as bool? ?? false,
            correctOptionIndex: (d['correctOptionIndex'] as num?)?.toInt() ?? 0,
            delayMs: (d['delayMs'] as num?)?.toInt() ?? 0,
          ),
        );
      } catch (e) {
        debugPrint('round_answer_result parse error: $e');
      }
    });

    socket.on('lobby_tick', (data) {
      try {
        final d = _asMap(data);
        _lobbyTick.add((d['remainingSeconds'] as num?)?.toInt() ?? 0);
      } catch (e) {
        debugPrint('lobby_tick parse error: $e');
      }
    });

    socket.on('round_tick', (data) {
      try {
        final d = _asMap(data);
        _roundTick.add((d['remainingSeconds'] as num?)?.toInt() ?? 0);
      } catch (e) {
        debugPrint('round_tick parse error: $e');
      }
    });

    socket.on('player_answered', (data) {
      try {
        final d = _asMap(data);
        _playerAnswered.add(
          PlayerAnsweredPayload(
            userId: d['userId'] as String? ?? '',
            firstName: d['firstName'] as String? ?? '',
            round: (d['round'] as num?)?.toInt() ?? 0,
            optionIndex: (d['optionIndex'] as num?)?.toInt() ?? 0,
            correct: d['correct'] as bool? ?? false,
            delayMs: (d['delayMs'] as num?)?.toInt() ?? 0,
            score: (d['score'] as num?)?.toInt() ?? 0,
          ),
        );
      } catch (e) {
        debugPrint('player_answered parse error: $e');
      }
    });

    socket.on('round_end', (data) {
      try {
        final d = _asMap(data);
        final rawResults = d['playerResults'] as List? ?? const [];
        final rawStandings = d['standings'] as List? ?? const [];
        _roundEnd.add(
          RoundEndData(
            round: (d['round'] as num?)?.toInt() ?? 0,
            total: (d['total'] as num?)?.toInt() ?? 10,
            correctOptionIndex: (d['correctOptionIndex'] as num?)?.toInt() ?? 0,
            correctTranslation: d['correctTranslation'] as String? ?? '',
            playerResults: rawResults.map((e) {
              final r = Map<String, dynamic>.from(e as Map);
              return PlayerRoundResult(
                userId: r['userId'] as String? ?? '',
                firstName: r['firstName'] as String? ?? '',
                selectedOptionIndex: (r['selectedOptionIndex'] as num?)
                    ?.toInt(),
                correct: r['correct'] as bool? ?? false,
                score: (r['score'] as num?)?.toInt() ?? 0,
                delayMs: (r['delayMs'] as num?)?.toInt(),
              );
            }).toList(),
            standings: rawStandings.map((e) {
              final s = Map<String, dynamic>.from(e as Map);
              return RoundStanding(
                rank: (s['rank'] as num?)?.toInt() ?? 0,
                userId: s['userId'] as String? ?? '',
                firstName: s['firstName'] as String? ?? '',
                score: (s['score'] as num?)?.toInt() ?? 0,
              );
            }).toList(),
          ),
        );
      } catch (e) {
        debugPrint('round_end parse error: $e');
      }
    });

    socket.on('game_over', (data) {
      try {
        final d = _asMap(data);
        final rawScoreboard = d['scoreboard'] as List? ?? const [];
        _gameOver.add(
          rawScoreboard
              .map(
                (e) => ScoreboardEntry.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
        );
      } catch (e) {
        debugPrint('game_over parse error: $e');
      }
    });

    socket.on('player_reaction', (data) {
      try {
        _playerReaction.add(PlayerReaction.fromJson(_asMap(data)));
      } catch (e) {
        debugPrint('player_reaction parse error: $e');
      }
    });

    socket.on('error', (data) {
      final msg = _asMap(data)['message'] as String? ?? 'Xatolik';
      _error.add(msg);
    });

    socket.connect();
    _socket = socket;
  }

  void joinQueue() => _socket?.emit('join_queue');

  void leaveQueue() => _socket?.emit('leave_queue');

  void submitAnswer({required String lobbyId, required int optionIndex}) {
    _socket?.emit('answer', {'lobbyId': lobbyId, 'optionIndex': optionIndex});
  }

  void sendReaction({required String lobbyId, required String emoji}) {
    _socket?.emit('emoji_reaction', {'lobbyId': lobbyId, 'emoji': emoji});
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _queueJoined.close();
    _lobbyJoined.close();
    _playerJoined.close();
    _playerLeft.close();
    _gameStarting.close();
    _roundStart.close();
    _roundAnswerResult.close();
    _lobbyTick.close();
    _roundTick.close();
    _playerAnswered.close();
    _roundEnd.close();
    _gameOver.close();
    _playerReaction.close();
    _error.close();
  }

  static Map<String, dynamic> _asMap(dynamic v) =>
      (v is Map) ? Map<String, dynamic>.from(v) : const {};
}
