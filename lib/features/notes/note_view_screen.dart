import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../features/notes/note_model.dart';
import '../../features/notes/note_edit_modal.dart';
import '../../features/notes/note_insert_modal.dart';
import '../../services/notes_service.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import '../../shared/utils/responsive.dart';
import '../../features/notes/note_settings_modal.dart';
import '../../services/notes_service.dart' show PersistentCategory;
import 'dart:convert';

// Category model (move to top level)
class Category {
  final String name;
  final Color color;
  Category({required this.name, required this.color});
}

// Highlighting text controller for selection-based and continuous highlights
class HighlightingTextController extends TextEditingController {
  HighlightingTextController({super.text, this.highlightColor});

  final Color? highlightColor;
  final List<TextRange> highlightedRanges = <TextRange>[];
  final List<TextRange> boldRanges = <TextRange>[];
  final List<TextRange> italicRanges = <TextRange>[];
  final List<TextRange> underlineRanges = <TextRange>[];

  void addHighlightRange(TextRange range) {
    if (range.isValid && !range.isCollapsed) {
      highlightedRanges.add(range);
      notifyListeners();
    }
  }

  void addOrMergeHighlightRange(TextRange range) {
    if (!range.isValid || range.isCollapsed) return;
    // Merge overlapping or adjacent ranges
    final List<TextRange> newRanges = <TextRange>[];
    TextRange current = range;
    for (final r
        in highlightedRanges..sort((a, b) => a.start.compareTo(b.start))) {
      if (current.end < r.start - 0) {
        newRanges.add(current);
        current = r;
      } else if (r.end < current.start - 0) {
        newRanges.add(r);
      } else {
        final start = current.start < r.start ? current.start : r.start;
        final end = current.end > r.end ? current.end : r.end;
        current = TextRange(start: start, end: end);
      }
    }
    newRanges.add(current);
    highlightedRanges
      ..clear()
      ..addAll(newRanges);
    notifyListeners();
  }

  void addOrMergeBoldRange(TextRange range) =>
      _addOrMergeInto(boldRanges, range);
  void addOrMergeItalicRange(TextRange range) =>
      _addOrMergeInto(italicRanges, range);
  void addOrMergeUnderlineRange(TextRange range) =>
      _addOrMergeInto(underlineRanges, range);

  void _addOrMergeInto(List<TextRange> list, TextRange range) {
    if (!range.isValid || range.isCollapsed) return;
    final List<TextRange> merged = <TextRange>[];
    TextRange current = range;
    for (final r in list..sort((a, b) => a.start.compareTo(b.start))) {
      if (current.end < r.start) {
        merged.add(current);
        current = r;
      } else if (r.end < current.start) {
        merged.add(r);
      } else {
        final start = current.start < r.start ? current.start : r.start;
        final end = current.end > r.end ? current.end : r.end;
        current = TextRange(start: start, end: end);
      }
    }
    merged.add(current);
    list
      ..clear()
      ..addAll(merged);
    notifyListeners();
  }

  // NEW: check if any existing highlight overlaps the given range
  bool hasAnyHighlightInRange(TextRange range) {
    if (!range.isValid || range.isCollapsed) return false;
    for (final r in highlightedRanges) {
      final bool overlaps = !(range.end <= r.start || range.start >= r.end);
      if (overlaps) return true;
    }
    return false;
  }

  bool hasAnyBoldInRange(TextRange range) =>
      _hasAnyIn(list: boldRanges, range: range);
  bool hasAnyItalicInRange(TextRange range) =>
      _hasAnyIn(list: italicRanges, range: range);
  bool hasAnyUnderlineInRange(TextRange range) =>
      _hasAnyIn(list: underlineRanges, range: range);

  bool _hasAnyIn({required List<TextRange> list, required TextRange range}) {
    if (!range.isValid || range.isCollapsed) return false;
    for (final r in list) {
      if (!(range.end <= r.start || range.start >= r.end)) return true;
    }
    return false;
  }

  // NEW: remove highlight within the given range (subtract from existing ranges)
  void removeHighlightRange(TextRange removal) {
    if (!removal.isValid || removal.isCollapsed) return;
    final List<TextRange> result = <TextRange>[];
    for (final r in highlightedRanges) {
      // No overlap: keep as-is
      if (removal.end <= r.start || removal.start >= r.end) {
        result.add(r);
        continue;
      }
      // Overlap exists: add left remainder if any
      final int leftStart = r.start;
      final int leftEnd = removal.start.clamp(r.start, r.end);
      if (leftEnd > leftStart) {
        result.add(TextRange(start: leftStart, end: leftEnd));
      }
      // Add right remainder if any
      final int rightStart = removal.end.clamp(r.start, r.end);
      final int rightEnd = r.end;
      if (rightEnd > rightStart) {
        result.add(TextRange(start: rightStart, end: rightEnd));
      }
    }
    highlightedRanges
      ..clear()
      ..addAll(result);
    notifyListeners();
  }

  void removeBoldRange(TextRange removal) => _removeFrom(boldRanges, removal);
  void removeItalicRange(TextRange removal) =>
      _removeFrom(italicRanges, removal);
  void removeUnderlineRange(TextRange removal) =>
      _removeFrom(underlineRanges, removal);

