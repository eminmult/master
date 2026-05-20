import 'package:master_mobile/features/applications/data/models/application.dart';
import 'package:master_mobile/features/orders/data/models/order.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';

/// Translates a backend [OrderStatus] enum into the active locale. Used by
/// the order list (`/orders`) and the order detail (`/order/:id`) so the same
/// status label everywhere reads the same way.
String orderStatusLabel(AppLocalizations loc, OrderStatus s) {
  switch (s) {
    case OrderStatus.searching:
    case OrderStatus.pendingMaster:
      return loc.order_status_searching;
    case OrderStatus.discussion:
      return loc.order_status_in_discussion;
    case OrderStatus.pendingClient:
      return loc.order_status_pending_client;
    case OrderStatus.pendingPayment:
      return loc.order_status_pending_payment;
    case OrderStatus.confirmed:
    case OrderStatus.accepted:
      return loc.order_status_confirmed;
    case OrderStatus.onTheWay:
      return loc.order_status_on_the_way;
    case OrderStatus.arrived:
      return loc.order_status_arrived;
    case OrderStatus.inProgress:
      return loc.order_status_in_progress;
    case OrderStatus.awaitingCompletion:
    case OrderStatus.awaitingReview:
      return loc.order_status_awaiting;
    case OrderStatus.completed:
    case OrderStatus.closed:
      return loc.order_status_completed;
    case OrderStatus.canceledByClient:
    case OrderStatus.canceledByMaster:
    case OrderStatus.canceledBySystem:
      return loc.order_status_canceled;
    case OrderStatus.disputed:
      return loc.order_status_disputed;
    default:
      return loc.order_status_draft;
  }
}

String applicationStatusLabel(AppLocalizations loc, ApplicationStatus s) {
  switch (s) {
    case ApplicationStatus.pending:    return loc.app_status_applied;
    case ApplicationStatus.discussing: return loc.app_status_discussing;
    case ApplicationStatus.proposed:   return loc.app_status_proposed;
    case ApplicationStatus.accepted:   return loc.app_status_accepted;
    case ApplicationStatus.rejected:   return loc.app_status_rejected;
    case ApplicationStatus.withdrawn:  return loc.app_status_withdrawn;
    default:                           return '';
  }
}
