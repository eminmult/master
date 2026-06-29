import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/common/widgets/app_text_field.dart';
import 'package:itez_mobile/features/addresses/bloc/addresses_bloc.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';

@RoutePage()
class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key, this.initial});
  final AddressModel? initial;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final TextEditingController _label;
  late final TextEditingController _full;
  late final TextEditingController _entrance;
  late final TextEditingController _floor;
  late final TextEditingController _intercom;
  late final TextEditingController _note;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _label = TextEditingController(text: i?.label);
    _full = TextEditingController(text: i?.fullAddress);
    _entrance = TextEditingController(text: i?.entrance);
    _floor = TextEditingController(text: i?.floor);
    _intercom = TextEditingController(text: i?.intercom);
    _note = TextEditingController(text: i?.note);
    _isDefault = i?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _full.dispose();
    _entrance.dispose();
    _floor.dispose();
    _intercom.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final draft = AddressModel(
      id: widget.initial?.id ?? 0,
      label: _label.text.trim().isEmpty ? null : _label.text.trim(),
      fullAddress: _full.text.trim(),
      lat: widget.initial?.lat,
      lng: widget.initial?.lng,
      entrance: _entrance.text.trim().isEmpty ? null : _entrance.text.trim(),
      floor: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
      intercom: _intercom.text.trim().isEmpty ? null : _intercom.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      isDefault: _isDefault,
    );
    final bloc = context.read<AddressesBloc>();
    if (widget.initial == null) {
      bloc.add(AddressCreated(draft));
    } else {
      bloc.add(AddressUpdated(widget.initial!.id, draft));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Новый адрес' : 'Редактирование'),
      ),
      body: BlocConsumer<AddressesBloc, AddressesState>(
        listenWhen: (p, c) =>
            p.mutating != c.mutating && !c.mutating && c.justSavedId != null,
        listener: (context, state) {
          context.router.maybePop();
        },
        builder: (context, state) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _label,
                  label: 'Название (опционально)',
                  hint: 'Дом / Офис / Дача',
                  prefixIcon: Icons.bookmark_outline,
                ),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _full,
                  label: 'Адрес',
                  hint: 'ул. Низами 28, кв. 14',
                  prefixIcon: Icons.place_outlined,
                  maxLines: 2,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _entrance,
                        label: 'Подъезд',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppTextField(
                        controller: _floor,
                        label: 'Этаж',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppTextField(
                        controller: _intercom,
                        label: 'Домофон',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _note,
                  label: 'Заметка для мастера',
                  hint: 'Зайти со двора, окно справа',
                  maxLines: 2,
                ),
                SizedBox(height: 12.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Использовать по умолчанию'),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                SizedBox(height: 16.h),
                AppPrimaryButton(
                  label: 'Сохранить',
                  loading: state.mutating,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
