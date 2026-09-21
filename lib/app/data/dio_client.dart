import 'package:ai_teacher/app/data/auth_interceptor.dart';
import 'package:ai_teacher/app/data/cache_service.dart';
import 'package:ai_teacher/app/data/network_config.dart';
import 'package:ai_teacher/app/data/socket_reconnect_coordinator.dart';
import 'package:ai_teacher/app/router/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

final _dioOptions = BaseOptions(
  baseUrl: NetworkConfig.baseApiUrl,
  headers: const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Debug builds point at an ngrok tunnel during local backend testing —
    // without this header ngrok's free-tier interstitial HTML page comes
    // back instead of the real API response. Harmless against production.
    'ngrok-skip-browser-warning': 'true',
  },
);

TalkerDioLogger _buildLogger() => TalkerDioLogger(
  settings: const TalkerDioLoggerSettings(
    printRequestHeaders: true,
    printResponseHeaders: false,
    printRequestData: true,
    printResponseData: true,
    printResponseMessage: true,
  ),
);

final _refreshDioProvider = Provider<Dio>((ref) {
  return Dio(_dioOptions);
});

/// Auth-aware Dio for endpoints that require a bearer token. Triggers refresh
/// on 401 via [AuthInterceptor].
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_dioOptions);

  dio.interceptors.add(
    AuthInterceptor(
      cache: ref.watch(cacheServiceProvider),
      refreshDio: ref.watch(_refreshDioProvider),
      onUnauthorized: () {
        try {
          ref.read(routerProvider).goNamed(AppRoute.login.name);
        } catch (_) {
          // Router not ready yet — ignore.
        }
      },
      onTokenRefreshed: () {
        try {
          ref.read(socketReconnectCoordinatorProvider).reconnectAll();
        } catch (_) {
          // Nothing to reconnect yet (e.g. refresh happened before any
          // socket provider was ever read) — ignore.
        }
      },
    ),
  );

  dio.interceptors.add(_buildLogger());

  return dio;
});

/// Public Dio for endpoints that should never carry an access token (sign-in,
/// sign-up, OTP). Skips [AuthInterceptor] so a stale token can't trigger a
/// refresh loop on 401 responses.
final unauthDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_dioOptions);
  dio.interceptors.add(_buildLogger());
  return dio;
});
