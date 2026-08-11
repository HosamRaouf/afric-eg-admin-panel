import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/services/auth_service.dart';
import 'package:afric_eg_admin_panel/features/agenda/data/repositories/agenda_admin_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/repositories/agenda_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:afric_eg_admin_panel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/auth/domain/repositories/auth_repository.dart';
import 'package:afric_eg_admin_panel/features/congress/data/repositories/congress_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/repositories/congress_repository.dart';
import 'package:afric_eg_admin_panel/features/live_room/data/repositories/live_room_admin_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/repositories/live_room_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/overview/domain/repositories/overview_repository.dart';
import 'package:afric_eg_admin_panel/features/push/data/repositories/push_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/push/domain/repositories/push_repository.dart';
import 'package:afric_eg_admin_panel/features/users/data/repositories/users_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/users/domain/repositories/users_repository.dart';
import 'package:afric_eg_admin_panel/features/workshops/data/repositories/workshop_admin_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/repositories/workshop_admin_repository.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies({AdminDataSource? dataSource}) async {
  // Services
  sl.registerLazySingleton<AuthService>(() => AuthService());

  // Data Source
  sl.registerLazySingleton<AdminDataSource>(() => dataSource ?? AdminDataSource());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<AuthService>()));
  sl.registerLazySingleton<OverviewRepository>(
      () => OverviewRepositoryImpl(sl<AdminDataSource>()));
  sl.registerLazySingleton<CongressRepository>(
      () => CongressRepositoryImpl(sl<AdminDataSource>()));
  sl.registerLazySingleton<AnnouncementRepository>(
      () => AnnouncementRepositoryImpl(sl<AdminDataSource>()));
  sl.registerLazySingleton<AgendaAdminRepository>(
      () => AgendaAdminRepositoryImpl(sl<AdminDataSource>()));
  sl.registerLazySingleton<LiveRoomAdminRepository>(
      () => LiveRoomAdminRepositoryImpl(sl<AdminDataSource>()));
  sl.registerLazySingleton<WorkshopAdminRepository>(
      () => WorkshopAdminRepositoryImpl(sl<AdminDataSource>()));
  sl.registerLazySingleton<UsersRepository>(
      () => UsersRepositoryImpl());
  sl.registerLazySingleton<PushRepository>(
      () => PushRepositoryImpl());
}
