import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/notes/note_model.dart';

class PersistentCategory {
  final String name;
  final int colorValue;
  PersistentCategory({required this.name, required this.colorValue});

  Map<String, dynamic> toJson() => {'name': name, 'color': colorValue};

  factory PersistentCategory.fromJson(Map<String, dynamic> json) =>
      PersistentCategory(name: json['name'], colorValue: json['color']);
}

const String _categoriesKey = 'loggit_categories';

class NotesService {
  static const String _storageKey = 'notes';

  // Get all notes
  static Future<List<Note>> getNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_storageKey) ?? [];

      final notes = <Note>[];
      for (final noteString in notesJson) {
        try {
          final noteMap = json.decode(noteString);
          notes.add(Note.fromJson(noteMap));
        } catch (e) {
          print('Error loading note: $e');
        }
      }

      // Sort by creation date (newest first)
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  // Save a note
  static Future<bool> saveNote(Note note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getNotes();

      // Check if note already exists (update) or is new (add)
      final existingIndex = notes.indexWhere((n) => n.id == note.id);
      if (existingIndex >= 0) {
        // Update existing note
        notes[existingIndex] = note.copyWith(updatedAt: DateTime.now());
      } else {
        // Add new note
        notes.add(note);
      }

      // Save to storage
      final notesJson = notes.map((n) => json.encode(n.toJson())).toList();
      return await prefs.setStringList(_storageKey, notesJson);
    } catch (e) {
      print('Error saving note: $e');
      return false;
    }
  }

  // Create a new note
  static Future<bool> createNote(Note note) async {
    return await saveNote(note);
  }

  // Update an existing note
  static Future<bool> updateNote(Note note) async {
    return await saveNote(note);
  }

  // Delete a note
  static Future<bool> deleteNote(String noteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getNotes();

      notes.removeWhere((note) => note.id == noteId);

      final notesJson = notes.map((n) => json.encode(n.toJson())).toList();
      return await prefs.setStringList(_storageKey, notesJson);
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  // Get notes by category
  static Future<List<Note>> getNotesByCategory(String category) async {
    final notes = await getNotes();
    return notes.where((note) => note.noteCategory == category).toList();
  }

  // Get notes by tag
  static Future<List<Note>> getNotesByTag(String tag) async {
    final notes = await getNotes();
    return notes.where((note) => note.tags.contains(tag)).toList();
  }

  // Search notes
  static Future<List<Note>> searchNotes(String query) async {
    final notes = await getNotes();
    final lowercaseQuery = query.toLowerCase();

    return notes.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
          note.content.toLowerCase().contains(lowercaseQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Get notes by type
  static Future<List<Note>> getNotesByType(NoteType type) async {
    final notes = await getNotes();
    return notes.where((note) => note.type == type).toList();
  }

  // Get all categories
  static Future<List<String>> getCategories() async {
    final notes = await getNotes();
    final categories = notes.map((note) => note.noteCategory).toSet().toList();
    categories.sort();
    return categories;
  }

  // Get all tags
  static Future<List<String>> getTags() async {
    final notes = await getNotes();
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags);
    }
    final sortedTags = tags.toList();
    sortedTags.sort();
    return sortedTags;
  }

  // Update checklist item
  static Future<bool> updateChecklistItem(
    String noteId,
    String itemId,
    bool isCompleted,
  ) async {
    try {
      final notes = await getNotes();
      final noteIndex = notes.indexWhere((note) => note.id == noteId);

      if (noteIndex == -1) return false;

      final note = notes[noteIndex];
      if (!note.isChecklist || note.checklistItems == null) return false;

      final updatedItems = note.checklistItems!.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null,
          );
        }
        return item;
      }).toList();

      final updatedNote = note.copyWith(
        checklistItems: updatedItems,
        updatedAt: DateTime.now(),
      );

      notes[noteIndex] = updatedNote;

      final prefs = await SharedPreferences.getInstance();
      final notesJson = notes.map((n) => json.encode(n.toJson())).toList();
      return await prefs.setStringList(_storageKey, notesJson);
    } catch (e) {
      print('Error updating checklist item: $e');
      return false;
    }
  }

  // Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Get note statistics
  static Future<Map<String, dynamic>> getNoteStatistics() async {
    final notes = await getNotes();

    final totalNotes = notes.length;
    final textNotes = notes.where((note) => note.type == NoteType.text).length;
    final checklistNotes = notes
        .where((note) => note.type == NoteType.checklist)
        .length;
    final mediaNotes = notes
        .where((note) => note.type == NoteType.media)
        .length;
    final quickNotes = notes
        .where((note) => note.type == NoteType.quick)
        .length;
    final linkedNotes = notes
        .where((note) => note.type == NoteType.linked)
        .length;

    final totalChecklistItems = notes
        .where((note) => note.isChecklist)
        .fold(0, (sum, note) => sum + note.totalChecklistItems);

    final completedChecklistItems = notes
        .where((note) => note.isChecklist)
        .fold(0, (sum, note) => sum + note.completedChecklistItems);

    return {
      'totalNotes': totalNotes,
      'textNotes': textNotes,
      'checklistNotes': checklistNotes,
      'mediaNotes': mediaNotes,
      'quickNotes': quickNotes,
      'linkedNotes': linkedNotes,
      'totalChecklistItems': totalChecklistItems,
      'completedChecklistItems': completedChecklistItems,
      'checklistProgress': totalChecklistItems > 0
          ? completedChecklistItems / totalChecklistItems
          : 0.0,
    };
  }

  // Ensure Quick category is always present
  static Future<void> ensureQuickCategory() async {
    final quick = PersistentCategory(
      name: 'Quick',
      colorValue: 0xFFFFEB3B,
    ); // Yellow
    await addOrUpdateCategory(quick);
  }

  // Modified getPersistentCategories to always include Quick
  static Future<List<PersistentCategory>> getPersistentCategories() async {
    await ensureQuickCategory();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_categoriesKey) ?? [];
    final categories = list
        .map((str) => PersistentCategory.fromJson(json.decode(str)))
        .toList();
    // Ensure Quick is first
    categories.removeWhere((c) => c.name == 'Quick');
    categories.insert(
      0,
      PersistentCategory(name: 'Quick', colorValue: 0xFF9CA3AF),
    );
    return categories;
  }

  // Add or update a persistent category
  static Future<void> addOrUpdateCategory(PersistentCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_categoriesKey) ?? [];
    final categories = list
        .map((str) => PersistentCategory.fromJson(json.decode(str)))
        .toList();
    final idx = categories.indexWhere((c) => c.name == category.name);
    if (idx >= 0) {
      categories[idx] = category;
    } else {
      categories.add(category);
    }
    final newList = categories.map((c) => json.encode(c.toJson())).toList();
    await prefs.setStringList(_categoriesKey, newList);
  }

  static Future<void> deleteCategory(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();

    // Get current categories
    final list = prefs.getStringList(_categoriesKey) ?? [];
    final categories = list
        .map((str) => PersistentCategory.fromJson(json.decode(str)))
        .where((cat) => cat.name != categoryName) // Remove the category
        .toList();

    // Save updated categories
    final newList = categories.map((c) => json.encode(c.toJson())).toList();
    await prefs.setStringList(_categoriesKey, newList);

    // Update all notes that use this category to use 'Quick'
    final notes = await getNotes();
    final updatedNotes = notes.map((note) {
      if (note.noteCategory == categoryName) {
        return note.copyWith(noteCategory: 'Quick');
      }
      return note;
    }).toList();

    // Save updated notes
    final notesJson = updatedNotes.map((n) => json.encode(n.toJson())).toList();
    await prefs.setStringList(_storageKey, notesJson);
  }
}
