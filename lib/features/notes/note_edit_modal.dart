import 'package:flutter/material.dart';
import '../../features/notes/note_model.dart';
import '../../services/notes_service.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';

Future<Note?> showNoteModal(BuildContext context, {Note? note}) async {
  return await showModalBottomSheet<Note?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black.withOpacity(0.5),
    builder: (context) => NoteEditModal(note: note),
  );
}

class NoteEditModal extends StatefulWidget {
  final Note? note;

  const NoteEditModal({super.key, this.note});

  @override
  State<NoteEditModal> createState() => _NoteEditModalState();
}

class _NoteEditModalState extends State<NoteEditModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  NoteType _selectedType = NoteType.text;
  String _selectedCategory = 'Personal';
  Color _selectedColor = const Color(0xFF2563eb);
  NotePriority _selectedPriority = NotePriority.medium;
  NoteStatus _selectedStatus = NoteStatus.final_;

  List<String> _tags = [];
  List<NoteItem> _checklistItems = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Personal',
    'Work',
    'Ideas',
    'Shopping',
    'Health',
    'Travel',
  ];

  final List<Color> _colorOptions = [
    const Color(0xFF3B82F6), // Modern Blue
    const Color(0xFFF472B6), // Pink
    const Color(0xFFF59E42), // Coral/Orange
    const Color(0xFFFACC15), // Yellow
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF10B981), // Mint/Green
    const Color(0xFF64748B), // Modern Gray
    const Color(0xFFFB7185), // Rose
    const Color(0xFF38BDF8), // Sky Blue
    const Color(0xFFFFFFFF), // White
    const Color(0xFF000000), // Black
    const Color(0xFFE5E7EB), // Light Grey
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.note != null) {
      final note = widget.note!;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedType = note.type;
      _selectedCategory = note.noteCategory;
      _selectedColor = note.color;
      _selectedPriority = note.priority;
      _selectedStatus = note.status;
      _tags = List.from(note.tags);
      _checklistItems = note.checklistItems != null
          ? List.from(note.checklistItems!)
          : [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addChecklistItem(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isNotEmpty) {
      setState(() {
        _checklistItems.add(
          NoteItem(id: NotesService.generateId(), text: trimmedText),
        );
      });
    }
  }

  void _removeChecklistItem(String itemId) {
    setState(() {
      _checklistItems.removeWhere((item) => item.id == itemId);
    });
  }

  void _toggleChecklistItem(String itemId) {
    setState(() {
      final itemIndex = _checklistItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final item = _checklistItems[itemIndex];
        _checklistItems[itemIndex] = item.copyWith(
          isCompleted: !item.isCompleted,
          completedAt: !item.isCompleted ? DateTime.now() : null,
        );
      }
    });
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final note = Note(
        id: widget.note?.id ?? NotesService.generateId(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        noteCategory: _selectedCategory,
        tags: _tags,
        color: _selectedColor,
        createdAt: widget.note?.createdAt,
        updatedAt: DateTime.now(),
        checklistItems: _selectedType == NoteType.checklist
            ? _checklistItems
            : null,
        status: _selectedStatus,
        priority: _selectedPriority,
      );

      final success = await NotesService.saveNote(note);

      if (success && mounted) {
        Navigator.of(context).pop(note);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save note')));
      }
    } catch (e) {
      print('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving note')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = false; // Always use light mode for modal
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: 440,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(bottom: 18),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LoggitColors.lighterGraySubtext,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Row(
              children: [
                Text(
                  widget.note == null ? 'New Note' : 'Edit Note',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: LoggitColors.darkGrayText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: LoggitColors.darkGrayText),
                ),
              ],
            ),
            SizedBox(height: 10),
            Divider(thickness: 1.2, color: Colors.grey[200]),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note Type
                      _buildSectionHeader('Type'),
                      SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: NoteType.values.map((type) {
                            final isSelected = type == _selectedType;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedType = type;
                                    if (type != NoteType.checklist) {
                                      _checklistItems.clear();
                                    }
                                  });
                                },
                                child: Container(
                                  width: 90,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? LoggitColors.teal.withOpacity(0.15)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? LoggitColors.teal
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _getTypeLabel(type),
                                        style: TextStyle(
                                          color: isSelected
                                              ? LoggitColors.teal
                                              : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.grey[200],
                        height: 32,
                      ),
                      // Checklist Items
                      if (_selectedType == NoteType.checklist) ...[
                        _buildSectionHeader('Checklist Items'),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tagController,
                                decoration: InputDecoration(
                                  hintText: 'Add checklist item',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: LoggitColors.lightGray,
                                ),
                                onFieldSubmitted: _addChecklistItem,
                              ),
                            ),
                            SizedBox(width: LoggitSpacing.sm),
                            IconButton(
                              onPressed: () =>
                                  _addChecklistItem(_tagController.text),
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: LoggitColors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_checklistItems.isNotEmpty) ...[
                          SizedBox(height: 8),
                          ..._checklistItems.map(
                            (item) => Card(
                              margin: EdgeInsets.only(bottom: LoggitSpacing.xs),
                              child: ListTile(
                                leading: Checkbox(
                                  value: item.isCompleted,
                                  onChanged: (_) =>
                                      _toggleChecklistItem(item.id),
                                ),
                                title: Text(
                                  item.text,
                                  style: TextStyle(
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.isCompleted
                                        ? LoggitColors.lighterGraySubtext
                                        : null,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () =>
                                      _removeChecklistItem(item.id),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        Divider(
                          thickness: 1,
                          color: Colors.grey[200],
                          height: 32,
                        ),
                      ],
                      // Category
                      _buildSectionHeader('Category'),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: LoggitColors.lightGray,
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.grey[200],
                        height: 32,
                      ),
                      // Tags
                      _buildSectionHeader('Tags'),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: InputDecoration(
                                hintText: 'Add tag',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: LoggitColors.lightGray,
                              ),
                              onFieldSubmitted: _addTag,
                            ),
                          ),
                          SizedBox(width: LoggitSpacing.sm),
                          IconButton(
                            onPressed: () => _addTag(_tagController.text),
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: LoggitColors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Wrap(
                          spacing: LoggitSpacing.xs,
                          runSpacing: LoggitSpacing.xs,
                          children: _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  onDeleted: () => _removeTag(tag),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      Divider(
                        thickness: 1,
                        color: Colors.grey[200],
                        height: 32,
                      ),
                      // Color
                      _buildSectionHeader('Color'),
                      SizedBox(height: 8),
                      _buildColorGrid(_colorOptions, _selectedColor, (color) {
                        setState(() {
                          _selectedColor = color;
                          print(
                            'Selected color:  [32m [1m [4m$_selectedColor\u001b[0m',
                          );
                        });
                      }),
                      Divider(
                        thickness: 1,
                        color: Colors.grey[200],
                        height: 32,
                      ),
                      // Priority
                      _buildSectionHeader('Priority'),
                      SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: NotePriority.values.map((priority) {
                            final isSelected = priority == _selectedPriority;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPriority = priority;
                                  });
                                },
                                child: Container(
                                  width: 90,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? LoggitColors.teal.withOpacity(0.15)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? LoggitColors.teal
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getPriorityLabel(priority),
                                      style: TextStyle(
                                        color: isSelected
                                            ? LoggitColors.teal
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.grey[200],
                        height: 32,
                      ),
                      // Status
                      _buildSectionHeader('Status'),
                      SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: NoteStatus.values.map((status) {
                            final isSelected = status == _selectedStatus;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                },
                                child: Container(
                                  width: 90,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? LoggitColors.teal.withOpacity(0.15)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? LoggitColors.teal
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getStatusLabel(status),
                                      style: TextStyle(
                                        color: isSelected
                                            ? LoggitColors.teal
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: LoggitColors.darkGrayText,
        letterSpacing: 0.1,
      ),
    );
  }

  String _getTypeLabel(NoteType type) {
    switch (type) {
      case NoteType.text:
        return 'Text';
      case NoteType.checklist:
        return 'Checklist';
      case NoteType.media:
        return 'Media';
      case NoteType.quick:
        return 'Quick';
      case NoteType.linked:
        return 'Linked';
    }
  }

  IconData _getTypeIcon(NoteType type) {
    switch (type) {
      case NoteType.text:
        return Icons.text_fields;
      case NoteType.checklist:
        return Icons.check_box;
      case NoteType.media:
        return Icons.image;
      case NoteType.quick:
        return Icons.flash_on;
      case NoteType.linked:
        return Icons.link;
    }
  }

  String _getPriorityLabel(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return 'Low';
      case NotePriority.medium:
        return 'Medium';
      case NotePriority.high:
        return 'High';
    }
  }

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return LoggitColors.completedTasksText;
      case NotePriority.medium:
        return LoggitColors.pendingTasksText;
      case NotePriority.high:
        return LoggitColors.remindersText;
    }
  }

  String _getStatusLabel(NoteStatus status) {
    switch (status) {
      case NoteStatus.draft:
        return 'Draft';
      case NoteStatus.final_:
        return 'Final';
      case NoteStatus.archived:
        return 'Archived';
    }
  }
}

Widget _buildColorGrid(
  List<Color> colors,
  Color selectedColor,
  Function(Color) onSelect,
) {
  const int colorsPerRow = 6;
  final rows = <Widget>[];
  for (int i = 0; i < colors.length; i += colorsPerRow) {
    final rowColors = colors.skip(i).take(colorsPerRow).toList();
    rows.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: rowColors.map((color) {
          final isSelected = color == selectedColor;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: GestureDetector(
              onTap: () => onSelect(color),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.deepPurple
                        : Colors.black.withOpacity(0.18),
                    width: isSelected ? 3 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.18),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: isSelected
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
}
