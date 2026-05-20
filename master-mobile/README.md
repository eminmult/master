# Master.az Mobile (Flutter)

Mobile client for the Master.az home-services marketplace. Talks to the
Laravel API at `https://master.gasimov.az/api/v1`.

This repo ships **only** `lib/` + config — Flutter platform folders
(`android/`, `ios/`, `web/`, `macos/`) are generated on first setup.

---

## 1. First-time setup

```bash
# 1. Install Flutter SDK ≥ 3.24 — https://docs.flutter.dev/get-started/install

# 2. Generate platform folders WITHOUT overwriting our lib/
cd master-mobile
flutter create . --org az.gasimov.master --platforms ios,android \
  --project-name master_mobile

# 3. Pull deps
flutter pub get

# 4. Generate freezed/json/riverpod sources + ARB → Dart i18n
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# 5. Copy env
cp .env.example .env
# edit .env — at minimum set API_BASE_URL and (later) GOOGLE_MAPS_API_KEY_*
```

## 2. Daily commands

```bash
# Run on connected device
flutter run --dart-define-from-file=.env

# Run watch mode for codegen (freezed/json) — keep in a second terminal
dart run build_runner watch --delete-conflicting-outputs

# Run on a specific device
flutter devices
flutter run -d <device_id> --dart-define-from-file=.env

# Build release
flutter build apk --release --dart-define-from-file=.env
flutter build appbundle --release --dart-define-from-file=.env
flutter build ipa --release --dart-define-from-file=.env

# Lint
flutter analyze
dart run custom_lint
```

## 3. Project structure

```
lib/
├── main.dart                           # entry — Firebase + ProviderScope
├── app.dart                            # MaterialApp.router + i18n + theme
├── core/
│   ├── api/                            # Dio + interceptors + typed errors
│   ├── auth/                           # Token storage + Riverpod controller
│   ├── push/push_service.dart          # FCM register / foreground display
│   ├── routing/router.dart             # go_router with auth guards
│   ├── theme/
│   │   ├── design_tokens.dart          # Handyman colors / radii / shadows
│   │   └── app_theme.dart              # Dark theme + Space Grotesk
│   └── config/app_config.dart          # Compile-time env
├── shared/
│   └── widgets/                        # HmAvatar, HmIconButton, HmPillButton,
│                                       # HmChip, HmSectionHead, HmBottomNav
├── features/
│   ├── auth/                           # Login + register
│   ├── home/                           # Handyman home screen
│   ├── orders/                         # Specialist list (list screen)
│   ├── chat/                           # Per-application chat
│   ├── profile/                        # Profile screen
│   ├── applications/                   # (data models)
│   ├── master/                         # Master-specific (TODO)
│   └── client/                         # Client-specific (TODO)
└── l10n/                               # ARB files for az/ru/en/tr/ar
```

## 3.1 Design system

Mirrors the Handyman App design (Figma → HTML → here). Tokens live in
`lib/core/theme/design_tokens.dart`:

| Token | Value | Use |
|---|---|---|
| `HmColors.bg` | `#0A0A0A` | App background |
| `HmColors.surface` | `#1A1A1A` | Cards, inputs, icon-buttons |
| `HmColors.accent` | `#FFFF00` | Primary CTA, links, ratings |
| `HmColors.text` / `text3` / `text5` | white / light / muted | Type scale |
| `HmRadius.pill` | 9999 | Buttons, inputs, nav |
| `HmRadius.card` / `cardLarge` / `banner` | 16 / 22 / 32 | Surface containers |
| Font | Space Grotesk via `google_fonts` | All text |

Reusable widgets in `lib/shared/widgets/`:
- `HmAvatar` — circular, optional yellow ring + green online dot
- `HmIconButton` — 44×44 (or 32×32 small) chip; supports `accent`, `flat`
- `HmPillButton` — small filter pill with active state
- `HmChip` — category tags
- `HmSectionHead` — title + accent link
- `HmBottomNav` — floating pill with glow halo on active tab

Implemented screens (1:1 with the Handyman design + missing screens drawn in
the same style, wired to the master-site backend logic):

**Auth:**
- `LoginPage` — accent glow button, error box
- `RegisterRolePickerPage` — choose client / master
- `RegisterClientPage` — single-form, validates phone regex like backend
- `RegisterMasterPage` — 3-step (identity → profile → categories grid via API)
- `VerifyPhonePage` — 6-digit OTP, auto-verify on entry, resend cooldown
- `ForgotPasswordPage` + `ResetPasswordPage` — full reset flow

**Main:**
- `HomePage` — header, search, banner carousel, categories, recommended specialists
- `CategoriesGridPage` — full categories from `/categories`
- `SpecialistListPage` — list with filter pills + FAB
- `MasterDetailPage` — stats, services, reviews from `/masters/:id` + `/reviews`
- `OrderCreatePage` — 3-step (category → describe → address) → POST `/orders`
- `MyOrdersPage` — paginated, status filter, refresh, FAB to create
- `OrderDetailPage` — status badge, address/budget, applications list (client view)
  with chat/accept actions, master action buttons (on_the_way → arrived → in_progress
  → awaiting_completion), cancel, review CTA
- `ChatPage` — auto-detects mock vs live mode via applicationId; in live mode
  hits `/order-applications/:id/messages` with 5s polling
