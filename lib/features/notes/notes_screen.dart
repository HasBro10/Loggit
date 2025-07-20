import 'package:flutter/material.dart';
import '../../features/notes/note_model.dart';
import '../../services/notes_service.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import '../../shared/design/widgets/header.dart';
import 'note_view_screen.dart';

class NotesScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final ThemeMode currentThemeMode;
  final VoidCallback? onBackToChat;

  const NotesScreen({
    super.key,
    this.onThemeToggle,
    required this.currentThemeMode,
    this.onBackToChat,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await NotesService.getNotes();
      final categories = await NotesService.getCategories();

      setState(() {
        _notes = notes;
        _categories = ['All', ...categories];
        _filteredNotes = _notes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterNotes() {
    setState(() {
      _filteredNotes = _notes.where((note) {
        // Category filter
        if (_selectedCategory != 'All' &&
            note.noteCategory != _selectedCategory) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query) ||
              note.tags.any((tag) => tag.toLowerCase().contains(query));
        }

        return true;
      }).toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterNotes();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterNotes();
  }

  Future<void> _createNote() async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(builder: (context) => const NoteViewScreen()),
    );
    if (result != null) {
      await _loadNotes();
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(builder: (context) => NoteViewScreen(note: note)),
    );
    if (result != null) {
      await _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await NotesService.deleteNote(note.id);
      if (success) {
        await _loadNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Note "${note.title}" deleted')),
          );
        }
      }
    }
  }

  Future<void> _toggleChecklistItem(Note note, NoteItem item) async {
    final success = await NotesService.updateChecklistItem(
      note.id,
      item.id,
      !item.isCompleted,
    );
    if (success) {
      await _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDark ? LoggitColors.darkBg : LoggitColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header - matching tasks screen style
            Container(
              padding: const EdgeInsets.all(LoggitSpacing.screenPadding),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : LoggitColors.darkGrayText,
                    ),
                    onPressed: () => widget.onBackToChat?.call(),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: isDark ? Colors.white : LoggitColors.darkGrayText,
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: LoggitSpacing.lg,
                vertical: LoggitSpacing.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: EdgeInsets.only(right: LoggitSpacing.xs),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => _onCategoryChanged(category),
                        backgroundColor: isDark
                            ? LoggitColors.darkCard
                            : Colors.white,
                        selectedColor: LoggitColors.teal,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: LoggitSpacing.lg,
                vertical: LoggitSpacing.xs,
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? LoggitColors.darkCard : Colors.white,
                ),
              ),
            ),

            // Notes List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredNotes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.all(LoggitSpacing.lg),
                      itemCount: _filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = _filteredNotes[index];
                        return _buildNoteCard(note);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        backgroundColor: LoggitColors.teal,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 80,
            color: isDark
                ? LoggitColors.lightGrayDarkMode
                : LoggitColors.lighterGraySubtext,
          ),
          SizedBox(height: LoggitSpacing.md),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? LoggitColors.lightGrayDarkMode
                  : LoggitColors.lighterGraySubtext,
            ),
          ),
          SizedBox(height: LoggitSpacing.sm),
          Text(
            'Tap the + button to create your first note',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? LoggitColors.lightGrayDarkMode
                  : LoggitColors.lighterGraySubtext,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    return Card(
      margin: EdgeInsets.only(bottom: LoggitSpacing.sm),
      color: isDark ? LoggitColors.darkCard : Colors.white,
      child: InkWell(
        onTap: () => _editNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(LoggitSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type icon and title
              Row(
                children: [
                  _buildNoteTypeIcon(note),
                  SizedBox(width: LoggitSpacing.sm),
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : LoggitColors.darkGrayText,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editNote(note);
                      } else if (value == 'delete') {
                        _deleteNote(note);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: LoggitSpacing.sm),

              // Content preview
              if (note.content.isNotEmpty) ...[
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? LoggitColors.lightGrayDarkMode
                        : LoggitColors.lighterGraySubtext,
                  ),
                ),
                SizedBox(height: LoggitSpacing.sm),
              ],

              // Checklist preview
              if (note.isChecklist && note.checklistItems != null) ...[
                ...note.checklistItems!
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: LoggitSpacing.xs),
                        child: Row(
                          children: [
                            Checkbox(
                              value: item.isCompleted,
                              onChanged: (_) =>
                                  _toggleChecklistItem(note, item),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            Expanded(
                              child: Text(
                                item.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isCompleted
                                      ? (isDark
                                            ? LoggitColors.lightGrayDarkMode
                                            : LoggitColors.lighterGraySubtext)
                                      : (isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (note.checklistItems!.length > 3) ...[
                  Text(
                    '... and ${note.checklistItems!.length - 3} more items',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? LoggitColors.lightGrayDarkMode
                          : LoggitColors.lighterGraySubtext,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: LoggitSpacing.sm),
                ],
              ],

              // Footer with metadata
              Row(
                children: [
                  // Category chip
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: LoggitSpacing.sm,
                      vertical: LoggitSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: note.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.noteCategory,
                      style: TextStyle(
                        fontSize: 14,
                        color: note.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Date
                  Text(
                    note.formattedCreatedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? LoggitColors.lightGrayDarkMode
                          : LoggitColors.lighterGraySubtext,
                    ),
                  ),
                ],
              ),

              // Tags
              if (note.tags.isNotEmpty) ...[
                SizedBox(height: LoggitSpacing.sm),
                Wrap(
                  spacing: LoggitSpacing.xs,
                  runSpacing: LoggitSpacing.xs,
                  children: note.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag, style: TextStyle(fontSize: 12)),
                          backgroundColor: LoggitColors.lighterGraySubtext
                              .withOpacity(0.1),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTypeIcon(Note note) {
    IconData iconData;
    Color iconColor;

    switch (note.type) {
      case NoteType.text:
        iconData = Icons.note;
        iconColor = LoggitColors.teal;
        break;
      case NoteType.checklist:
        iconData = Icons.checklist;
        iconColor = LoggitColors.completedTasksText;
        break;
      case NoteType.media:
        iconData = Icons.image;
        iconColor = LoggitColors.pendingTasksText;
        break;
      case NoteType.quick:
        iconData = Icons.flash_on;
        iconColor = LoggitColors.indigo;
        break;
      case NoteType.linked:
        iconData = Icons.link;
        iconColor = LoggitColors.lighterGraySubtext;
        break;
    }

    return Container(
      padding: EdgeInsets.all(LoggitSpacing.xs),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, size: 18, color: iconColor),
    );
  }
}
