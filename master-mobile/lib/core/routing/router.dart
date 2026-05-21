import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/routing/auth_gate.dart';
import 'package:master_mobile/core/routing/guards.dart';
import 'package:master_mobile/core/routing/route_error_page.dart';
import 'package:master_mobile/core/routing/routes.dart';
import 'package:master_mobile/core/routing/shell_page.dart';
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
import 'package:master_mobile/features/onboarding/presentation/language_picker_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/announcement_detail_page.dart';
import 'package:master_mobile/features/orders/presentation/pages/announcements_page.dart';
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
import 'package:master_mobile/features/user_profile/presentation/user_detail_page.dart';
import 'package:master_mobile/features/wallet/presentation/wallet_page.dart';

/// App router. Architecture:
///
///   GoRouter
///   ├── /onboarding/language          (first-launch flow, lives outside shell)
///   ├── /login, /register/*, /verify, /forgot-password, /reset-password
///   │       (auth flow, lives outside shell — login can't sit "inside" a
///   │       protected tab branch because then a logout would have no place
///   │       to land)
///   └── StatefulShellRoute.indexedStack
///       ├── Branch Home          /home, /categories, /category/:slug,
///       │                        /list/:cat, /master/:id, /user/:id
///       ├── Branch Announcements /announcements, /announcements/:id,
///       │                        /chat/application/:id
///       ├── Branch Orders        /orders, /order/:id, /order/:id/review,
///       │                        /order/create, /chat/order/:id
///       └── Branch Profile       /profile, /profile/edit, /wallet,
///                                /payment-methods, /payment-methods/new,
///                                /settings, /notifications,
///                                /addresses/new, /chat
///
/// Each branch owns an independent navigator stack — switching tabs never
/// rebuilds the inactive ones. Drill-down within a branch uses context.push
/// (stacks grow naturally); root-level tab navigation uses
/// navigationShell.goBranch(i) in HmShellPage.
///
/// Redirect logic is composed from RouteGuard instances (OnboardingGuard,
/// AuthGuard) — adding a new guard means a new class, not a new branch in
/// the giant switch.
final routerProvider = Provider<GoRouter>((ref) {
  final guards = RouteGuardChain([OnboardingGuard(), AuthGuard()]);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) => guards.evaluate(ref, state),
    errorBuilder: (_, __) => const RouteErrorPage(),
    routes: [
      // ─── Splash (resolves to /home or /onboarding/language) ────────────
      GoRoute(path: Routes.splash, pageBuilder: (_, s) => _cp(s, const _Splash())),

      // ─── First-launch language picker ──────────────────────────────────
      GoRoute(
        path: Routes.onboardingLanguage,
        pageBuilder: (_, s) => _cp(s, const LanguagePickerPage()),
      ),

      // ─── Auth flow ─────────────────────────────────────────────────────
      GoRoute(path: Routes.login, pageBuilder: (_, s) => _cp(s, const LoginPage())),
      GoRoute(
        path: Routes.register,
        pageBuilder: (_, s) => _cp(s, const RegisterRolePickerPage()),
      ),
      GoRoute(
        path: Routes.registerClient,
        pageBuilder: (_, s) => _cp(s, const RegisterClientPage()),
      ),
      GoRoute(
        path: Routes.registerMaster,
        pageBuilder: (_, s) => _cp(s, const RegisterMasterPage()),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (_, s) => _cp(s, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: Routes.resetPassword,
        pageBuilder: (_, s) => _cp(
          s,
          ResetPasswordPage(
            initialLogin: s.uri.queryParameters['login'],
            token: s.uri.queryParameters['token'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.verifyPhone,
        pageBuilder: (_, s) => _cp(s, const VerifyPhonePage()),
      ),

      // ─── Stateful shell with 4 branches ────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HmShellPage(navigationShell: shell),
        branches: [
          // ─ Branch 0: Home (discovery surface) ────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                pageBuilder: (_, s) => _cp(s, const HomePage()),
                routes: [
                  // Children push on this branch's navigator; back-swipe
                  // returns to /home with its scroll & state intact.
                ],
              ),
              GoRoute(
                path: Routes.categories,
                pageBuilder: (_, s) => _cp(s, const CategoriesGridPage()),
              ),
              GoRoute(
                path: '/category/:slug',
                pageBuilder: (_, s) {
                  // Frontend page already redirects mismatched slugs to
                  // canonical via the master/{slug}.vue pattern; here we
                  // just open whatever the URL says.
                  // Reuses existing SpecialistListPage with a slug param.
                  return _cp(
                    s,
                    SpecialistListPage(
                      categoryId: s.pathParameters['slug'],
                      title: s.extra as String?,
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/list/:categoryId',
                pageBuilder: (_, s) => _cp(
                  s,
                  SpecialistListPage(
                    categoryId: s.pathParameters['categoryId'],
                    title: s.extra as String?,
                  ),
                ),
              ),
              GoRoute(
                path: '/master/:id',
                pageBuilder: (_, s) => _cp(
                  s,
                  MasterDetailPage(masterId: int.parse(s.pathParameters['id']!)),
                ),
              ),
              GoRoute(
                path: '/user/:id',
                pageBuilder: (_, s) => _cp(
                  s,
                  UserDetailPage(userId: int.parse(s.pathParameters['id']!)),
                ),
              ),
            ],
          ),

          // ─ Branch 1: Announcements (public order board) ──────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.announcements,
                pageBuilder: (_, s) => _cp(s, const AnnouncementsPage()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, s) {
                      final appParam = s.uri.queryParameters['app'];
                      return _cp(
                        s,
                        AnnouncementDetailPage(
                          id: int.parse(s.pathParameters['id']!),
                          existingApplicationId:
                              appParam != null ? int.tryParse(appParam) : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/chat/application/:id',
                pageBuilder: (_, s) => _cp(
                  s,
                  ChatPage(applicationId: int.parse(s.pathParameters['id']!)),
                ),
              ),
            ],
          ),

          // ─ Branch 2: Orders (auth-gated via AuthGate widget) ────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.orders,
                pageBuilder: (_, s) => _cp(
                  s,
                  Builder(builder: (ctx) {
                    final loc = ctx.l10n;
                    return AuthGate(
                      nextPath: Routes.orders,
                      placeholderTitle: loc.guest_orders_title,
                      placeholderBody: loc.guest_orders_body,
                      child: const MyOrdersPage(),
                    );
                  }),
                ),
              ),
              GoRoute(
                path: '/order/create',
                pageBuilder: (_, s) {
                  final masterId = int.tryParse(s.uri.queryParameters['master_id'] ?? '');
                  final masterName = s.uri.queryParameters['master_name'];
                  final categoryId = int.tryParse(s.uri.queryParameters['category_id'] ?? '');
                  return _cp(
                    s,
                    OrderCreatePage(
                      preselectedCategoryId: categoryId,
                      preferredMasterId: masterId,
                      preferredMasterName: masterName,
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/order/:id',
                pageBuilder: (_, s) => _cp(
                  s,
                  OrderDetailPage(orderId: int.parse(s.pathParameters['id']!)),
                ),
              ),
              GoRoute(
                path: '/order/:id/review',
                pageBuilder: (_, s) => _cp(
                  s,
                  OrderReviewPage(orderId: int.parse(s.pathParameters['id']!)),
                ),
              ),
              GoRoute(
                path: '/chat/order/:id',
                pageBuilder: (_, s) => _cp(
                  s,
                  ChatPage(orderId: int.parse(s.pathParameters['id']!)),
                ),
              ),
            ],
          ),

          // ─ Branch 3: Profile (auth-gated via AuthGate widget) ───────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                pageBuilder: (_, s) => _cp(
                  s,
                  Builder(builder: (ctx) {
                    final loc = ctx.l10n;
                    return AuthGate(
                      nextPath: Routes.profile,
                      placeholderTitle: loc.guest_profile_title,
                      placeholderBody: loc.guest_profile_body,
                      child: const ProfilePage(),
                    );
                  }),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (_, s) => _cp(s, const ProfileEditPage()),
                  ),
                ],
              ),
              GoRoute(
                path: Routes.wallet,
                pageBuilder: (_, s) => _cp(s, const WalletPage()),
              ),
              GoRoute(
                path: Routes.paymentMethods,
                pageBuilder: (_, s) => _cp(s, const PaymentMethodsPage()),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (_, s) => _cp(s, const AddPaymentCardPage()),
                  ),
                ],
              ),
              GoRoute(
                path: Routes.settings,
                pageBuilder: (_, s) => _cp(s, const SettingsPage()),
              ),
              GoRoute(
                path: Routes.notifications,
                pageBuilder: (_, s) => _cp(s, const NotificationsPage()),
              ),
              GoRoute(
                path: Routes.addressesNew,
                pageBuilder: (_, s) => _cp(s, const AddAddressPage()),
              ),
              GoRoute(
                path: Routes.chat,
                pageBuilder: (_, s) => _cp(s, const ChatPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// Build a CupertinoPage for GoRouter so every route inherits the native
// iOS-style edge-swipe-back gesture, which is implemented directly inside
// CupertinoPageRoute (not via the Material theme).
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
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: HmColors.bg,
        body: Center(child: CircularProgressIndicator(color: HmColors.accent)),
      );
}
