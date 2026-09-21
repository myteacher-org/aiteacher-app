class NetworkConfig {
  static const String devHostUrl =
      'https://28d4-37-110-214-131.ngrok-free.app';
  static const String mainHostUrl = 'https://ai.myteacher.uz';

  // TEMP: pointed at production at your request (the ngrok dev tunnel keeps
  // going offline). Ask before reverting to the kDebugMode ternary.
  static String get hostUrl => mainHostUrl;

  static String get baseApiUrl => '$hostUrl/api/';

  static String get baseCdnUrl => '$hostUrl/public';

  static String resolveStatic(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final clean = pathOrUrl.replaceFirst(RegExp(r'^/+'), '');
    return '$baseCdnUrl/$clean';
  }
}
