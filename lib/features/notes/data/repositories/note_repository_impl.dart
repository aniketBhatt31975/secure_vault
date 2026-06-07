import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/encryption_utils.dart';
import '../datasources/local/db_interface.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DbInterface db;
  final String encryptionKey;

  NoteRepositoryImpl({required this.db, required this.encryptionKey});

  @override
  Future<List<Note>> getNotes() async {
    final models = await db.getNotes();
    return models.map((e) => _decrypt(e)).toList();
  }

  @override
  Future<Note> getNoteById(String id) async {
    final model = await db.getNoteById(id);
    if (model == null) throw StorageException('Note not found: $id');
    return _decrypt(model);
  }

  @override
  Future<void> createNote(Note note) async {
    final model = NoteModel.fromEntity(_encrypt(note));
    await db.insertNote(model);
  }

  @override
  Future<void> updateNote(Note note) async {
    final model = NoteModel.fromEntity(_encrypt(note));
    await db.updateNote(model);
  }

  @override
  Future<void> deleteNote(String id) => db.deleteNote(id);

  @override
  Future<List<Note>> searchNotes(String query) async {
    // Search is on encrypted titles — search the decrypted list in memory.
    // For large datasets, consider storing a plaintext search index separately.
    final all = await getNotes();
    final lower = query.toLowerCase();
    return all.where((n) => n.title.toLowerCase().contains(lower)).toList();
  }

  // ---------------------------------------------------------------------------
  // Encrypt/decrypt helpers — content and title are both encrypted at rest
  // ---------------------------------------------------------------------------

  Note _encrypt(Note note) => note.copyWith(
    title: EncryptionUtils.encrypt(note.title, encryptionKey),
    encryptedContent: EncryptionUtils.encrypt(
      note.encryptedContent,
      encryptionKey,
    ),
  );

  Note _decrypt(NoteModel model) => Note(
    id: model.id,
    title: EncryptionUtils.decrypt(model.title, encryptionKey),
    encryptedContent: EncryptionUtils.decrypt(
      model.encryptedContent,
      encryptionKey,
    ),
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    isPinned: model.isPinned,
  );
}
