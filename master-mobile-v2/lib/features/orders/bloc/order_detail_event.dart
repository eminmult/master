part of 'order_detail_bloc.dart';

sealed class OrderDetailEvent {
  const OrderDetailEvent();
}

class OrderDetailRequested extends OrderDetailEvent {
  const OrderDetailRequested(this.id, {this.publicFallback = false});
  final int id;

  /// Если backend вернул 403 (например, гость пытается смотреть приватный заказ)
  /// — попытаться открыть через `/orders/public/{id}`.
  final bool publicFallback;
}

class OrderDetailRefreshed extends OrderDetailEvent {
  const OrderDetailRefreshed();
}

class OrderCancelRequested extends OrderDetailEvent {
  const OrderCancelRequested({this.reason});
  final String? reason;
}

class OrderConfirmRequested extends OrderDetailEvent {
  const OrderConfirmRequested();
}

class OrderStatusUpdated extends OrderDetailEvent {
  const OrderStatusUpdated(this.status);
  final String status;
}

class OrderAccepted extends OrderDetailEvent {
  const OrderAccepted();
}

class OrderDeclined extends OrderDetailEvent {
  const OrderDeclined();
}

class OrderConfirmWork extends OrderDetailEvent {
  const OrderConfirmWork({required this.price, this.completedAt, this.note});
  final double price;
  final DateTime? completedAt;
  final String? note;
}

class OrderRejectProposal extends OrderDetailEvent {
  const OrderRejectProposal();
}

// ───────── chat ─────────
class OrderMessagesRequested extends OrderDetailEvent {
  const OrderMessagesRequested();
}

class OrderMessagesRefreshed extends OrderDetailEvent {
  const OrderMessagesRefreshed();
}

class OrderMessageSent extends OrderDetailEvent {
  const OrderMessageSent(this.text, {this.imageDataUri});
  final String text;
  final String? imageDataUri;
}

/// Реалтайм сообщение из Reverb-канала `private-order.{id}`.
class OrderMessageReceived extends OrderDetailEvent {
  const OrderMessageReceived(this.message);
  final Map<String, dynamic> message;
}

// ───────── applications (inbox для клиента) ─────────
class OrderApplicationsRequested extends OrderDetailEvent {
  const OrderApplicationsRequested();
}

// ───────── review ─────────
class OrderReviewSubmitted extends OrderDetailEvent {
  const OrderReviewSubmitted({required this.rating, this.comment});
  final int rating;
  final String? comment;
}
