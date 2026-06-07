import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/biometric_datasource.dart';
import '../../features/auth/data/datasources/keystore_channel.dart';
import '../../features/auth/data/datasources/root_detection_channel.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/authenticate_biometric.dart';
import '../../features/auth/domain/usecases/check_root.dart';
import '../../features/auth/domain/usecases/get_encryption_key.dart';
import '../../features/notes/data/datasources/local/db_interface.dart';
import '../../features/notes/data/datasources/local/hive_datasource.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/notes/domain/usecases/create_note.dart';
import '../../features/notes/domain/usecases/delete_note.dart';
import '../../features/notes/domain/usecases/get_notes.dart';
import '../../features/notes/domain/usecases/search_notes.dart';
import '../../features/notes/domain/usecases/update_note.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // -------------------------------------------------------------------------
  // Native channels — singletons, stateless wrappers around MethodChannels
  // -------------------------------------------------------------------------
  sl.registerLazySingleton<KeystoreChannel>(() => KeystoreChannel());
  sl.registerLazySingleton<RootDetectionChannel>(() => RootDetectionChannel());
  sl.registerLazySingleton<BiometricDatasource>(() => BiometricDatasource());

  // -------------------------------------------------------------------------
  // Auth repository + use cases
  // -------------------------------------------------------------------------
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      biometricDatasource: sl(),
      keystoreChannel: sl(),
      rootDetectionChannel: sl(),
    ),
  );

  sl.registerLazySingleton(() => AuthenticateBiometric(sl()));
  sl.registerLazySingleton(() => CheckRoot(sl()));
  sl.registerLazySingleton(() => GetEncryptionKey(sl()));

  // -------------------------------------------------------------------------
  // DB — swap HiveDatasource for DriftDatasource here to change the engine
  // -------------------------------------------------------------------------
  final DbInterface db = HiveDatasource();
  await db.init();
  sl.registerSingleton<DbInterface>(db);

  // -------------------------------------------------------------------------
  // Encryption key — fetched once at startup from native Keystore
  // -------------------------------------------------------------------------
  final encryptionKey = await sl<GetEncryptionKey>().call();

  // -------------------------------------------------------------------------
  // Notes repository + use cases
  // -------------------------------------------------------------------------
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(db: sl(), encryptionKey: encryptionKey),
  );

  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => CreateNote(sl()));
  sl.registerLazySingleton(() => UpdateNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));
  sl.registerLazySingleton(() => SearchNotes(sl()));
}
