import 'dart:async';

import 'package:ai_teacher/app/data/cache_service.dart';
import 'package:ai_teacher/app/modal_queue/modal_queue_notifier.dart';
import 'package:ai_teacher/app/modal_queue/modal_task.dart';
import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/call/presentation/call_controller.dart';
import 'package:ai_teacher/core/cashback/data/cashback_repository.dart';
import 'package:ai_teacher/core/chat/data/chat_socket.dart';
import 'package:ai_teacher/core/chat/presentation/chat_unread_provider.dart';
import 'package:ai_teacher/core/promo/data/promo_dtos.dart';
import 'package:ai_teacher/core/promo/data/promo_socket.dart';
import 'package:ai_teacher/core/streak/presentation/streak_check_in_controller.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:ai_teacher/ui/blog/blog_page.dart' show CommentsPage;
import 'package:ai_teacher/ui/cashback/cashback_earned_toast.dart';
import 'package:ai_teacher/ui/courses/courses_page.dart';
import 'package:ai_teacher/ui/home/home_page.dart';
import 'package:ai_teacher/ui/profile/profile_page.dart';
import 'package:ai_teacher/ui/promo/promo_screen.dart'
    show PromoModal, PromoSheet;
import 'package:ai_teacher/ui/shared/widget/app_bottom_nav.dart';
import 'package:ai_teacher/ui/shared/widget/feature_intro_overlay.dart';
import 'package:ai_teacher/ui/streak/streak_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Set to a tab index to switch the MainScreen tab from anywhere in the app.
/// Consumed and reset to null by MainScreen after switching.
final pendingMainTabProvider = StateProvider<int?>((ref) => null);

