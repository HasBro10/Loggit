import 'package:flutter/material.dart';
import '../../features/notes/note_model.dart';
import '../../features/notes/note_edit_modal.dart';
import '../../features/notes/note_insert_modal.dart';
import '../../services/notes_service.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import '../../features/notes/note_settings_modal.dart'; // Added import for NoteSettingsModal
import '../../services/notes_service.dart' show PersistentCategory;

// Category model (move to top level)
class Category {
  final String name;
  final Color color;
  Category({required this.name, required this.color});
}

class NoteViewScreen extends StatefulWidget {
  final Note? note; // null for new note, existing note for editing

  const NoteViewScreen({super.key, this.note});

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Text formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  bool _isBulletList = false;
  bool _isNumberedList = false;
  double _fontSize = 16.0;

  late Color _noteColor;
  NoteType _selectedType = NoteType.text;
  List<NoteItem> _checklistItems = [];
  List<Category> _categories = [];
  String _selectedCategory = 'Quick';
  Color _selectedCategoryColor = Colors.yellow;
  List<String> _tags = [];
  NotePriority _selectedPriority = NotePriority.medium;
  NoteStatus _selectedStatus = NoteStatus.final_;

  Future<Map<String, dynamic>?> _showAddCategoryDialog() async {
    String newCategoryName = '';
    Color? tempSelectedColor;
    bool showColorError = false;
    final colorOptions = [
      const Color(0xFFFFFFFF), // White
      const Color(0xFFE5E7EB), // Light Grey
      const Color(0xFF64748B), // Grey
      const Color(0xFF000000), // Black
      const Color(0xFFFACC15), // Yellow
      const Color(0xFFF59E42), // Orange
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF38BDF8), // Light Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF472B6), // Pink
      const Color(0xFFFB7185), // Red
      const Color(0xFF10B981), // Teal/Green
    ];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 18),
                    TextField(
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Category name',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (val) => newCategoryName = val,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Pick a color:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: colorOptions.map((color) {
                        final isSelected = tempSelectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              tempSelectedColor = color;
                              showColorError = false;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : showColorError &&
                                          tempSelectedColor == null
                                    ? Colors.red
                                    : Colors.grey[300]!,
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
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    if (showColorError && tempSelectedColor == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Assign a color to this category.',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (newCategoryName.trim().isEmpty ||
                                tempSelectedColor == null) {
                              setState(() {
                                showColorError = tempSelectedColor == null;
                              });
                              return;
                            }
                            Navigator.of(context).pop({
                              'name': newCategoryName.trim(),
                              'color': tempSelectedColor,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LoggitColors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Add',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null && result['name'] != null && result['color'] != null) {
      final newCat = Category(name: result['name'], color: result['color']);
      setState(() {
        if (!_categories.any((cat) => cat.name == newCat.name)) {
          _categories.add(newCat);
        }
        _selectedCategory = newCat.name;
        _selectedCategoryColor = newCat.color;
        _noteColor = newCat.color;
      });
      // Save to persistent storage
      await NotesService.addOrUpdateCategory(
        PersistentCategory(name: newCat.name, colorValue: newCat.color.value),
      );
      return result;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _showEditCategoryDialog(
    String categoryName,
    Color categoryColor,
  ) async {
    String newCategoryName = categoryName;
    Color? tempSelectedColor = categoryColor;
    bool showColorError = false;
    final colorOptions = [
      const Color(0xFFFFFFFF), // White
      const Color(0xFFE5E7EB), // Light Grey
      const Color(0xFF64748B), // Grey
      const Color(0xFF000000), // Black
      const Color(0xFFFACC15), // Yellow
      const Color(0xFFF59E42), // Orange
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF38BDF8), // Light Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF472B6), // Pink
      const Color(0xFFFB7185), // Red
      const Color(0xFF10B981), // Teal/Green
    ];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 18),
                    TextField(
                      autofocus: true,
                      controller: TextEditingController(text: newCategoryName),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Category name',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (val) => newCategoryName = val,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Pick a color:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: colorOptions.map((color) {
                        final isSelected = tempSelectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              tempSelectedColor = color;
                              showColorError = false;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : showColorError &&
                                          tempSelectedColor == null
                                    ? Colors.red
                                    : Colors.grey[300]!,
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
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    if (showColorError && tempSelectedColor == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Assign a color to this category.',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Category'),
                                content: Text(
                                  'All notes in this category will be moved to the "Quick" category. Are you sure you want to delete "${newCategoryName}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              Navigator.of(context).pop({'action': 'delete'});
                            }
                          },
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (newCategoryName.trim().isEmpty ||
                                tempSelectedColor == null) {
                              setState(() {
                                showColorError = tempSelectedColor == null;
                              });
                              return;
                            }
                            Navigator.of(context).pop({
                              'action': 'save',
                              'name': newCategoryName.trim(),
                              'color': tempSelectedColor,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LoggitColors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadPersistentCategories();
    _noteColor = widget.note?.color ?? Colors.white;
    if (widget.note != null) {
      _selectedType = widget.note!.type;
      _checklistItems = widget.note!.checklistItems ?? [];
      _selectedCategory = widget.note!.noteCategory;
      final foundCat = _categories.firstWhere(
        (cat) => cat.name == _selectedCategory,
        orElse: () => Category(name: 'Quick', color: Colors.yellow),
      );
      _selectedCategoryColor = foundCat.color;
      _tags = List.from(widget.note!.tags);
      _selectedPriority = widget.note!.priority;
      _selectedStatus = widget.note!.status;
    }
  }

  void _initializeForm() {
    if (widget.note != null) {
      final note = widget.note!;
      _titleController.text = note.title;
      _contentController.text = note.content;
    }

    // Listen for changes
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toggleBold() {
    setState(() {
      _isBold = !_isBold;
    });
    _applyFormatting();
  }

  void _toggleItalic() {
    setState(() {
      _isItalic = !_isItalic;
    });
    _applyFormatting();
  }

  void _toggleUnderline() {
    setState(() {
      _isUnderlined = !_isUnderlined;
    });
    _applyFormatting();
  }

  void _toggleBulletList() {
    setState(() {
      _isBulletList = !_isBulletList;
      if (_isBulletList) _isNumberedList = false;
    });
    _applyFormatting();
  }

  void _toggleNumberedList() {
    setState(() {
      _isNumberedList = !_isNumberedList;
      if (_isNumberedList) _isBulletList = false;
    });
    _applyFormatting();
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + 2).clamp(12.0, 32.0);
    });
    _applyFormatting();
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - 2).clamp(12.0, 32.0);
    });
    _applyFormatting();
  }

  void _applyFormatting() {
    // Note: In a real implementation, you'd need to use a rich text editor
    // For now, this is a placeholder for the formatting logic
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _showInsertModal() async {
    await showNoteInsertModal(
      context,
      onInsert: (type, {data}) {
        // Handle different insert types
        switch (type) {
          case 'photo':
          case 'gallery':
          case 'image':
            _insertImage();
            break;
          case 'voice_record':
          case 'audio':
            _insertAudio();
            break;
          case 'file':
            _insertFile();
            break;
          case 'link':
            _insertLink();
            break;
          case 'table':
            _insertTable();
            break;
          case 'drawing':
            _insertDrawing();
            break;
        }
      },
    );
  }

  void _insertImage() {
    // TODO: Implement image insertion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image insertion coming soon!')),
    );
  }

  void _insertAudio() {
    // TODO: Implement audio insertion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio insertion coming soon!')),
    );
  }

  void _insertFile() {
    // TODO: Implement file insertion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File insertion coming soon!')),
    );
  }

  void _insertLink() {
    // TODO: Implement link insertion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link insertion coming soon!')),
    );
  }

  void _insertTable() {
    // TODO: Implement table insertion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Table insertion coming soon!')),
    );
  }

  void _insertDrawing() {
    // TODO: Implement drawing insertion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drawing insertion coming soon!')),
    );
  }

  Future<Note?> _saveNote({bool allowEmptyTitle = false}) async {
    if (_titleController.text.trim().isEmpty && !allowEmptyTitle) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return null;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If no category is selected, assign to Quick
      String categoryToUse = _selectedCategory.isEmpty
          ? 'Quick'
          : _selectedCategory;
      Color colorToUse = _noteColor;
      if (_selectedCategory.isEmpty ||
          !_categories.any((c) => c.name == _selectedCategory)) {
        // Use persistent Quick color
        final persistent = await NotesService.getPersistentCategories();
        final quick = persistent.firstWhere(
          (c) => c.name == 'Quick',
          orElse: () =>
              PersistentCategory(name: 'Quick', colorValue: 0xFFFFEB3B),
        );
        colorToUse = Color(quick.colorValue);
        categoryToUse = 'Quick';
      }
      if (widget.note == null) {
        // Create new note
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
          noteCategory: categoryToUse,
          color: colorToUse,
          priority: _selectedPriority,
          status: _selectedStatus,
          tags: _tags,
          checklistItems: _selectedType == NoteType.checklist
              ? _checklistItems
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final success = await NotesService.createNote(newNote);
        if (success && mounted) {
          Navigator.of(
            context,
          ).pop({'note': newNote, 'categories': _categories});
          return newNote;
        }
      } else {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
          noteCategory: categoryToUse,
          color: colorToUse,
          priority: _selectedPriority,
          status: _selectedStatus,
          tags: _tags,
          checklistItems: _selectedType == NoteType.checklist
              ? _checklistItems
              : null,
          updatedAt: DateTime.now(),
        );

        final success = await NotesService.updateNote(updatedNote);
        if (success && mounted) {
          Navigator.of(
            context,
          ).pop({'note': updatedNote, 'categories': _categories});
          return updatedNote;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    return null;
  }

  Future<void> _loadPersistentCategories() async {
    final persistent = await NotesService.getPersistentCategories();
    setState(() {
      _categories = persistent
          .map((c) => Category(name: c.name, color: Color(c.colorValue)))
          .toList();
    });
  }

  Future<void> _openDetailedModal() async {
    // Create a temporary note with current content for the modal
    final tempNote =
        widget.note?.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        ) ??
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: NoteType.text,
          noteCategory: 'Personal',
          color: const Color(0xFF2563eb),
          priority: NotePriority.medium,
          status: NoteStatus.final_,
          tags: [],
          checklistItems: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    final result = await showNoteModal(context, note: tempNote);

    if (result != null) {
      // Update the form with changes from modal
      setState(() {
        _titleController.text = result.title;
        _contentController.text = result.content;
        _hasChanges = true;
      });
    }
  }

  Widget _buildFormattingToolbar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final toolbarHeight = isSmallScreen ? 68.0 : 80.0;
    final buttonSpacing = isSmallScreen ? 12.0 : 20.0;
    final floatingPadding = isSmallScreen ? 10.0 : 20.0;

    return Padding(
      padding: EdgeInsets.only(
        left: floatingPadding,
        right: floatingPadding,
        bottom: floatingPadding,
      ),
      child: Container(
        height: toolbarHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Static Plus button
            _buildFloatingToolbarButton(
              icon: Icons.add,
              isActive: false,
              onPressed: _showInsertModal,
              tooltip: 'Insert',
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(width: buttonSpacing),
            // Scrollable toolbar buttons
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFloatingToolbarButton(
                        icon: Icons.check_box,
                        isActive: false,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checklist coming soon!'),
                            ),
                          );
                        },
                        tooltip: 'Checklist',
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: buttonSpacing),
                      _buildFloatingToolbarButton(
                        icon: Icons.format_bold,
                        isActive: _isBold,
                        onPressed: _toggleBold,
                        tooltip: 'Bold',
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: buttonSpacing),
                      _buildFloatingToolbarButton(
                        icon: Icons.format_italic,
                        isActive: _isItalic,
                        onPressed: _toggleItalic,
                        tooltip: 'Italic',
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: buttonSpacing),
                      _buildFloatingToolbarButton(
                        icon: Icons.format_underline,
                        isActive: _isUnderlined,
                        onPressed: _toggleUnderline,
                        tooltip: 'Underline',
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: buttonSpacing),
                      _buildFloatingToolbarButton(
                        icon: Icons.format_list_bulleted,
                        isActive: _isBulletList,
                        onPressed: _toggleBulletList,
                        tooltip: 'Bullet List',
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: buttonSpacing),
                      _buildFloatingToolbarButton(
                        icon: Icons.format_list_numbered,
                        isActive: _isNumberedList,
                        onPressed: _toggleNumberedList,
                        tooltip: 'Numbered List',
                        isSmallScreen: isSmallScreen,
                      ),
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

  Widget _buildFloatingToolbarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
    bool isSmallScreen = false,
  }) {
    final buttonSize = isSmallScreen ? 52.0 : 64.0;
    final iconSize = isSmallScreen ? 26.0 : 32.0;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onPressed,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: isActive
                    ? LoggitColors.teal.withOpacity(0.15)
                    : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: LoggitColors.teal.withOpacity(0.10),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: Colors.grey.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: isActive ? LoggitColors.teal : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNewNote = widget.note == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () async {
            final hasTitle = _titleController.text.trim().isNotEmpty;
            final hasContent = _contentController.text.trim().isNotEmpty;
            if (!hasTitle && !hasContent) {
              // Nothing typed, just go back without saving
              if (mounted) Navigator.of(context).pop();
              return;
            }
            // Otherwise, save (even if title is empty)
            final note = await _saveNote(allowEmptyTitle: true);
            // _saveNote already pops with the correct value, so do not pop again here
          },
          icon: Icon(Icons.arrow_back, color: LoggitColors.darkGrayText),
        ),
        title: Text(
          isNewNote ? 'New Note' : 'Edit Note',
          style: TextStyle(
            color: LoggitColors.darkGrayText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: LoggitColors.darkGrayText),
            tooltip: 'Settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  return NoteSettingsModal(
                    selectedType: _selectedType,
                    onTypeChanged: (type) =>
                        setState(() => _selectedType = type),
                    checklistItems: _checklistItems
                        .map((item) => item.text)
                        .toList(),
                    onAddChecklistItem: (text) {
                      if (text.trim().isNotEmpty) {
                        setState(() {
                          _checklistItems.add(
                            NoteItem(id: DateTime.now().toString(), text: text),
                          );
                        });
                      }
                    },
                    onRemoveChecklistItem: (index) {
                      setState(() {
                        _checklistItems.removeAt(index);
                      });
                    },
                    selectedCategory: _selectedCategory,
                    categories: _categories.map((cat) => cat.name).toList(),
                    onCategoryChanged: (cat) {
                      setState(() {
                        _selectedCategory = cat;
                        final foundCat = _categories.firstWhere(
                          (c) => c.name == cat,
                          orElse: () =>
                              Category(name: 'Quick', color: Colors.yellow),
                        );
                        _selectedCategoryColor = foundCat.color;
                      });
                    },
                    tags: _tags,
                    onAddTag: (tag) {
                      final trimmed = tag.trim();
                      if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
                        setState(() {
                          _tags.add(trimmed);
                        });
                      }
                    },
                    onRemoveTag: (tag) => setState(() => _tags.remove(tag)),
                    selectedColor: _noteColor,
                    colorOptions: [
                      const Color(0xFF3B82F6),
                      const Color(0xFFF472B6),
                      const Color(0xFFF59E42),
                      const Color(0xFFFACC15),
                      const Color(0xFF8B5CF6),
                      const Color(0xFF10B981),
                      const Color(0xFF64748B),
                      const Color(0xFFFB7185),
                      const Color(0xFF38BDF8),
                      const Color(0xFFFFFFFF),
                      const Color(0xFF000000),
                      const Color(0xFFE5E7EB),
                    ],
                    onColorSelected: (color) {
                      setState(() {
                        _noteColor = color;
                      });
                      Navigator.of(context).pop();
                    },
                    selectedPriority: _selectedPriority,
                    onPriorityChanged: (priority) =>
                        setState(() => _selectedPriority = priority),
                    selectedStatus: _selectedStatus,
                    onStatusChanged: (status) =>
                        setState(() => _selectedStatus = status),
                    onAddCategory: () async => await _showAddCategoryDialog(),
                    onEditCategory: (categoryName, categoryColor) async {
                      final result = await _showEditCategoryDialog(
                        categoryName,
                        categoryColor,
                      );
                      if (result != null) {
                        if (result['action'] == 'save') {
                          // Update category in persistent storage
                          final newCat = Category(
                            name: result['name'],
                            color: result['color'],
                          );
                          setState(() {
                            final idx = _categories.indexWhere(
                              (c) => c.name == categoryName,
                            );
                            if (idx >= 0) {
                              _categories[idx] = newCat;
                              if (_selectedCategory == categoryName) {
                                _selectedCategory = newCat.name;
                                _selectedCategoryColor = newCat.color;
                                _noteColor = newCat.color;
                              }
                            }
                          });
                          await NotesService.addOrUpdateCategory(
                            PersistentCategory(
                              name: newCat.name,
                              colorValue: newCat.color.value,
                            ),
                          );
                        } else if (result['action'] == 'delete') {
                          // Remove category from persistent storage and reassign notes
                          await NotesService.deleteCategory(categoryName);
                          setState(() {
                            _categories.removeWhere(
                              (c) => c.name == categoryName,
                            );
                            if (_selectedCategory == categoryName) {
                              _selectedCategory = 'Quick';
                              _selectedCategoryColor = Colors.yellow;
                              _noteColor = Colors.yellow;
                            }
                          });
                        }
                      }
                      return result;
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Title field - extends to edges
          Container(
            width: double.infinity,
            color: LoggitColors.lightGray,
            child: Padding(
              padding: EdgeInsets.all(LoggitSpacing.lg),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: LoggitColors.darkGrayText,
                ),
                decoration: InputDecoration(
                  hintText: 'Note title...',
                  hintStyle: TextStyle(
                    color: LoggitColors.lighterGraySubtext,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                ),
              ),
            ),
          ),

          // Content field - extends to edges
          Expanded(
            child: Container(
              width: double.infinity,
              color: _noteColor,
              child: Padding(
                padding: EdgeInsets.all(LoggitSpacing.lg),
                child: TextField(
                  controller: _contentController,
                  style: TextStyle(
                    fontSize: _fontSize,
                    color: LoggitColors.darkGrayText,
                    height: 1.5,
                    fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                    decoration: _isUnderlined
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start writing your note...',
                    hintStyle: TextStyle(
                      color: LoggitColors.lighterGraySubtext,
                      fontSize: _fontSize,
                      height: 1.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
          ),

          // Formatting toolbar at bottom
          _buildFormattingToolbar(),
        ],
      ),
    );
  }
}

Widget _buildPrettyColorCircle(Color color, bool isSelected) {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: isSelected ? Colors.white : Colors.grey[200]!,
        width: 3,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.18),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: isSelected ? Icon(Icons.check, color: Colors.white, size: 20) : null,
  );
}

Widget _buildAlignmentButton(IconData icon, String tooltip) {
  return Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {}, // TODO: Implement alignment logic
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(icon, color: Colors.black87, size: 26),
        ),
      ),
    ),
  );
}
