import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        children: const [
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Политика приватности'),
            trailing: Icon(Icons.open_in_new),
          ),
          ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Условия использования'),
            trailing: Icon(Icons.open_in_new),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('О приложении'),
          ),
        ],
      ),
    );
  }
}
