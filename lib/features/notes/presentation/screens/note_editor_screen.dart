import 'package:flutter/material.dart';

class NoteEditorScreen extends StatelessWidget {
  final String? id; // null = new note, non-null = edit existing
  const NoteEditorScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(id == null ? 'New Note' : 'Edit Note: $id')),
    );
  }
}
