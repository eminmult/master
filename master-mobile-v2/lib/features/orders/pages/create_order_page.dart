import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/hm_icon_button.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/features/addresses/bloc/addresses_bloc.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/categories/bloc/categories_bloc.dart';
import 'package:itez_mobile/features/categories/models/category_model.dart';
import 'package:itez_mobile/features/categories/repositories/category_repository.dart';
import 'package:itez_mobile/features/orders/bloc/create_order_bloc.dart';
import 'package:itez_mobile/features/orders/models/create_order_draft.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

/// Multi-step order creation — точный порт `order_create_page.dart` из
/// master-mobile.
///
/// Step 0 — выбор категории (grid 2-col с круглой иконкой)
/// Step 1 — описание + фото (max 5)
/// Step 2 — выбор адреса из сохранённых
///
/// Sticky FilledButton 52h внизу: «Продолжить» → «Продолжить» → «Создать».
@RoutePage()
class CreateOrderPage extends StatelessWidget implements AutoRouteWrapper {
  const CreateOrderPage({
    super.key,
    this.preferredMasterId,
    this.preferredMasterName,
    this.preselectedCategoryId,
  });

  final int? preferredMasterId;
  final String? preferredMasterName;
  final int? preselectedCategoryId;

  @override
  Widget wrappedRoute(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CreateOrderBloc(locator<OrderRepository>()),
        ),
        BlocProvider(
          create: (_) => CategoriesBloc(locator<CategoryRepository>())
            ..add(const CategoriesRequested()),
        ),
      ],
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Form(
      preferredMasterId: preferredMasterId,
      preferredMasterName: preferredMasterName,
      preselectedCategoryId: preselectedCategoryId,
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({
    required this.preferredMasterId,
    required this.preferredMasterName,
    required this.preselectedCategoryId,
  });
  final int? preferredMasterId;
  final String? preferredMasterName;
  final int? preselectedCategoryId;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  int _step = 0;
  int? _categoryId;
  final _description = TextEditingController();
  AddressModel? _selectedAddress;
  bool _busy = false;
  String? _error;

  final List<String> _photos = [];
  static const int _maxPhotos = 5;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.preselectedCategoryId;
    if (_categoryId != null) _step = 1;
    // Гарантируем список адресов (на случай гостя, который только что вошёл).
    final addr = context.read<AddressesBloc>();
    if (addr.state.items.isEmpty && !addr.state.loading) {
      addr.add(const AddressesRequested());
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (_step == 0) return _categoryId != null;
    if (_step == 1) return _description.text.trim().length >= 5;
    return _selectedAddress != null;
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= _maxPhotos) return;
    final picker = ImagePicker();
    final remaining = _maxPhotos - _photos.length;
    final picked = await picker.pickMultiImage(
      imageQuality: 80,
      limit: remaining,
    );
    if (picked.isEmpty) return;
    setState(() => _busy = true);
    final encoded = <String>[];
    for (final x in picked.take(remaining)) {
      try {
        final bytes = await x.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) continue;
        encoded.add('data:${x.mimeType ?? "image/jpeg"};base64,${base64Encode(bytes)}');
      } catch (_) {/* skip broken */}
    }
    if (!mounted) return;
    setState(() {
      _photos.addAll(encoded);
      _busy = false;
    });
  }

  void _removePhoto(int idx) =>
      setState(() => _photos.removeAt(idx));

  void _submit() {
    final addr = _selectedAddress!;
    final user = context.read<AuthBloc>().state.user;
    final draft = CreateOrderDraft(
      categoryId: _categoryId!,
      description: _description.text.trim(),
      fullAddress: addr.fullAddress,
      lat: addr.lat,
      lng: addr.lng,
      entrance: addr.entrance,
      floor: addr.floor,
      intercom: addr.intercom,
      contactPhone: user?.phone ?? '',
      desiredTime: DesiredTime.asap,
      urgency: OrderUrgency.normal,
      comment: addr.note,
      preferredMasterId: widget.preferredMasterId,
      photosBase64: _photos,
    );
    context.read<CreateOrderBloc>().add(CreateOrderSubmitted(draft));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocConsumer<CreateOrderBloc, CreateOrderState>(
        listener: (context, state) {
          if (state is CreateOrderSuccess) {
            context.router.replace(OrderDetailRoute(id: state.order.id));
          } else if (state is CreateOrderFailure) {
            setState(() => _error = state.message);
          }
        },
        builder: (context, state) {
          final inProgress = state is CreateOrderInProgress;
          return SafeArea(
            child: Column(
              children: [
                _TopBar(
                  step: _step,
                  onBack: () {
                    if (_step != 0) {
                      setState(() => _step--);
                    } else if (context.router.canPop()) {
                      context.router.maybePop();
                    } else {
                      context.router.replaceAll([const HomeRoute()]);
                    }
                  },
                ),
                if (widget.preferredMasterId != null)
                  _PreferredMasterPill(
                    label: l.order_for_master_label,
                    name: widget.preferredMasterName ??
                        '#${widget.preferredMasterId}',
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: switch (_step) {
                      0 => _CategoryStep(
                          selectedId: _categoryId,
                          onSelect: (id) => setState(() => _categoryId = id),
                        ),
                      1 => _DescribeStep(
                          controller: _description,
                          photos: _photos,
                          maxPhotos: _maxPhotos,
                          busy: _busy,
                          error: _error,
                          onAddPhotos: _pickPhotos,
                          onRemovePhoto: _removePhoto,
                          onChanged: () => setState(() {}),
                        ),
                      _ => _AddressStep(
                          selected: _selectedAddress,
                          error: _error,
                          onSelect: (a) =>
                              setState(() => _selectedAddress = a),
                          onAddNew: () =>
                              context.router.push(AddressFormRoute()),
                        ),
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRadius.pill)),
                      boxShadow: AppShadows.accentGlow,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: !_canContinue || inProgress
                            ? null
                            : () {
                                if (_step < 2) {
                                  setState(() => _step++);
                                } else {
                                  _submit();
                                }
                              },
                        child: inProgress
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.black,
                                ),
                              )
                            : Text(_step < 2
                                ? l.common_continue
                                : l.order_create_submit),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onBack});
  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          HmIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            small: true,
            flat: true,
            onTap: onBack,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= step ? AppColors.accent : AppColors.surface2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _PreferredMasterPill extends StatelessWidget {
  const _PreferredMasterPill({required this.label, required this.name});
  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_pin_circle_rounded,
                size: 18, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── Step 0: category ─────────────────────
class _CategoryStep extends StatelessWidget {
  const _CategoryStep({required this.selectedId, required this.onSelect});
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.order_create_step1_q,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.order_create_step1_sub,
          style: const TextStyle(fontSize: 14, color: AppColors.text5),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, state) => switch (state) {
              CategoriesInitial() || CategoriesLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              CategoriesFailed() => Text(
                  l.auth_failed_to_load,
                  style: const TextStyle(color: AppColors.danger),
                ),
              CategoriesLoaded(:final items) => GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final c = items[i];
                    final selected = selectedId == c.id;
                    return _CategoryTile(
                      category: c,
                      selected: selected,
                      onTap: () => onSelect(c.id),
                    );
                  },
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });
  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : AppColors.accentSoft,
              ),
              child: Icon(
                Icons.handyman_rounded,
                color: selected ? AppColors.black : AppColors.accent,
                size: 20,
              ),
            ),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── Step 1: describe + photos ─────────────────────
