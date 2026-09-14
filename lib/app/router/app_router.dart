import 'package:ai_teacher/app/data/cache_service.dart';
import 'package:ai_teacher/core/auth/data/auth_dtos.dart';
import 'package:ai_teacher/core/course/data/course_dtos.dart';
import 'package:ai_teacher/core/promo/data/promo_dtos.dart';
import 'package:ai_teacher/core/speaking/data/assessment.dart';
import 'package:ai_teacher/ui/auth/login_screen.dart';
import 'package:ai_teacher/ui/auth/otp_screen.dart';
import 'package:ai_teacher/ui/auth/register_screen.dart';
import 'package:ai_teacher/core/timetable/data/timetable_dtos.dart';
import 'package:ai_teacher/ui/battle/battle_screen.dart';
import 'package:ai_teacher/ui/booking/booking_confirm_screen.dart';
import 'package:ai_teacher/ui/booking/mentor_browse_screen.dart';
import 'package:ai_teacher/ui/booking/slot_picker_screen.dart';
import 'package:ai_teacher/ui/call/call_screen.dart';
import 'package:ai_teacher/ui/chat/chat_screen.dart';
import 'package:ai_teacher/ui/courses/course_web_screen.dart';
import 'package:ai_teacher/ui/dictionary/dictionary_explanatory_screen.dart';
import 'package:ai_teacher/ui/dictionary/dictionary_home_screen.dart';
import 'package:ai_teacher/ui/dictionary/dictionary_saved_words_screen.dart';
import 'package:ai_teacher/ui/dictionary/dictionary_search_screen.dart';
import 'package:ai_teacher/ui/dictionary/dictionary_stats_screen.dart';
import 'package:ai_teacher/ui/language/language_select_screen.dart';
import 'package:ai_teacher/ui/lessons/upcoming_lessons_screen.dart';
import 'package:ai_teacher/ui/main/main_screen.dart';
import 'package:ai_teacher/ui/notifications/notifications_screen.dart';
import 'package:ai_teacher/ui/onboarding/onboarding_screen.dart';
import 'package:ai_teacher/ui/promo/promo_screen.dart';
import 'package:ai_teacher/ui/speaking/assessment_history_screen.dart';
import 'package:ai_teacher/ui/speaking/speaking_partner_screen.dart';
import 'package:ai_teacher/ui/speaking/speaking_report_screen.dart';
import 'package:ai_teacher/ui/support/support_screen.dart';
import 'package:ai_teacher/ui/survey/survey_data.dart';
import 'package:ai_teacher/ui/survey/survey_screen.dart';
import 'package:ai_teacher/ui/vocabulary/vocabulary_training_screen.dart';
import 'package:ai_teacher/ui/writing_task/writing_task_list_screen.dart';
import 'package:ai_teacher/ui/writing_task/writing_task_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final cache = ref.read(cacheServiceProvider);
  final hasAccessToken = (cache.accessToken ?? '').isNotEmpty;
  final hasLanguage = (cache.languageCode ?? '').isNotEmpty;
  return GoRouter(
    initialLocation: !hasLanguage
        ? AppRoute.languageSelect.path
        : hasAccessToken
        ? AppRoute.main.path
        : AppRoute.onboarding.path,
    routes: [
      GoRoute(
        path: AppRoute.languageSelect.path,
        name: AppRoute.languageSelect.name,
        builder: (context, state) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.survey.path,
        name: AppRoute.survey.name,
        builder: (context, state) => const SurveyScreen(),
      ),
      GoRoute(
        path: AppRoute.register.path,
        name: AppRoute.register.name,
        builder: (context, state) {
          final extra = state.extra;
          return RegisterScreen(
            surveyAnswers: extra is SurveyAnswers ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.otp.path,
        name: AppRoute.otp.name,
        builder: (context, state) {
          if (state.extra is! RegistrationDraft) {
            return const RegisterScreen();
          }
          return OtpScreen(draft: state.extra as RegistrationDraft);
        },
      ),
      GoRoute(
        path: AppRoute.main.path,
        name: AppRoute.main.name,
        builder: (context, state) {
          final tab = state.extra is int
              ? state.extra as int
              : MainScreen.homeTab;
          return MainScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: AppRoute.speaking.path,
        name: AppRoute.speaking.name,
        builder: (context, state) => const SpeakingPartnerScreen(),
      ),
      GoRoute(
        path: AppRoute.speakingReport.path,
        name: AppRoute.speakingReport.name,
        builder: (context, state) {
          final assessment = state.extra is Assessment
              ? state.extra as Assessment
              : kSampleAssessment;
          return SpeakingReportScreen(assessment: assessment);
        },
      ),
      GoRoute(
        path: AppRoute.chat.path,
        name: AppRoute.chat.name,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoute.call.path,
        name: AppRoute.call.name,
        builder: (context, state) => const CallScreen(),
      ),
      GoRoute(
        path: AppRoute.speakingHistory.path,
        name: AppRoute.speakingHistory.name,
        builder: (context, state) => const AssessmentHistoryScreen(),
      ),
      GoRoute(
        path: AppRoute.vocabularyTraining.path,
        name: AppRoute.vocabularyTraining.name,
        builder: (context, state) => const VocabularyTrainingScreen(),
      ),
      GoRoute(
        path: AppRoute.wordBattle.path,
        name: AppRoute.wordBattle.name,
        builder: (context, state) => const BattleScreen(),
      ),
      GoRoute(
        path: AppRoute.courseWeb.path,
        name: AppRoute.courseWeb.name,
        builder: (context, state) {
          final course = state.extra as Course;
          return CourseWebScreen(
            title: course.title,
            url: course.url,
            login: course.login,
            password: course.password,
            isDemo: course.isDemo,
            courseId: course.id,
          );
        },
      ),
      GoRoute(
        path: AppRoute.notifications.path,
        name: AppRoute.notifications.name,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoute.mentorBrowse.path,
        name: AppRoute.mentorBrowse.name,
        builder: (context, state) => const MentorBrowseScreen(),
      ),
      GoRoute(
        path: AppRoute.slotPicker.path,
        name: AppRoute.slotPicker.name,
        builder: (context, state) =>
            SlotPickerScreen(mentor: state.extra as BookableMentor),
      ),
      GoRoute(
        path: AppRoute.bookingConfirm.path,
        name: AppRoute.bookingConfirm.name,
        builder: (context, state) =>
            BookingConfirmScreen(selection: state.extra as BookingSelection),
      ),
      GoRoute(
        path: AppRoute.upcomingLessons.path,
        name: AppRoute.upcomingLessons.name,
        builder: (context, state) => const UpcomingLessonsScreen(),
      ),
      GoRoute(
        path: AppRoute.support.path,
        name: AppRoute.support.name,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoute.writingTask.path,
        name: AppRoute.writingTask.name,
        builder: (context, state) => const WritingTaskListScreen(),
      ),
      GoRoute(
        path: AppRoute.writingTaskDetail.path,
        name: AppRoute.writingTaskDetail.name,
        builder: (context, state) =>
            WritingTaskScreen(taskId: state.extra as String?),
      ),
      GoRoute(
        path: AppRoute.dictionary.path,
        name: AppRoute.dictionary.name,
        builder: (context, state) => const DictionaryHomeScreen(),
      ),
      GoRoute(
        path: AppRoute.dictionarySearch.path,
        name: AppRoute.dictionarySearch.name,
        builder: (context, state) => const DictionarySearchScreen(),
      ),
      GoRoute(
        path: AppRoute.dictionaryExplanatory.path,
        name: AppRoute.dictionaryExplanatory.name,
        builder: (context, state) => const DictionaryExplanatoryScreen(),
      ),
      GoRoute(
        path: AppRoute.dictionarySavedWords.path,
        name: AppRoute.dictionarySavedWords.name,
        builder: (context, state) => const DictionarySavedWordsScreen(),
      ),
      GoRoute(
        path: AppRoute.dictionaryStats.path,
        name: AppRoute.dictionaryStats.name,
        builder: (context, state) => const DictionaryStatsScreen(),
      ),
      GoRoute(
        path: AppRoute.promo.path,
        name: AppRoute.promo.name,
        builder: (context, state) =>
            PromoScreen(promo: state.extra as PromoEvent),
      ),
    ],
  );
});

enum AppRoute {
  languageSelect('/language-select'),
  onboarding('/'),
  survey('/survey'),
  register('/register'),
  login('/login'),
  otp('/otp'),
  main('/main'),
  speaking('/speaking'),
  speakingReport('/speaking-report'),
  speakingHistory('/speaking-history'),
  vocabularyTraining('/vocabulary-training'),
  wordBattle('/word-battle'),
  courseWeb('/course-web'),
  mentorBrowse('/booking/mentors'),
  slotPicker('/booking/slots'),
  bookingConfirm('/booking/confirm'),
  upcomingLessons('/lessons/upcoming'),
  support('/support'),
  writingTask('/writing-task'),
  writingTaskDetail('/writing-task/detail'),
  dictionary('/dictionary'),
  dictionarySearch('/dictionary/search'),
  dictionaryExplanatory('/dictionary/explanatory'),
  dictionarySavedWords('/dictionary/saved'),
  dictionaryStats('/dictionary/stats'),
  notifications('/notifications'),
  chat('/chat'),
  call('/call'),
  promo('/promo');

  const AppRoute(this.path);

  final String path;
}
