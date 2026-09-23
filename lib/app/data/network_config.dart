class NetworkConfig {
  static const String localHostUrl = 'http://localhost:8000';
  static const String devHostUrl =
      'https://28d4-37-110-214-131.ngrok-free.app';
  static const String mainHostUrl = 'https://ai.myteacher.uz';

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