/// Set to a route path to push a screen from MainScreen after any promo
/// overlay closes. Consumed and reset to null immediately after pushing.
final pendingNavigationProvider = StateProvider<String?>((ref) => null);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, this.initialTab = MainScreen.homeTab});

  static const int chatTab = 0;
  static const int coursesTab = 1;
  static const int homeTab = 2;
  static const int commentsTab = 3;
  static const int profileTab = 4;

  final int initialTab;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  late int _activeTab = widget.initialTab;

  static const _pages = <Widget>[
    SizedBox.shrink(),
    CoursesPage(),
    HomePage(),
    CommentsPage(),
    ProfilePage(),
  ];

  bool _processingQueue = false;
  bool _cashbackFetched = false;
  bool _introTriggered = false;

  StreamSubscription<dynamic>? _chatUnreadSub;
  StreamSubscription<PromoEvent>? _promoSub;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatUnreadSub?.cancel();
    _promoSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Server-side changes (e.g. a subscription being deactivated) only show
    // up once /users/me is refetched. Refresh on every resume so returning
    // from background always reflects the latest plan/course access.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(currentUserProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(callControllerProvider.notifier).ensureListening();
      _connectChatSocket();
      _listenPromos();

      final streak = await ref
          .read(streakCheckInProvider.notifier)
          .runIfNeeded();
      if (!mounted) return;
      if (streak != null || kDebugMode) {
        final cache = ref.read(cacheServiceProvider);
        final last = cache.lastStreakSheetShownAt;
        final shownToday =
            !kDebugMode &&
            last != null &&
            DateTime.now().difference(last).inHours < 24;
        if (!shownToday) {
          await cache.setLastStreakSheetShownAt(DateTime.now());
          ref.read(modalQueueProvider.notifier).enqueue(StreakTask());
        }
      }

      await _enqueueCashbackIfAny();
      _maybeFireIntroTrigger();
    });
  }

  Future<void> _enqueueCashbackIfAny() async {
    if (_cashbackFetched) return;
    _cashbackFetched = true;
    try {
      final cashbacks = await ref.read(cashbackRepositoryProvider).list();
      final unclaimed = cashbacks.where((c) => !c.claimed).toList();
      if (!mounted || unclaimed.isEmpty) return;
      ref.read(modalQueueProvider.notifier).enqueue(CashbackTask(unclaimed));
    } catch (_) {
      _cashbackFetched = false;
    }
  }

  void _listenPromos() {
    _promoSub?.cancel();
    final socket = ref.read(promoSocketProvider);
    _promoSub = socket.events.listen((event) {
      if (!kDebugMode &&
          ref.read(cacheServiceProvider).shownPromoIds.contains(event.id)) {
        return;
      }
      ref.read(modalQueueProvider.notifier).enqueue(PromoTask(event));
    });
    socket.reconnect().catchError((_) {});
  }

  Future<void> _processQueue() async {
    if (_processingQueue) return;
    _processingQueue = true;
    try {
      final notifier = ref.read(modalQueueProvider.notifier);
      while (true) {
        if (!mounted) break;
        final task = notifier.dequeue();
        if (task == null) break;
        try {
          await _showTask(task);
        } catch (_) {
          // Skip failed task and continue with the rest.
        }
      }
    } finally {
      _processingQueue = false;
      _maybeFireIntroTrigger();
    }
  }

  void _maybeFireIntroTrigger() {
    if (_introTriggered || !mounted) return;
    if (!kDebugMode && ref.read(cacheServiceProvider).introCompleted) return;
    if (_processingQueue) return;
    if (ref.read(modalQueueProvider).isNotEmpty) return;
    _introTriggered = true;
    ref.read(introTriggerProvider.notifier).update((v) => v + 1);
  }

  Future<void> _showTask(ModalTask task) async {
    if (!mounted) return;
    switch (task) {
      case PromoTask(:final event):
        switch (event.type) {
          case PromoType.screen:
            await context.push(AppRoute.promo.path, extra: event);
          case PromoType.sheet:
            await PromoSheet.show(context, event);
          case PromoType.modal:
            await PromoModal.show(context, event);
        }
        await ref.read(cacheServiceProvider).addShownPromoId(event.id);
      case CashbackTask(:final unclaimed):
        await CashbackEarnedToast.show(context, unclaimed: unclaimed);
      case StreakTask():
        if (ref.read(introActiveProvider)) return;
        await StreakSheet.show(context);
    }
  }

  void _connectChatSocket() {
    try {
      final socket = ref.read(chatSocketProvider);
      socket
          .connect()
          .then((_) {
            _chatUnreadSub = socket.incoming.listen((_) {
              if (!mounted) return;
              if (!ref.read(chatScreenActiveProvider)) {
                ref.read(chatUnreadProvider.notifier).state = true;
              }
            });
          })
          .catchError((_) {});
    } catch (_) {}
  }

  void _onTabTap(int index) {
    if (index == MainScreen.chatTab) {
      ref.read(chatUnreadProvider.notifier).state = false;
      context.pushNamed(AppRoute.chat.name);
      return;
    }
    if (index == _activeTab) return;
    if (index == MainScreen.coursesTab || index == MainScreen.profileTab) {
      // Plan/course access is gated on activeSubscription; refetch it so a
      // subscription deactivated server-side is reflected as soon as the
      // user opens either tab, not just after logout/login.
      ref.invalidate(currentUserProvider);
    }
    setState(() => _activeTab = index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallState>(callControllerProvider, (prev, next) {
      final wasIdle = prev == null || prev.phase == CallPhase.idle;
      final isLive =
          next.phase == CallPhase.incoming ||
          next.phase == CallPhase.outgoing ||
          next.phase == CallPhase.connecting ||
          next.phase == CallPhase.active;
      if (wasIdle && isLive) {
        context.pushNamed(AppRoute.call.name);
      }
    });

    // Watch the global queue and drain it whenever new items arrive.
    ref.listen<List<ModalTask>>(modalQueueProvider, (_, next) {
      if (next.isNotEmpty) _processQueue();
    });

    ref.listen<int?>(pendingMainTabProvider, (_, tab) {
      if (tab != null) {
        setState(() => _activeTab = tab);
        ref.read(pendingMainTabProvider.notifier).state = null;
      }
    });

    ref.listen<String?>(pendingNavigationProvider, (_, path) {
      if (path != null) {
        ref.read(pendingNavigationProvider.notifier).state = null;
        context.push(path);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _activeTab, children: _pages),
        ),
        bottomNavigationBar: AppBottomNav(
          activeIndex: _activeTab,
          onTap: _onTabTap,
          chatBadge: ref.watch(chatUnreadProvider),
          hideCoursesTab:
              ref
                  .watch(currentUserProvider)
                  .valueOrNull
                  ?.phoneNumber
                  .endsWith('990000000') ??
              false,
        ),
      ),
    );
  }
}
