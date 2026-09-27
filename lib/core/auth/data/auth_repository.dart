import 'package:ai_teacher/app/data/cache_service.dart';
import 'package:ai_teacher/app/data/dio_client.dart';
import 'package:ai_teacher/core/auth/data/auth_dtos.dart';
import 'package:ai_teacher/core/auth/data/auth_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(unauthDioProvider),
    cache: ref.watch(cacheServiceProvider),
  );
});

class AuthRepository {
  AuthRepository({required this.dio, required this.cache});

  final Dio dio;
  final CacheService cache;

  /// Returns whether an account with this phone number or email exists, so
  /// the app can choose between the sign-in and sign-up flow.
  Future<bool> exists({String? phoneNumber, String? email}) async {
    assert(
      (phoneNumber != null) ^ (email != null),
      'Provide exactly one of phoneNumber or email',
    );
    try {
      final response = await dio.post<Map<String, dynamic>>(
        phoneNumber != null ? 'auth/exists/phone' : 'auth/exists/email',
        data: {'phoneNumber': ?phoneNumber, 'email': ?email},
      );
      return response.data?['exists'] == true;
    } on DioException catch (e) {
      throw AuthException.fromDio(e);
    }
  }

  Future<OtpRequestResult> requestOtp({
    String? phoneNumber,
    String? email,
  }) async {
    assert(
      (phoneNumber != null) ^ (email != null),
      'Provide exactly one of phoneNumber or email',
    );
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'auth/otp/request',
        data: {'phoneNumber': ?phoneNumber, 'email': ?email},
      );
      return OtpRequestResult.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw AuthException.fromDio(e);
    }
  }

  Future<OtpVerifyResult> verifyOtp({
    String? phoneNumber,
    String? email,
    required String code,
  }) async {
    assert(
      (phoneNumber != null) ^ (email != null),
      'Provide exactly one of phoneNumber or email',
    );
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'auth/otp/verify',
        data: {'phoneNumber': ?phoneNumber, 'email': ?email, 'code': code},
      );
      return OtpVerifyResult.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw AuthException.fromDio(e);
    }
  }

  Future<AuthTokens> signUp({
    required RegistrationDraft draft,
    required String verificationToken,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'auth/sign-up',
        data: {
          'firstName': draft.firstName,
          'lastName': draft.lastName,
          'phoneNumber': ?draft.phoneNumber,
          'email': ?draft.email,
          'password': draft.password,
          'verificationToken': verificationToken,
          'goal': ?draft.goal,
          'level': ?draft.level,
          'dailyTime': ?draft.dailyTime,
          'referralCode': ?draft.referralCode,
        },
      );
      final tokens = AuthTokens.fromJson(response.data ?? const {});
      await _persist(tokens);
      return tokens;
    } on DioException catch (e) {
      throw AuthException.fromDio(e);
    }
  }

  Future<AuthTokens> signIn({
    String? phoneNumber,
    String? email,
    required String password,
  }) async {
    assert(
      (phoneNumber != null) ^ (email != null),
      'Provide exactly one of phoneNumber or email',
    );
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'auth/sign-in',
        data: {
          'phoneNumber': ?phoneNumber,
          'email': ?email,
          'password': password,
        },
      );
      final tokens = AuthTokens.fromJson(response.data ?? const {});
      await _persist(tokens);
      return tokens;
    } on DioException catch (e) {
      throw AuthException.fromDio(e, fallback: 'Login yoki parol xato');
    }
  }

  Future<void> signOut() => cache.clear();

  Future<void> _persist(AuthTokens tokens) async {
    if (tokens.accessToken.isNotEmpty) {
      await cache.setAccessToken(tokens.accessToken);
    }
    if (tokens.refreshToken.isNotEmpty) {
      await cache.setRefreshToken(tokens.refreshToken);
    }
  }
}
