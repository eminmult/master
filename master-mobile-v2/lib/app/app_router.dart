import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:itez_mobile/core/routing/auth_guard.dart';
import 'package:itez_mobile/features/auth/pages/login_page.dart';
import 'package:itez_mobile/features/auth/pages/register_page.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';
import 'package:itez_mobile/features/addresses/pages/address_form_page.dart';
import 'package:itez_mobile/features/addresses/pages/addresses_page.dart';
import 'package:itez_mobile/features/announcements/pages/announcements_page.dart';
import 'package:itez_mobile/features/auth/pages/forgot_password_page.dart';
import 'package:itez_mobile/features/auth/pages/register_master_page.dart';
import 'package:itez_mobile/features/auth/pages/register_role_picker_page.dart';
import 'package:itez_mobile/features/auth/pages/reset_password_page.dart';
import 'package:itez_mobile/features/auth/pages/verify_phone_page.dart';
import 'package:itez_mobile/features/calls/pages/call_page.dart';
import 'package:itez_mobile/features/chat/pages/chat_page.dart';
import 'package:itez_mobile/features/notifications/pages/notifications_page.dart';
import 'package:itez_mobile/features/smart_search/pages/smart_search_page.dart';
import 'package:itez_mobile/features/wallet/pages/wallet_page.dart';
import 'package:itez_mobile/features/home/pages/home_page.dart';
import 'package:itez_mobile/features/main/main_page.dart';
import 'package:itez_mobile/features/masters/pages/master_detail_page.dart';
import 'package:itez_mobile/features/masters/pages/masters_list_page.dart';
import 'package:itez_mobile/features/onboarding/pages/language_page.dart';
import 'package:itez_mobile/features/orders/pages/create_order_page.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_page.dart';
import 'package:itez_mobile/features/orders/pages/my_orders_page.dart';
import 'package:itez_mobile/features/profile/pages/change_password_page.dart';
import 'package:itez_mobile/features/profile/pages/edit_profile_page.dart';
import 'package:itez_mobile/features/profile/pages/profile_page.dart';
import 'package:itez_mobile/features/profile/pages/settings_page.dart';
import 'package:itez_mobile/features/splash/splash_page.dart';

part 'app_router.gr.dart';

/// AutoRoute v11. Корневой стек:
/// - `/`        — SplashRoute (initial). Решает, куда дальше.
/// - `/language` — выбор языка при первом запуске.
/// - `/login`   — публичный.
/// - `/register` — публичный.
/// - `/main`    — shell с табами (Home/Search/Orders/Profile). Часть детей
///                публичные (Home/Search), часть закрыты AuthGuard
///                (Orders/Profile) — настраивается на route'ах позже.
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: SplashRoute.page, path: '/', initial: true),
        AutoRoute(page: LanguageRoute.page, path: '/language'),
        AutoRoute(page: LoginRoute.page, path: '/login'),
        AutoRoute(page: RegisterRoute.page, path: '/register'),
        AutoRoute(page: RegisterRolePickerRoute.page, path: '/register/role'),
        AutoRoute(page: RegisterMasterRoute.page, path: '/register/master'),
        AutoRoute(page: ForgotPasswordRoute.page, path: '/forgot-password'),
        AutoRoute(page: ResetPasswordRoute.page, path: '/reset-password'),
        AutoRoute(
          page: MainRoute.page,
          path: '/main',
          children: [
            CustomRoute(
              page: HomeRoute.page,
              path: 'home',
              initial: true,
              transitionsBuilder: TransitionsBuilders.noTransition,
            ),
            AutoRoute(page: MastersListRoute.page, path: 'masters'),
            AutoRoute(
              page: MasterDetailRoute.page,
              path: 'masters/:idOrSlug',
            ),
            AutoRoute(
              page: OrdersRoute.page,
              path: 'orders',
              guards: [AuthGuard()],
            ),
            // OrderDetailRoute публичный: backend сам контролирует доступ
            // через `publicShow` для гостей, `/orders/{id}` для авторизованных.
            // OrderDetailBloc включает `publicFallback: true`, поэтому
            // на 401/403 он переключится на публичный endpoint.
            // AuthGuard тут вешать нельзя — на deep-link до bootstrap'a
            // AuthBloc сидит в Unknown, guard думает гость и редиректит,
            // что выглядит как зависший серый экран.
            AutoRoute(
              page: OrderDetailRoute.page,
              path: 'orders/:id',
            ),
            AutoRoute(
              page: CreateOrderRoute.page,
              path: 'orders/new',
              guards: [AuthGuard()],
            ),
            AutoRoute(
              page: ProfileRoute.page,
              path: 'profile',
              guards: [AuthGuard()],
            ),
            AutoRoute(
              page: EditProfileRoute.page,
              path: 'profile/edit',
              guards: [AuthGuard()],
            ),
            AutoRoute(
              page: ChangePasswordRoute.page,
              path: 'profile/password',
              guards: [AuthGuard()],
            ),
            AutoRoute(
              page: AddressesRoute.page,
              path: 'addresses',
              guards: [AuthGuard()],
            ),
            AutoRoute(
              page: AddressFormRoute.page,
              path: 'addresses/new',
              guards: [AuthGuard()],
            ),
            AutoRoute(page: SettingsRoute.page, path: 'settings'),
            AutoRoute(
              page: NotificationsRoute.page,
              path: 'notifications',
              guards: [AuthGuard()],
            ),
            AutoRoute(
              page: WalletRoute.page,
              path: 'wallet',
              guards: [AuthGuard()],
            ),
            AutoRoute(
              page: ChatRoute.page,
              path: 'orders/:orderId/chat',
              guards: [AuthGuard()],
            ),
            AutoRoute(page: AnnouncementsRoute.page, path: 'announcements'),
            AutoRoute(page: SmartSearchRoute.page, path: 'smart-search'),
            AutoRoute(
              page: VerifyPhoneRoute.page,
              path: 'verify-phone',
              guards: [AuthGuard()],
            ),
            //          ProfileRoute (guards: [AuthGuard()])
            //          CreateOrderRoute (guards: [AuthGuard()])
            //          AddressesRoute (guards: [AuthGuard()])
          ],
        ),
        AutoRoute(
          page: CallRoute.page,
          path: '/call',
          guards: [AuthGuard()],
        ),
      ];
}
