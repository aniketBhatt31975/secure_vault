import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.title,
    required super.encryptedContent,
    required super.createdAt,
    required super.updatedAt,
    super.isPinned = false,
  });

  factory NoteModel.fromEntity(Note note) => NoteModel(
        id: note.id,
        title: note.title,
        encryptedContent: note.encryptedContent,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        isPinned: note.isPinned,
      );

  factory NoteModel.fromMap(Map<String, dynamic> map) => NoteModel(
        id: map['id'] as String,
        title: map['title'] as String,
        encryptedContent: map['encrypted_content'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        isPinned: (map['is_pinned'] as int) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'encrypted_content': encryptedContent,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'is_pinned': isPinned ? 1 : 0,
      };

  Note toEntity() => Note(
        id: id,
        title: title,
        encryptedContent: encryptedContent,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isPinned: isPinned,
      );
}
