import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:ai_teacher/app/data/cache_service.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/chatbot/presentation/chatbot_controller.dart';
import 'package:ai_teacher/core/student_activity/data/student_activity_socket.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/courses/course_video_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Args for opening an arbitrary link (e.g. a lesson.myteacher.uz link a
/// mentor shared in chat) through [CourseWebScreen] via `AppRoute.linkWeb`,
/// without needing a full [Course] object.
class LinkWebArgs {
  const LinkWebArgs({required this.title, required this.url});

  final String title;
  final String url;
}

class CourseWebScreen extends ConsumerStatefulWidget {
  const CourseWebScreen({
    super.key,
    required this.title,
    required this.url,
    this.login,
    this.password,
    this.isDemo = false,
    this.courseId,
  });

  final String title;
  final String url;
  final String? login;
  final String? password;
  final bool isDemo;
  final String? courseId;

  static const int dailyLimitSeconds = 600; // 10 minutes

  @override
  ConsumerState<CourseWebScreen> createState() => _CourseWebScreenState();
}

class _CourseWebScreenState extends ConsumerState<CourseWebScreen> {
  InAppWebViewController? _controller;
  double _progress = 0;
  late final StudentActivitySocket _activitySocket;

  // Captured in initState so it is safe to use in dispose (ref may be invalid then).
  late final CacheService _cache;

  // Demo time-limit tracking
  Timer? _ticker;
  int _secondsUsed = 0;
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _activitySocket = ref.read(studentActivitySocketProvider);
    _cache = ref.read(cacheServiceProvider);

