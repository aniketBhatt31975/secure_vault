import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String encryptedContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  const Note({
    required this.id,
    required this.title,
    required this.encryptedContent,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  Note copyWith({
    String? title,
    String? encryptedContent,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [id, title, encryptedContent, createdAt, updatedAt, isPinned];
}
