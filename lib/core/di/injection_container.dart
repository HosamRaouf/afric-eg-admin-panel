import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/services/auth_service.dart';
import 'package:afric_eg_admin_panel/features/agenda/data/repositories/agenda_admin_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/agenda/data/repositories/speaker_talk_sync.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/repositories/agenda_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_bloc.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_event.dart';
import 'package:afric_eg_admin_panel/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:afric_eg_admin_panel/features/announcements/presentation/bloc/announcement_bloc.dart';
import 'package:afric_eg_admin_panel/features/announcements/presentation/bloc/announcement_event.dart';
import 'package:afric_eg_admin_panel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/auth/domain/repositories/auth_repository.dart';
import 'package:afric_eg_admin_panel/features/committee/data/repositories/committee_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/repositories/committee_repository.dart';
import 'package:afric_eg_admin_panel/features/committee/presentation/bloc/committee_bloc.dart';
import 'package:afric_eg_admin_panel/features/committee/presentation/bloc/committee_event.dart';
import 'package:afric_eg_admin_panel/features/congress/data/repositories/congress_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/repositories/congress_repository.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_bloc.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_event.dart';
import 'package:afric_eg_admin_panel/features/live_room/data/repositories/live_room_admin_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/repositories/live_room_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_bloc.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_event.dart';
import 'package:afric_eg_admin_panel/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/overview/domain/repositories/overview_repository.dart';
import 'package:afric_eg_admin_panel/features/overview/presentation/bloc/overview_bloc.dart';
import 'package:afric_eg_admin_panel/features/overview/presentation/bloc/overview_event.dart';
import 'package:afric_eg_admin_panel/features/push/data/repositories/push_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/push/domain/repositories/push_repository.dart';
import 'package:afric_eg_admin_panel/features/sponsors/data/repositories/sponsor_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/sponsors/domain/repositories/sponsor_repository.dart';
import 'package:afric_eg_admin_panel/features/sponsors/presentation/bloc/sponsor_bloc.dart';
import 'package:afric_eg_admin_panel/features/sponsors/presentation/bloc/sponsor_event.dart';
import 'package:afric_eg_admin_panel/features/users/data/repositories/users_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/users/domain/repositories/users_repository.dart';
import 'package:afric_eg_admin_panel/features/users/presentation/bloc/users_bloc.dart';
import 'package:afric_eg_admin_panel/features/users/presentation/bloc/users_event.dart';
import 'package:afric_eg_admin_panel/features/workshops/data/repositories/workshop_admin_repository_impl.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/repositories/workshop_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_bloc.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_event.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies({AdminDataSource? dataSource}) async {
  // Services
  sl.registerLazySingleton<AuthService>(() => AuthService());

  // Data Source
  sl.registerLazySingleton<AdminDataSource>(() => dataSource ?? AdminDataSource());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<AuthService>()));
  sl.registerLazySingleton<UsersRepository>(
      () => UsersRepositoryImpl());
  sl.registerLazySingleton<OverviewRepository>(
      () => OverviewRepositoryImpl(sl<AdminDataSource>(), sl<UsersRepository>()));
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
  sl.registerLazySingleton<PushRepository>(
      () => PushRepositoryImpl());
  sl.registerLazySingleton<SponsorRepository>(
      () => SponsorRepositoryImpl(sl<AdminDataSource>()));
  sl.registerLazySingleton<CommitteeRepository>(
      () => CommitteeRepositoryImpl(sl<AdminDataSource>()));

  // Blocs — registered as app-scoped lazy singletons so each feature fetches
  // its data once per admin session. Pages reference `sl<Bloc>()` instead of
  // creating a fresh bloc on every navigation, which previously re-read every
  // collection each time a screen was re-entered. The first `sl<Bloc>()`
  // access constructs the bloc AND dispatches its initial load; navigating
  // away and back reuses the same loaded bloc. Manual refresh is still
  // available where a page exposes it.
  sl.registerLazySingleton<OverviewBloc>(
      () => OverviewBloc(repository: sl())..add(const LoadOverviewEvent()));
  sl.registerLazySingleton<AnnouncementBloc>(
      () => AnnouncementBloc(repository: sl(), pushRepository: sl())
        ..add(const LoadAnnouncementsEvent()));
  sl.registerLazySingleton<SponsorBloc>(
      () => SponsorBloc(repository: sl())..add(const LoadSponsorsEvent()));
  sl.registerLazySingleton<CommitteeBloc>(
      () => CommitteeBloc(repository: sl())..add(const LoadCommitteeEvent()));
  sl.registerLazySingleton<WorkshopBloc>(
      () => WorkshopBloc(repository: sl())..add(const LoadWorkshopsEvent()));
  sl.registerLazySingleton<CongressBloc>(
      () => CongressBloc(repository: sl())..add(const LoadCongressEvent()));
  sl.registerLazySingleton<AgendaBloc>(
      () => AgendaBloc(
        repository: sl(),
        speakerTalkSync: SpeakerTalkSync(
          dataSource: sl<AdminDataSource>(),
          users: sl<UsersRepository>(),
        ),
      )..add(const LoadAgendaEvent()));
  sl.registerLazySingleton<UsersBloc>(
      () => UsersBloc(repository: sl())..add(const LoadUsersEvent()));
  sl.registerLazySingleton<LiveRoomsBloc>(
      () => LiveRoomsBloc(repository: sl())..add(const LoadLiveRoomsEvent()));
}
