# Strips references to non-public / deprecated Apple APIs out of third-party
# plugin sources before CocoaPods compiles them.
#
# App Store Connect rejects the binary when it finds these symbols:
#   * PGHostedWindow                            (flutter_inappwebview_ios)
#   * RPSystemBroadcastPickerView.buttonPressed:  (flutter_webrtc)
#
# Both packages are already on their newest pub.dev release, so there is no
# upgrade that removes them. This script runs from the Podfile `pre_install`
# hook and rewrites the plugin sources in place (they live in the pub cache,
# reached through ios/.symlinks/plugins). It is idempotent, and re-applies
# itself automatically if the pub cache is repaired or a plugin is upgraded.

PLUGINS_DIR = File.expand_path(File.join(__dir__, '..', '.symlinks', 'plugins'))

PATCHES = [
  {
    # `isVideoPlayerWindow` filters out non-video UIWindow subclasses by name.
    # PGHostedWindow is a private class; drop it from the list. Modern iOS
    # never surfaces one, so fullscreen detection is unaffected.
    files: ['flutter_inappwebview_ios/ios/Classes/InAppWebView/InAppWebView.swift'],
    marker: 'PGHostedWindow',
    find: /"UIRemoteKeyboardWindow",\s*\n\s*"PGHostedWindow"\]/,
    replace: '"UIRemoteKeyboardWindow"]',
  },
  {
    # Screen sharing through a broadcast extension auto-taps the picker by
    # calling the private -buttonPressed: selector. This app never requests
    # display media, so the call is dead code; the picker itself is public and
    # stays in place.
    files: [
      'flutter_webrtc/ios/Classes/FlutterRTCDesktopCapturer.m',
      'flutter_webrtc/common/darwin/Classes/FlutterRTCDesktopCapturer.m',
      'flutter_webrtc/macos/Classes/FlutterRTCDesktopCapturer.m',
    ],
    marker: 'buttonPressed:',
    find: /^\s*SEL selector = NSSelectorFromString\(@"buttonPressed:"\);\n\s*if \(\[picker respondsToSelector:selector\]\) \{\n\s*\[picker performSelector:selector withObject:nil\];\n\s*\}\n/,
    replace: "    // Removed: auto-tapping the picker goes through a private selector,\n" \
             "    // which App Store review rejects. The user taps the picker instead.\n",
  },
].freeze

def apply_private_api_patches
  PATCHES.each do |patch|
    patch[:files].each do |relative|
      path = File.join(PLUGINS_DIR, relative)

      unless File.exist?(path)
        # Plugin not used on this platform / not resolved: nothing to patch.
        next
      end

      source = File.read(path)
      next unless source.include?(patch[:marker])

      patched = source.sub(patch[:find], patch[:replace])
      if patched == source
        raise "[private-api-patch] #{relative} still references #{patch[:marker]} " \
              'but the expected code was not found. The plugin changed upstream — ' \
              'update ios/patches/remove_private_apis.rb.'
      end

      File.write(path, patched)
      puts "[private-api-patch] removed #{patch[:marker]} from #{relative}"
    end
  end
end
