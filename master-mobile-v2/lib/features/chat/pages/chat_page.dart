import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/chat/bloc/chat_bloc.dart';
import 'package:itez_mobile/features/chat/models/chat_message.dart';
import 'package:itez_mobile/features/chat/repositories/chat_repository.dart';

@RoutePage()
class ChatPage extends StatelessWidget implements AutoRouteWrapper {
  const ChatPage({super.key, @PathParam('orderId') required this.orderId});
  final int orderId;

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ChatBloc(locator<ChatRepository>())..add(ChatRequested(orderId)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Чат · Заказ #$orderId')),
      body: const SafeArea(child: _ChatBody()),
    );
  }
}

class _ChatBody extends StatefulWidget {
  const _ChatBody();

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final _scroll = ScrollController();
  final _input = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(ChatSent(text));
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthBloc>().state.user?.id;
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (p, c) => p.messages.length != c.messages.length,
      listener: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      },
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: state.loading && state.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 8.h),
                      itemCount: state.messages.length,
                      itemBuilder: (_, i) {
                        final msg = state.messages[i];
                        return _Bubble(
                          message: msg,
                          mine: msg.senderId == myId,
                        );
                      },
                    ),
            ),
            _Composer(
              controller: _input,
              sending: state.sending,
              onSend: _send,
            ),
          ],
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final bg = mine
        ? AppColors.brandPrimary
        : Theme.of(context).cardTheme.color ?? AppColors.surfaceLight;
    final fg = mine ? AppColors.white : Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14.r),
            topRight: Radius.circular(14.r),
            bottomLeft: Radius.circular(mine ? 14.r : 4.r),
            bottomRight: Radius.circular(mine ? 4.r : 14.r),
          ),
          border: mine
              ? null
              : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: TextStyle(color: fg, fontSize: 14.sp)),
            if (message.createdAt != null) ...[
              SizedBox(height: 2.h),
              Text(
                message.createdAt!.toLocal().toString().substring(11, 16),
                style: TextStyle(
                  color: fg.withOpacity(0.7),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Сообщение…',
              ),
            ),
          ),
          SizedBox(width: 6.w),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            icon: sending
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
