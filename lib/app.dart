import 'dart:async';
import 'dart:io' show Platform;

import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_theme.dart';
import 'package:ai_teacher/core/locale/presentation/locale_controller.dart';
import 'package:ai_teacher/core/auth/data/auth_session.dart';
import 'package:ai_teacher/core/promo/data/promo_socket.dart';
import 'package:ai_teacher/core/purchases/presentation/purchases_controller.dart';
import 'package:ai_teacher/core/session/presentation/session_controller.dart';
import 'package:ai_teacher/core/update/update_checker.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/main/main_screen.dart';
import 'package:ai_teacher/ui/shared/widget/keyboard_dismiss_bar.dart';
import 'package:ai_teacher/ui/shared/widget/update_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<String>? _fcmRefreshSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _fcmRefreshSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final sessionCtrl = ref.read(sessionControllerProvider.notifier);

    // RevenueCat must be configured before anything reads entitlements.
    await ref
        .read(purchasesControllerProvider.notifier)
        .configure(userId: ref.read(authSessionProvider).currentUserId);
    if (!mounted) return;

    // Connect promo socket immediately — no auth required to attempt.
    _connectPromoSocket();

    // Run update check in parallel with FCM bootstrap.
    final updateFuture = UpdateChecker.check();

    String? fcmToken;
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(
        (msg) => _logMessage('foreground', msg),
      );

      // App opened from a notification while it was terminated.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleLaunchMessage('launch:terminated', initial);

      // App brought to foreground by tapping a notification.
      FirebaseMessaging.onMessageOpenedApp.listen(
        (msg) => _handleLaunchMessage('launch:background', msg),
      );

      // iOS needs an APNs token before getToken() can succeed; Android has
      // no APNs round-trip so we call getToken() directly.
      if (Platform.isIOS) {
        String? apnsToken;
        for (var i = 0; i < 10; i++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) {
          debugPrint(
            'APNS token unavailable after 10s — continuing without FCM token.',
          );
        } else {
          fcmToken = await messaging.getToken();
        }
      } else {
        fcmToken = await messaging.getToken();
      }
      debugPrint('FCM token: $fcmToken');

      _fcmRefreshSub?.cancel();
      _fcmRefreshSub = messaging.onTokenRefresh.listen((next) {
        debugPrint('FCM token refreshed: $next');
        sessionCtrl.updateFcmToken(next);
      });
    } catch (e, st) {
      debugPrint('FCM bootstrap failed: $e\n$st');
    }

    if (!mounted) return;
    // Route initial token through the same path as refreshes: cache + sync.
    // When there is no token (failed bootstrap, simulator), still sync so the
    // session is created/attached.
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await sessionCtrl.updateFcmToken(fcmToken);
    } else {
      await sessionCtrl.syncSession();
    }

    final navContext = ref
        .read(routerProvider)
        .routerDelegate
        .navigatorKey
        .currentContext;

    final updateInfo = await updateFuture;
    if (navContext != null && navContext.mounted && updateInfo != null) {
      await UpdateDialog.show(navContext, updateInfo);
    }
  }

  void _connectPromoSocket() {
    try {
      ref.read(promoSocketProvider).connect().catchError((_) {});
    } catch (_) {}
  }

  void _handleLaunchMessage(String source, RemoteMessage msg) {
    _logMessage(source, msg);
    if (!mounted) return;
    final screen = msg.data['screen'] as String?;
    if (screen == null) return;
    final router = ref.read(routerProvider);
    switch (screen) {
      case 'chat':
        router.push(AppRoute.chat.path);
      case 'notifications':
        router.push(AppRoute.notifications.path);
      case 'speaking':
        router.push(AppRoute.speaking.path);
      case 'speaking_history':
        router.push(AppRoute.speakingHistory.path);
      case 'vocabulary':
        router.push(AppRoute.vocabularyTraining.path);
      case 'word_battle':
        router.push(AppRoute.wordBattle.path);
      case 'writing_task':
        router.push(AppRoute.writingTask.path);
      case 'support':
        router.push(AppRoute.support.path);
      case 'home':
        ref.read(pendingMainTabProvider.notifier).state = MainScreen.homeTab;
      case 'courses':
        ref.read(pendingMainTabProvider.notifier).state = MainScreen.coursesTab;
      case 'profile':
        ref.read(pendingMainTabProvider.notifier).state = MainScreen.profileTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: 'AI Teacher',
      theme: AppTheme.light,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          KeyboardDismissBarHost(child: child ?? const SizedBox.shrink()),
    );
  }
}

void _logMessage(String source, RemoteMessage msg) {
  final n = msg.notification;
  final lines = [
    '── FCM [$source] ──────────────────────',
    'messageId : ${msg.messageId ?? '-'}',
    'from      : ${msg.from ?? '-'}',
    'sentTime  : ${msg.sentTime?.toIso8601String() ?? '-'}',
    if (n != null) ...[
      'title     : ${n.title ?? '-'}',
      'body      : ${n.body ?? '-'}',
    ],
    if (msg.data.isNotEmpty)
      ...msg.data.entries.map((e) => 'data.${e.key.padRight(10)}: ${e.value}'),
    '─────────────────────────────────────',
  ];
  debugPrint(lines.join('\n'));
}
