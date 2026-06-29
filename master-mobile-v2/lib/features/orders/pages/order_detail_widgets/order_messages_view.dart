import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/orders/bloc/order_detail_bloc.dart';

/// Inline-чат заказа: список bubble + system cards + composer с attach.
/// Поллинг — 10 сек; список scroll-pinned-to-bottom.
class OrderMessagesView extends StatefulWidget {
  const OrderMessagesView({super.key});

  @override
  State<OrderMessagesView> createState() => _OrderMessagesViewState();
}

class _OrderMessagesViewState extends State<OrderMessagesView> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  Timer? _poll;
  bool _attaching = false;

  @override
  void initState() {
    super.initState();
    context.read<OrderDetailBloc>().add(const OrderMessagesRequested());
    _poll = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      context.read<OrderDetailBloc>().add(const OrderMessagesRefreshed());
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<OrderDetailBloc>().add(OrderMessageSent(text));
    _input.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _attachPhoto() async {
    if (_attaching) return;
    final src = await showModalBottomSheet<ImageSource?>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded,
                    color: AppColors.accent),
                title: Text(context.l10n.chat_attach_camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.accent),
                title: Text(context.l10n.chat_attach_gallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (src == null || !mounted) return;
    setState(() => _attaching = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: src,
        maxWidth: 1600,
        imageQuality: 75,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.chat_photo_too_big),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }
      final mime = file.mimeType ?? _guessMime(file.name);
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      context.read<OrderDetailBloc>().add(OrderMessageSent(
            '',
            imageDataUri: 'data:$mime;base64,$b64',
          ));
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.chat_photo_failed),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthBloc>().state.user?.id;
    return BlocConsumer<OrderDetailBloc, OrderDetailState>(
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
              child: state.messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.l10n.chat_empty_hint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      itemCount: state.messages.length,
                      itemBuilder: (_, i) {
                        final m = state.messages[i];
                        // Системные сообщения: backend кладёт `payload._type`
                        // или `system_type`. Рендерим отдельной карточкой
                        // вместо обычного bubble.
                        final systemType = _systemType(m);
                        if (systemType != null) {
                          return _SystemCard(
                            type: systemType,
                            payload: _systemPayload(m),
                            createdAt: m['created_at']?.toString(),
                          );
                        }
                        final senderId = parseInt(m['sender_id']);
                        return _Bubble(
                          message: m,
                          mine: myId != null && senderId == myId,
                        );
                      },
                    ),
            ),
            _Composer(
              controller: _input,
              sending: state.sendingMessage || _attaching,
              onSend: _sendText,
              onAttach: _attachPhoto,
            ),
          ],
        );
      },
    );
  }

  String? _systemType(Map<String, dynamic> m) {
    final st = m['system_type']?.toString();
    if (st != null && st.isNotEmpty) return st;
    final payload = m['payload'];
    if (payload is Map && payload['_type'] != null) {
      return payload['_type'].toString();
    }
    return null;
  }

  Map<String, dynamic> _systemPayload(Map<String, dynamic> m) {
    final p = m['payload'];
    if (p is Map<String, dynamic>) return p;
    if (p is Map) {
      return p.map((k, v) => MapEntry(k.toString(), v));
    }
    return m;
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final Map<String, dynamic> message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final text = (message['text'] ?? message['message'] ?? '').toString();
    final imageUrl =
        (message['image_url'] ?? message['image'])?.toString();
    final createdAt = message['created_at']?.toString();

    final bg = mine ? AppColors.accent : AppColors.surface;
    final fg = mine ? AppColors.black : AppColors.text;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
          border: mine ? null : Border.all(color: AppColors.border2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _openLightbox(context, imageUrl),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(fontSize: 14, color: fg, height: 1.4),
              ),
            if (createdAt != null && createdAt.length >= 16) ...[
              const SizedBox(height: 2),
              Text(
                createdAt.substring(11, 16),
                style: TextStyle(
                  color: fg.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openLightbox(BuildContext context, String url) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _ChatPhotoLightbox(url: url),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _ChatPhotoLightbox extends StatelessWidget {
  const _ChatPhotoLightbox({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Системная карточка в чате — proposal / confirmed / rejected / work_started
/// / callout_paid. Отрисовывается по центру, не bubble.
class _SystemCard extends StatelessWidget {
  const _SystemCard({
    required this.type,
    required this.payload,
    required this.createdAt,
  });
  final String type;
  final Map<String, dynamic> payload;
  final String? createdAt;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (icon, label, info) = _render(l, type, payload);
    final time = createdAt != null && createdAt!.length >= 16
        ? createdAt!.substring(11, 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                  if (info != null && info.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      info,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.text2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (time != null) ...[
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.text5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (IconData, String, String?) _render(
    dynamic l,
    String type,
    Map<String, dynamic> p,
  ) {
    switch (type) {
      case 'proposal':
        final price = p['price'];
        final date = p['date'];
        final info = [
          if (price != null) '$price AZN',
          if (date != null) date.toString(),
        ].join(' · ');
        return (Icons.handshake_rounded, l.chat_sys_proposal, info);
      case 'confirmed':
        return (
          Icons.check_circle_rounded,
          l.chat_sys_confirmed,
          null,
        );
      case 'rejected':
        return (Icons.refresh_rounded, l.chat_sys_rejected, null);
      case 'work_started':
        final dur = p['duration'];
        return (
          Icons.construction_rounded,
          l.chat_sys_work_started,
          dur != null ? '~$dur min' : null,
        );
      case 'callout_paid':
        final amount = p['amount'];
        final currency = p['currency']?.toString() ?? 'AZN';
        return (
          Icons.payments_rounded,
          l.chat_sys_callout_paid,
          amount != null ? '$amount $currency' : null,
        );
      default:
        return (Icons.info_outline_rounded, l.chat_sys_default, null);
    }
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: sending ? null : onAttach,
            icon: const Icon(Icons.attach_file_rounded,
                size: 20, color: AppColors.text4),
            tooltip: 'Attach',
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: context.l10n.chat_composer_hint,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.border2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.border2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                      color: AppColors.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : onSend,
              child: SizedBox(
                width: 42,
                height: 42,
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: AppColors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: AppColors.black, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
