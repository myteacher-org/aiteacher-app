import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService(ref.watch(sharedPreferencesProvider));
});

class CacheService {
  CacheService(this._prefs);

  final SharedPreferences _prefs;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionIdKey = 'session_id';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _webIdentifierKey = 'web_identifier';
  static const String _webPasswordKey = 'web_password';

  String? get accessToken => _prefs.getString(_accessTokenKey);

  Future<bool> setAccessToken(String token) =>
      _prefs.setString(_accessTokenKey, token);

  Future<bool> removeAccessToken() => _prefs.remove(_accessTokenKey);

  String? get refreshToken => _prefs.getString(_refreshTokenKey);

  Future<bool> setRefreshToken(String token) =>
      _prefs.setString(_refreshTokenKey, token);

  Future<bool> removeRefreshToken() => _prefs.remove(_refreshTokenKey);

  Future<void> clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  String? get sessionId => _prefs.getString(_sessionIdKey);

  Future<bool> setSessionId(String id) => _prefs.setString(_sessionIdKey, id);

  Future<bool> removeSessionId() => _prefs.remove(_sessionIdKey);

  String? get fcmToken => _prefs.getString(_fcmTokenKey);

  Future<bool> setFcmToken(String token) =>
      _prefs.setString(_fcmTokenKey, token);

  Future<bool> removeFcmToken() => _prefs.remove(_fcmTokenKey);

  String? get webIdentifier => _prefs.getString(_webIdentifierKey);

  Future<bool> setWebIdentifier(String v) =>
      _prefs.setString(_webIdentifierKey, v);

  String? get webPassword => _prefs.getString(_webPasswordKey);

  Future<bool> setWebPassword(String v) => _prefs.setString(_webPasswordKey, v);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  /// Returns seconds used in the current 24-hour window.
  /// Records the window start date immediately (synchronous memory write) so
  /// it is always present before the first tick saves anything.
  /// If the stored start date is ≥ 24 h old the window resets to 0.
  int getDemoSecondsUsed(String courseId) {
    final startKey = 'demo_start_$courseId';
    final secsKey = 'demo_secs_$courseId';
    final startStr = _prefs.getString(startKey);

    if (startStr == null) {
      // First access — open a new window right now.
      _prefs.setString(startKey, DateTime.now().toIso8601String());
      return 0;
    }

    final startDate = DateTime.tryParse(startStr);
    if (startDate == null ||
        DateTime.now().difference(startDate).inHours >= 24) {
      // Expired — open a fresh window.
      _prefs.setString(startKey, DateTime.now().toIso8601String());
      _prefs.remove(secsKey);
      return 0;
    }

    return _prefs.getInt(secsKey) ?? 0;
  }

  /// Persists elapsed seconds for the current demo window.
  Future<void> setDemoSecondsUsed(String courseId, int seconds) {
    return _prefs.setInt('demo_secs_$courseId', seconds);
  }

  static const String _streakSheetShownAtKey = 'streak_sheet_shown_at';

  DateTime? get lastStreakSheetShownAt {
    final raw = _prefs.getString(_streakSheetShownAtKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> setLastStreakSheetShownAt(DateTime time) =>
      _prefs.setString(_streakSheetShownAtKey, time.toIso8601String());

  static const String _streakCheckInDateKey = 'streak_check_in_date';

  /// The calendar date (`yyyy-MM-dd`, device-local) the daily streak
  /// check-in last succeeded on — lets the client skip calling the
  /// check-in endpoint again on a later app open the same day, instead of
  /// relying entirely on the backend to dedupe repeated hits.
  String? get lastStreakCheckInDate => _prefs.getString(_streakCheckInDateKey);

  Future<void> setLastStreakCheckInDate(String date) =>
      _prefs.setString(_streakCheckInDateKey, date);

  static const String _shownPromoIdsKey = 'shown_promo_ids';

  Set<String> get shownPromoIds =>
      (_prefs.getStringList(_shownPromoIdsKey) ?? const []).toSet();

  Future<void> addShownPromoId(String id) async {
    final ids = shownPromoIds..add(id);
    await _prefs.setStringList(_shownPromoIdsKey, ids.toList());
  }

  static const String _introCompletedKey = 'feature_intro_completed';

  bool get introCompleted => _prefs.getBool(_introCompletedKey) ?? false;

  Future<void> setIntroCompleted() => _prefs.setBool(_introCompletedKey, true);

  static const String _languageCodeKey = 'language_code';

  /// `null` means the user hasn't picked a language yet.
  String? get languageCode => _prefs.getString(_languageCodeKey);

  Future<bool> setLanguageCode(String code) =>
      _prefs.setString(_languageCodeKey, code);

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();
}
