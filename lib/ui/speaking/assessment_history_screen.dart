import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/speaking/data/conversation_summary.dart';
import 'package:ai_teacher/core/speaking/data/speaking_repository.dart';
import 'package:ai_teacher/core/speaking/presentation/assessment_history_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AssessmentHistoryScreen extends ConsumerStatefulWidget {
  const AssessmentHistoryScreen({super.key});

  @override
  ConsumerState<AssessmentHistoryScreen> createState() =>
      _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState
    extends ConsumerState<AssessmentHistoryScreen> {
  String? _openingId;

  Future<void> _onOpen(ConversationSummary item) async {
    final l10n = AppLocalizations.of(context);
    if (_openingId != null) return;
    if (!item.hasReport) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.speakingScreenNoReportYet)));
      return;
    }
    setState(() => _openingId = item.id);
    try {
      final report = await ref
          .read(speakingRepositoryProvider)
          .getConversationReport(item.id);
      if (!mounted) return;
      if (report == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.speakingScreenReportNotFound)),
          );
        return;
      }
      context.pushNamed(AppRoute.speakingReport.name, extra: report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.speakingScreenReportLoadFailed)),
        );
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(assessmentHistoryProvider);
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
              _TopBar(onBack: () => _onBack(context)),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(assessmentHistoryProvider);
                    await ref.read(assessmentHistoryProvider.future);
                  },
                  child: historyAsync.when(
                    loading: () => const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                    error: (_, _) =>
                        _Empty(text: l10n.speakingScreenHistoryLoadFailed),
                    data: (items) {
                      if (items.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            _Empty(text: l10n.speakingScreenHistoryEmpty),
                          ],
                        );
                      }
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _HistoryItem(
                            item: item,
                            loading: _openingId == item.id,
                            onTap: () => _onOpen(item),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.main.name);
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF6B7A9F),
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.speakingScreenHistoryTitle,
            style: const TextStyle(
              color: Color(0xFF0D1B4B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.item,
    required this.loading,
    required this.onTap,
  });

  final ConversationSummary item;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tappable = item.hasReport;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0D1B4B),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !item.hasReport
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  !item.hasReport
                      ? Icons.history_rounded
                      : Icons.assignment_turned_in_rounded,
                  color: !item.hasReport
                      ? const Color(0xFF64748B)
                      : const Color(0xFF15803D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDate(item.updatedAt.toLocal(), l10n),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusChip(
                          label: !item.hasReport
                              ? (item.readyForAnalyze
                                    ? l10n.speakingScreenStatusReady
                                    : l10n.speakingScreenStatusNotEnough)
                              : l10n.speakingScreenStatusFullReport,
                          background: !item.hasReport
                              ? (item.readyForAnalyze
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFF1F5F9))
                              : const Color(0xFFDCFCE7),
                          textColor: !item.hasReport
                              ? (item.readyForAnalyze
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF64748B))
                              : const Color(0xFF15803D),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                )
              else if (tappable)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB7BCC8),
                  size: 22,
                )
              else
                const SizedBox(width: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A8580),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

List<String> _monthNames(AppLocalizations l10n) => [
  l10n.speakingScreenMonthJanuary,
  l10n.speakingScreenMonthFebruary,
  l10n.speakingScreenMonthMarch,
  l10n.speakingScreenMonthApril,
  l10n.speakingScreenMonthMay,
  l10n.speakingScreenMonthJune,
  l10n.speakingScreenMonthJuly,
  l10n.speakingScreenMonthAugust,
  l10n.speakingScreenMonthSeptember,
  l10n.speakingScreenMonthOctober,
  l10n.speakingScreenMonthNovember,
  l10n.speakingScreenMonthDecember,
];

String _formatDate(DateTime d, AppLocalizations l10n) {
  final months = _monthNames(l10n);
  final month = (d.month >= 1 && d.month <= 12) ? months[d.month - 1] : '';
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day}-$month ${d.year} · $h:$m';
}
