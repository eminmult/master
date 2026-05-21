/// Typed, single source of truth for every URL the app navigates to.
///
/// Why this exists (architecture decision record):
///
/// - Magic strings (`context.push('/master/' + id)`) decay silently when
///   routes are renamed and pollute every page with hard-coded paths.
/// - go_router has no compile-time guard against a path/argument mismatch.
/// - The first time we ship a deep-link from a push notification, we need a
///   single place that knows how to build EVERY URL — not a treasure hunt
///   through 80 widget files.
///
/// Rule: never write a route string inline. If you need a route somewhere,
/// add a builder here and use it via `Routes.master(19)`.
abstract final class Routes {
  // ─── First-launch / onboarding ──────────────────────────────────────────
  static const splash = '/';
  static const onboardingLanguage = '/onboarding/language';

  // ─── Auth flow (lives outside the bottom-nav shell) ─────────────────────
  static const login = '/login';
  static String loginWithNext(String returnTo) =>
      '$login?next=${Uri.encodeComponent(returnTo)}';
  static const register = '/register';
  static const registerClient = '/register/client';
  static const registerMaster = '/register/master';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyPhone = '/verify-phone';

  // ─── Tabs (root of each shell branch) ───────────────────────────────────
  static const home = '/home';
  static const announcements = '/announcements';
  static const orders = '/orders';
  static const profile = '/profile';

  // ─── Drill-down within "Home" branch ────────────────────────────────────
  static const categories = '/categories';
  static String category(String slug) => '/category/$slug';
  static String specialists(String categoryId) => '/list/$categoryId';
  static String master(int id) => '/master/$id';
  static String user(int id) => '/user/$id';

  // ─── Drill-down within "Announcements" branch ───────────────────────────
  static String announcement(int id, {int? applicationId}) {
    final base = '/announcements/$id';
    return applicationId != null ? '$base?app=$applicationId' : base;
  }
  static String chatApplication(int applicationId) => '/chat/application/$applicationId';

  // ─── Drill-down within "Orders" branch ──────────────────────────────────
  static String orderCreate({int? masterId, String? masterName, int? categoryId}) {
    final params = <String, String>{};
    if (masterId != null) params['master_id'] = masterId.toString();
    if (masterName != null) params['master_name'] = masterName;
    if (categoryId != null) params['category_id'] = categoryId.toString();
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return qs.isEmpty ? '/order/create' : '/order/create?$qs';
  }
  static String order(int id) => '/order/$id';
  static String orderReview(int id) => '/order/$id/review';
  static String chatOrder(int orderId) => '/chat/order/$orderId';

  // ─── Drill-down within "Profile" branch ─────────────────────────────────
  static const profileEdit = '/profile/edit';
  static const paymentMethods = '/payment-methods';
  static const paymentMethodsNew = '/payment-methods/new';
  static const wallet = '/wallet';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const addressesNew = '/addresses/new';

  // ─── Misc ───────────────────────────────────────────────────────────────
  static const chat = '/chat';

  /// True if the given location lives inside an authenticated branch.
  /// Used by RouteGuard chain to decide whether a guest can reach it.
  static bool isProtected(String location) {
    return location.startsWith('/profile') ||
        location.startsWith('/orders') ||
        location.startsWith('/order/') ||
        location.startsWith('/chat') ||
        location.startsWith('/wallet') ||
        location.startsWith('/payment-methods') ||
        location.startsWith('/settings') ||
        location.startsWith('/notifications') ||
        location.startsWith('/addresses/');
  }

  /// True if the given location is one of the auth-flow surfaces.
  static bool isAuthGate(String location) {
    return location == login ||
        location.startsWith('/register') ||
        location.startsWith('/forgot-password') ||
        location.startsWith('/reset-password') ||
        location.startsWith('/verify');
  }

  /// True if the given location is OK for a guest to view.
  static bool isPublic(String location) {
    if (location == splash || location == onboardingLanguage) return true;
    if (location == home || location == categories || location == announcements) return true;
    if (location.startsWith('/announcements/') ||
        location.startsWith('/list/') ||
        location.startsWith('/master/') ||
        location.startsWith('/user/') ||
        location.startsWith('/category/')) return true;
    return isAuthGate(location);
  }
}
