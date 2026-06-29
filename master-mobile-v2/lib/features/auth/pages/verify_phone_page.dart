import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/auth/repositories/auth_repository.dart';

/// Подтверждение телефона по SMS-OTP.
///
/// Доступна только авторизованным (бэк-эндпоинты `/auth/phone/*` находятся
/// под `auth:sanctum`). Поэтому страница используется внутри сессии —
/// например, из Profile → «Подтвердить телефон».
@RoutePage()
class VerifyPhonePage extends StatefulWidget {
  const VerifyPhonePage({super.key});

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final _code = TextEditingController();
  bool _requesting = false;
  bool _verifying = false;
  String? _error;
  int _cooldown = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    unawaited(_requestOtp());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_cooldown > 0) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      await locator<AuthRepository>().requestPhoneOtp();
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _cooldown = 60;
      });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _cooldown -= 1;
          if (_cooldown <= 0) _ticker?.cancel();
        });
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _error = e.message ?? 'Не удалось отправить код';
      });
    }
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await locator<AuthRepository>().verifyPhoneOtp(_code.text.trim());
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthMeRefreshRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Телефон подтверждён')),
      );
      context.router.maybePop();
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.errors?['code']?.first ?? e.message;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.message ?? 'Неверный код';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<AuthBloc>().state.user?.phone ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Подтвердить телефон')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl.w, vertical: AppSpacing.lg.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.lg.h),
              Text(
                'Введите код',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Мы отправили SMS на $phone',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.text4,
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                  color: AppColors.text,
                ),
                decoration: const InputDecoration(
                  hintText: '······',
                  counterText: '',
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 6.h),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.sp,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.lg.h),
              AppPrimaryButton(
                label: 'Подтвердить',
                loading: _verifying,
                onPressed: _verify,
              ),
              SizedBox(height: AppSpacing.md.h),
              Center(
                child: TextButton(
                  onPressed: _cooldown > 0 || _requesting ? null : _requestOtp,
                  child: Text(
                    _cooldown > 0
                        ? 'Повторить через $_cooldown с'
                        : (_requesting
                            ? 'Отправляем…'
                            : 'Отправить ещё раз'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
