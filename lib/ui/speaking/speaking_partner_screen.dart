import 'dart:async';
import 'dart:math';

import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/core/speaking/data/speaking_repository.dart';
import 'package:ai_teacher/core/speaking/presentation/speaking_controller.dart';
import 'package:ai_teacher/core/student_activity/data/student_activity_socket.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/speaking/widget/partner_avatar.dart';
import 'package:ai_teacher/ui/speaking/widget/partner_controls.dart';
import 'package:ai_teacher/ui/speaking/widget/partner_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpeakingPartnerScreen extends ConsumerStatefulWidget {
  const SpeakingPartnerScreen({super.key});

  @override
  ConsumerState<SpeakingPartnerScreen> createState() =>
      _SpeakingPartnerScreenState();
}

class _SpeakingPartnerScreenState extends ConsumerState<SpeakingPartnerScreen> {
  late final StudentActivitySocket _activitySocket;
  String? _lastErrorShown;

  @override
  void initState() {
    super.initState();
    _activitySocket = ref.read(studentActivitySocketProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _activitySocket.emitSpeakingStart();
    });
  }

  void _onBack() {
    ref.read(speakingControllerProvider.notifier).endConversation();
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.main.name);
    }
  }

  void _onConversationLimitReached() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.speakingScreenLimitTitle)));
    _onBack();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onMicTap() async {
    final controller = ref.read(speakingControllerProvider.notifier);
    final state = ref.read(speakingControllerProvider);
    if (state.phase == SpeakingPhase.recording) {
      await controller.stopAndSend();
    } else if (!state.isBusy) {
      if (state.conversationId == null) {
        final limit = ref.read(conversationLimitProvider).valueOrNull;
        if (limit != null && limit.remaining == 0 && !limit.isUnlimited) {
          _onConversationLimitReached();
          return;
        }
      }
      await controller.startRecording();
    }
  }

  Future<void> _onAnalyzeTap() async {
    final state = ref.read(speakingControllerProvider);
    if (state.analyzingReport) return;
    if (!state.readyForAnalyze || state.conversationId == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.speakingScreenNotEnoughForReport)),
        );
      return;
    }
    final assessment = await ref
        .read(speakingControllerProvider.notifier)
        .requestReport();
    if (!mounted || assessment == null) return;
    context.pushNamed(AppRoute.speakingReport.name, extra: assessment);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SpeakingState>(speakingControllerProvider, (prev, next) {
      final wasLimited = prev?.limitReached ?? false;
      if (!wasLimited && next.limitReached) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(speakingControllerProvider.notifier).dismissLimit();
          ref.read(speakingControllerProvider.notifier).resetError();
          _onConversationLimitReached();
        });
      }
    });

    final state = ref.watch(speakingControllerProvider);

    if (state.phase == SpeakingPhase.error &&
        !state.limitReached &&
        state.error != null &&
        state.error != _lastErrorShown) {
      _lastErrorShown = state.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!)));
        ref.read(speakingControllerProvider.notifier).resetError();
      });
    }

    final limitAsync = ref.watch(conversationLimitProvider);
    final limit = limitAsync.valueOrNull;
    final limitFraction =
        (limit != null && !limit.isUnlimited && limit.effectiveLimit > 0)
        ? (limit.remaining / limit.effectiveLimit).clamp(0.0, 1.0)
        : null;

    final timerLabel = switch (state.phase) {
      SpeakingPhase.recording => _formatDuration(state.elapsed),
      _ => '00:00',
    };

    final l10n = AppLocalizations.of(context);
    final statusText = _statusText(state, l10n);
    final fallback = l10n.speakingScreenFallbackGreeting;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFF5F7FF),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        body: SafeArea(
          child: Column(
            children: [
              PartnerTopBar(timerLabel: timerLabel, onBack: _onBack),
              const SizedBox(height: 24),
              PartnerAvatar(limitFraction: limitFraction),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                  child: _ConversationCard(
                    turns: state.turns,
                    fallback: fallback,
                    statusText: statusText,
                    isProcessing: state.phase == SpeakingPhase.processing,
                  ),
                ),
              ),
              if (state.phase == SpeakingPhase.recording)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WaveVisualizer(amplitudes: state.amplitudes),
                )
              else if (state.phase == SpeakingPhase.processing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _TypingDots(),
                ),
              if (state.readyForAnalyze)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 8),
                  child: _AnalyzeHint(loading: state.analyzingReport),
                ),
              PartnerControls(
                onHistory: () =>
                    context.pushNamed(AppRoute.speakingHistory.name),
                onMic: state.isBusy ? () {} : _onMicTap,
                onMagic: state.analyzingReport ? () {} : _onAnalyzeTap,
                recording: state.phase == SpeakingPhase.recording,
                reportReady: state.readyForAnalyze,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activitySocket.emitSpeakingEnd();
    super.dispose();
  }

  String? _statusText(SpeakingState state, AppLocalizations l10n) {
    switch (state.phase) {
      case SpeakingPhase.recording:
        return l10n.speakingScreenListeningStatus;
      case SpeakingPhase.processing:
        return l10n.speakingScreenProcessingStatus;
      default:
        return null;
    }
  }
}

