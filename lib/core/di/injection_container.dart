import 'package:get_it/get_it.dart';
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
  final DbInterface db = HiveDatasource();
  await db.init();
  sl.registerSingleton<DbInterface>(db);

  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(db: sl()),
  );

  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => CreateNote(sl()));
  sl.registerLazySingleton(() => UpdateNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));
  sl.registerLazySingleton(() => SearchNotes(sl()));
}