class _DescribeStep extends StatelessWidget {
  const _DescribeStep({
    required this.controller,
    required this.photos,
    required this.maxPhotos,
    required this.busy,
    required this.error,
    required this.onAddPhotos,
    required this.onRemovePhoto,
    required this.onChanged,
  });
  final TextEditingController controller;
  final List<String> photos;
  final int maxPhotos;
  final bool busy;
  final String? error;
  final VoidCallback onAddPhotos;
  final ValueChanged<int> onRemovePhoto;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.order_create_step2_title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.order_create_step2_sub,
          style: const TextStyle(fontSize: 14, color: AppColors.text5),
        ),
        const SizedBox(height: 16),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(error!,
                style: const TextStyle(color: AppColors.danger)),
          ),
        TextField(
          controller: controller,
          maxLines: 6,
          maxLength: 1000,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: l.order_create_desc_hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _PhotosPicker(
          photos: photos,
          max: maxPhotos,
          busy: busy,
          onAdd: onAddPhotos,
          onRemove: onRemovePhoto,
        ),
      ],
    );
  }
}

class _PhotosPicker extends StatelessWidget {
  const _PhotosPicker({
    required this.photos,
    required this.max,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });
  final List<String> photos;
  final int max;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canAddMore = photos.length < max && !busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.photo_library_rounded,
              size: 16, color: AppColors.text4),
          const SizedBox(width: 6),
          Text(
            l.order_create_photos_label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          Text(
            '${photos.length}/$max',
            style: const TextStyle(fontSize: 12, color: AppColors.text5),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          l.order_create_photos_hint,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.text5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < photos.length; i++)
              _PhotoTile(
                dataUri: photos[i],
                onRemove: () => onRemove(i),
              ),
            if (canAddMore) _AddPhotoTile(onTap: onAdd),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.dataUri, required this.onRemove});
  final String dataUri;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final commaIdx = dataUri.indexOf(',');
    final b64 = commaIdx >= 0 ? dataUri.substring(commaIdx + 1) : dataUri;
    final Uint8List bytes = base64Decode(b64);
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
      Positioned(
        top: 4,
        right: 4,
        child: Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  color: AppColors.white, size: 14),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.add_a_photo_rounded,
              color: AppColors.text4, size: 22),
        ),
      ),
    );
  }
}