class _ConversationCard extends StatefulWidget {
  const _ConversationCard({
    required this.turns,
    required this.fallback,
    this.statusText,
    this.isProcessing = false,
  });

  final List<SpeakingTurn> turns;
  final String fallback;
  final String? statusText;
  final bool isProcessing;

  @override
  State<_ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends State<_ConversationCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _ConversationCard old) {
    super.didUpdateWidget(old);
    if (old.turns.length != widget.turns.length ||
        old.statusText != widget.statusText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B4B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: widget.turns.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: widget.isProcessing
                    ? const _RotatingWaitText(large: true)
                    : Text(
                        widget.statusText ?? widget.fallback,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0D1B4B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final turn in widget.turns) _TurnBubble(turn: turn),
                  if (widget.statusText != null) ...[
                    const SizedBox(height: 4),
                    if (widget.isProcessing)
                      const _RotatingWaitText()
                    else
                      Text(
                        widget.statusText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B7A9F),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn});

  final SpeakingTurn turn;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == 'user';
    final maxWidth = MediaQuery.of(context).size.width * 0.7;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 14),
              ),
            ),
            child: Text(
              turn.transcript,
              style: TextStyle(
                color: isUser
                    ? const Color(0xFF1E1B4B)
                    : const Color(0xFF0D1B4B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotatingWaitText extends StatefulWidget {
  const _RotatingWaitText({this.large = false});

  final bool large;

  @override
  State<_RotatingWaitText> createState() => _RotatingWaitTextState();
}

List<String> _waitingTexts(AppLocalizations l10n) => [
  l10n.speakingScreenWaitText1,
  l10n.speakingScreenWaitText2,
  l10n.speakingScreenWaitText3,
  l10n.speakingScreenWaitText4,
  l10n.speakingScreenWaitText5,
  l10n.speakingScreenWaitText6,
  l10n.speakingScreenWaitText7,
  l10n.speakingScreenWaitText8,
  l10n.speakingScreenWaitText9,
  l10n.speakingScreenWaitText10,
  l10n.speakingScreenWaitText11,
  l10n.speakingScreenWaitText12,
  l10n.speakingScreenWaitText13,
  l10n.speakingScreenWaitText14,
  l10n.speakingScreenWaitText15,
  l10n.speakingScreenWaitText16,
  l10n.speakingScreenWaitText17,
  l10n.speakingScreenWaitText18,
  l10n.speakingScreenWaitText19,
  l10n.speakingScreenWaitText20,
  l10n.speakingScreenWaitText21,
  l10n.speakingScreenWaitText22,
  l10n.speakingScreenWaitText23,
  l10n.speakingScreenWaitText24,
  l10n.speakingScreenWaitText25,
  l10n.speakingScreenWaitText26,
  l10n.speakingScreenWaitText27,
  l10n.speakingScreenWaitText28,
  l10n.speakingScreenWaitText29,
  l10n.speakingScreenWaitText30,
];

class _RotatingWaitTextState extends State<_RotatingWaitText> {
  static const int _textsCount = 30;

  int _index = 0;
  late final Timer _timer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _index = _random.nextInt(_textsCount);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      int next;
      do {
        next = _random.nextInt(_textsCount);
      } while (next == _index);
      setState(() => _index = next);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texts = _waitingTexts(l10n);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Text(
        texts[_index],
        key: ValueKey(_index),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.large
              ? const Color(0xFF0D1B4B)
              : const Color(0xFF6B7A9F),
          fontSize: widget.large ? 16 : 13,
          fontStyle: FontStyle.italic,
          fontWeight: widget.large ? FontWeight.w600 : FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              _Dot(progress: _phaseFor(i)),
              if (i < 2) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }

  double _phaseFor(int index) {
    final t = (_controller.value + index * (1 / 3)) % 1.0;
    return t < 0.5 ? t * 2 : (1 - t) * 2;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = 0.6 + 0.6 * progress;
    final opacity = 0.35 + 0.65 * progress;
    return Transform.translate(
      offset: Offset(0, -4 * progress),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF1340C4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveVisualizer extends StatelessWidget {
  const _WaveVisualizer({required this.amplitudes});

  final List<double> amplitudes;

  static const int _barCount = 32;
  static const double _height = 48;
  static const double _minBar = 4;

  @override
  Widget build(BuildContext context) {
    final padded = _padded();
    return SizedBox(
      height: _height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < padded.length; i++) ...[
            _Bar(level: padded[i]),
            if (i < padded.length - 1) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }

  List<double> _padded() {
    if (amplitudes.length >= _barCount) {
      return amplitudes.sublist(amplitudes.length - _barCount);
    }
    return [
      ...List<double>.filled(_barCount - amplitudes.length, 0),
      ...amplitudes,
    ];
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final h =
        _WaveVisualizer._minBar +
        (_WaveVisualizer._height - _WaveVisualizer._minBar) * level;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      width: 4,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1340C4), Color(0xFF0D2B8E)],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _AnalyzeHint extends StatelessWidget {
  const _AnalyzeHint({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width - 96;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(160, 360)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1B4B).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1340C4),
                ),
              )
            else
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: Color(0xFF1340C4),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                loading
                    ? l10n.speakingScreenReportPreparing
                    : l10n.speakingScreenReportReadyHint,
                style: const TextStyle(
                  color: Color(0xFF1340C4),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
