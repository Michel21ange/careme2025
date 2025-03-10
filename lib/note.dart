import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Note {
  int id;
  String title;
  String content;
  DateTime modifiedTime;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.modifiedTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'modifiedTime': modifiedTime.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      modifiedTime: DateTime.parse(json['modifiedTime']),
    );
  }
}

class NotesManager {
  static const String notesKey = 'notes'; // Clé pour récupérer les notes depuis SharedPreferences

  // Sauvegarder les notes dans SharedPreferences
  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notesJson = notes.map((note) => json.encode(note.toJson())).toList();
    await prefs.setStringList(notesKey, notesJson);
  }

  // Charger les notes depuis SharedPreferences
  static Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? notesJson = prefs.getStringList(notesKey);
    if (notesJson == null) {
      return []; // Retourne une liste vide si aucune note n'est trouvée
    }
    return notesJson.map((noteJson) => Note.fromJson(json.decode(noteJson))).toList();
  }
}



List<Note> sampleNotes = [];