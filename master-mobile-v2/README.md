# itez_mobile (v2) — BLoC

Параллельный мобильный клиент itez.app под архитектурой BLoC + auto_route + get_it.
Не трогает существующий `/root/master-mobile` (Riverpod + go_router).

## Стек

| Слой           | Технология                                                       |
| -------------- | ---------------------------------------------------------------- |
| State          | `flutter_bloc` 9 + `bloc_concurrency`                            |
| Routing        | `auto_route` 11 (codegen, защищённые маршруты через `AuthGuard`) |
| DI             | `get_it` 9 (lazy singletons)                                     |
| HTTP           | `http` 1.6 (singleton `ApiClient`, Bearer + 401-refresh coalesced) |
| Storage        | `flutter_secure_storage` + `shared_preferences` (fallback)       |
| UI scaling     | `flutter_screenutil` 375×812                                     |
| L10n           | `flutter_localizations` + ARB (`ru`, `az`, `en`)                 |
| Realtime       | `pusher_channels_flutter` (совместим с Laravel Reverb)           |
| Calls          | `flutter_webrtc` (audio-only по умолчанию)                       |
| Push           | `firebase_messaging` + `firebase_core` + `firebase_analytics`    |

## Структура

```
lib/
├── app/                       MaterialApp, router, theme, DI, ConfigBloc
├── core/
│   ├── api_client/            ApiClient + Urls (single source of truth)
│   ├── constants/             AppColors, AppIcons
│   ├── exceptions/            AppException иерархия
│   ├── extensions/            BuildContext helpers
│   ├── services/              LocalStorage
│   ├── push/                  PushService (FCM regular + device register)
│   ├── realtime/              RealtimeService (Reverb через Pusher)
│   └── routing/               AuthGuard
├── common/                    переиспользуемые widgets
├── features/
│   ├── splash/  onboarding/
│   ├── main/                  bottom-nav shell
│   ├── home/                  каталог категорий
│   ├── auth/                  login / register / change-password
│   ├── categories/            CategoryRepository + bloc
│   ├── masters/               list + detail + reviews
│   ├── orders/                list / detail / create + 7 actions
│   ├── addresses/             CRUD адресов
│   ├── profile/               edit / change-password / settings
│   ├── notifications/         badge + list + mark-read
│   ├── chat/                  per-order чат с realtime подпиской
│   ├── calls/                 WebRTC + сигналинг через REST + Reverb
│   └── wallet/                баланс + транзакции (мастер)
└── l10n/                      app_*.arb
```

## Запуск web-превью (через Docker, без локального Flutter SDK)

```bash
cd /root/master-mobile-v2
docker compose up --build -d
# → http://localhost:8096/mobile-v2/
```

Параметры сборки:

```bash
API_BASE_URL=https://itez.app/api/v1 \
SITE_URL=https://itez.app \
REVERB_HOST=ws.itez.app \
REVERB_KEY=your-app-key \
BUILD_ID=$(date +%s) \
docker compose up --build -d
```

## Сборка APK

```bash
./scripts/build_apk.sh
# артефакт: build/app/outputs/flutter-apk/app-release.apk
```

Скрипт пробрасывает те же `--dart-define` что и web; параметры берёт из env.

## Локальный запуск (если есть Flutter 3.24.5 локально)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run --dart-define=API_BASE_URL=https://itez.app/api/v1
```

## Архитектурные правила

1. **BLoC per feature**: `Initial → Loading → Loaded → Failed`, events — `sealed class`.
2. **Repositories** через `setupLocator()`, в BLoC инжектятся конструктором.
3. **Ошибки** репозитория наружу через иерархию `AppException` —
   `NetworkException` / `ServerException` / `UnauthorizedException` /
   `ValidationException(errors)` / `NotFoundException` / `ForbiddenException`.
4. **No hardcoded strings** в UI — только через AppLocalizations / константы.
5. **`strict-casts + strict-inference`** — никакого `dynamic`.
6. **Pagination**: `LoadMore` event + `_page` / `_isLastPage` внутри BLoC.
7. **Per-page BLoC** через `AutoRouteWrapper.wrappedRoute`, глобальные —
   через `App.MultiBlocProvider` (Auth, Addresses, Notifications, Call).
8. **AuthGuard** в `auto_route` — `locator<AuthBloc>().state` → редирект на /login.

## Карта endpoints (Laravel backend, prefix `/api/v1`)

| Group         | Endpoints                                                          |
| ------------- | ------------------------------------------------------------------ |
| Auth          | `auth/login`, `auth/register/{client,master}`, `auth/me`, `auth/refresh`, `auth/logout`, `auth/forgot-password`, `auth/reset-password`, `auth/change-password`, `auth/phone/{request,verify}-otp` |
| Catalog       | `categories`, `categories/{id}`, `masters`, `masters/{idOrSlug}`, `masters/{idOrSlug}/reviews` |
| Orders        | `orders` (POST), `orders/my`, `orders/available`, `orders/public`, `orders/{id}`, `orders/{id}/{accept,decline,confirm,cancel,reject-proposal,status,apply,messages,callout-fee,pay-callout,review}` |
| Addresses     | `addresses` (CRUD)                                                 |
| Profile       | `client/profile`, `master/profile`, `me/locale`, `me/export`, `me/delete` |
| Notifications | `notifications`, `notifications/unread-count`, `notifications/{id}/read`, `notifications/read-all` |
| Chat          | `orders/{id}/messages`, `chat/unread`                              |
| Calls         | `calls`, `calls/{id}/{accept,reject,end,signal}`                   |
| Wallet        | `wallet/balance`, `wallet/transactions`                            |
| Push          | `devices/register`, `devices/unregister`                           |

## Roadmap

- Phase 0 ✅ — фундамент (router, theme, ApiClient, ConfigBloc, LocalStorage, splash, onboarding, shell)
- Phase 1 ✅ — auth (login/register + Sanctum + AuthGuard + AuthInterceptor)
- Phase 2 ✅ — catalog (categories, masters, search)
- Phase 3 ✅ — orders + addresses + profile
- Phase 4 ✅ — realtime: calls, push, notifications, chat, wallet
- Phase 5 ✅ — build pipeline (Docker + nginx + APK script)
