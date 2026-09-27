import 'package:ai_teacher/app/data/network_config.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/lead/data/trial_request_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hali kurs olmagan o'quvchi uchun Kurslar bo'limi — bepul 1-1 sinov darsi
/// landingi (lesson.myteacher.uz/bepul-dars.html).
///
/// Sahifadagi "Bepul darsga yozilish" tugmasi `trialRequest` handler'ini
/// chaqiradi: so'rov shu yerdan, o'quvchining akkaunti bilan yuboriladi —
/// ism va telefonni qayta so'rash shart emas.
class TrialLandingView extends ConsumerStatefulWidget {
  const TrialLandingView({super.key});

  @override
  ConsumerState<TrialLandingView> createState() => _TrialLandingViewState();
}

class _TrialLandingViewState extends ConsumerState<TrialLandingView> {
  double _progress = 0;
  bool _xato = false;
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    if (_xato) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Sahifani yuklab bo'lmadi",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() => _xato = false);
                _controller?.reload();
              },
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(NetworkConfig.trialLandingUrl),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: true,
            allowsInlineMediaPlayback: true,
            supportZoom: false,
            transparentBackground: true,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            controller.addJavaScriptHandler(
              handlerName: 'trialBook',
              callback: (args) async {
                final startsAt = args.isNotEmpty ? args[0]?.toString() : null;
                if (startsAt == null || startsAt.isEmpty) {
                  return {'ok': false, 'message': 'Vaqtni tanlang'};
                }
                try {
                  await ref.read(trialRequestRepositoryProvider).book(startsAt);
                  return {'ok': true};
                } on DioException catch (e) {
                  final m = e.response?.data is Map
                      ? (e.response!.data as Map)['message']
                      : null;
                  return {
                    'ok': false,
                    'message': m is String
                        ? m
                        : "Yuborib bo'lmadi. Internetni tekshirib, qayta urinib ko'ring.",
                  };
                } catch (_) {
                  return {
                    'ok': false,
                    'message':
                        "Yuborib bo'lmadi. Internetni tekshirib, qayta urinib ko'ring.",
                  };
                }
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'trialRequest',
              callback: (_) async {
                try {
                  final r = await ref
                      .read(trialRequestRepositoryProvider)
                      .request();
                  return {'ok': true, 'already': r.already};
                } catch (_) {
                  return {
                    'ok': false,
                    'message':
                        "Yuborib bo'lmadi. Internetni tekshirib, qayta urinib ko'ring.",
                  };
                }
              },
            );
          },
          onProgressChanged: (_, p) {
            if (mounted) setState(() => _progress = p / 100);
          },
          onReceivedError: (controller, request, error) {
            if (request.isForMainFrame ?? false) {
              if (mounted) setState(() => _xato = true);
            }
          },
        ),
        if (_progress < 1)
          LinearProgressIndicator(
            value: _progress == 0 ? null : _progress,
            minHeight: 2,
            color: AppColors.primary,
            backgroundColor: Colors.transparent,
          ),
      ],
    );
  }
}
