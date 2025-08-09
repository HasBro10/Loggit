import 'package:flutter/material.dart';
import '../../features/notes/note_model.dart';
import '../../services/notes_service.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import 'note_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Helper function to convert Delta format to plain text
String _convertDeltaToPlainText(String deltaContent) {
  try {
    if (deltaContent.isEmpty) return '';

    // Check if it's Delta format (starts with [)
    if (deltaContent.startsWith('[')) {
      final List<dynamic> delta = jsonDecode(deltaContent);
      String plainText = '';

      for (final operation in delta) {
        if (operation is Map && operation.containsKey('insert')) {
          final insert = operation['insert'];
          if (insert is String) {
            plainText += insert;
          }
        }
      }

      return plainText.trim();
    }

    // If not Delta format, return as-is (for backward compatibility)
    return deltaContent;
  } catch (e) {
    // If parsing fails, return the original content
    return deltaContent;
  }
}

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

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<String> _categories = ['All'];
  Map<String, Color> _categoryColors = {};
  bool _isGridView = false;
  bool _isCompactView = false; // New compact view option
  final bool _showCategoryDropdown = false;
  double _dropdownHeight = 0.0;
  double _maxDropdownHeight = 320.0;
  final double _minDropdownHeight = 0.0;
  bool _isDraggingDropdown = false;
  late AnimationController _dropdownAnimController;
  late Animation<double> _dropdownAnim;
  // Minimum height: category bar (44) + minimal vertical padding (4+4) + divider (1) + handle (24)
  final double _collapsedHeight = 44 + 4 + 4 + 1 + 24;
  final double _categoryRowHeight = 44; // height of one row of category buttons
  final double _verticalPadding =
      32; // estimated total vertical padding (top+between+bottom)
  final double _handleHeight = 24; // height for the handle area
  // Calculate dynamic expanded height for overlay to fit all categories (no scroll)
  double get _dynamicExpandedHeight {
    // Top bar: 44 (height) + vertical padding (LoggitSpacing.sm*2)
    final double barHeight = 44 + (LoggitSpacing.sm * 2);
    final double dividerHeight = 1;
    final double gapBelowDivider = 12;
    final double handleHeight = 24;
    final double gapBelowHandle = 4;

    // Extra categories
    final int categoriesPerRow = 3; // 3 per row for compactness
    final int extraCount = (_categories.length > 5)
        ? _categories.length - 5
        : 0;
    final int rows = (extraCount / categoriesPerRow).ceil();
    final double buttonHeight = 36;
    final double rowSpacing = 8;

    // If no extra categories, provide minimum height for message
    final double wrapHeight = extraCount > 0
        ? (rows * buttonHeight) + ((rows - 1) * rowSpacing) + gapBelowDivider
        : 80; // Minimum height to show the message

    return barHeight +
        dividerHeight +
        wrapHeight +
        handleHeight +
        gapBelowHandle +
        24;
  }
  // _expandedHeight is now dynamic, see _dynamicExpandedHeight above

  // Define button size and font for all categories
  final double categoryButtonWidth = 110;
  final double categoryButtonHeight = 44;
  final double categoryFontSize = 15;
  final GlobalKey _overlayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadViewPreference();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
        // Automatically deselect category when searching
        if (_searchQuery.isNotEmpty) {
          _selectedCategory = 'All';
        }
      });
      _filterNotes(); // Apply the filtering
    });
    _dropdownHeight = _collapsedHeight;
    _dropdownAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );
    _dropdownAnim =
        Tween<double>(begin: _dropdownHeight, end: _dropdownHeight).animate(
          CurvedAnimation(
            parent: _dropdownAnimController,
            curve: Curves.easeInOut,
          ),
        )..addListener(() {
          setState(() {
            _dropdownHeight = _dropdownAnim.value;
          });
        });
  }

  // Load saved view preference
  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final viewType =
        prefs.getString('notes_view_type') ?? 'list'; // Default to list view

    setState(() {
      switch (viewType) {
        case 'grid':
          _isGridView = true;
          _isCompactView = false;
          break;
        case 'compact':
          _isGridView = false;
          _isCompactView = true;
          break;
        case 'list':
        default:
          _isGridView = false;
          _isCompactView = false;
          break;
      }
    });
  }

  // Save view preference
  Future<void> _saveViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    String viewType;

    if (_isGridView) {
      viewType = 'grid';
    } else if (_isCompactView) {
      viewType = 'compact';
    } else {
      viewType = 'list';
    }

    await prefs.setString('notes_view_type', viewType);
  }

  @override
  void dispose() {
    _dropdownAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await NotesService.getNotes();
      final persistent = await NotesService.getPersistentCategories();
      final categories = persistent.map((c) => c.name).toList();

      // Create category colors map
      final categoryColors = <String, Color>{};
      for (final cat in persistent) {
        categoryColors[cat.name] = Color(cat.colorValue);
      }

      setState(() {
        _notes = notes;
        _categories = ['All', ...categories];
        _categoryColors = categoryColors;
        _filteredNotes = _notes;
        _isLoading = false;
      });

      // Update animation with new dynamic height
      _dropdownAnim =
          Tween<double>(
              begin: _collapsedHeight,
              end: _dynamicExpandedHeight,
            ).animate(
              CurvedAnimation(
                parent: _dropdownAnimController,
                curve: Curves.easeInOut,
              ),
            )
            ..addListener(() {
              setState(() {
                _dropdownHeight = _dropdownAnim.value;
              });
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
        // If searching, override category filter and show all matching notes
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query) ||
              note.noteCategory.toLowerCase().contains(query) ||
              note.tags.any((tag) => tag.toLowerCase().contains(query));
        }

        // If not searching, apply category filter
        if (_selectedCategory != 'All' &&
            note.noteCategory != _selectedCategory) {
          return false;
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
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const NoteViewScreen()));
    // Always refresh notes and categories when returning from note creation/editing
    await _loadNotes();
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => NoteViewScreen(note: note)));
    // Always refresh notes and categories when returning from note creation/editing
    await _loadNotes();
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

  void _animateTo(double targetHeight) {
    _dropdownAnim = Tween<double>(begin: _dropdownHeight, end: targetHeight)
        .animate(
          CurvedAnimation(
            parent: _dropdownAnimController,
            curve: Curves.easeInOut,
          ),
        );
    _dropdownAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDark ? LoggitColors.darkBg : LoggitColors.pureWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _maxDropdownHeight = constraints.maxHeight;
            return Column(
              children: [
                // Fixed header - matching tasks screen style
                Container(
                  padding: const EdgeInsets.all(LoggitSpacing.screenPadding),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDark
                              ? Colors.white
                              : LoggitColors.darkGrayText,
                        ),
                        onPressed: () => widget.onBackToChat?.call(),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: isDark
                              ? Colors.white
                              : LoggitColors.darkGrayText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isGridView
                              ? Icons.view_list
                              : _isCompactView
                              ? Icons.grid_view
                              : Icons.view_compact,
                          color: isDark
                              ? Colors.white
                              : LoggitColors.darkGrayText,
                        ),
                        tooltip: _isGridView
                            ? 'List View'
                            : _isCompactView
                            ? 'Grid View'
                            : 'Compact View',
                        onPressed: () {
                          setState(() {
                            if (_isGridView) {
                              // From Grid (Card) view → List (Tile) view
                              _isGridView = false;
                              _isCompactView = false;
                            } else if (_isCompactView) {
                              // From Compact view → Grid (Card) view
                              _isGridView = true;
                              _isCompactView = false;
                            } else {
                              // From List (Tile) view → Compact view
                              _isGridView = false;
                              _isCompactView = true;
                            }
                          });
                          _saveViewPreference(); // Save the new view preference
                        },
                      ),
                    ],
                  ),
                ),
                // Everything below header is wrapped in a Stack for overlay
                Expanded(
                  child: Stack(
                    children: [
                      // Main content (search bar, notes) as the base layer (NO category bar here)
                      Column(
                        children: [
                          // Push content down by the height of the collapsed overlay
                          SizedBox(height: _collapsedHeight + 20),
                          // Search bar
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: LoggitSpacing.lg,
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search notes...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[500],
                                ),
                                filled: true,
                                fillColor: Color(0xFFF1F5F9),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : LoggitColors.darkGrayText,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          SizedBox(height: LoggitSpacing.lg),
                          // Notes List
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _filteredNotes.isEmpty
                                ? _buildEmptyState()
                                : _isGridView
                                ? GridView.count(
                                    padding: EdgeInsets.fromLTRB(
                                      LoggitSpacing.lg,
                                      LoggitSpacing.lg,
                                      LoggitSpacing.lg,
                                      LoggitSpacing.lg +
                                          80, // Extra bottom padding for FAB
                                    ),
                                    crossAxisCount: 2,
                                    crossAxisSpacing: LoggitSpacing.lg,
                                    mainAxisSpacing: LoggitSpacing.lg,
                                    childAspectRatio: 1,
                                    children: _filteredNotes
                                        .map(_buildNoteCard)
                                        .toList(),
                                  )
                                : _isCompactView
                                ? ListView.builder(
                                    padding: EdgeInsets.fromLTRB(
                                      LoggitSpacing.md,
                                      LoggitSpacing.md,
                                      LoggitSpacing.md,
                                      LoggitSpacing.md +
                                          80, // Extra bottom padding for FAB
                                    ),
                                    itemCount: _filteredNotes.length,
                                    itemBuilder: (context, index) {
                                      final note = _filteredNotes[index];
                                      return _buildCompactNoteCard(note);
                                    },
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.fromLTRB(
                                      LoggitSpacing.lg,
                                      LoggitSpacing.lg,
                                      LoggitSpacing.lg,
                                      LoggitSpacing.lg +
                                          80, // Extra bottom padding for FAB
                                    ),
                                    itemCount: _filteredNotes.length,
                                    itemBuilder: (context, index) {
                                      final note = _filteredNotes[index];
                                      return _buildMainNoteCard(note);
                                    },
                                  ),
                          ),
                        ],
                      ),
                      // Add a transparent GestureDetector to close overlay when open and clicking outside
                      if (_dropdownHeight > _collapsedHeight)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _animateTo(_collapsedHeight),
                            child: Container(),
                          ),
                        ),
                      // Drag-down overlay (blind) as a single AnimatedContainer
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedContainer(
                          key: _overlayKey,
                          duration: _isDraggingDropdown
                              ? Duration.zero
                              : Duration(milliseconds: 260),
                          curve: Curves.easeInOut,
                          height: _dropdownHeight.clamp(
                            _collapsedHeight,
                            _dynamicExpandedHeight,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Scrollable content
                              SingleChildScrollView(
                                physics: ClampingScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Top row: plus button + main categories (always visible in overlay)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: LoggitSpacing.lg,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          // Main categories (first 5)
                                          Expanded(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: _categories.take(5).map((
                                                  category,
                                                ) {
                                                  final isSelected =
                                                      category ==
                                                      _selectedCategory;
                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 12,
                                                    ),
                                                    child: GestureDetector(
                                                      onTap: () =>
                                                          _onCategoryChanged(
                                                            category,
                                                          ),
                                                      child: Container(
                                                        width: 110,
                                                        height: 44,
                                                        decoration: BoxDecoration(
                                                          color: isSelected
                                                              ? (category ==
                                                                        'All'
                                                                    ? LoggitColors
                                                                          .teal
                                                                          .withOpacity(
                                                                            0.15,
                                                                          )
                                                                    : _categoryColors[category]?.withOpacity(
                                                                            0.15,
                                                                          ) ??
                                                                          Colors
                                                                              .grey[100])
                                                              : Colors
                                                                    .grey[100],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? (category ==
                                                                          'All'
                                                                      ? LoggitColors
                                                                            .teal
                                                                      : _categoryColors[category] ??
                                                                            Colors.grey[300]!)
                                                                : Colors
                                                                      .grey[300]!,
                                                            width: isSelected
                                                                ? 2
                                                                : 1,
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            category,
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? (category ==
                                                                            'All'
                                                                        ? LoggitColors
                                                                              .teal
                                                                        : (category ==
                                                                                  'Quick'
                                                                              ? Colors.black
                                                                              : _categoryColors[category] ??
                                                                                    Colors.black87))
                                                                  : Colors
                                                                        .black87,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Add spacing and a faint divider if expanded and there are extra categories
                                    if (_dropdownHeight > _collapsedHeight &&
                                        _categories.length > 5) ...[
                                      SizedBox(height: 12),
                                      Divider(
                                        thickness: 1,
                                        color: Colors.grey[300],
                                        height: 1,
                                        indent: 0,
                                        endIndent: 0,
                                      ),
                                      SizedBox(height: 12),
                                    ],
                                    // Extra categories as a wrap below when expanded, all buttons same size
                                    if (_dropdownHeight > _collapsedHeight &&
                                        _categories.length > 5)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: LoggitSpacing.lg,
                                          vertical: 8,
                                        ),
                                        child: Wrap(
                                          spacing: 12,
                                          runSpacing: 8,
                                          children: [
                                            ..._categories.skip(5).map((
                                              category,
                                            ) {
                                              final isSelected =
                                                  category == _selectedCategory;
                                              // Calculate expansion progress (0.0 = collapsed, 1.0 = fully expanded)
                                              final double expansionProgress =
                                                  ((_dropdownHeight -
                                                              _collapsedHeight) /
                                                          (_dynamicExpandedHeight -
                                                              _collapsedHeight))
                                                      .clamp(0.0, 1.0);
                                              // Animate each category's appearance based on expansionProgress
                                              return AnimatedBuilder(
                                                animation:
                                                    _dropdownAnimController,
                                                builder: (context, child) {
                                                  final slideY =
                                                      (1.0 -
                                                          expansionProgress) *
                                                      -24; // Slide from above
                                                  final opacity =
                                                      expansionProgress;
                                                  return Opacity(
                                                    opacity: opacity,
                                                    child: Transform.translate(
                                                      offset: Offset(0, slideY),
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _onCategoryChanged(
                                                        category,
                                                      ),
                                                  child: Container(
                                                    width: 90,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? (category == 'All'
                                                                ? LoggitColors
                                                                      .teal
                                                                      .withOpacity(
                                                                        0.15,
                                                                      )
                                                                : _categoryColors[category]
                                                                          ?.withOpacity(
                                                                            0.15,
                                                                          ) ??
                                                                      Colors
                                                                          .grey[100])
                                                          : Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? (category == 'All'
                                                                  ? LoggitColors
                                                                        .teal
                                                                  : _categoryColors[category] ??
                                                                        Colors
                                                                            .grey[300]!)
                                                            : Colors.grey[300]!,
                                                        width: isSelected
                                                            ? 2
                                                            : 1,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        category,
                                                        style: TextStyle(
                                                          color: isSelected
                                                              ? (category ==
                                                                        'All'
                                                                    ? LoggitColors
                                                                          .teal
                                                                    : (category ==
                                                                              'Quick'
                                                                          ? Colors.black
                                                                          : _categoryColors[category] ??
                                                                                Colors.black87))
                                                              : Colors.black87,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    // Message shown when overlay is expanded and there are 5 or fewer categories
                                    if (_dropdownHeight > _collapsedHeight &&
                                        _categories.length <= 5)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16.0,
                                        ),
                                        child: AnimatedBuilder(
                                          animation: _dropdownAnimController,
                                          builder: (context, child) {
                                            // Calculate expansion progress (0.0 = collapsed, 1.0 = fully expanded)
                                            final double expansionProgress =
                                                ((_dropdownHeight -
                                                            _collapsedHeight) /
                                                        (_dynamicExpandedHeight -
                                                            _collapsedHeight))
                                                    .clamp(0.0, 1.0);
                                            final slideY =
                                                (1.0 - expansionProgress) *
                                                -24; // Slide from above
                                            final opacity = expansionProgress;
                                            return Opacity(
                                              opacity: opacity,
                                              child: Transform.translate(
                                                offset: Offset(0, slideY),
                                                child: Center(
                                                  child: Text(
                                                    'Add more categories to see them here!',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    SizedBox(height: 48),
                                  ],
                                ),
                              ),
                              // Handle at the very bottom center, always visible
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 6,
                                child: GestureDetector(
                                  onTap: () {
                                    // Toggle overlay on tap
                                    if (_dropdownHeight >
                                        (_collapsedHeight +
                                                _dynamicExpandedHeight) /
                                            2) {
                                      _animateTo(_collapsedHeight);
                                    } else {
                                      _animateTo(_dynamicExpandedHeight);
                                    }
                                  },
                                  onVerticalDragStart: _onHandleDragStart,
                                  onVerticalDragUpdate: _onHandleDragUpdate,
                                  onVerticalDragEnd: _onHandleDragEnd,
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                    height: 40, // Larger hit area
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 36,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
    return Container(
      margin: EdgeInsets.only(bottom: LoggitSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        color: isDark ? LoggitColors.darkCard : Colors.white,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(minHeight: 80), // Extend card vertically
          decoration: BoxDecoration(
            border: Border.all(color: note.color, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _editNote(note),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(LoggitSpacing.md),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title only
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title.isNotEmpty
                                    ? note.title[0].toUpperCase() +
                                          note.title.substring(1)
                                    : '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
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
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (note.content.isNotEmpty) ...[
                          Text(
                            _convertDeltaToPlainText(note.content),
                            maxLines: 2,
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
                        if (note.isChecklist &&
                            note.checklistItems != null) ...[
                          ...note.checklistItems!
                              .take(3)
                              .map(
                                (item) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: LoggitSpacing.xs,
                                  ),
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
                                                      ? LoggitColors
                                                            .lightGrayDarkMode
                                                      : LoggitColors
                                                            .lighterGraySubtext)
                                                : (isDark
                                                      ? Colors.white
                                                      : LoggitColors
                                                            .darkGrayText),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                        if (note.checklistItems != null &&
                            note.checklistItems!.length > 3) ...[
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
                    ),
                  ),
                  // Footer pinned to bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      children: [
                        // Category and date row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category on the left
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: LoggitSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: note.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: note.color, width: 1),
                              ),
                              child: Text(
                                note.noteCategory,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Tags in the middle - show only one tag in grid view
                            if (note.tags.isNotEmpty) ...[
                              Container(
                                margin: EdgeInsets.only(
                                  right: LoggitSpacing.xs,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: LoggitSpacing.xs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: LoggitColors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: LoggitColors.teal,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  note.tags.first.isNotEmpty
                                      ? note.tags.first[0].toUpperCase()
                                      : '', // Show only the first letter
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            // Date on the right
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainNoteCard(Note note) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    return Container(
      margin: EdgeInsets.only(bottom: LoggitSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        color: isDark ? LoggitColors.darkCard : Colors.white,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(
            minHeight: 150,
          ), // Extend main card vertically
          decoration: BoxDecoration(
            border: Border.all(color: note.color, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _editNote(note),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(LoggitSpacing.md),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title only
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title.isNotEmpty
                                    ? note.title[0].toUpperCase() +
                                          note.title.substring(1)
                                    : '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
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
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (note.content.isNotEmpty) ...[
                          Text(
                            _convertDeltaToPlainText(note.content),
                            maxLines: 2,
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
                        if (note.isChecklist &&
                            note.checklistItems != null) ...[
                          ...note.checklistItems!
                              .take(3)
                              .map(
                                (item) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: LoggitSpacing.xs,
                                  ),
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
                                                      ? LoggitColors
                                                            .lightGrayDarkMode
                                                      : LoggitColors
                                                            .lighterGraySubtext)
                                                : (isDark
                                                      ? Colors.white
                                                      : LoggitColors
                                                            .darkGrayText),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                        if (note.checklistItems != null &&
                            note.checklistItems!.length > 3) ...[
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
                          SizedBox(height: 50), // Extra space for main card
                        ],
                      ],
                    ),
                  ),
                  // Footer pinned to bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      children: [
                        // Add spacing between content and footer
                        SizedBox(height: LoggitSpacing.sm),
                        // Category and date row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category and tags grouped on the left
                            Expanded(
                              child: Wrap(
                                spacing: LoggitSpacing.xs,
                                runSpacing: LoggitSpacing.xs,
                                children: [
                                  // Category chip
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: LoggitSpacing.xs,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: note.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: note.color,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      note.noteCategory,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Tag chips
                                  ...note.tags.map(
                                    (tag) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: LoggitSpacing.xs,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: LoggitColors.teal.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: LoggitColors.teal,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Date on the right
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNoteCard(Note note) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    return Container(
      margin: EdgeInsets.only(bottom: LoggitSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        color: isDark ? LoggitColors.darkCard : Colors.white,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: note.color, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => _editNote(note),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(LoggitSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Title, Category, Date, Menu
                  Row(
                    children: [
                      // Title - truncated to make space for tag
                      Expanded(
                        flex: 2, // Give more space to title
                        child: Text(
                          note.title.isNotEmpty
                              ? note.title[0].toUpperCase() +
                                    note.title.substring(1)
                              : 'Untitled',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDark
                                ? Colors.white
                                : LoggitColors.darkGrayText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: LoggitSpacing.xs),
                      // Tag - show only one tag
                      if (note.tags.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: LoggitSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: LoggitColors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: LoggitColors.teal,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            note.tags.first, // Show only the first tag
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: LoggitSpacing.xs),
                      ],
                      // Category
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: LoggitSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: note.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: note.color, width: 1),
                        ),
                        child: Text(
                          note.noteCategory,
                          style: TextStyle(
                            fontSize: 12,
                            color: note.noteCategory == 'Quick'
                                ? Colors.black
                                : note.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: LoggitSpacing.sm),
                      // Date
                      Text(
                        note.formattedCreatedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? LoggitColors.lightGrayDarkMode
                              : LoggitColors.lighterGraySubtext,
                        ),
                      ),
                      SizedBox(width: LoggitSpacing.xs),
                      // Popup menu
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: isDark
                              ? LoggitColors.lightGrayDarkMode
                              : LoggitColors.lighterGraySubtext,
                        ),
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
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Description row (if content exists)
                  if (note.content.isNotEmpty) ...[
                    SizedBox(height: LoggitSpacing.xs),
                    Text(
                      _convertDeltaToPlainText(note.content),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? LoggitColors.lightGrayDarkMode
                            : LoggitColors.lighterGraySubtext,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  void _onHandleDragStart(DragStartDetails details) {
    setState(() {
      _isDraggingDropdown = true;
    });
    _dropdownAnimController.stop();
  }

  void _onHandleDragUpdate(DragUpdateDetails details) {
    setState(() {
      final newHeight = _dropdownHeight + details.delta.dy;
      if (newHeight >= _collapsedHeight &&
          newHeight <= _dynamicExpandedHeight) {
        _dropdownHeight = newHeight;
      } else if (newHeight < _collapsedHeight) {
        _dropdownHeight = _collapsedHeight;
      } else {
        _dropdownHeight = _dynamicExpandedHeight;
      }
    });
  }

  void _onHandleDragEnd(DragEndDetails details) {
    setState(() {
      _isDraggingDropdown = false;
    });
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity > 200) {
      // Flick down - open
      _animateTo(_dynamicExpandedHeight);
    } else if (velocity < -200) {
      // Flick up - close
      _animateTo(_collapsedHeight);
    } else {
      // Snap to nearest
      if (_dropdownHeight > (_collapsedHeight + _dynamicExpandedHeight) / 2) {
        _animateTo(_dynamicExpandedHeight);
      } else {
        _animateTo(_collapsedHeight);
      }
    }
    // Do NOT set _dropdownHeight directly here; always use _animateTo
  }
}
