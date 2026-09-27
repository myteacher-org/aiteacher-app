import 'package:ai_teacher/app/data/network_config.dart';
import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/course/data/course_dtos.dart';
import 'package:ai_teacher/core/course/presentation/courses_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/courses/widget/course_info_sheet.dart';
import 'package:ai_teacher/ui/courses/widget/my_mentor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── Static testimonial data ──────────────────────────────────────────────────

class _TData {
  const _TData({
    required this.name,
    required this.result,
    required this.duration,
    required this.text,
    required this.initial,
    required this.color,
  });

  final String name;
  final String result;
  final String duration;
  final String text;
  final String initial;
  final Color color;
}

List<_TData> _kTestimonials(AppLocalizations l10n) => [
  _TData(
    name: 'Aziz T.',
    result: l10n.coursesTestimonial1Result,
    duration: l10n.coursesTestimonial1Duration,
    text: l10n.coursesTestimonial1Text,
    initial: 'A',
    color: const Color(0xFF818CF8),
  ),
  _TData(
    name: 'Malika R.',
    result: l10n.coursesTestimonial2Result,
    duration: l10n.coursesTestimonial2Duration,
    text: l10n.coursesTestimonial2Text,
    initial: 'M',
    color: const Color(0xFFF472B6),
  ),
  _TData(
    name: 'Jasur K.',
    result: l10n.coursesTestimonial3Result,
    duration: l10n.coursesTestimonial3Duration,
    text: l10n.coursesTestimonial3Text,
    initial: 'J',
    color: const Color(0xFFFBBF24),
  ),
];

List<_TData> _kPlatformTestimonials(AppLocalizations l10n) => [
  _TData(
    name: 'Dilnoza S.',
    result: l10n.coursesPlatformTestimonial1Result,
    duration: l10n.coursesPlatformTestimonial1Duration,
    text: l10n.coursesPlatformTestimonial1Text,
    initial: 'D',
    color: const Color(0xFF8B5CF6),
  ),
  _TData(
    name: 'Sardor M.',
    result: l10n.coursesPlatformTestimonial2Result,
    duration: l10n.coursesPlatformTestimonial2Duration,
    text: l10n.coursesPlatformTestimonial2Text,
    initial: 'S',
    color: const Color(0xFF6366F1),
  ),
  _TData(
    name: 'Feruza A.',
    result: l10n.coursesPlatformTestimonial3Result,
    duration: l10n.coursesPlatformTestimonial3Duration,
    text: l10n.coursesPlatformTestimonial3Text,
    initial: 'F',
    color: const Color(0xFFA78BFA),
  ),
];

