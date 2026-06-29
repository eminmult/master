/// Жизненный цикл заказа со стороны бэка (`Order::STATUS_*`).
/// Все возможные значения собраны в один enum чтобы UI знал, что показывать
/// (цвет, кнопку, доступные действия). На неизвестных строках возвращаем
/// `unknown` — клиент не должен падать, если бэк добавит новый статус.
enum OrderStatus {
  draft('draft', 'Черновик'),
  newOrder('new', 'Новый'),
  searching('searching_master', 'Ищем мастера'),
  pendingMaster('pending_master', 'Ожидает мастера'),
  discussion('discussion', 'Обсуждение'),
  pendingClient('pending_client', 'Ожидает клиента'),
  pendingPayment('pending_payment', 'Ожидает оплаты'),
  confirmed('confirmed', 'Подтверждён'),
  accepted('accepted', 'Принят'),
  onTheWay('on_the_way', 'В пути'),
  arrived('arrived', 'Прибыл'),
  inProgress('in_progress', 'В работе'),
  awaitingCompletion('awaiting_completion', 'Завершается'),
  completed('completed', 'Завершён'),
  awaitingReview('awaiting_review', 'Ждёт отзыва'),
  canceledClient('canceled_by_client', 'Отменён клиентом'),
  canceledMaster('canceled_by_master', 'Отменён мастером'),
  canceledSystem('canceled_by_system', 'Отменён системой'),
  disputed('disputed', 'Спор'),
  closed('closed', 'Закрыт'),
  unknown('unknown', 'Неизвестно');

  const OrderStatus(this.value, this.label);
  final String value;
  final String label;

  static OrderStatus fromValue(String? raw) {
    if (raw == null) return OrderStatus.unknown;
    for (final s in OrderStatus.values) {
      if (s.value == raw) return s;
    }
    return OrderStatus.unknown;
  }

  bool get isActive => const {
        OrderStatus.newOrder,
        OrderStatus.searching,
        OrderStatus.pendingMaster,
        OrderStatus.discussion,
        OrderStatus.pendingClient,
        OrderStatus.pendingPayment,
        OrderStatus.confirmed,
        OrderStatus.accepted,
        OrderStatus.onTheWay,
        OrderStatus.arrived,
        OrderStatus.inProgress,
        OrderStatus.awaitingCompletion,
      }.contains(this);

  bool get isFinished => const {
        OrderStatus.completed,
        OrderStatus.awaitingReview,
        OrderStatus.closed,
      }.contains(this);

  bool get isCanceled => const {
        OrderStatus.canceledClient,
        OrderStatus.canceledMaster,
        OrderStatus.canceledSystem,
      }.contains(this);
}

enum OrderUrgency {
  normal('normal'),
  urgent('urgent');

  const OrderUrgency(this.value);
  final String value;

  static OrderUrgency fromValue(String? raw) =>
      raw == 'urgent' ? OrderUrgency.urgent : OrderUrgency.normal;
}

enum DesiredTime {
  asap('asap'),
  scheduled('scheduled');

  const DesiredTime(this.value);
  final String value;

  static DesiredTime fromValue(String? raw) =>
      raw == 'scheduled' ? DesiredTime.scheduled : DesiredTime.asap;
}
