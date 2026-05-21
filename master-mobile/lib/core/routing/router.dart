import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/addresses/presentation/add_address_page.dart';
import 'package:master_mobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:master_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:master_mobile/features/auth/presentation/pages/register_client_page.dart';
import 'package:master_mobile/features/auth/presentation/pages/register_master_page.dart';
import 'package:master_mobile/features/auth/presentation/pages/register_role_picker_page.dart';
import 'package:master_mobile/features/auth/presentation/pages/reset_password_page.dart';
import 'package:master_mobile/features/auth/presentation/pages/verify_phone_page.dart';
import 'package:master_mobile/features/categories/presentation/pages/categories_grid_page.dart';
import 'package:master_mobile/features/chat/presentation/pages/chat_page.dart';
import 'package:master_mobile/features/home/presentation/pages/home_page.dart';
import 'package:master_mobile/features/master/presentation/pages/master_detail_page.dart';
import 'package:master_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/announcement_detail_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/announcements_page.dart';
import 'package:master_mobile/features/user_profile/presentation/user_detail_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/my_orders_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/order_create_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/order_detail_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/order_review_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/specialist_list_page.dart';
import 'package:master_mobile/features/payment/presentation/pages/add_payment_card_page.dart';
import 'package:master_mobile/features/payment/presentation/pages/payment_methods_page.dart';
import 'package:master_mobile/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:master_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:master_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:master_mobile/features/wallet/presentation/wallet_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final atAuthGate = loc == '/login' ||
          loc.startsWith('/register') ||
          loc.startsWith('/forgot-password') ||
          loc.startsWith('/reset-password') ||
          loc.startsWith('/verify');

      // Public routes — guest can browse: home, categories, specialist list,
      // master detail. Anything else (orders, chat, profile, settings,
      // notifications, /order/create) requires auth.
      final isPublic = loc == '/' ||
          loc == '/home' ||
          loc == '/categories' ||
          loc == '/announcements' ||
          loc.startsWith('/announcements/') ||
          loc.startsWith('/list/') ||
          loc.startsWith('/master/') ||
          atAuthGate;

      switch (auth) {
        case AuthLoading():
          return null;
        case AuthUnauthenticated() when isPublic:
          // Splash route shows /home for guests too — no forced login.
          return loc == '/' ? '/home' : null;
        case AuthUnauthenticated():
          // Protected route → bounce to /login, remember where they wanted
          // to go via ?next= so login can return them after success.
          return '/login?next=${Uri.encodeComponent(loc)}';
        case AuthAuthenticated() when atAuthGate:
          // Honour ?next= so a login triggered from a protected route
          // returns the user to the page they actually wanted.
          final next = state.uri.queryParameters['next'];
          return (next != null && next.isNotEmpty) ? Uri.decodeComponent(next) : '/home';
        case AuthAuthenticated() when loc == '/':
          return '/home';
        case AuthAuthenticated():
          return null;
      }
    },
    routes: [
      // Every public route uses CupertinoPage. CupertinoPageRoute has a
      // built-in edge-swipe gesture detector that works reliably across
      // Forms, TextFields and horizontal scrollables — much better than
      // relying on MaterialPage + CupertinoPageTransitionsBuilder, which is
      // visually identical but routinely loses the gesture to inner widgets.
      GoRoute(path: '/', pageBuilder: (_, s) => _cp(s, const _Splash())),

      // Auth flow
      GoRoute(path: '/login', pageBuilder: (_, s) => _cp(s, const LoginPage())),
      GoRoute(path: '/register', pageBuilder: (_, s) => _cp(s, const RegisterRolePickerPage())),
      GoRoute(path: '/register/client', pageBuilder: (_, s) => _cp(s, const RegisterClientPage())),
      GoRoute(path: '/register/master', pageBuilder: (_, s) => _cp(s, const RegisterMasterPage())),
      GoRoute(path: '/forgot-password', pageBuilder: (_, s) => _cp(s, const ForgotPasswordPage())),
      GoRoute(path: '/reset-password', pageBuilder: (_, s) => _cp(s, ResetPasswordPage(
        initialLogin: s.uri.queryParameters['login'],
        token: s.uri.queryParameters['token'],
      ))),
      GoRoute(path: '/verify-phone', pageBuilder: (_, s) => _cp(s, const VerifyPhonePage())),

      // Main app
      GoRoute(path: '/home', pageBuilder: (_, s) => _cp(s, const HomePage())),
      GoRoute(path: '/orders', pageBuilder: (_, s) => _cp(s, const MyOrdersPage())),
      GoRoute(
        path: '/order/create',
        pageBuilder: (_, s) {
          final masterId = int.tryParse(s.uri.queryParameters['master_id'] ?? '');
          final masterName = s.uri.queryParameters['master_name'];
          final categoryId = int.tryParse(s.uri.queryParameters['category_id'] ?? '');
          return _cp(s, OrderCreatePage(
            preselectedCategoryId: categoryId,
            preferredMasterId: masterId,
            preferredMasterName: masterName,
          ));
        },
      ),
      GoRoute(
        path: '/order/:id',
        pageBuilder: (_, s) => _cp(s, OrderDetailPage(
          orderId: int.parse(s.pathParameters['id']!),
        )),
      ),
      GoRoute(
        path: '/order/:id/review',
        pageBuilder: (_, s) => _cp(s, OrderReviewPage(
          orderId: int.parse(s.pathParameters['id']!),
        )),
      ),

      // Specialist list (by category)
      GoRoute(
        path: '/list/:categoryId',
        pageBuilder: (_, s) => _cp(s, SpecialistListPage(
          categoryId: s.pathParameters['categoryId'],
          title: s.extra as String?,
        )),
      ),

      // Categories grid
      GoRoute(path: '/categories', pageBuilder: (_, s) => _cp(s, const CategoriesGridPage())),
      GoRoute(path: '/announcements', pageBuilder: (_, s) => _cp(s, const AnnouncementsPage())),
      GoRoute(
        path: '/announcements/:id',
        pageBuilder: (_, s) {
          final appParam = s.uri.queryParameters['app'];
          return _cp(s, AnnouncementDetailPage(
            id: int.parse(s.pathParameters['id']!),
            existingApplicationId: appParam != null ? int.tryParse(appParam) : null,
          ));
        },
      ),

      // Master detail
      GoRoute(
        path: '/master/:id',
        pageBuilder: (_, s) => _cp(s, MasterDetailPage(
          masterId: int.parse(s.pathParameters['id']!),
        )),
      ),

      // Generic user profile (works for both clients and masters; masters
      // get a "View full profile" CTA that pushes /master/<id>).
      GoRoute(
        path: '/user/:id',
        pageBuilder: (_, s) => _cp(s, UserDetailPage(
          userId: int.parse(s.pathParameters['id']!),
        )),
      ),

      // Chat — generic (preview) and per-application (real backend chat)
      GoRoute(path: '/chat', pageBuilder: (_, s) => _cp(s, const ChatPage())),
      GoRoute(
        path: '/chat/application/:id',
        pageBuilder: (_, s) => _cp(s, ChatPage(
          applicationId: int.parse(s.pathParameters['id']!),
        )),
      ),
      GoRoute(
        path: '/chat/order/:id',
        pageBuilder: (_, s) => _cp(s, ChatPage(
          orderId: int.parse(s.pathParameters['id']!),
        )),
      ),

      GoRoute(path: '/notifications', pageBuilder: (_, s) => _cp(s, const NotificationsPage())),
      GoRoute(path: '/addresses/new', pageBuilder: (_, s) => _cp(s, const AddAddressPage())),
      GoRoute(path: '/profile', pageBuilder: (_, s) => _cp(s, const ProfilePage())),
      GoRoute(path: '/profile/edit', pageBuilder: (_, s) => _cp(s, const ProfileEditPage())),
      GoRoute(path: '/payment-methods', pageBuilder: (_, s) => _cp(s, const PaymentMethodsPage())),
      GoRoute(path: '/wallet', pageBuilder: (_, s) => _cp(s, const WalletPage())),
      GoRoute(path: '/payment-methods/new', pageBuilder: (_, s) => _cp(s, const AddPaymentCardPage())),
      GoRoute(path: '/settings', pageBuilder: (_, s) => _cp(s, const SettingsPage())),
    ],
  );
});

// Build a CupertinoPage for GoRouter so every route inherits the native
// iOS-style edge-swipe-back gesture, which is implemented directly inside
// CupertinoPageRoute (not via the Material theme). pageKey keeps the same
// page instance across navigations to a different URL but identical route,
// preventing unintended rebuilds.
CupertinoPage<void> _cp(GoRouterState state, Widget child) =>
    CupertinoPage<void>(key: state.pageKey, child: child);

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: HmColors.bg, body: Center(child: CircularProgressIndicator(color: HmColors.accent)));
}
