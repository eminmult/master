import 'package:get_it/get_it.dart';
import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/push/push_service.dart';
import 'package:itez_mobile/core/realtime/realtime_service.dart';
import 'package:itez_mobile/features/addresses/bloc/active_address_cubit.dart';
import 'package:itez_mobile/features/addresses/bloc/addresses_bloc.dart';
import 'package:itez_mobile/features/addresses/repositories/address_repository.dart';
import 'package:itez_mobile/features/announcements/bloc/announcements_bloc.dart';
import 'package:itez_mobile/features/applications/repositories/application_repository.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/auth/repositories/auth_repository.dart';
import 'package:itez_mobile/features/calls/bloc/call_bloc.dart';
import 'package:itez_mobile/features/calls/repositories/call_repository.dart';
import 'package:itez_mobile/features/categories/repositories/category_repository.dart';
import 'package:itez_mobile/features/chat/repositories/chat_repository.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';
import 'package:itez_mobile/features/notifications/bloc/notifications_bloc.dart';
import 'package:itez_mobile/features/notifications/repositories/notification_repository.dart';
import 'package:itez_mobile/features/orders/gps_tracking/gps_pusher.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';
import 'package:itez_mobile/features/profile/repositories/profile_repository.dart';
import 'package:itez_mobile/features/wallet/repositories/wallet_repository.dart';

final locator = GetIt.I;

/// Регистрация singletons. Repositories для фич регистрируются здесь;
/// глобальные BLoC'и (Auth, Notifications, Call) — тоже здесь, чтобы доставать
/// их из guards/services где нет BuildContext.
void setupLocator() {
  if (locator.isRegistered<ApiClient>()) return;

  locator.registerLazySingleton<ApiClient>(() => ApiClient());

  // ─── Phase 1: Auth ───
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<AuthBloc>(
    () => AuthBloc(repository: locator<AuthRepository>()),
  );

  // ─── Phase 2: Catalog ───
  locator.registerLazySingleton<CategoryRepository>(
    () => CategoryRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<MasterRepository>(
    () => MasterRepository(locator<ApiClient>()),
  );

  // ─── Phase 3: Orders + Addresses + Profile ───
  locator.registerLazySingleton<OrderRepository>(
    () => OrderRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<AddressRepository>(
    () => AddressRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<AddressesBloc>(
    () => AddressesBloc(locator<AddressRepository>()),
  );
  locator.registerLazySingleton<ActiveAddressCubit>(
    () => ActiveAddressCubit(locator<AddressesBloc>()),
  );

  // ─── Phase 4: Realtime / Push / Calls / Chat / Wallet / Notifications ───
  locator.registerLazySingleton<RealtimeService>(() => RealtimeService());
  locator.registerLazySingleton<PushService>(
    () => PushService(locator<ApiClient>()),
  );

  locator.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<NotificationsBloc>(
    () => NotificationsBloc(locator<NotificationRepository>()),
  );

  locator.registerLazySingleton<ChatRepository>(
    () => ChatRepository(locator<ApiClient>()),
  );

  locator.registerLazySingleton<CallRepository>(
    () => CallRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<CallBloc>(
    () => CallBloc(locator<CallRepository>()),
  );

  locator.registerLazySingleton<WalletRepository>(
    () => WalletRepository(locator<ApiClient>()),
  );

  // Announcements использует OrderRepository.publicFeed — отдельный
  // singleton, чтобы лента не пересоздавалась при каждом возврате на таб.
  locator.registerLazySingleton<AnnouncementsBloc>(
    () => AnnouncementsBloc(locator<OrderRepository>()),
  );

  // Applications (отклики мастеров).
  locator.registerLazySingleton<ApplicationRepository>(
    () => ApplicationRepository(locator<ApiClient>()),
  );

  // GPS uplink для мастера во время on_the_way/arrived/in_progress.
  locator.registerLazySingleton<GpsPusher>(
    () => GpsPusher(orders: locator<OrderRepository>()),
  );
}
