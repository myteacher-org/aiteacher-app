/// RevenueCat project settings. The SDK keys are public (they ship inside
/// the app binary), so they live in source. While a key is empty the SDK is
/// not configured and no purchase sheet is shown.
class RevenueCatConfig {
  const RevenueCatConfig._();

  /// Public Apple SDK key (starts with `appl_`).
  static const appleApiKey = 'appl_ZKAUMzpgppCoGNXwMBrBQPJtpdU';

  /// Public Google SDK key (starts with `goog_`).
  static const googleApiKey = '';
}
