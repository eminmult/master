import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/payment/data/payment_cards_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Add-card form. PAN + CVV stay on this screen; only brand+last4+exp+holder
/// hit the API. Brand is derived live as the user types so the form preview
/// updates without a round-trip.
class AddPaymentCardPage extends ConsumerStatefulWidget {
  const AddPaymentCardPage({super.key});
  @override
  ConsumerState<AddPaymentCardPage> createState() =>
      _AddPaymentCardPageState();
}

class _AddPaymentCardPageState extends ConsumerState<AddPaymentCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();
  final _holder = TextEditingController();
  bool _isDefault = false;
  bool _busy = false;
  String? _error;
  String _brand = 'unknown';

  @override
  void initState() {
    super.initState();
    _number.addListener(_onNumberChanged);
  }

  @override
  void dispose() {
    _number.dispose();
    _exp.dispose();
    _cvv.dispose();
    _holder.dispose();
    super.dispose();
  }

  void _onNumberChanged() {
    final d = _number.text.replaceAll(RegExp(r'\D'), '');
    final b = _detectBrand(d);
    if (b != _brand) setState(() => _brand = b);
  }

  String _detectBrand(String digits) {
    if (digits.isEmpty) return 'unknown';
    if (digits.startsWith('4')) return 'visa';
    final first2 = int.tryParse(digits.length >= 2 ? digits.substring(0, 2) : '0') ?? 0;
    if (first2 >= 51 && first2 <= 55) return 'mastercard';
    final first4 = int.tryParse(digits.length >= 4 ? digits.substring(0, 4) : '0') ?? 0;
    if (first4 >= 2221 && first4 <= 2720) return 'mastercard';
    if (digits.startsWith('34') || digits.startsWith('37')) return 'amex';
    return 'unknown';
  }

  bool _luhn(String digits) {
    if (digits.length < 12) return false;
    var sum = 0;
    var alt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final digits = _number.text.replaceAll(RegExp(r'\D'), '');
      final parts = _exp.text.split('/');
      final month = int.parse(parts[0]);
      final year2 = int.parse(parts[1]);
      final year = year2 < 100 ? 2000 + year2 : year2;
      await ref.read(paymentCardsRepositoryProvider).add(
            number: digits,
            expMonth: month,
            expYear: year,
            cvv: _cvv.text,
            holderName: _holder.text.trim(),
            isDefault: _isDefault,
          );
      ref.invalidate(paymentCardsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.payment_card_added),
          backgroundColor: HmColors.success,
        ));
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Scaffold(
      backgroundColor: HmColors.bg2,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(children: [
                  HmIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    small: true, flat: true,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/payment-methods'),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(loc.payment_add_card,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4)),
                  ),
                ]),
              ),
              // Live preview card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _PreviewCard(
                  number: _number.text,
                  exp: _exp.text,
                  holder: _holder.text,
                  brand: _brand,
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                ctrl: _number,
                label: loc.payment_card_number,
                hint: '1234 5678 9012 3456',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                  _CardNumberFormatter(),
                ],
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (d.length < 12) return loc.payment_invalid_card;
                  if (!_luhn(d)) return loc.payment_invalid_card;
                  return null;
                },
              ),
              _Field(
                ctrl: _holder,
                label: loc.payment_card_holder,
                hint: 'CARDHOLDER NAME',
                textCapitalization: TextCapitalization.characters,
              ),
              Row(children: [
                Expanded(
                  child: _Field(
                    ctrl: _exp,
                    label: loc.payment_card_exp,
                    hint: 'MM/YY',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpFormatter(),
                    ],
                    validator: (v) {
                      final t = (v ?? '');
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(t)) {
                        return loc.payment_invalid_exp;
                      }
                      final parts = t.split('/');
                      final m = int.tryParse(parts[0]) ?? 0;
                      final y2 = int.tryParse(parts[1]) ?? 0;
                      if (m < 1 || m > 12) return loc.payment_invalid_exp;
                      final y = y2 < 100 ? 2000 + y2 : y2;
                      final now = DateTime.now();
                      final lastDayOfMonth = DateTime(y, m + 1, 0);
                      if (lastDayOfMonth.isBefore(DateTime(now.year, now.month, 1))) {
                        return loc.payment_card_expired;
                      }
                      return null;
                    },
                  ),
                ),
                Expanded(
                  child: _Field(
                    ctrl: _cvv,
                    label: 'CVV',
                    hint: '123',
                    obscure: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (v) {
                      if ((v ?? '').length < 3) return loc.payment_invalid_cvv;
                      return null;
                    },
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: SwitchListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  title: Text(loc.payment_set_as_default,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: HmColors.text2)),
                  activeColor: HmColors.accent,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1FEF4444),
                      border: Border.all(color: const Color(0x4DEF4444)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: HmColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: HmColors.danger, fontSize: 12.5))),
                    ]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: SizedBox(
                  width: double.infinity, height: 50,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.black))
                        : const Icon(Icons.check_rounded,
                            size: 16, color: Colors.black),
                    label: Text(_busy ? loc.profile_saving : loc.payment_save_card,
                        style: const TextStyle(color: Colors.black)),
                    style: FilledButton.styleFrom(
                      backgroundColor: HmColors.accent,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(children: [
                  const Icon(Icons.lock_rounded,
                      size: 12, color: HmColors.text5),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(loc.payment_security_note,
                        style: const TextStyle(
                            fontSize: 11, color: HmColors.text5, height: 1.4)),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl, required this.label,
    this.hint, this.keyboardType, this.obscure = false,
    this.inputFormatters, this.validator,
    this.textCapitalization = TextCapitalization.none,
  });
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HmColors.border2),
        ),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: const TextStyle(
              fontSize: 14, color: HmColors.text2, letterSpacing: 0.5),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(color: HmColors.text4, fontSize: 13),
            hintStyle: const TextStyle(color: HmColors.text5, fontSize: 13),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          validator: validator,
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.number, required this.exp,
    required this.holder, required this.brand,
  });
  final String number;
  final String exp;
  final String holder;
  final String brand;
  @override
  Widget build(BuildContext context) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final formatted = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) formatted.write(' ');
      formatted.write(i < digits.length ? digits[i] : '•');
    }
    final (label, color) = switch (brand) {
      'visa' => ('VISA', const Color(0xFFFFD200)),
      'mastercard' => ('MC', const Color(0xFFEB001B)),
      'amex' => ('AMEX', const Color(0xFF2E77BB)),
      _ => ('•', HmColors.text5),
    };
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F1F1F), Color(0xFF0A0A0A)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HmColors.border2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.contactless_rounded,
                size: 20, color: HmColors.text4),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.8)),
            ),
          ]),
          const Spacer(),
          Text(formatted.toString(),
              style: const TextStyle(
                  fontSize: 17,
                  letterSpacing: 1.6,
                  color: HmColors.text,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.payment_card_holder.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 8,
                          color: HmColors.text5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800)),
                  Text(holder.isEmpty ? '—' : holder.toUpperCase(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: HmColors.text2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.payment_card_exp.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 8,
                        color: HmColors.text5,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800)),
                Text(exp.isEmpty ? '••/••' : exp,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: HmColors.text2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6)),
              ],
            ),
          ]),
        ]),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) out.write(' ');
      out.write(digits[i]);
    }
    return TextEditingValue(
      text: out.toString(),
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _ExpFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) out.write('/');
      out.write(digits[i]);
    }
    return TextEditingValue(
      text: out.toString(),
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