    InAppWebViewController.clearAllCache();
    if (Platform.isAndroid) {
      WebStorageManager.instance().deleteAllData();
    }
    CookieManager.instance().deleteAllCookies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _activitySocket.emitCourseStart();
    });

    final courseId = widget.courseId;
    if (widget.isDemo && courseId != null && courseId.isNotEmpty) {
      _secondsUsed = _cache.getDemoSecondsUsed(courseId);
      if (_secondsUsed >= CourseWebScreen.dailyLimitSeconds) {
        _limitReached = true;
      } else {
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      }
    }
  }

  void _tick() {
    if (!mounted) return;
    _secondsUsed++;
    if (_secondsUsed >= CourseWebScreen.dailyLimitSeconds) {
      _ticker?.cancel();
      _ticker = null;
      _saveSecondsUsed();
      setState(() => _limitReached = true);
    } else {
      setState(() {});
    }
  }

  int get _remainingSeconds =>
      (CourseWebScreen.dailyLimitSeconds - _secondsUsed).clamp(
        0,
        CourseWebScreen.dailyLimitSeconds,
      );

  String get _remainingLabel {
    final r = _remainingSeconds;
    final m = (r ~/ 60).toString().padLeft(2, '0');
    final s = (r % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _saveSecondsUsed() {
    final courseId = widget.courseId;
    if (courseId == null || courseId.isEmpty) return;
    _cache.setDemoSecondsUsed(courseId, _secondsUsed);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (widget.isDemo) _saveSecondsUsed();
    super.dispose();
  }

  static const _observerScript = '''
(function() {
  if (window._appVideoObserver) {
    window._appVideoObserver.disconnect();
    window._appVideoObserver = null;
  }

  function replaceVideo(video) {
    if (video.hasAttribute("data-app-replaced")) return;
    var src = video.src || video.currentSrc;
    if (!src) {
      var s = video.querySelector("source");
      if (s) src = s.src;
    }
    if (!src || src.length === 0) return;

    video.setAttribute("data-app-replaced", "");
    video.hidden = true;

    var h = video.offsetHeight || 180;

    var wrap = document.createElement("div");
    wrap.style.cssText =
      "display:flex;align-items:center;justify-content:center;" +
      "width:100%;height:" + h + "px;" +
      "background:#4f6ef7;cursor:pointer;box-sizing:border-box;";

    wrap.innerHTML =
      "<div style=\\"width:64px;height:64px;border-radius:50%;" +
      "background:rgba(255,255,255,0.2);display:flex;" +
      "align-items:center;justify-content:center;\\">" +
      "<svg width=\\"28\\" height=\\"28\\" viewBox=\\"0 0 24 24\\" fill=\\"white\\">" +
      "<path d=\\"M8 5v14l11-7z\\"/></svg></div>";

    (function(videoSrc) {
      wrap.onclick = function() {
        window.flutter_inappwebview.callHandler("playVideo", videoSrc);
      };
    })(src);

    video.parentNode.insertBefore(wrap, video);
    debugPrint("[CourseWebScreen] Replaced video: " + src);
  }

  document.querySelectorAll("video:not([data-app-replaced])").forEach(replaceVideo);

  window._appVideoObserver = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      mutation.addedNodes.forEach(function(node) {
        if (node.nodeType !== 1) return;
        if (node.tagName === "VIDEO") {
          replaceVideo(node);
        } else if (node.querySelectorAll) {
          node.querySelectorAll("video:not([data-app-replaced])").forEach(replaceVideo);
        }
      });
    });
  });

  window._appVideoObserver.observe(document.body, { childList: true, subtree: true });
})()
''';

  void _injectObserver() {
    _controller?.evaluateJavascript(source: _observerScript);
  }

  /// Matches either the main course platform's login form
  /// (`input[name="email"|"password"]` on a `/auth/login` URL) or
  /// `lesson.myteacher.uz`'s own login form (`#login`/`#parol` on
  /// `login.html`) — mentors share lesson links in chat, and students land
  /// on whichever of the two the link points at.
  void _tryAutoFill(WebUri? url) {
    final urlStr = url?.toString() ?? '';
    if (!urlStr.contains('/auth/login') && !urlStr.contains('login.html')) {
      return;
    }

    // Falls back to the credentials cached at sign-in (see
    // `LoginController`/`OtpController`) when the caller didn't pass an
    // explicit login/password — covers links opened via `AppRoute.linkWeb`
    // (e.g. a lesson.myteacher.uz link shared in chat), which aren't tied
    // to a specific [Course]. lesson.myteacher.uz's own login form expects
    // the phone number without the "+998" prefix the app stores it with.
    final cachedIdentifier = _cache.webIdentifier;
    final login =
        widget.login ??
        (urlStr.contains('login.html')
            ? cachedIdentifier?.replaceFirst('+998', '')
            : cachedIdentifier);
    final password = widget.password ?? _cache.webPassword;
    if (login == null ||
        login.isEmpty ||
        password == null ||
        password.isEmpty) {
      return;
    }

    final idJson = jsonEncode(login);
    final pwJson = jsonEncode(password);

    final script =
        '''
(function() {
  if (window._appAutoFillDone) return;

  function setReactInputValue(el, value) {
    var setter = Object.getOwnPropertyDescriptor(
      window.HTMLInputElement.prototype, 'value'
    ).set;
    setter.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }

  var attempts = 0;
  var maxAttempts = 30;

  function tryFill() {
    var emailEl = document.querySelector('input[name="email"]') ||
                  document.getElementById('login');
    var passwordEl = document.querySelector('input[name="password"]') ||
                      document.getElementById('parol');

    if (!emailEl || !passwordEl) {
      if (++attempts < maxAttempts) setTimeout(tryFill, 300);
      return;
    }

    window._appAutoFillDone = true;
    setReactInputValue(emailEl, $idJson);
    setReactInputValue(passwordEl, $pwJson);

    setTimeout(function() {
      var form = emailEl.closest('form');
      var btn = document.querySelector('button[type="submit"]');
      if (form && form.requestSubmit) {
        form.requestSubmit();
      } else if (btn) {
        btn.click();
      } else if (form) {
        form.dispatchEvent(
          new Event('submit', { bubbles: true, cancelable: true })
        );
      }
    }, 400);
  }

  tryFill();
})();
''';

    _controller?.evaluateJavascript(source: script);
  }

  @override
  Widget build(BuildContext context) {
    // Keep the chatbot session alive for the entire duration of this screen.
    ref.watch(chatbotControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF0F172A),
            onPressed: () async {
              if (_controller != null && await _controller!.canGoBack()) {
                _controller!.goBack();
              } else if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            if (widget.isDemo && !_limitReached)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _TimerChip(
                  label: _remainingLabel,
                  seconds: _remainingSeconds,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF0F172A),
              onPressed: () {
                _activitySocket.emitCourseEnd();
                Navigator.of(context).pop();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _progress < 1
                ? LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialUserScripts: UnmodifiableListView([
                UserScript(
                  source: '''
                try {
                  localStorage.clear();
                  sessionStorage.clear();
                } catch(e) {}
              ''',
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                ),
              ]),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useOnDownloadStart: true,
              ),
              onPermissionRequest: (controller, request) async {
                // Video lessons (lesson.myteacher.uz links shared in chat)
                // run over in-browser WebRTC and need camera + mic. Granting
                // the JS-side request alone does nothing unless the
                // underlying Android runtime permission has actually been
                // granted first — request it here.
                await [Permission.camera, Permission.microphone].request();
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onDownloadStartRequest: (controller, request) {
                // The platform WebView can't render documents (PDF, Word,
                // Excel, ...) inline and would otherwise hand them off to
                // the OS as a download. Route them through Google's viewer
                // instead so they open inside the app.
                final viewerUrl =
                    'https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(request.url.toString())}';
                controller.loadUrl(
                  urlRequest: URLRequest(url: WebUri(viewerUrl)),
                );
              },
              onWebViewCreated: (controller) {
                _controller = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'playVideo',
                  callback: (args) {
                    if (args.isNotEmpty && mounted) {
                      debugPrint('[CourseWebScreen] Opening video: ${args[0]}');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CourseVideoScreen(videoUrl: args[0].toString()),
                        ),
                      );
                    }
                  },
                );
              },
              onProgressChanged: (_, progress) {
                setState(() => _progress = progress / 100);
              },
              onLoadStop: (controller, url) {
                _injectObserver();
                _tryAutoFill(url);
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                _injectObserver();
                _tryAutoFill(url);
              },
            ),
            if (_limitReached)
              _DailyLimitOverlay(
                onClose: () {
                  _activitySocket.emitCourseEnd();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.label, required this.seconds});

  final String label;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bg;
    if (seconds <= 30) {
      color = const Color(0xFFDC2626);
      bg = const Color(0xFFFEF2F2);
    } else if (seconds <= 120) {
      color = const Color(0xFFF97316);
      bg = const Color(0xFFFFF7ED);
    } else {
      color = const Color(0xFF0D9488);
      bg = const Color(0xFFF0FDFA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyLimitOverlay extends StatelessWidget {
  const _DailyLimitOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lock_clock_rounded,
                  size: 32,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.coursesDailyLimitTitle,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.coursesDailyLimitMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    l10n.commonClose,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
