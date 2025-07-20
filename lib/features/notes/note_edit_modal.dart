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
    const Color(0xFF2563eb), // Blue
    const Color(0xFFdc2626), // Red
    const Color(0xFF16a34a), // Green
    const Color(0xFFca8a04), // Yellow
    const Color(0xFF9333ea), // Purple
    const Color(0xFFea580c), // Orange
    const Color(0xFF0891b2), // Cyan
    const Color(0xFFbe185d), // Pink
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
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: 500,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: LoggitSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: LoggitColors.lighterGraySubtext,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(LoggitSpacing.lg),
            child: Row(
              children: [
                Text(
                  widget.note == null ? 'New Note' : 'Edit Note',
                  style: TextStyle(
                    fontSize: 24,
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
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(LoggitSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: LoggitSpacing.xs),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter note title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: LoggitColors.lightGray,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: LoggitSpacing.md),

                    // Note Type
                    Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: LoggitSpacing.xs),
                    Wrap(
                      spacing: LoggitSpacing.sm,
                      children: NoteType.values.map((type) {
                        final isSelected = type == _selectedType;
                        return ChoiceChip(
                          label: Text(_getTypeLabel(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedType = type;
                                if (type != NoteType.checklist) {
                                  _checklistItems.clear();
                                }
                              });
                            }
                          },
                          backgroundColor: LoggitColors.lightGray,
                          selectedColor: LoggitColors.teal,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontSize: 14,
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: LoggitSpacing.md),

                    // Content
                    Text(
                      'Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: LoggitSpacing.xs),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Enter note content',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: LoggitColors.lightGray,
                      ),
                      maxLines: 5,
                    ),

                    // Checklist Items
                    if (_selectedType == NoteType.checklist) ...[
                      SizedBox(height: LoggitSpacing.md),
                      Text(
                        'Checklist Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: LoggitSpacing.xs),

                      // Add new item
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

                      // Checklist items list
                      if (_checklistItems.isNotEmpty) ...[
                        SizedBox(height: LoggitSpacing.sm),
                        ..._checklistItems.map(
                          (item) => Card(
                            margin: EdgeInsets.only(bottom: LoggitSpacing.xs),
                            child: ListTile(
                              leading: Checkbox(
                                value: item.isCompleted,
                                onChanged: (_) => _toggleChecklistItem(item.id),
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
                                onPressed: () => _removeChecklistItem(item.id),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],

                    SizedBox(height: LoggitSpacing.md),

                    // Category
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: LoggitSpacing.xs),
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

                    SizedBox(height: LoggitSpacing.md),

                    // Tags
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: LoggitSpacing.xs),

                    // Add tag
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

                    // Tags list
                    if (_tags.isNotEmpty) ...[
                      SizedBox(height: LoggitSpacing.sm),
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

                    SizedBox(height: LoggitSpacing.md),

                    // Color
                    Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: LoggitSpacing.xs),
                    Wrap(
                      spacing: LoggitSpacing.sm,
                      children: _colorOptions.map((color) {
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: LoggitSpacing.md),

                    // Priority
                    Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: LoggitSpacing.xs),
                    Wrap(
                      spacing: LoggitSpacing.sm,
                      children: NotePriority.values.map((priority) {
                        final isSelected = priority == _selectedPriority;
                        return ChoiceChip(
                          label: Text(_getPriorityLabel(priority)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPriority = priority;
                              });
                            }
                          },
                          backgroundColor: LoggitColors.lightGray,
                          selectedColor: _getPriorityColor(priority),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontSize: 14,
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: LoggitSpacing.md),

                    // Status
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: LoggitSpacing.xs),
                    Wrap(
                      spacing: LoggitSpacing.sm,
                      children: NoteStatus.values.map((status) {
                        final isSelected = status == _selectedStatus;
                        return ChoiceChip(
                          label: Text(_getStatusLabel(status)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStatus = status;
                              });
                            }
                          },
                          backgroundColor: LoggitColors.lightGray,
                          selectedColor: LoggitColors.teal,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontSize: 14,
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: LoggitSpacing.xl),
                  ],
                ),
              ),
            ),
          ),

          // Save button
          Container(
            padding: EdgeInsets.all(LoggitSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoggitColors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: LoggitSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.note == null ? 'Create Note' : 'Save Changes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
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
