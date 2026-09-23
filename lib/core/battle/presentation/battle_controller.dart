import 'dart:async';

import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:ai_teacher/core/battle/data/battle_socket.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BattleController extends AutoDisposeNotifier<BattleState> {
  @override
  BattleState build() {
    final socket = ref.watch(battleSocketProvider);
    socket.connect();

    final subs = <StreamSubscription>[
      socket.onQueueJoined.listen((lobbyId) {
        state = state.copyWith(
          phase: BattlePhase.queuing,
          lobbyId: lobbyId,
          error: null,
        );
      }),
      socket.onLobbyJoined.listen((e) {
        state = state.copyWith(lobbyId: e.lobbyId, lobbyPlayers: e.players);
      }),
      socket.onPlayerJoined.listen((player) {
        state = state.copyWith(lobbyPlayers: [...state.lobbyPlayers, player]);
      }),
      socket.onPlayerLeft.listen((userId) {
        state = state.copyWith(
          lobbyPlayers: state.lobbyPlayers
              .where((p) => p.userId != userId)
              .toList(),
        );
      }),
      socket.onGameStarting.listen((e) {
        final previousPlayers = {
          for (final player in state.lobbyPlayers) player.userId: player,
        };
        state = state.copyWith(
          phase: BattlePhase.playing,
          lobbyPlayers: e.players.map((player) {
            final previous = previousPlayers[player.userId];
            return LobbyPlayer(
              userId: player.userId,
              firstName: player.firstName,
              avatar: player.avatar ?? previous?.avatar,
              score: player.score,
            );
          }).toList(),
          totalRounds: e.totalRounds,
        );
      }),
      socket.onLobbyTick.listen((remaining) {
        state = state.copyWith(lobbyTick: remaining);
      }),
      socket.onRoundStart.listen((e) {
        state = state.copyWith(
          currentRound: e.round,
          totalRounds: e.total,
          roundTick: e.timeSeconds,
          word: e.word,
          options: e.options,
          selectedOptionIndex: null,
          roundAnswerResult: null,
          roundEnd: null,
          roundPlayerAnswers: [],
        );
      }),
      socket.onRoundTick.listen((remaining) {
        state = state.copyWith(roundTick: remaining);
      }),
      socket.onRoundAnswerResult.listen((r) {
        state = state.copyWith(roundAnswerResult: r);
      }),
      socket.onPlayerAnswered.listen((payload) {
        // Update the answering player's score live as they answer.
        final updatedPlayers = state.lobbyPlayers.map((p) {
          return p.userId == payload.userId ? p.withScore(payload.score) : p;
        }).toList();
        state = state.copyWith(
          lobbyPlayers: updatedPlayers,
          roundPlayerAnswers: [...state.roundPlayerAnswers, payload],
        );
      }),
      socket.onRoundEnd.listen((data) {
        // Sync scores + order from authoritative standings.
        final standingMap = {for (final s in data.standings) s.userId: s};
        final updatedPlayers = state.lobbyPlayers.map((p) {
          final s = standingMap[p.userId];
          return s != null ? p.withScore(s.score) : p;
        }).toList();
        state = state.copyWith(lobbyPlayers: updatedPlayers, roundEnd: data);
      }),
      socket.onGameOver.listen((scoreboard) {
        final lobbyAvatars = {
          for (final player in state.lobbyPlayers) player.userId: player.avatar,
        };
        state = state.copyWith(
          phase: BattlePhase.gameOver,
          scoreboard: scoreboard.map((entry) {
            final avatar = entry.avatar ?? lobbyAvatars[entry.userId];
            if (avatar == entry.avatar) return entry;
            return ScoreboardEntry(
              rank: entry.rank,
              userId: entry.userId,
              firstName: entry.firstName,
              avatar: avatar,
              score: entry.score,
              sumDelayMs: entry.sumDelayMs,
              answers: entry.answers,
            );
          }).toList(),
        );
      }),
      socket.onError.listen((msg) {
        state = state.copyWith(error: msg);
      }),
    ];

    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });

    return BattleState.initial;
  }

  void joinQueue() {
    final myUserId = ref.read(currentUserProvider).valueOrNull?.id;
    state = state.copyWith(
      phase: BattlePhase.queuing,
      myUserId: myUserId,
      error: null,
    );
    ref.read(battleSocketProvider).joinQueue();
  }

  void leaveQueue() {
    ref.read(battleSocketProvider).leaveQueue();
    state = BattleState.initial;
  }

  void submitAnswer(int optionIndex) {
    final lobbyId = state.lobbyId;
    if (lobbyId == null || state.selectedOptionIndex != null) return;
    state = state.copyWith(selectedOptionIndex: optionIndex);
    ref
        .read(battleSocketProvider)
        .submitAnswer(lobbyId: lobbyId, optionIndex: optionIndex);
  }

  /// Live reactions from either player, forwarded straight from the socket.
  Stream<PlayerReaction> get reactions =>
      ref.read(battleSocketProvider).onPlayerReaction;

  void sendReaction(String emoji) {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return;
    ref.read(battleSocketProvider).sendReaction(lobbyId: lobbyId, emoji: emoji);
  }

  void reset() {
    state = BattleState.initial;
  }
}

final battleControllerProvider =
    AutoDisposeNotifierProvider<BattleController, BattleState>(
      BattleController.new,
    );
