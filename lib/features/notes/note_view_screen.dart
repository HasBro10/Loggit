import 'package:flutter/material.dart';
import '../../features/notes/note_model.dart';
import '../../features/notes/note_edit_modal.dart';
import '../../features/notes/note_insert_modal.dart';
import '../../services/notes_service.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';

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

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.note == null) {
        // Create new note
        final newNote = Note(
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

        final success = await NotesService.createNote(newNote);
        if (success && mounted) {
          Navigator.of(context).pop(newNote);
        }
      } else {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          updatedAt: DateTime.now(),
        );

        final success = await NotesService.updateNote(updatedNote);
        if (success && mounted) {
          Navigator.of(context).pop(updatedNote);
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
                      SizedBox(width: buttonSpacing),
                      _buildFloatingToolbarButton(
                        icon: Icons.more_horiz,
                        isActive: false,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            backgroundColor: Colors.white,
                            builder: (context) {
                              return Container(
                                height: 380,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Format',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: LoggitColors.darkGrayText,
                                        ),
                                      ),
                                      // Alignment buttons row
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _buildAlignmentButton(
                                              Icons.format_align_left,
                                              'Left',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.format_align_center,
                                              'Center',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.format_align_right,
                                              'Right',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.format_align_justify,
                                              'Justify',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.format_indent_increase,
                                              'Increase Indent',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.format_indent_decrease,
                                              'Decrease Indent',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.format_line_spacing,
                                              'Line Spacing',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.format_clear,
                                              'Clear Formatting',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.highlight,
                                              'Highlight',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.format_color_text,
                                              'Text Color',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.undo,
                                              'Undo',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.redo,
                                              'Redo',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.link,
                                              'Insert Link',
                                            ),
                                            SizedBox(width: 12),
                                            _buildAlignmentButton(
                                              Icons.link_off,
                                              'Remove Link',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(
                                        thickness: 1.2,
                                        color: Colors.grey[200],
                                      ),
                                      // Styles row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.text_fields,
                                                color:
                                                    LoggitColors.darkGrayText,
                                                size: 22,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Styles',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color:
                                                      LoggitColors.darkGrayText,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Normal',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        thickness: 1.2,
                                        color: Colors.grey[200],
                                      ),
                                      // Font row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.font_download,
                                                color:
                                                    LoggitColors.darkGrayText,
                                                size: 22,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Font',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color:
                                                      LoggitColors.darkGrayText,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Calibri',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        thickness: 1.2,
                                        color: Colors.grey[200],
                                      ),
                                      // Size row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.format_size,
                                                color:
                                                    LoggitColors.darkGrayText,
                                                size: 22,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Size',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color:
                                                      LoggitColors.darkGrayText,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: _decreaseFontSize,
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: 20,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Container(
                                                width: 36,
                                                height: 36,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                                child: Text(
                                                  _fontSize.toInt().toString(),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: _increaseFontSize,
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 20,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                        tooltip: 'More',
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
            if (_hasChanges) {
              await _saveNote();
            } else {
              Navigator.of(context).pop();
            }
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
            onPressed: _openDetailedModal,
            icon: Icon(Icons.settings, color: LoggitColors.darkGrayText),
            tooltip: 'Advanced Settings',
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
              color: Colors.white,
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
                    fillColor: Colors.white,
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
