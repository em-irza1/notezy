import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesyNote {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final bool favorite;

  NotesyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.favorite = false,
  });

  /// Converts the saved Quill document into normal readable text.
  /// This is what Home uses for the note preview.
  String get preview {
    try {
      final decoded = jsonDecode(content);

      if (decoded is List) {
        final document = Document.fromJson(
          List<Map<String, dynamic>>.from(
            decoded.map((item) => Map<String, dynamic>.from(item as Map)),
          ),
        );

        final text = document
            .toPlainText()
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        return text;
      }
    } catch (_) {
      // Supports older notes that may already contain plain text.
    }

    return content.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String get dateLabel {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
      'favorite': favorite,
    };
  }

  factory NotesyNote.fromJson(Map<String, dynamic> json) {
    return NotesyNote(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Note',
      content: json['content'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  NotesyNote copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? favorite,
  }) {
    return NotesyNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      favorite: favorite ?? this.favorite,
    );
  }
}

class NoteStorageService {
  static const String _notesKey = 'notesy_notes';

  // Profile keys
  static const String _profileNameKey = 'notesy_profile_name';
  static const String _profileUsernameKey = 'notesy_profile_username';

  // Theme key
  static const String _themeModeKey = 'notesy_theme_mode';

  // ------------------------------------------------------------
  // NOTES
  // ------------------------------------------------------------

  static Future<List<NotesyNote>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final savedNotes = prefs.getStringList(_notesKey) ?? [];

    final notes = <NotesyNote>[];

    for (final item in savedNotes) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map) {
          notes.add(NotesyNote.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {
        // Ignore damaged individual notes instead of breaking the app.
      }
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return notes;
  }

  static Future<void> saveNote(NotesyNote note) async {
    final prefs = await SharedPreferences.getInstance();

    final notes = await getNotes();

    final existingIndex = notes.indexWhere((item) => item.id == note.id);

    if (existingIndex >= 0) {
      notes[existingIndex] = note;
    } else {
      notes.insert(0, note);
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    await prefs.setStringList(
      _notesKey,
      notes.map((note) => jsonEncode(note.toJson())).toList(),
    );
  }

  static Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();

    final notes = await getNotes();

    notes.removeWhere((note) => note.id == id);

    await prefs.setStringList(
      _notesKey,
      notes.map((note) => jsonEncode(note.toJson())).toList(),
    );
  }

  static Future<void> updateFavorite(String id, bool favorite) async {
    final notes = await getNotes();

    final index = notes.indexWhere((note) => note.id == id);

    if (index == -1) return;

    notes[index] = notes[index].copyWith(favorite: favorite);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _notesKey,
      notes.map((note) => jsonEncode(note.toJson())).toList(),
    );
  }

  // ------------------------------------------------------------
  // QUILL DOCUMENT CONVERSION
  // ------------------------------------------------------------

  static String documentToJson(Document document) {
    return jsonEncode(document.toDelta().toJson());
  }

  static Document documentFromJson(String value) {
    try {
      final decoded = jsonDecode(value);

      if (decoded is List) {
        return Document.fromJson(
          List<Map<String, dynamic>>.from(
            decoded.map((item) => Map<String, dynamic>.from(item as Map)),
          ),
        );
      }
    } catch (_) {
      // Fall back to plain text for older/damaged notes.
    }

    return Document()..insert(0, value);
  }

  // ------------------------------------------------------------
  // PROFILE
  // ------------------------------------------------------------

  static Future<String> getProfileName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_profileNameKey) ?? 'Notesy User';
  }

  static Future<String> getProfileUsername() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_profileUsernameKey) ?? '@notesy_user';
  }

  static Future<void> saveProfile({
    required String name,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _profileNameKey,
      name.trim().isEmpty ? 'Notesy User' : name.trim(),
    );

    await prefs.setString(
      _profileUsernameKey,
      username.trim().isEmpty
          ? '@notesy_user'
          : username.trim().startsWith('@')
          ? username.trim()
          : '@${username.trim()}',
    );
  }

  // ------------------------------------------------------------
  // THEME
  // ------------------------------------------------------------

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_themeModeKey) ?? 'system';
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_themeModeKey, mode);
  }

  // ------------------------------------------------------------
  // CLEAR ALL NOTES
  // ------------------------------------------------------------

  static Future<void> clearAllNotes() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_notesKey);
  }
}
