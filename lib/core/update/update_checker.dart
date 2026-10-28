import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';

enum UpdateType { optional, forced }

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.storeVersion,
    required this.type,
    this.storeUrl,
  });

  final String currentVersion;
  final String storeVersion;
  final UpdateType type;
  final String? storeUrl;
}

class UpdateChecker {
  static Future<UpdateInfo?> check() async {
    if (kDebugMode) return null;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final upgrader = Upgrader();
      await upgrader.initialize();

      debugPrint('Current version: $currentVersion');
      final storeVersionObj = upgrader.versionInfo?.appStoreVersion;
      debugPrint('Store version: $storeVersionObj');
      if (storeVersionObj == null) return null;

      final storeVersion = storeVersionObj.toString();
      final storeUrl = upgrader.versionInfo?.appStoreListingURL;

      final current = _parse(currentVersion);
      final store = _parse(storeVersion);
      if (current == null || store == null) return null;
      if (!_isNewer(store, current)) return null;

      // Minor or major bump → forced; patch-only → optional.
      final forced = store[0] > current[0] || store[1] > current[1];

      return UpdateInfo(
        currentVersion: currentVersion,
        storeVersion: storeVersion,
        type: forced ? UpdateType.forced : UpdateType.optional,
        storeUrl: storeUrl,
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  static List<int>? _parse(String version) {
    try {
      final parts = version.trim().split('.').map(int.parse).toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts;
    } catch (_) {
      return null;
    }
  }

  static bool _isNewer(List<int> store, List<int> current) {
    for (var i = 0; i < 3; i++) {
      if (store[i] > current[i]) return true;
      if (store[i] < current[i]) return false;
    }
    return false;
  }
}
