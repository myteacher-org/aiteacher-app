# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Run linter
dart format lib/         # Format Dart code
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
flutter build appbundle  # Build Android App Bundle
```

There is no test suite configured in this project.

## Architecture

Flutter app using **Riverpod** for state management and **GoRouter** for navigation. Source is split into two top-level namespaces under `lib/`:

- `core/` — business logic: repositories, controllers, DTOs, WebSocket clients, models
- `ui/` — presentation layer: screens and widgets organized by feature

Each feature folder contains `data/` (API, models, cache) and `presentation/` (Riverpod controllers) sub-folders. Nothing in `ui/` makes network calls directly; all data flows through `core/`.

### Application-level services (`lib/app/`)

| Module | Role |
|---|---|
| `app/data/` | `DioClient` (HTTP with `AuthInterceptor`), `CacheService` (SharedPreferences wrapper) |
| `app/router/` | GoRouter definition; all route declarations live here |
| `app/theme/` | Colors (`AppColors`), typography, global theme |
| `app/modal_queue/` | Global queue for serializing modals across unrelated features |

### Bootstrap sequence

`main()` initializes Firebase and SharedPreferences, then overrides `sharedPreferencesProvider` in the root `ProviderScope`. `App._bootstrap()` runs post-frame and in order: connects the promo socket, fires an update check, bootstraps FCM (with iOS APNs retry loop), then calls `SessionController.syncSession()`.

### Networking

Two Dio providers in `app/data/dio_client.dart`:
- `dioProvider` — auth-aware; injects bearer token via `AuthInterceptor`, auto-refreshes on 401, redirects to `/login` on refresh failure
- `unauthDioProvider` — no token injection; use for login/register/OTP endpoints to avoid refresh loops

Base URL is in `NetworkConfig`: in `kDebugMode` points to `http://192.168.0.2:8000`, in release to `https://ai.myteacher.uz`. All static assets resolve through `NetworkConfig.resolveStatic()`.

Push notifications via Firebase Cloud Messaging. FCM `data.screen` values `"chat"` and `"notifications"` are deep-linked on notification tap.

### Navigation

Routes are declared as the `AppRoute` enum in `app/router/app_router.dart`. Always navigate by name (`context.goNamed(AppRoute.x.name)`) rather than raw path strings. Route extras are typed — check the route builder for the expected type before pushing.

`MainScreen` is the bottom-nav shell. Tab indices are constants on the class: `chatTab=0`, `coursesTab=1`, `homeTab=2`, `commentsTab=3`, `profileTab=4`. Pass the desired tab as `extra` when pushing to `AppRoute.main`.

### Session bootstrap

`core/session/` drives session lifecycle. `SessionController.syncSession()` runs on every app launch and FCM token refresh — creates a session if none exists, or PUTs to refresh the FCM token if already logged in. Call `claimSession()` once immediately after login/register to link the server session to the logged-in user.

### Auth

`AuthSession` (in `core/auth/data/auth_session.dart`) reads the JWT from `CacheService` and exposes the current `userId` by decoding the `sub` claim. This is the canonical source of "who is logged in."

`CacheService` stores: `access_token`, `refresh_token`, `session_id`, `fcm_token`, `web_identifier`, `web_password`.

### Modal queue

`modalQueueProvider` (a `NotifierProvider<ModalQueueNotifier, List<ModalTask>>`) serializes global modals. Tasks are typed via the sealed class `ModalTask`: `PromoTask`, `CashbackTask`, `StreakTask`. `MainScreen` drains the queue after each modal closes. Add new modal types by extending the sealed class and handling them in `MainScreen`.

### WebSocket pattern

`PromoSocket` (`core/promo/data/promo_socket.dart`) is the reference implementation for feature-scoped WebSocket clients using `socket_io_client`. Key pattern: `reconnect()` is a no-op when the same `userId` is already connecting, preventing duplicate sockets across auth state changes. Expose events as a broadcast `Stream`.

### Key feature modules

| Module | Description |
|---|---|
| `core/speaking/` + `ui/speaking/` | Audio recording pipeline (`record` pkg) → REST → AI grading. `SpeakingPhase` enum: `idle → recording → processing → speaking → error` |
| `core/battle/` | Multiplayer word battle via WebSocket |
| `core/call/` | WebRTC voice/video (`flutter_webrtc`) |
| `core/chat/` | AI chat with a chat socket (`chat_socket.dart`) and unread badge provider |
| `core/chatbot/` | Separate chatbot flow (distinct from `chat/`) |
| `core/promo/` | WebSocket promo events → `modalQueueProvider` |
| `core/cashback/` | Cashback rewards; unclaimed cashback surfaces via modal queue |
| `core/streak/` | Daily check-in streak; streak sheet surfaces via modal queue |
| `core/course/` | Course listing; `CourseWebScreen` opens course URLs in `flutter_inappwebview` |
| `core/vocabulary/` | Vocabulary training |
| `core/writing_task/` | Written assignment submission |
| `core/assignment/` | General assignments |
| `core/notification/` | In-app notification list |
| `core/update/` | In-app update checker using `upgrader` |
| `core/user/` | User profile data |
| `core/student_activity/` | Activity feed |
| `core/comments/` | Blog/content comments |
| `core/support/` | Support contact |

### Assets

- `assets/images/` — PNGs (onboarding, branding)
- `assets/lottie/` — Lottie animation JSON files
