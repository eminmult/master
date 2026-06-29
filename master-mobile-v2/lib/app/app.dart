import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/app_theme.dart';
import 'package:itez_mobile/app/config_bloc/config_bloc.dart';
import 'package:itez_mobile/app/config_model.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/i18n/supported_locales.dart';
import 'package:itez_mobile/l10n/generated/app_localizations.dart';
import 'package:itez_mobile/features/addresses/bloc/active_address_cubit.dart';
import 'package:itez_mobile/features/addresses/bloc/addresses_bloc.dart';
import 'package:itez_mobile/features/announcements/bloc/announcements_bloc.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/calls/bloc/call_bloc.dart';
import 'package:itez_mobile/features/notifications/bloc/notifications_bloc.dart';

class App extends StatefulWidget {
  const App({super.key, required this.configModel});
  final ConfigModel configModel;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _appRouter = AppRouter();

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ConfigBloc(widget.configModel),
          lazy: false,
        ),
        BlocProvider<AuthBloc>(
          create: (_) =>
              locator<AuthBloc>()..add(const AuthBootstrapRequested()),
          lazy: false,
        ),
        BlocProvider<AddressesBloc>(
          create: (_) => locator<AddressesBloc>(),
        ),
        BlocProvider<ActiveAddressCubit>(
          create: (_) => locator<ActiveAddressCubit>(),
          lazy: false,
        ),
        BlocProvider<NotificationsBloc>(
          create: (_) => locator<NotificationsBloc>(),
        ),
        BlocProvider<CallBloc>(
          create: (_) => locator<CallBloc>(),
        ),
        BlocProvider<AnnouncementsBloc>(
          create: (_) => locator<AnnouncementsBloc>(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        child: KeyboardDismisser(
          child: BlocListener<ConfigBloc, ConfigState>(
            listenWhen: (p, c) => p.configModel.locale != c.configModel.locale,
            listener: (_, state) {
              locator<ApiClient>()
                  .setLocale(state.configModel.locale.languageCode);
            },
            child: BlocListener<AuthBloc, AuthState>(
              listenWhen: (p, c) =>
                  (p is AuthAuthenticated) != (c is AuthAuthenticated),
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  // Подтягиваем список адресов + unread-count при логине
                  // — без этого header не будет знать о сохранённых адресах
                  // и непрочитанных уведомлениях до явного открытия экрана.
                  context
                      .read<AddressesBloc>()
                      .add(const AddressesRequested());
                  context
                      .read<NotificationsBloc>()
                      .add(const NotificationsUnreadRefreshed());
                } else if (state is AuthUnauthenticated) {
                  _appRouter.replaceAll([const LoginRoute()]);
                }
              },
              child: BlocBuilder<ConfigBloc, ConfigState>(
                buildWhen: (p, c) => p.configModel != c.configModel,
                builder: (context, state) => MaterialApp.router(
                  title: 'itez',
                  debugShowCheckedModeBanner: false,
                  routerConfig: _appRouter.config(),
                  themeMode: state.configModel.themeMode,
                  locale: state.configModel.locale,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: SupportedLocale.supportedLocales,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
