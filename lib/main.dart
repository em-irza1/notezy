import 'package:flutter/material.dart';

void main() {
  runApp(const NotezyApp());
}

class NotezyApp extends StatelessWidget {
  const NotezyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notezy',
      home: Scaffold(
        appBar: AppBar(title: const Text('Notezy')),
        body: const Center(
          child: Text(
            'Welcome to Notezy!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
