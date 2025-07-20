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
    final toolbarHeight = screenWidth < 400 ? 60.0 : 70.0;
    final buttonSpacing = screenWidth < 400 ? 8.0 : 12.0;

    return Container(
      height: toolbarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 400 ? LoggitSpacing.sm : LoggitSpacing.md,
          vertical: screenWidth < 400 ? 8.0 : LoggitSpacing.sm,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Plus button (Insert) - prominent on the left
              _buildToolbarButton(
                icon: Icons.add,
                isActive: false,
                onPressed: _showInsertModal,
                tooltip: 'Insert',
              ),
              SizedBox(width: buttonSpacing),

              // Checklist button
              _buildToolbarButton(
                icon: Icons.check_box,
                isActive: false,
                onPressed: () {
                  // TODO: Implement checklist
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checklist coming soon!')),
                  );
                },
                tooltip: 'Checklist',
              ),
              SizedBox(width: buttonSpacing),

              // Bullet list
              _buildToolbarButton(
                icon: Icons.format_list_bulleted,
                isActive: _isBulletList,
                onPressed: _toggleBulletList,
                tooltip: 'Bullet List',
              ),
              SizedBox(width: buttonSpacing),

              // Numbered list
              _buildToolbarButton(
                icon: Icons.format_list_numbered,
                isActive: _isNumberedList,
                onPressed: _toggleNumberedList,
                tooltip: 'Numbered List',
              ),
              SizedBox(width: buttonSpacing),

              // Text alignment buttons
              _buildToolbarButton(
                icon: Icons.format_align_left,
                isActive: false,
                onPressed: () {
                  // TODO: Implement left align
                },
                tooltip: 'Align Left',
              ),
              SizedBox(width: 8),

              _buildToolbarButton(
                icon: Icons.format_align_center,
                isActive: false,
                onPressed: () {
                  // TODO: Implement center align
                },
                tooltip: 'Align Center',
              ),
              SizedBox(width: 8),

              _buildToolbarButton(
                icon: Icons.format_align_right,
                isActive: false,
                onPressed: () {
                  // TODO: Implement right align
                },
                tooltip: 'Align Right',
              ),
              SizedBox(width: buttonSpacing),

              // Drawing tool
              _buildToolbarButton(
                icon: Icons.brush,
                isActive: false,
                onPressed: () {
                  // TODO: Implement drawing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Drawing coming soon!')),
                  );
                },
                tooltip: 'Drawing',
              ),
              SizedBox(width: buttonSpacing),

              // Bold
              _buildToolbarButton(
                icon: Icons.format_bold,
                isActive: _isBold,
                onPressed: _toggleBold,
                tooltip: 'Bold',
              ),
              SizedBox(width: buttonSpacing),

              // Italic
              _buildToolbarButton(
                icon: Icons.format_italic,
                isActive: _isItalic,
                onPressed: _toggleItalic,
                tooltip: 'Italic',
              ),
              SizedBox(width: buttonSpacing),

              // Underline
              _buildToolbarButton(
                icon: Icons.format_underline,
                isActive: _isUnderlined,
                onPressed: _toggleUnderline,
                tooltip: 'Underline',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth < 400 ? 36.0 : 40.0;
    final iconSize = screenWidth < 400 ? 18.0 : 20.0;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6B46C1) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onPressed,
            child: Icon(
              icon,
              size: iconSize,
              color: isActive ? Colors.white : Colors.black87,
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
          onPressed: () => Navigator.of(context).pop(),
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
          if (widget.note != null) // Only show detailed edit for existing notes
            IconButton(
              onPressed: _openDetailedModal,
              icon: Icon(Icons.settings, color: LoggitColors.darkGrayText),
              tooltip: 'Advanced Settings',
            ),
          IconButton(
            onPressed: _hasChanges ? _saveNote : null,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hasChanges
                            ? LoggitColors.teal
                            : LoggitColors.lighterGraySubtext,
                      ),
                    ),
                  )
                : Icon(
                    Icons.check,
                    color: _hasChanges
                        ? LoggitColors.teal
                        : LoggitColors.lighterGraySubtext,
                  ),
            tooltip: 'Save',
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