  void _removeFrom(List<TextRange> list, TextRange removal) {
    if (!removal.isValid || removal.isCollapsed) return;
    final List<TextRange> result = <TextRange>[];
    for (final r in list) {
      if (removal.end <= r.start || removal.start >= r.end) {
        result.add(r);
        continue;
      }
      final int leftStart = r.start;
      final int leftEnd = removal.start.clamp(r.start, r.end);
      if (leftEnd > leftStart) {
        result.add(TextRange(start: leftStart, end: leftEnd));
      }
      final int rightStart = removal.end.clamp(r.start, r.end);
      final int rightEnd = r.end;
      if (rightEnd > rightStart) {
        result.add(TextRange(start: rightStart, end: rightEnd));
      }
    }
    list
      ..clear()
      ..addAll(result);
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final String fullText = text;
    if (fullText.isEmpty) {
      return TextSpan(style: style, text: fullText);
    }

    // Build segmentation across all style ranges
    final Set<int> cuts = {0, fullText.length};
    void addCutsFrom(List<TextRange> ranges) {
      for (final r in ranges) {
        if (!r.isValid || r.isCollapsed) continue;
        cuts.add(r.start.clamp(0, fullText.length));
        cuts.add(r.end.clamp(0, fullText.length));
      }
    }

    addCutsFrom(highlightedRanges);
    addCutsFrom(boldRanges);
    addCutsFrom(italicRanges);
    addCutsFrom(underlineRanges);
    final List<int> points = cuts.toList()..sort();

    final List<InlineSpan> children = <InlineSpan>[];
    final Color bg = (highlightColor ?? const Color(0xFFFFF59D));
    for (int i = 0; i < points.length - 1; i++) {
      final int start = points[i];
      final int end = points[i + 1];
      if (end <= start) continue;
      final seg = TextRange(start: start, end: end);
      bool isHl = _containedIn(seg, highlightedRanges);
      bool isB = _containedIn(seg, boldRanges);
      bool isI = _containedIn(seg, italicRanges);
      bool isU = _containedIn(seg, underlineRanges);
      TextStyle segStyle = (style ?? const TextStyle());
      if (isHl) segStyle = segStyle.copyWith(backgroundColor: bg);
      if (isB) segStyle = segStyle.copyWith(fontWeight: FontWeight.bold);
      if (isI) segStyle = segStyle.copyWith(fontStyle: FontStyle.italic);
      if (isU) {
        segStyle = segStyle.copyWith(decoration: TextDecoration.underline);
      }
      children.add(
        TextSpan(text: fullText.substring(start, end), style: segStyle),
      );
    }
    return TextSpan(style: style, children: children);
  }

  bool _containedIn(TextRange seg, List<TextRange> ranges) {
    for (final r in ranges) {
      if (!r.isValid || r.isCollapsed) continue;
      if (seg.start >= r.start && seg.end <= r.end) return true;
    }
    return false;
  }
}

// Highlighted text span model
class HighlightedSpan {
  final int start;
  final int end;
  final Color color;

  HighlightedSpan({
    required this.start,
    required this.end,
    this.color = const Color(0xFFFFEB3B), // Default yellow
  });

  bool contains(int position) {
    return position >= start && position < end;
  }
}

class NoteViewScreen extends StatefulWidget {
  final Note? note; // null for new note, existing note for editing

  const NoteViewScreen({super.key, this.note});

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  static const String _prefKeyFloatingBarVisible =
      'notes_floating_format_bar_visible';
  final _titleController = TextEditingController();
  final HighlightingTextController _contentController =
      HighlightingTextController();
  final _contentFocusNode = FocusNode();
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();
  final ScrollController _contentScrollController = ScrollController();
  final GlobalKey _contentContainerKey = GlobalKey();
  bool _showFloatingFormatBar = true;
  bool _formatBarDocked = true; // when true, auto-docks under end of content
  Offset? _dragStartGlobal;
  Offset? _barStartLocal;
  // Approximate minimum vertical spacing below end-of-content when docked
  static const double _formatBarMinDistance =
      120.0; // ~1.5in approx in logical px
  double _formatBarLeft = 0;
  double _formatBarTop = 0;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Text formatting state
  bool _isBold = false; // acts as continuous bold mode
  bool _isItalic = false; // acts as continuous italic mode
  bool _isUnderlined = false; // acts as continuous underline mode
  bool _isBulletList = false;
  bool _isNumberedList = false;
  final bool _isHighlighted = false;
  double _fontSize = 16.0;

  // Highlighting system
  bool _highlightModeActive = false; // Whether highlighting is currently active
  final List<TextRange> _highlightedRanges = []; // Ranges of highlighted text
  int _lastCursorPosition = 0; // Track cursor position for highlighting
  int _previousTextLength =
      0; // Track previous text length to detect inserted chars
  TextSelection? _storedSelection; // Preserve selection across modal

  // ValueNotifier to trigger modal rebuilds
  final ValueNotifier<bool> _formatStateNotifier = ValueNotifier<bool>(false);

  late Color _noteColor;
  NoteType _selectedType = NoteType.text;
  final List<NoteItem> _checklistItems = [];
  List<Category> _categories = [];
  String _selectedCategory = 'Quick';
  Color _selectedCategoryColor = Colors.grey[400]!;
  List<String> _tags = [];
  NotePriority _selectedPriority = NotePriority.medium;
  NoteStatus _selectedStatus = NoteStatus.final_;

