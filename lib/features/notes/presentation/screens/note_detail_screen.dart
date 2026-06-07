import 'package:flutter/material.dart';

class NoteDetailScreen extends StatelessWidget {
  final String id;
  const NoteDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Note Detail: $id')),
    );
  }
}
