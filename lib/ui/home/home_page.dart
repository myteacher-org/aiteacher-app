import 'package:ai_teacher/app/data/cache_service.dart';
import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/cashback/cashback_info_sheet.dart';
import 'package:ai_teacher/ui/home/widget/cashback_card.dart';
import 'package:ai_teacher/ui/home/widget/dictionary_card.dart';
import 'package:ai_teacher/ui/home/widget/home_header.dart';
import 'package:ai_teacher/ui/home/widget/live_card.dart';
import 'package:ai_teacher/ui/home/widget/mini_cards_row.dart';
import 'package:ai_teacher/ui/home/widget/page_dots.dart';
import 'package:ai_teacher/ui/home/widget/radar_card.dart';
import 'package:ai_teacher/ui/home/widget/section_header.dart';
import 'package:ai_teacher/ui/home/widget/stats_card.dart';
import 'package:ai_teacher/ui/home/widget/streak_card.dart';
import 'package:ai_teacher/ui/home/widget/writing_task_card.dart';
import 'package:ai_teacher/ui/shared/widget/feature_intro_overlay.dart';
import 'package:ai_teacher/ui/streak/streak_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _speakingKey = GlobalKey();
  final _vocabKey = GlobalKey();
  final _battleKey = GlobalKey();
  final _writingTaskKey = GlobalKey();
  final _cashbackKey = GlobalKey();

  OverlayEntry? _introEntry;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _introEntry?.remove();
    _introEntry = null;
    super.dispose();
  }

  void _maybeShowIntro() {
    if (!mounted || _introEntry != null) return;

    final l10n = AppLocalizations.of(context);

    final steps = [
      IntroStep(
        targetKey: _speakingKey,
        title: l10n.homeIntroSpeakingTitle,
        description: l10n.homeIntroSpeakingDescription,
        icon: Icons.record_voice_over_rounded,
        iconColor: AppColors.primary,
        iconBackground: AppColors.primarySubtle,
      ),
      IntroStep(
        targetKey: _vocabKey,
        title: l10n.homeIntroVocabTitle,
        description: l10n.homeIntroVocabDescription,
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBackground: const Color(0xFFEFF6FF),
      ),
      IntroStep(
        targetKey: _battleKey,
        title: l10n.homeIntroBattleTitle,
        description: l10n.homeIntroBattleDescription,
        icon: Icons.sports_esports_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBackground: const Color(0xFFFEF2F2),
      ),
      IntroStep(
        targetKey: _writingTaskKey,
        title: l10n.homeIntroWritingTitle,
        description: l10n.homeIntroWritingDescription,
        icon: Icons.edit_note_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBackground: const Color(0xFFF5F3FF),
      ),
      IntroStep(
        targetKey: _cashbackKey,
        title: l10n.homeIntroCashbackTitle,
        description: l10n.homeIntroCashbackDescription,
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF059669),
        iconBackground: const Color(0xFFECFDF5),
      ),
    ];

    _introEntry = OverlayEntry(
      builder: (_) =>
          FeatureIntroOverlay(steps: steps, onComplete: _finishIntro),
    );

    ref.read(introActiveProvider.notifier).state = true;
    Overlay.of(context).insert(_introEntry!);
  }

  void _finishIntro() {
    _introEntry?.remove();
    _introEntry = null;
    ref.read(introActiveProvider.notifier).state = false;
    ref.read(cacheServiceProvider).setIntroCompleted();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(introTriggerProvider, (_, _) => _maybeShowIntro());

    final l10n = AppLocalizations.of(context);
    final firstName = ref.watch(currentUserProvider).valueOrNull?.firstName;
    final greeting = firstName == null || firstName.isEmpty
        ? l10n.homeGreetingNoName
        : l10n.homeGreetingWithName(firstName);

    return Column(
      children: [
        const HomeHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
                  child: Text(
                    greeting,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const RadarCard(),
                SectionHeader(
                  title: l10n.homeStreakSectionTitle,
                  actionLabel: l10n.homeSeeMoreAction,
                  onAction: () => StreakSheet.show(context),
                ),
                const StreakCard(),
                SectionHeader(title: l10n.homeChatSectionTitle),
                LiveCard(
                  key: _speakingKey,
                  onStart: () => context.pushNamed(AppRoute.speaking.name),
                ),
                MiniCardsRow(vocabularyKey: _vocabKey, battleKey: _battleKey),
                DictionaryCard(
                  onTap: () => context.pushNamed(AppRoute.dictionary.name),
                ),
                SectionHeader(title: l10n.homeWritingSectionTitle),
                WritingTaskCard(
                  key: _writingTaskKey,
                  onStart: () => context.pushNamed(AppRoute.writingTask.name),
                ),
                SectionHeader(
                  title: l10n.homeCashbackSectionTitle,
                  actionLabel: l10n.homeSeeMoreAction,
                  onAction: () => CashbackInfoSheet.show(context),
                ),
                CashbackCard(
                  key: _cashbackKey,
                  onTap: () => CashbackInfoSheet.show(context),
                ),
                SectionHeader(title: l10n.homeGrowthSectionTitle),
                const StatsCard(),
                const PageDots(length: 4, activeIndex: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