// ───────────────────── Step 2: address ─────────────────────
class _AddressStep extends StatelessWidget {
  const _AddressStep({
    required this.selected,
    required this.error,
    required this.onSelect,
    required this.onAddNew,
  });
  final AddressModel? selected;
  final String? error;
  final ValueChanged<AddressModel> onSelect;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.order_create_step3_title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.order_create_step3_sub,
          style: const TextStyle(fontSize: 14, color: AppColors.text5),
        ),
        const SizedBox(height: 16),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(error!,
                style: const TextStyle(color: AppColors.danger)),
          ),
        Expanded(
          child: BlocBuilder<AddressesBloc, AddressesState>(
            builder: (context, state) {
              if (state.loading && state.items.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2.4,
                  ),
                );
              }
              if (state.error != null && state.items.isEmpty) {
                return Center(
                  child: Text(
                    l.auth_failed_to_load,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                );
              }
              if (state.items.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border2),
                      ),
                      child: const Icon(Icons.location_off_outlined,
                          size: 28, color: AppColors.text5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.address_no_addresses,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.text4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: onAddNew,
                        icon: const Icon(Icons.add_location_alt_rounded,
                            size: 16, color: AppColors.black),
                        label: Text(
                          l.address_add_new,
                          style: const TextStyle(color: AppColors.black),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.black,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: state.items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (i == state.items.length) {
                    return _AddNewTile(
                      label: l.address_add_new,
                      onTap: onAddNew,
                    );
                  }
                  final a = state.items[i];
                  return _AddressTile(
                    address: a,
                    selected: selected?.id == a.id,
                    onTap: () => onSelect(a),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddNewTile extends StatelessWidget {
  const _AddNewTile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 20, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.accent),
          ]),
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });
  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      color: selected ? AppColors.accentSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border2,
            ),
          ),
          child: Row(children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? AppColors.accent : AppColors.text5,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (address.label != null && address.label!.isNotEmpty) ...[
                      Text(
                        address.label!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Text(
                          l.address_default_badge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.text3,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if ((address.entrance?.isNotEmpty ?? false) ||
                      (address.floor?.isNotEmpty ?? false) ||
                      (address.intercom?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (address.entrance?.isNotEmpty == true)
                          '${l.address_entrance}: ${address.entrance}',
                        if (address.floor?.isNotEmpty == true)
                          '${l.address_floor}: ${address.floor}',
                        if (address.intercom?.isNotEmpty == true)
                          '${l.address_intercom}: ${address.intercom}',
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.text5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
