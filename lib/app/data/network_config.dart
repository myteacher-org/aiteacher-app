import 'package:flutter/foundation.dart';

class NetworkConfig {
  static const String devHostUrl = 'http://192.168.0.2:8000';
  static const String mainHostUrl = 'https://ai.myteacher.uz';

  static String get hostUrl => kDebugMode ? devHostUrl : mainHostUrl;

  // static String get hostUrl => mainHostUrl;

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