- `NotificationsPage` — list with type icons, mark-read, deep-links to order/chat
- `ProfilePage` — gradient avatar ring, premium badge, account/preferences sections
- `SettingsPage` — language picker, GDPR export/delete, sign out

**Repositories** (data layer):
- `auth_repository.dart` — register, login, refresh, OTP, email verify
- `orders_repository.dart` — my, public, available, show, create, status, cancel, dispute, review
- `applications_repository.dart` — apply, propose, accept, reject, withdraw, messages, send
- `categories_repository.dart` — list, show
- `masters_repository.dart` — list with filters, show, reviews
- `notifications_repository.dart` — list, unread-count, mark-read, mark-all-read

All repositories return typed Freezed models, throw `ApiException` on failure
(`UnauthenticatedException`, `ValidationException` with field map,
`SubscriptionRequiredException` with expiry, etc.). Reference the full API:
`../master-site/MOBILE_API.md`.

Each `feature/` has the same shape:
- `data/models/` — freezed + json_serializable DTOs
- `data/<x>_repository.dart` — thin Dio wrapper
- `presentation/pages/` — UI
- `presentation/<x>_controller.dart` — Riverpod state

## 4. State management — Riverpod

- `Provider<T>` for stateless services (Dio, repositories).
- `StateNotifierProvider` for state machines like AuthController.
- `FutureProvider`/`StreamProvider` for one-shot async data.
- Watch state with `ref.watch`, mutate via `ref.read(...notifier).method()`.

`authStateProvider` is the source of truth — sealed `AuthState`:
- `AuthLoading` — boot, while we fetch /auth/me
- `AuthAuthenticated(User)` — token valid
- `AuthUnauthenticated` — show login

## 5. Wiring Firebase

### Android
1. Create a Firebase project, add Android app with `applicationId = az.gasimov.master.master_mobile`.
2. Download `google-services.json` → `android/app/google-services.json`.
3. In `android/build.gradle` add: `classpath 'com.google.gms:google-services:4.4.2'`.
4. In `android/app/build.gradle` bottom: `apply plugin: 'com.google.gms.google-services'`.

### iOS
1. Add iOS app in same Firebase project with bundle id `az.gasimov.master.masterMobile`.
2. Download `GoogleService-Info.plist` → drop into `ios/Runner/` via Xcode.
3. Enable Push Notifications + Background Modes (Remote notifications, Background fetch).
4. Upload APNs auth key in Firebase Console → Project Settings → Cloud Messaging.

After these steps `firebase_messaging.getToken()` returns a real FCM token,
which `PushService.init()` POSTs to `/devices/register`.

## 6. Talking to the API

Use the auth-aware `Dio` from `apiClientProvider` for everything:

```dart
final dio = ref.read(apiClientProvider);
final res = await dio.get<Map<String, dynamic>>('/orders/my');
```

Errors come back as `DioException` — wrap in `try/catch` and convert via
`ApiException.fromDio(e)` for a typed result. See `AuthRepository` for the
canonical pattern.

The full API surface is documented in `../master-site/MOBILE_API.md`.

## 7. Adding a new feature in 5 steps

Example: "show notifications inbox".

1. **Model**: `lib/features/notifications/data/models/notification.dart` —
   freezed class matching `/notifications` JSON shape.
2. **Repository**: `lib/features/notifications/data/notifications_repository.dart` —
   inject `Dio`, add `Future<List<Notification>> list()`.
3. **Controller**: `notifications_controller.dart` — `AsyncNotifierProvider`
   that wraps the repo and exposes loading/error/data states.
4. **Page**: `presentation/pages/notifications_page.dart` — `ConsumerWidget`
   that watches the controller and renders.
5. **Route**: add to `core/routing/router.dart`.

## 8. Real-time (planned)

Reverb (Pusher protocol) is wired into the backend but channels aren't
enabled yet. When ready:

```dart
// core/realtime/realtime_service.dart (TODO)
final pusher = PusherChannelsFlutter.getInstance();
await pusher.init(apiKey: AppConfig.reverbAppKey, cluster: 'mt1');
await pusher.subscribe(channelName: 'private-application.$appId');
```

Until then mobile polls (5s active chat / 30s background / 60s lists).

## 9. Pre-flight before App Store / Play

- [ ] Firebase configured for both platforms
- [ ] Google Maps API keys in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`
- [ ] App icons + splash via `flutter_launcher_icons` + `flutter_native_splash`
- [ ] Update `version: x.y.z+build` in `pubspec.yaml` for each release
- [ ] Test on real iPhone (push doesn't work in simulator) and a low-end Android
- [ ] Privacy policy URL = https://master.gasimov.az/privacy (already live)
- [ ] Bundle ID matches Apple/Google console
- [ ] Update `APP_MIN_VERSION_IOS` / `_ANDROID` in backend `.env` after each release

## 10. Backend contract

- Base URL: `https://master.gasimov.az/api/v1`
- Auth: bearer token, 30-day expiry, refresh via `POST /auth/refresh` proactively
- Locale: `Accept-Language: az|ru|en|tr|ar`
- Error envelope: `{ "message": "...", "errors": {...}, "code": "..." }`
- 402 with `code: subscription_required` → master subscription paywall
- Push: `POST /devices/register` on login, `/devices/unregister` on logout

Full reference: `master-site/MOBILE_API.md`.
