/// Все backend endpoints. Один источник правды — менять путь
/// нужно ровно здесь, репозиторий просто склеивает с параметрами.
///
/// Базовый домен переопределяется через `--dart-define=API_BASE_URL=...` при
/// сборке (см. Dockerfile / flutter build команды).
class Urls {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://itez.app/api/v1',
  );

  static const siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://itez.app',
  );

  // ───────── auth (Sanctum, единый Bearer-токен) ─────────
  static const authLogin = '$baseUrl/auth/login';
  static const authRegisterClient = '$baseUrl/auth/register/client';
  static const authRegisterMaster = '$baseUrl/auth/register/master';
  static const authForgotPassword = '$baseUrl/auth/forgot-password';
  static const authResetPassword = '$baseUrl/auth/reset-password';
  static const authVerifyEmail = '$baseUrl/auth/verify-email';
  static const authResendVerification = '$baseUrl/auth/resend-verification';
  static const authChangePassword = '$baseUrl/auth/change-password';
  static const authLogout = '$baseUrl/auth/logout';
  static const authRefresh = '$baseUrl/auth/refresh';
  static const authMe = '$baseUrl/auth/me';
  static const authPhoneRequestOtp = '$baseUrl/auth/phone/request-otp';
  static const authPhoneVerifyOtp = '$baseUrl/auth/phone/verify-otp';

  // ───────── smart search (Gemini AI classifier) ─────────
  static const smartSearch = '$baseUrl/smart-search';

  // ───────── catalog ─────────
  static const categories = '$baseUrl/categories';
  static String category(int id) => '$categories/$id';

  static const masters = '$baseUrl/masters';
  static String master(String idOrSlug) => '$masters/$idOrSlug';
  static String masterReviews(String idOrSlug) =>
      '$masters/$idOrSlug/reviews';

  // Публичные заказы — анонимный пользователь может просматривать.
  static const ordersPublic = '$baseUrl/orders/public';
  static String orderPublic(int id) => '$ordersPublic/$id';

  // ───────── orders ─────────
  static const orders = '$baseUrl/orders';
  static const ordersMy = '$baseUrl/orders/my';
  static const ordersAvailable = '$baseUrl/orders/available';
  static String order(int id) => '$orders/$id';
  static String orderAccept(int id) => '$orders/$id/accept';
  static String orderDecline(int id) => '$orders/$id/decline';
  static String orderConfirm(int id) => '$orders/$id/confirm';
  static String orderRejectProposal(int id) => '$orders/$id/reject-proposal';
  static String orderStatus(int id) => '$orders/$id/status';
  static String orderCancel(int id) => '$orders/$id/cancel';
  static String orderApply(int id) => '$orders/$id/apply';
  static String orderApplications(int id) => '$orders/$id/applications';
  static String orderCalloutFee(int id) => '$orders/$id/callout-fee';

  // ───────── applications (отклики мастеров) ─────────
  static const masterApplications = '$baseUrl/master/applications';
  static String application(int id) => '$baseUrl/order-applications/$id';
  static String applicationStartDiscussion(int id) =>
      '$baseUrl/order-applications/$id/start-discussion';
  static String applicationReject(int id) =>
      '$baseUrl/order-applications/$id/reject';
  static String applicationWithdraw(int id) =>
      '$baseUrl/order-applications/$id/withdraw';
  static String applicationPropose(int id) =>
      '$baseUrl/order-applications/$id/propose';
  static String applicationAcceptProposal(int id) =>
      '$baseUrl/order-applications/$id/accept-proposal';
  static String applicationRejectProposal(int id) =>
      '$baseUrl/order-applications/$id/reject-proposal';
  static String orderPayCallout(int id) => '$orders/$id/pay-callout';
  static String orderReview(int id) => '$orders/$id/review';
  static String orderMessages(int id) => '$orders/$id/messages';

  // ───────── addresses ─────────
  static const addresses = '$baseUrl/addresses';
  static String address(int id) => '$addresses/$id';

  // ───────── profile / user ─────────
  static const clientProfile = '$baseUrl/client/profile';
  static const masterProfile = '$baseUrl/master/profile';
  static const masterStatus = '$baseUrl/master/status';
  static const masterLocation = '$baseUrl/master/location';
  static const masterWorkHours = '$baseUrl/master/work-hours';
  static const masterEarnings = '$baseUrl/master/earnings';
  static const meLocale = '$baseUrl/me/locale';
  static const meExport = '$baseUrl/me/export';
  static const meDelete = '$baseUrl/me/delete';

  // ───────── wallet (master) ─────────
  static const wallet = '$baseUrl/master/wallet';
  static const walletTransactions = '$baseUrl/master/wallet/transactions';
  static const walletWithdraw = '$baseUrl/master/wallet/withdraw';

  // ───────── notifications ─────────
  static const notifications = '$baseUrl/notifications';
  static const notificationsUnreadCount = '$baseUrl/notifications/unread-count';
  static const notificationsReadAll = '$baseUrl/notifications/read-all';
  static String notificationRead(int id) => '$notifications/$id/read';

  // ───────── calls (WebRTC через Reverb) ─────────
  static const calls = '$baseUrl/calls';
  static String call(int id) => '$calls/$id';
  static String callAccept(int id) => '$calls/$id/accept';
  static String callReject(int id) => '$calls/$id/reject';
  static String callEnd(int id) => '$calls/$id/end';
  static String callSignal(int id) => '$calls/$id/signal';

  // ───────── chat ─────────
  static String chatMessages(int orderId) => '$orders/$orderId/messages';
  static const chatUnread = '$baseUrl/chat/unread';

  // ───────── wallet ─────────
  static const walletBalance = '$baseUrl/wallet/balance';
  static const walletTx = '$baseUrl/wallet/transactions';

  // ───────── push (FCM device tokens) ─────────
  static const devicesRegister = '$baseUrl/devices/register';
  static const devicesUnregister = '$baseUrl/devices/unregister';

  // ───────── realtime (Reverb/Pusher) ─────────
  static const reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: 'ws.itez.app',
  );
  static const reverbKey = String.fromEnvironment(
    'REVERB_KEY',
    defaultValue: '',
  );
  static const reverbPort = int.fromEnvironment('REVERB_PORT', defaultValue: 443);
  static const broadcastingAuth = '$siteUrl/broadcasting/auth';
}