// ─── Main page ────────────────────────────────────────────────────────────────

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(coursesControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.coursesLoadError,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(coursesControllerProvider.notifier).refresh(),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () =>
              ref.read(coursesControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
                  child: Text(
                    l10n.coursesTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    l10n.coursesSubtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // ── My enrolled courses ─────────────────────────────────────
              if (state.mine.isNotEmpty) ...[
                _SectionLabel(title: l10n.coursesMyEnrolledSectionTitle),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: state.mine.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _EnrolledCourseCard(course: state.mine[i]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
              // ── My mentor ────────────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: MyMentorCard(),
                ),
              ),
              // ── Teacher mentoring hero ──────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _TeacherHeroSection(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // ── Platform section ────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _PlatformSection(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// ─── Animated teacher avatar ──────────────────────────────────────────────────

class _TeacherAvatar extends StatefulWidget {
  const _TeacherAvatar();

  @override
  State<_TeacherAvatar> createState() => _TeacherAvatarState();
}

class _TeacherAvatarState extends State<_TeacherAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final Animation<double> _float = Tween<double>(
    begin: -5.0,
    end: 5.0,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _float.value), child: child),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.28),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('👨‍🏫', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

// ─── Teacher hero section ─────────────────────────────────────────────────────

class _TeacherHeroSection extends StatelessWidget {
  const _TeacherHeroSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final testimonials = _kTestimonials(l10n);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.09),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: badge + avatar ───────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: AppColors.primaryLight,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.coursesMentorshipProgramBadge,
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.coursesTeacherHeroTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _TeacherAvatar(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.coursesTeacherHeroSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                // ── Features ─────────────────────────────────────────────
                _DarkFeature(
                  icon: Icons.calendar_month_rounded,
                  text: l10n.coursesTeacherFeature1,
                ),
                const SizedBox(height: 11),
                _DarkFeature(
                  icon: Icons.route_rounded,
                  text: l10n.coursesTeacherFeature2,
                ),
                const SizedBox(height: 11),
                _DarkFeature(
                  icon: Icons.mark_chat_read_rounded,
                  text: l10n.coursesTeacherFeature3,
                ),
                const SizedBox(height: 11),
                _DarkFeature(
                  icon: Icons.chat_bubble_rounded,
                  text: l10n.coursesTeacherFeature4,
                ),
                const SizedBox(height: 11),
                _DarkFeature(
                  icon: Icons.laptop_rounded,
                  text: l10n.coursesTeacherFeature5,
                ),
                const SizedBox(height: 26),
                // ── Testimonials ─────────────────────────────────────────
                _RowDivider(label: l10n.coursesTestimonialsDividerLabel),
                const SizedBox(height: 16),
                SizedBox(
                  height: 152,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: testimonials.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) =>
                        _TestimonialCard(data: testimonials[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkFeature extends StatelessWidget {
  const _DarkFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        ),
      ],
    );
  }
}

// ─── Testimonial card ─────────────────────────────────────────────────────────

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.data});

  final _TData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Icon(
                Icons.star_rounded,
                size: 13,
                color: Color(0xFFFBBF24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              '"${data.text}"',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: data.color.withValues(alpha: 0.35)),
                ),
                alignment: Alignment.center,
                child: Text(
                  data.initial,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${data.result} · ${data.duration}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Platform animated avatar ─────────────────────────────────────────────────

class _PlatformAvatar extends StatefulWidget {
  const _PlatformAvatar();

  @override
  State<_PlatformAvatar> createState() => _PlatformAvatarState();
}

class _PlatformAvatarState extends State<_PlatformAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat(reverse: true);

  late final Animation<double> _float = Tween<double>(
    begin: -5.0,
    end: 5.0,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _float.value), child: child),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('📱', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

// ─── Platform section ─────────────────────────────────────────────────────────

class _PlatformSection extends StatelessWidget {
  const _PlatformSection();

  static const _violet = Color(0xFF7C3AED);
  static const _violetLight = Color(0xFFA78BFA);
  static const _indigo = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final testimonials = _kPlatformTestimonials(l10n);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A1A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Decorative glow circles
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _violet.withValues(alpha: 0.09),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _indigo.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: badge + avatar ───────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _violet.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _violet.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 12,
                                  color: _violetLight,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.coursesPlatformBadge,
                                  style: const TextStyle(
                                    color: _violetLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.coursesPlatformHeroTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _PlatformAvatar(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.coursesPlatformHeroSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                // ── 2×2 feature grid ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _PlatformFeatureCard(
                        icon: Icons.record_voice_over_rounded,
                        title: l10n.coursesFeatureAiSpeakingTitle,
                        subtitle: l10n.coursesFeatureUnlimitedTalk,
                        color: _violetLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PlatformFeatureCard(
                        icon: Icons.play_circle_rounded,
                        title: l10n.coursesFeatureVideoCoursesTitle,
                        subtitle: l10n.coursesFeatureNativeSpeakers,
                        color: _indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PlatformFeatureCard(
                        icon: Icons.smart_toy_rounded,
                        title: l10n.coursesFeatureAiAssistantTitle,
                        subtitle: l10n.coursesFeature247Response,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PlatformFeatureCard(
                        icon: Icons.quiz_rounded,
                        title: l10n.coursesFeatureMockTestsTitle,
                        subtitle: l10n.coursesFeatureIeltsCefr,
                        color: const Color(0xFFF472B6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // ── CEFR level chips ─────────────────────────────────────
                _RowDivider(label: l10n.coursesLevelsDividerLabel),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final lvl in [
                        'A1',
                        'A2',
                        'B1',
                        'B2',
                        'C1',
                        'C2',
                      ]) ...[_LevelChip(level: lvl), const SizedBox(width: 8)],
                    ],
                  ),
                ),
                // ── Testimonials ─────────────────────────────────────────
                const SizedBox(height: 26),
                _RowDivider(label: l10n.coursesTestimonialsDividerLabel),
                const SizedBox(height: 16),
                SizedBox(
                  height: 152,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: testimonials.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) =>
                        _TestimonialCard(data: testimonials[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformFeatureCard extends StatelessWidget {
  const _PlatformFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: Color(0xFFA78BFA),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Enrolled course card ─────────────────────────────────────────────────────

class _EnrolledCourseCard extends StatelessWidget {
  const _EnrolledCourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => CourseInfoSheet.showEnrolled(
            context,
            course: course,
            onNavigate: () =>
                context.pushNamed(AppRoute.courseWeb.name, extra: course),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CourseCover(coverUrl: course.coverUrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                    if ((course.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        course.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Course cover ─────────────────────────────────────────────────────────────

class _CourseCover extends StatelessWidget {
  const _CourseCover({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final fullUrl = coverUrl != null
        ? '${NetworkConfig.hostUrl}/public/$coverUrl'
        : null;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: 160,
        child: fullUrl != null
            ? Image.network(
                fullUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.primary.withValues(alpha: 0.08),
    alignment: Alignment.center,
    child: Icon(
      Icons.school_rounded,
      size: 48,
      color: AppColors.primary.withValues(alpha: 0.4),
    ),
  );
}
