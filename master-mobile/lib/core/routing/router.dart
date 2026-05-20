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
      GoRoute(path: '/', builder: (_, __) => const _Splash()),

      // Auth flow
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterRolePickerPage()),
      GoRoute(path: '/register/client', builder: (_, __) => const RegisterClientPage()),
      GoRoute(path: '/register/master', builder: (_, __) => const RegisterMasterPage()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: '/reset-password', builder: (context, state) => ResetPasswordPage(
        initialLogin: state.uri.queryParameters['login'],
        token: state.uri.queryParameters['token'],
      )),
      GoRoute(path: '/verify-phone', builder: (_, __) => const VerifyPhonePage()),

      // Main app
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/orders', builder: (_, __) => const MyOrdersPage()),
      GoRoute(
        path: '/order/create',
        builder: (context, state) {
          final masterId = int.tryParse(state.uri.queryParameters['master_id'] ?? '');
          final masterName = state.uri.queryParameters['master_name'];
          final categoryId = int.tryParse(state.uri.queryParameters['category_id'] ?? '');
          return OrderCreatePage(
            preselectedCategoryId: categoryId,
            preferredMasterId: masterId,
            preferredMasterName: masterName,
          );
        },
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) => OrderDetailPage(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/order/:id/review',
        builder: (context, state) => OrderReviewPage(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Specialist list (by category)
      GoRoute(
        path: '/list/:categoryId',
        builder: (context, state) => SpecialistListPage(
          categoryId: state.pathParameters['categoryId'],
          title: state.extra as String?,
        ),
      ),

      // Categories grid
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesGridPage()),
      GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsPage()),
      GoRoute(
        path: '/announcements/:id',
        builder: (context, state) {
          final appParam = state.uri.queryParameters['app'];
          return AnnouncementDetailPage(
            id: int.parse(state.pathParameters['id']!),
            existingApplicationId: appParam != null ? int.tryParse(appParam) : null,
          );
        },
      ),

      // Master detail
      GoRoute(
        path: '/master/:id',
        builder: (context, state) => MasterDetailPage(
          masterId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Generic user profile (works for both clients and masters; masters
      // get a "View full profile" CTA that pushes /master/<id>).
      GoRoute(
        path: '/user/:id',
        builder: (context, state) => UserDetailPage(
          userId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Chat — generic (preview) and per-application (real backend chat)
      GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
      GoRoute(
        path: '/chat/application/:id',
        builder: (context, state) => ChatPage(
          applicationId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/chat/order/:id',
        builder: (context, state) => ChatPage(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),

      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/addresses/new', builder: (_, __) => const AddAddressPage()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const ProfileEditPage()),
      GoRoute(path: '/payment-methods', builder: (_, __) => const PaymentMethodsPage()),
      GoRoute(path: '/wallet', builder: (_, __) => const WalletPage()),
      GoRoute(path: '/payment-methods/new', builder: (_, __) => const AddPaymentCardPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
});

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