  // Custom selection handles (for web/desktop)
  String? _draggingSelectionHandle; // 'base' or 'extent'

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
                      textCapitalization: TextCapitalization.sentences,
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
                              'name': newCategoryName.trim().isNotEmpty
                                  ? newCategoryName.trim()[0].toUpperCase() +
                                        newCategoryName.trim().substring(1)
                                  : newCategoryName.trim(),
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
        _noteColor = Colors.white; // Always keep page white
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
    // Only select the color in colorOptions that matches the assigned color value
    int matchIndex = colorOptions.indexWhere(
      (c) => c.value == categoryColor.value,
    );
    if (matchIndex != -1) {
      tempSelectedColor = colorOptions[matchIndex];
    } else {
      tempSelectedColor = null; // No color highlighted if not found
    }

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
                        final isSelected =
                            tempSelectedColor?.value == color.value;
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
                                  'All notes in this category will be moved to the "Quick" category. Are you sure you want to delete "$newCategoryName"?',
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
                              'name': newCategoryName.trim().isNotEmpty
                                  ? newCategoryName.trim()[0].toUpperCase() +
                                        newCategoryName.trim().substring(1)
                                  : newCategoryName.trim(),
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
    _loadNote();
    // Track selection and text changes to move the floating toolbar
    _contentController.addListener(_onTextOrSelectionChange);
    _contentScrollController.addListener(_updateFloatingToolbarPosition);
    _contentFocusNode.addListener(() {
      if (_contentFocusNode.hasFocus) {
        _updateFloatingToolbarPosition();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateFloatingToolbarPosition(),
    );
    // Load persisted floating toolbar visibility preference
    _loadFloatingBarPreference();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _loadNote() {
    if (widget.note != null) {
      // Load existing note data
      _titleController.text = widget.note!.title;

      // Convert content from Delta format to plain text if needed
      String content = widget.note!.content;
      if (content.startsWith('[') && content.contains('"insert"')) {
        // This is Delta format, convert to plain text
        content = _convertDeltaToPlainText(content);
      }
      _contentController.text = content;

      // Load persisted highlights for this note
      _loadHighlights(widget.note!.id);

      _selectedCategory = widget.note!.noteCategory;
      _tags = List<String>.from(widget.note!.tags);
      _selectedPriority = widget.note!.priority;
      _selectedStatus = widget.note!.status;
      _selectedType = widget.note!.type;
      _noteColor = widget.note!.color;

      // Load category color
      _loadPersistentCategories().then((_) {
        final category = _categories.firstWhere(
          (c) => c.name == _selectedCategory,
          orElse: () => Category(name: 'Quick', color: Colors.grey[400]!),
        );
        _selectedCategoryColor = category.color;
      });
    } else {
      // New note - set defaults
      _selectedCategory = 'Quick';
      _selectedCategoryColor = Colors.grey[400]!;
      _noteColor = Colors.white;
      _contentController.clear();
      _loadPersistentCategories();
    }
  }

  String _convertDeltaToPlainText(String deltaJson) {
    try {
      final List<dynamic> delta = json.decode(deltaJson);
      String plainText = '';

      for (final operation in delta) {
        if (operation is Map<String, dynamic> &&
            operation.containsKey('insert')) {
          final insert = operation['insert'];
          if (insert is String) {
            plainText += insert;
          }
        }
      }

      return plainText;
    } catch (e) {
      print('Error converting Delta to plain text: $e');
      return deltaJson; // Return original if conversion fails
    }
  }

  void _getCurrentSelection() {
    // Track cursor position for highlighting
    _lastCursorPosition = _contentController.selection.baseOffset;
  }

  void _toggleBold() {
    final sel = _contentController.selection;
    final hasSel = sel.isValid && !sel.isCollapsed;
    if (hasSel) {
      if (_contentController.hasAnyBoldInRange(sel)) {
        _contentController.removeBoldRange(sel);
      } else {
        _contentController.addOrMergeBoldRange(sel);
      }
      _contentController.selection = TextSelection.collapsed(offset: sel.end);
      return;
    }
    setState(() {
      _isBold = !_isBold; // toggle continuous mode
      _hasChanges = true;
      if (_isBold) {
        _previousTextLength = _contentController.text.length;
      }
    });
    _formatStateNotifier.value = !_formatStateNotifier.value;
  }

  void _toggleItalic() {
    final sel = _contentController.selection;
    final hasSel = sel.isValid && !sel.isCollapsed;
    if (hasSel) {
      if (_contentController.hasAnyItalicInRange(sel)) {
        _contentController.removeItalicRange(sel);
      } else {
        _contentController.addOrMergeItalicRange(sel);
      }
      _contentController.selection = TextSelection.collapsed(offset: sel.end);
      return;
    }
    setState(() {
      _isItalic = !_isItalic;
      _hasChanges = true;
      if (_isItalic) {
        _previousTextLength = _contentController.text.length;
      }
    });
    _formatStateNotifier.value = !_formatStateNotifier.value;
  }

  void _toggleUnderline() {
    final sel = _contentController.selection;
    final hasSel = sel.isValid && !sel.isCollapsed;
    if (hasSel) {
      if (_contentController.hasAnyUnderlineInRange(sel)) {
        _contentController.removeUnderlineRange(sel);
      } else {
        _contentController.addOrMergeUnderlineRange(sel);
      }
      _contentController.selection = TextSelection.collapsed(offset: sel.end);
      return;
    }
    setState(() {
      _isUnderlined = !_isUnderlined;
      _hasChanges = true;
      if (_isUnderlined) {
        _previousTextLength = _contentController.text.length;
      }
    });
    _formatStateNotifier.value = !_formatStateNotifier.value;
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
    // Trigger a rebuild to update the text field styling
    setState(() {
      _hasChanges = true;
    });
  }

  void _showInsertModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NoteInsertModal(
        onInsert: (type, {data}) {
          // Handle insert actions
          switch (type) {
            case 'image':
              _insertImage();
              break;
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
      ),
    );
  }

  Widget _buildFormatModal() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          5 + MediaQuery.of(context).padding.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Top Section - Button Rows
              Column(
                children: [
                  // Row 1: Bold, Italic, Underline, Strike, [gap], Color, Highlight
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Left group: Bold, Italic, Underline, Strike, Checkbox
                        Row(
                          children: [
                            _buildFormatButton(
                              icon: Icons.format_bold,
                              isActive: _isBold,
                              onTap: () {
                                _toggleBold();
                              },
                            ),
                            SizedBox(width: 8),
                            _buildFormatButton(
                              icon: Icons.format_italic,
                              isActive: _isItalic,
                              onTap: () {
                                _toggleItalic();
                              },
                            ),
                            SizedBox(width: 8),
                            _buildFormatButton(
                              icon: Icons.format_underline,
                              isActive: _isUnderlined,
                              onTap: () {
                                _toggleUnderline();
                              },
                            ),
                            SizedBox(width: 8),
                            _buildFormatButton(
                              icon: Icons.strikethrough_s,
                              isActive: false,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Strikethrough coming soon!'),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 8),
                            _buildFormatButton(
                              icon: Icons.check_box,
                              isActive: false,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Checklist coming soon!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(width: 12),
                        // Right group: Color, Highlight
                        Row(
                          children: [
                            _buildFormatButton(
                              icon: Icons.format_color_text,
                              isActive: false,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Text color coming soon!'),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 8),
                            // Single highlight button: applies current selection/word and toggles continuous mode
                            _buildFormatButton(
                              icon: Icons.highlight,
                              isActive: _highlightModeActive,
                              onTap: () {
                                _toggleHighlight();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // Row 2: Bullet, Numbered, [gap], Left Align, Right Align, Quote
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Left group: Bullet, Numbered, Left Align, Right Align
                        Row(
                          children: [
                            _buildFormatButton(
                              icon: Icons.format_list_bulleted,
                              isActive: _isBulletList,
                              onTap: () {
                                _toggleBulletList();
                              },
                            ),
                            SizedBox(width: 8),
                            _buildFormatButton(
                              icon: Icons.format_list_numbered,
                              isActive: _isNumberedList,
                              onTap: () {
                                _toggleNumberedList();
                              },
                            ),
                            SizedBox(width: 8),
                            _buildFormatButton(
                              icon: Icons.format_align_left,
                              isActive: false,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Text alignment coming soon!',
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 8),
                            _buildFormatButton(
                              icon: Icons.format_align_right,
                              isActive: false,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Text alignment coming soon!',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(width: 12),
                        // Right group: Quote
                        Row(
                          children: [
                            _buildFormatButton(
                              icon: Icons.format_quote,
                              isActive: false,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Quote/Blockquote coming soon!',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Styles Row
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Styles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Normal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Font Row
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Font',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Calibri',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Size Row
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Size',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        _buildSmallButton(
                          icon: Icons.remove,
                          onTap: () {
                            _decreaseFontSize();
                          },
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${_fontSize.toInt()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 12),
                        _buildSmallButton(
                          icon: Icons.add,
                          onTap: () {
                            _increaseFontSize();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom extension to cover gap
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? LoggitColors.teal.withOpacity(
                  0.15,
                ) // Transparent teal background
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? LoggitColors.tealDark
                : Colors.grey[300]!, // Deep teal border when active
            width: isActive ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? LoggitColors.tealDark
              : Colors.black87, // Deep teal icon when active
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  void _showFormatModal() {
    // Store current selection so we can act on it inside the modal
    _storedSelection = _contentController.selection;
    // Keep focus on the editor so the blue selection stays visible
    _contentFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_storedSelection != null && _storedSelection!.isValid) {
        _contentController.selection = _storedSelection!;
      }
      _contentFocusNode.requestFocus();
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // Remove black tint
      isDismissible: true, // Allow dismissing by tapping outside
      enableDrag: true,
      builder: (context) => GestureDetector(
        onTap: () {
          // Close modal when tapping outside
          Navigator.of(context).pop();
        },
        child: Container(
          color: Colors.transparent,
          child: DraggableScrollableSheet(
            initialChildSize: 0.47,
            minChildSize: 0.4,
            maxChildSize: 0.5,
            builder: (context, scrollController) => GestureDetector(
              onTap: () {
                // Prevent closing when tapping inside the modal
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _formatStateNotifier,
                  builder: (context, value, child) {
                    return _buildFormatModal();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildFormatOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: isActive
              ? LoggitColors.teal.withOpacity(0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? LoggitColors.teal : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? LoggitColors.teal : Colors.black87,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? LoggitColors.teal : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
      Color colorToUse = _selectedCategoryColor;
      if (_selectedCategory.isEmpty ||
          !_categories.any((c) => c.name == _selectedCategory)) {
        // Use persistent Quick color
        final persistent = await NotesService.getPersistentCategories();
        final quick = persistent.firstWhere(
          (c) => c.name == 'Quick',
          orElse: () =>
              PersistentCategory(name: 'Quick', colorValue: 0xFF9CA3AF),
        );
        colorToUse = Color(quick.colorValue);
        categoryToUse = 'Quick';
      }
      if (widget.note == null) {
        // Create new note
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          content: _contentController.text,
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
          await _saveHighlights(newNote.id);
          Navigator.of(
            context,
          ).pop({'note': newNote, 'categories': _categories});
          return newNote;
        }
      } else {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text,
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
          await _saveHighlights(updatedNote.id);
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

  Future<void> _showSettingsModal() async {
    // Ensure categories are loaded
    await _loadPersistentCategories();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.transparent,
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return GestureDetector(
                  onTap: () {}, // Prevent taps on modal content from closing it
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          margin: EdgeInsets.only(top: 12, bottom: 16),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: NoteSettingsModal(
                            selectedCategory: _selectedCategory,
                            categories: _categories
                                .map((cat) => cat.name)
                                .toList(),
                            onCategoryChanged: (cat) {
                              setState(() {
                                _selectedCategory = cat;
                                final foundCat = _categories.firstWhere(
                                  (c) => c.name == cat,
                                  orElse: () => Category(
                                    name: 'Quick',
                                    color: Colors.grey[400]!,
                                  ),
                                );
                                _selectedCategoryColor = foundCat.color;
                              });
                            },
                            tags: _tags,
                            onAddTag: (tag) {
                              final trimmed = tag.trim();
                              if (trimmed.isNotEmpty &&
                                  !_tags.contains(trimmed)) {
                                setState(() {
                                  _tags.add(trimmed);
                                });
                              }
                            },
                            onRemoveTag: (tag) =>
                                setState(() => _tags.remove(tag)),
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
                                _noteColor =
                                    Colors.white; // Always keep page white
                              });
                              Navigator.of(context).pop();
                            },
                            onAddCategory: () async {
                              final result = await _showAddCategoryDialog();
                              if (result != null) {
                                // Add the new category
                                final newCat = Category(
                                  name: result['name'],
                                  color: result['color'],
                                );
                                setState(() {
                                  _categories.add(newCat);
                                  _selectedCategory = newCat.name;
                                  _selectedCategoryColor = newCat.color;
                                });
                                // Save to persistent storage
                                await NotesService.addOrUpdateCategory(
                                  PersistentCategory(
                                    name: newCat.name,
                                    colorValue: newCat.color.value,
                                  ),
                                );
                                // Refresh the modal to show the new category with its color
                                Navigator.of(context).pop();
                                await _showSettingsModal();
                              }
                              return result;
                            },
                            onEditCategory: (categoryName, categoryColor) async {
                              final result = await _showEditCategoryDialog(
                                categoryName,
                                categoryColor,
                              );
                              if (result != null) {
                                if (result['action'] == 'save') {
                                  final newCatName = result['name'];
                                  final newCatColor = result['color'];

                                  // Remove the old category first
                                  await NotesService.deleteCategory(
                                    categoryName,
                                  );

                                  // Add the updated category
                                  final newCat = Category(
                                    name: newCatName,
                                    color: newCatColor,
                                  );

                                  setState(() {
                                    // Remove old category
                                    _categories.removeWhere(
                                      (c) => c.name == categoryName,
                                    );
                                    // Add new category
                                    _categories.add(newCat);

                                    // Update selected category if it was the edited one
                                    if (_selectedCategory == categoryName) {
                                      _selectedCategory = newCatName;
                                      _selectedCategoryColor = newCatColor;
                                      _noteColor = Colors.white;
                                    }
                                  });

                                  // Save the new category
                                  await NotesService.addOrUpdateCategory(
                                    PersistentCategory(
                                      name: newCatName,
                                      colorValue: newCatColor.value,
                                    ),
                                  );

                                  // Force a rebuild to ensure categories are updated
                                  setState(() {});
                                  // Refresh the modal to show the updated category with its color
                                  Navigator.of(context).pop();
                                  await _showSettingsModal();
                                } else if (result['action'] == 'delete') {
                                  // Remove category from persistent storage and reassign notes
                                  await NotesService.deleteCategory(
                                    categoryName,
                                  );
                                  setState(() {
                                    _categories.removeWhere(
                                      (c) => c.name == categoryName,
                                    );
                                    if (_selectedCategory == categoryName) {
                                      _selectedCategory = 'Quick';
                                      _selectedCategoryColor =
                                          Colors.grey[400]!;
                                      _noteColor = Colors
                                          .white; // Always keep page white
                                    }
                                  });
                                  // Force a rebuild to ensure categories are updated
                                  setState(() {});
                                  // Refresh the modal to show the updated category list
                                  Navigator.of(context).pop();
                                  await _showSettingsModal();
                                }
                              }
                              return result;
                            },
                            categoryColors: Map.fromEntries(
                              _categories.map(
                                (cat) => MapEntry(cat.name, cat.color),
                              ),
                            ),
                          ),
                        ),
                        // Fixed buttons at the bottom
                        Padding(
                          padding: EdgeInsets.only(
                            left: LoggitSpacing.screenPadding,
                            right: LoggitSpacing.screenPadding,
                            top: 16,
                            bottom: 40 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: LoggitColors.teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Done',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    // Handle export results
    if (result != null) {
      switch (result) {
        case 'export_text':
          _exportAsText();
          break;
        case 'export_pdf':
          _exportAsPDF();
          break;
        case 'share_email':
          _shareViaEmail();
          break;
      }
    }
  }

  Future<void> _openDetailedModal() async {
    // Create a temporary note with current content for the modal
    final tempNote =
        widget.note?.copyWith(
          title: _titleController.text.trim(),
          content:
              _contentController.text, // Save content directly from TextField
        ) ??
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          content:
              _contentController.text, // Save content directly from TextField
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
        _contentController.text = result.content; // Use TextField content
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
                        icon: Icons.format_list_bulleted,
                        isActive: false,
                        onPressed: _showFormatModal,
                        tooltip: 'Format Options',
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: buttonSpacing),
                      _buildFloatingToolbarButton(
                        icon: Icons.text_fields,
                        isActive: _showFloatingFormatBar,
                        onPressed: () {
                          final next = !_showFloatingFormatBar;
                          setState(() {
                            _showFloatingFormatBar = next;
                            if (next) {
                              _formatBarDocked = true; // re-dock on show
                            }
                          });
                          if (next) {
                            _updateFloatingToolbarPosition();
                          }
                          _saveFloatingBarPreference(next);
                        },
                        tooltip: _showFloatingFormatBar
                            ? 'Hide Format Bar'
                            : 'Show Format Bar',
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: buttonSpacing),
                      _buildFloatingToolbarButton(
                        icon: Icons.settings,
                        isActive: false,
                        onPressed: _showSettingsModal,
                        tooltip: 'Settings',
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
        actions: [],
      ),
      body: Column(
        children: [
          // Title field - extends to edges
          Container(
            width: double.infinity,
            color: LoggitColors.lightGray,
            child: Padding(
              padding: EdgeInsets.all(LoggitSpacing.lg),
              child: Row(
                children: [
                  // Title TextField
                  Expanded(
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
                        suffixIcon: _selectedCategory.isNotEmpty
                            ? Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () async {
                                    await _showSettingsModal();
                                  },
                                  child: SizedBox(
                                    width: 60,
                                    height: 28,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedCategoryColor
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _selectedCategoryColor
                                              .withOpacity(0.8),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _selectedCategory,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
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
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: (details) {
                    _selectWordAtGlobalPosition(details.globalPosition);
                  },
                  child: Stack(
                    key: _contentContainerKey,
                    children: [
                      Positioned.fill(
                        child: EditableText(
                          key: _editableKey,
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          style: TextStyle(
                            // Base style; selective formatting applied via controller spans
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                            decoration: TextDecoration.none,
                            height: 1.2,
                          ),
                          cursorColor: Colors.black87,
                          backgroundCursorColor: Colors.black12,
                          selectionColor: Colors.blue.withOpacity(0.30),
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          scrollController: _contentScrollController,
                          maxLines: null,
                          expands: true,
                          onChanged: (text) => _handleTextChange(text),
                        ),
                      ),
                      // Custom selection handles overlay for web/desktop
                      ..._buildCustomSelectionHandles(),
                      if (_showFloatingFormatBar)
                        Positioned(
                          left: _formatBarLeft,
                          top: _formatBarTop,
                          child: _buildFloatingFormatBar(),
                        ),
                    ],
                  ),
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

  void _exportAsText() {
    final noteContent =
        '''
Title: ${_titleController.text}
Category: $_selectedCategory
Tags: ${_tags.join(', ')}
Content:
${_contentController.text}
''';

    // For now, just show a snackbar. In a real app, you'd save to file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Note exported as text (${noteContent.length} characters)',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportAsPDF() {
    // For now, just show a snackbar. In a real app, you'd generate PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF export coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareViaEmail() {
    final subject = 'Note: ${_titleController.text}';
    final body =
        '''
Note from Loggit:

Title: ${_titleController.text}
Category: $_selectedCategory
Tags: ${_tags.join(', ')}

Content:
${_contentController.text}
''';

    // For now, just show a snackbar. In a real app, you'd open email app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email sharing coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _applyHighlightForCurrentSelectionOrWord() {
    // Prefer stored selection captured when modal opened
    final selection = (_storedSelection != null && _storedSelection!.isValid)
        ? _storedSelection!
        : _contentController.selection;
    final String fullText = _contentController.text;

    if (selection.isValid && !selection.isCollapsed) {
      // Toggle highlight within the selected range
      if (_contentController.hasAnyHighlightInRange(selection)) {
        _contentController.removeHighlightRange(selection);
      } else {
        _contentController.addOrMergeHighlightRange(selection);
      }
      // Move caret to end of range
      final collapseOffset = selection.end.clamp(0, fullText.length);
      _contentController.selection = TextSelection.collapsed(
        offset: collapseOffset,
      );
      if (_highlightModeActive) {
        _lastCursorPosition = collapseOffset;
      }
      // Clear stored selection after using it
      _storedSelection = null;
      return;
    }

    // No selection: find word at caret
    final int caret = selection.baseOffset.clamp(0, fullText.length);
    if (fullText.isEmpty || caret < 0 || caret > fullText.length) return;

    int start = caret;
    int end = caret;

    // Expand left to word boundary
    while (start > 0) {
      final ch = fullText[start - 1];
      if (ch.trim().isEmpty) break; // stop at whitespace
      start--;
    }
    // Expand right to word boundary
    while (end < fullText.length) {
      final ch = fullText[end];
      if (ch.trim().isEmpty) break;
      end++;
    }

    if (end > start) {
      final wordRange = TextRange(start: start, end: end);
      // Toggle highlight for the word
      if (_contentController.hasAnyHighlightInRange(wordRange)) {
        _contentController.removeHighlightRange(wordRange);
      } else {
        _contentController.addOrMergeHighlightRange(wordRange);
      }
      // Move caret to end of word and set start point for continuous highlight
      _contentController.selection = TextSelection.collapsed(offset: end);
      if (_highlightModeActive) {
        _lastCursorPosition = end;
      }
    }
  }

  void _applyHighlightPressed() {
    // Apply highlight to selection or word without toggling continuous mode
    _applyHighlightForCurrentSelectionOrWord();
    // Ensure we don't accidentally enable continuous highlighting
    // Leave _highlightModeActive unchanged
    // Also refresh modal UI if open
    _formatStateNotifier.value = !_formatStateNotifier.value;
  }

  void _toggleHighlight() {
    // Determine if there is an explicit selection
    final hasSelection =
        _contentController.selection.isValid &&
        !_contentController.selection.isCollapsed;

    if (hasSelection) {
      // One-shot: apply highlight to the selection, do not enable continuous mode
      _applyHighlightForCurrentSelectionOrWord();
      // Ensure continuous mode is OFF after applying
      setState(() {
        _highlightModeActive = false;
        _hasChanges = true;
      });
      _formatStateNotifier.value = !_formatStateNotifier.value;
      return;
    }

    // No selection: toggle continuous highlight mode
    setState(() {
      _highlightModeActive = !_highlightModeActive;
      _hasChanges = true;
      if (_highlightModeActive) {
        // Baseline for newly typed characters
        _previousTextLength = _contentController.text.length;
        _lastCursorPosition = _contentController.selection.baseOffset;
        // Also apply immediate word highlight if caret is on a word
        _applyHighlightForCurrentSelectionOrWord();
      }
    });

    _formatStateNotifier.value = !_formatStateNotifier.value;
  }

  void _handleTextChange(String text) {
    _hasChanges = true;

    // Update baseline text length if needed
    final int newLength = text.length;

    if (_highlightModeActive || _isBold || _isItalic || _isUnderlined) {
      final int caret = _contentController.selection.baseOffset;
      final int delta = newLength - _previousTextLength;
      if (delta > 0 && caret >= delta) {
        // Only highlight newly inserted characters, not the gap
        final int start = caret - delta;
        final int end = caret;
        final range = TextRange(start: start, end: end);
        if (_highlightModeActive) {
          _contentController.addOrMergeHighlightRange(range);
        }
        if (_isBold) {
          _contentController.addOrMergeBoldRange(range);
        }
        if (_isItalic) {
          _contentController.addOrMergeItalicRange(range);
        }
        if (_isUnderlined) {
          _contentController.addOrMergeUnderlineRange(range);
        }
      }
      _previousTextLength = newLength;
    } else {
      _previousTextLength = newLength;
    }

    _lastCursorPosition = _contentController.selection.baseOffset;

    // When docked, keep the floating bar following the end of content
    if (_formatBarDocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateFloatingToolbarPosition();
      });
    }
  }

  Future<void> _loadHighlights(String noteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'note_highlights_$noteId';
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) return;
      final List<dynamic> data = json.decode(jsonString);
      final int maxLen = _contentController.text.length;
      final List<TextRange> ranges = [];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final int? s = item['s'];
          final int? e = item['e'];
          if (s != null && e != null && s >= 0 && e >= 0 && e > s) {
            final clampedStart = s.clamp(0, maxLen);
            final clampedEnd = e.clamp(0, maxLen);
            if (clampedEnd > clampedStart) {
              ranges.add(TextRange(start: clampedStart, end: clampedEnd));
            }
          }
        }
      }
      _contentController.highlightedRanges
        ..clear()
        ..addAll(ranges);
      _contentController.notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveHighlights(String noteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'note_highlights_$noteId';
      final int maxLen = _contentController.text.length;
      final List<Map<String, int>> data = _contentController.highlightedRanges
          .where((r) => r.isValid && !r.isCollapsed)
          .map((r) {
            final s = r.start.clamp(0, maxLen);
            final e = r.end.clamp(0, maxLen);
            return {'s': s, 'e': e};
          })
          .toList();
      await prefs.setString(key, json.encode(data));
    } catch (_) {}
  }

  void _selectWordAtGlobalPosition(Offset globalPosition) {
    final editableState = _editableKey.currentState;
    if (editableState == null) return;
    final RenderBox renderBox = editableState.renderEditable as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(globalPosition);
    final TextPosition pos = editableState.renderEditable.getPositionForPoint(
      localOffset,
    );

    final String fullText = _contentController.text;
    int index = pos.offset.clamp(0, fullText.length);
    if (fullText.isEmpty) return;

    int start = index;
    int end = index;
    while (start > 0 && fullText[start - 1].trim().isNotEmpty) {
      start--;
    }
    while (end < fullText.length && fullText[end].trim().isNotEmpty) {
      end++;
    }
    if (end > start) {
      _contentController.selection = TextSelection(
        baseOffset: start,
        extentOffset: end,
      );
      _contentFocusNode.requestFocus();
    }
  }

  void _onTextOrSelectionChange() {
    if (_formatBarDocked) {
      _updateFloatingToolbarPosition();
    }
  }

  void _updateFloatingToolbarPosition() {
    final editable = _editableKey.currentState?.renderEditable;
    final containerBox =
        (_contentContainerKey.currentContext?.findRenderObject()) as RenderBox?;
    if (editable == null || containerBox == null) return;

    // Always position under end-of-document when docked
    final int endOffset = _contentController.text.length;
    final TextPosition pos = TextPosition(offset: endOffset);
    final Rect caretRect = editable.getLocalRectForCaret(pos);

    // Convert caret position to global, then to container-local
    final Offset caretGlobal = editable.localToGlobal(caretRect.bottomLeft);
    final Offset containerOriginGlobal = containerBox.localToGlobal(
      Offset.zero,
    );
    final double localX = caretGlobal.dx - containerOriginGlobal.dx;
    final double localY = caretGlobal.dy - containerOriginGlobal.dy;

    final double containerWidth = containerBox.size.width;
    final double containerHeight = containerBox.size.height;
    // Estimated bar size
    const double barWidth = 240;
    const double barHeight = 44;
    const double padding = 8;

    // Center horizontally when docked
    double left = (containerWidth - barWidth) / 2;
    if (left < padding) left = padding;
    if (left + barWidth + padding > containerWidth) {
      left = containerWidth - barWidth - padding;
      if (left < padding) left = padding;
    }
    // Position with minimum vertical spacing below end-of-content when docked
    double top = localY + _formatBarMinDistance;
    if (top + barHeight + padding > containerHeight) {
      top = containerHeight - barHeight - padding;
      if (top < padding) top = padding;
    }

    setState(() {
      _formatBarLeft = left;
      _formatBarTop = top;
    });
  }

  Widget _buildFloatingFormatBar() {
    final bool activeBold = _isBoldActiveUI();
    final bool activeItalic = _isItalicActiveUI();
    final bool activeUnderline = _isUnderlineActiveUI();
    final bool activeHighlight = _isHighlightActiveUI();
    return GestureDetector(
      onLongPressStart: (details) {
        // Start manual drag: undock
        _formatBarDocked = false;
        _dragStartGlobal = details.globalPosition;
        _barStartLocal = Offset(_formatBarLeft, _formatBarTop);
      },
      onLongPressMoveUpdate: (details) {
        final containerBox =
            (_contentContainerKey.currentContext?.findRenderObject())
                as RenderBox?;
        if (containerBox == null ||
            _dragStartGlobal == null ||
            _barStartLocal == null) {
          return;
        }
        const double barWidth = 240;
        const double barHeight = 44;
        const double padding = 8;
        final Offset delta = details.globalPosition - _dragStartGlobal!;
        double left = _barStartLocal!.dx + delta.dx;
        double top = _barStartLocal!.dy + delta.dy;
        // Clamp within container
        final size = containerBox.size;
        if (left < padding) left = padding;
        if (left > size.width - barWidth - padding) {
          left = size.width - barWidth - padding;
        }
        if (top < padding) top = padding;
        if (top > size.height - barHeight - padding) {
          top = size.height - barHeight - padding;
        }
        setState(() {
          _formatBarLeft = left;
          _formatBarTop = top;
        });
      },
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.format_bold,
                  size: 20,
                  color: activeBold ? LoggitColors.tealDark : Colors.black87,
                ),
                tooltip: 'Bold',
                onPressed: _toggleBold,
              ),
              IconButton(
                icon: Icon(
                  Icons.format_italic,
                  size: 20,
                  color: activeItalic ? LoggitColors.tealDark : Colors.black87,
                ),
                tooltip: 'Italic',
                onPressed: _toggleItalic,
              ),
              IconButton(
                icon: Icon(
                  Icons.format_underline,
                  size: 20,
                  color: activeUnderline
                      ? LoggitColors.tealDark
                      : Colors.black87,
                ),
                tooltip: 'Underline',
                onPressed: _toggleUnderline,
              ),
              IconButton(
                icon: Icon(
                  Icons.highlight,
                  size: 20,
                  color: activeHighlight
                      ? LoggitColors.tealDark
                      : Colors.black87,
                ),
                tooltip: 'Highlight',
                onPressed: _toggleHighlight,
              ),
              const SizedBox(width: 4),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.close, size: 20),
                tooltip: 'Close',
                onPressed: () {
                  setState(() {
                    _showFloatingFormatBar = false;
                    // Re-dock next time it's shown
                    _formatBarDocked = true;
                  });
                  _saveFloatingBarPreference(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadFloatingBarPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visible = prefs.getBool(_prefKeyFloatingBarVisible);
      setState(() {
        _showFloatingFormatBar = visible ?? true; // default to visible
        if (_showFloatingFormatBar) {
          _formatBarDocked = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _updateFloatingToolbarPosition(),
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _saveFloatingBarPreference(bool visible) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyFloatingBarVisible, visible);
    } catch (_) {}
  }

  // UI helpers: determine active state for format buttons
  bool _offsetInRanges(int offset, List<TextRange> ranges) {
    for (final r in ranges) {
      if (!r.isValid || r.isCollapsed) continue;
      if (offset >= r.start && offset < r.end) return true;
    }
    return false;
  }

  bool _selectionFullyCovered(TextSelection sel, List<TextRange> ranges) {
    for (final r in ranges) {
      if (!r.isValid || r.isCollapsed) continue;
      if (r.start <= sel.start && r.end >= sel.end) return true;
    }
    return false;
  }

  bool _isBoldActiveUI() {
    final sel = _contentController.selection;
    if (sel.isValid && !sel.isCollapsed) {
      return _selectionFullyCovered(sel, _contentController.boldRanges);
    }
    final caret = sel.baseOffset;
    return _isBold || _offsetInRanges(caret, _contentController.boldRanges);
  }

  bool _isItalicActiveUI() {
    final sel = _contentController.selection;
    if (sel.isValid && !sel.isCollapsed) {
      return _selectionFullyCovered(sel, _contentController.italicRanges);
    }
    final caret = sel.baseOffset;
    return _isItalic || _offsetInRanges(caret, _contentController.italicRanges);
  }

  bool _isUnderlineActiveUI() {
    final sel = _contentController.selection;
    if (sel.isValid && !sel.isCollapsed) {
      return _selectionFullyCovered(sel, _contentController.underlineRanges);
    }
    final caret = sel.baseOffset;
    return _isUnderlined ||
        _offsetInRanges(caret, _contentController.underlineRanges);
  }

  bool _isHighlightActiveUI() {
    final sel = _contentController.selection;
    if (sel.isValid && !sel.isCollapsed) {
      return _selectionFullyCovered(sel, _contentController.highlightedRanges);
    }
    final caret = sel.baseOffset;
    return _highlightModeActive ||
        _offsetInRanges(caret, _contentController.highlightedRanges);
  }

  bool _shouldShowCustomHandles() {
    if (kIsWeb) return true;
    // Desktop platforms
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return true;
    }
    return false;
  }

  List<Widget> _buildCustomSelectionHandles() {
    if (!_shouldShowCustomHandles()) return const [];
    if (!_contentFocusNode.hasFocus) return const [];
    final sel = _contentController.selection;
    if (!(sel.isValid && !sel.isCollapsed)) return const [];

    final editable = _editableKey.currentState?.renderEditable;
    final containerBox =
        (_contentContainerKey.currentContext?.findRenderObject()) as RenderBox?;
    if (editable == null || containerBox == null) return const [];

    // Anchor handles to caret rectangles for base and extent
    final TextPosition basePos = TextPosition(offset: sel.baseOffset);
    final TextPosition extentPos = TextPosition(offset: sel.extentOffset);
    final Rect baseRect = editable.getLocalRectForCaret(basePos);
    final Rect extentRect = editable.getLocalRectForCaret(extentPos);

    final Offset containerOrigin = containerBox.localToGlobal(Offset.zero);
    Offset toContainerLocal(Offset editableLocalPoint) {
      final Offset global = editable.localToGlobal(editableLocalPoint);
      return global - containerOrigin;
    }

    // Use bottomLeft of caret rects to emulate native handle anchor
    final Offset baseLocal = toContainerLocal(baseRect.bottomLeft);
    final Offset extentLocal = toContainerLocal(extentRect.bottomLeft);

    const double handleSize = 18;
    const double handleRadius = handleSize / 2;

    Widget buildHandle(Offset localPos, String which) {
      return Positioned(
        left: localPos.dx - handleRadius,
        top: localPos.dy - handleRadius,
        child: GestureDetector(
          onPanStart: (_) {
            _draggingSelectionHandle = which;
          },
          onPanUpdate: (details) {
            // Use absolute pointer position for precise dragging
            final Offset editableLocal = editable.globalToLocal(
              details.globalPosition,
            );
            final pos = editable.getPositionForPoint(editableLocal).offset;
            final current = _contentController.selection;
            TextSelection nextSel;
            if (_draggingSelectionHandle == 'base') {
              nextSel = TextSelection(
                baseOffset: pos,
                extentOffset: current.extentOffset,
              );
            } else {
              nextSel = TextSelection(
                baseOffset: current.baseOffset,
                extentOffset: pos,
              );
            }
            setState(() {
              _contentController.selection = nextSel;
            });
          },
          onPanEnd: (_) {
            _draggingSelectionHandle = null;
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return [buildHandle(baseLocal, 'base'), buildHandle(extentLocal, 'extent')];
  }
}
