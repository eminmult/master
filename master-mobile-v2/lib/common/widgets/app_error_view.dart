import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.r, color: Theme.of(context).hintColor),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
