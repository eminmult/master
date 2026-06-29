part of 'call_bloc.dart';

sealed class CallEvent {
  const CallEvent();
}

class CallOutgoingRequested extends CallEvent {
  const CallOutgoingRequested({required this.calleeId, this.orderId});
  final int calleeId;
  final int? orderId;
}

class CallIncomingArrived extends CallEvent {
  const CallIncomingArrived(this.call);
  final CallModel call;
}

class CallAccepted extends CallEvent {
  const CallAccepted();
}

class CallRejected extends CallEvent {
  const CallRejected();
}

class CallHungUp extends CallEvent {
  const CallHungUp();
}

class CallSignalReceived extends CallEvent {
  const CallSignalReceived(this.signal);
  final CallSignal signal;
}

class CallStatusChanged extends CallEvent {
  const CallStatusChanged(this.status);
  final CallStatus status;
}
