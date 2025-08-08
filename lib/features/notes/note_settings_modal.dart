import 'package:flutter/material.dart';
import '../../features/notes/note_model.dart';
import '../../shared/design/color_guide.dart';

class NoteSettingsModal extends StatefulWidget {
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategoryChanged;
  final List<String> tags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final Color selectedColor;
  final List<Color> colorOptions;
  final ValueChanged<Color> onColorSelected;
  final Future<Map<String, dynamic>?> Function()? onAddCategory;
  final Future<Map<String, dynamic>?> Function(String, Color)? onEditCategory;
  final Map<String, Color>
  categoryColors; // Map of category names to their colors

  const NoteSettingsModal({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.selectedColor,
    required this.colorOptions,
    required this.onColorSelected,
    this.onAddCategory,
    this.onEditCategory,
    required this.categoryColors, // Map of category names to their colors
  });

  @override
  State<NoteSettingsModal> createState() => _NoteSettingsModalState();
}

class _NoteSettingsModalState extends State<NoteSettingsModal> {
  late String _internalSelectedCategory;
  late List<String> _internalCategories;
  late ScrollController _categoryScrollController;
  String? _categoryToFocus; // Track which category to focus on

  // Internal tag state
  late List<String> _internalTags;
  final TextEditingController tagController = TextEditingController();
  final checklistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _internalSelectedCategory = widget.selectedCategory;
    _internalCategories = List<String>.from(widget.categories);
    _internalTags = List<String>.from(widget.tags);
    _categoryScrollController = ScrollController();

    // Focus on the selected category when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_internalSelectedCategory != 'Quick') {
        _scrollToCategory(_internalSelectedCategory);
      }
    });
  }

  @override
  void didUpdateWidget(NoteSettingsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal categories when widget categories change
    if (widget.categories != oldWidget.categories) {
      setState(() {
        _internalCategories = List<String>.from(widget.categories);
      });
    }
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String categoryName) {
    // Calculate the position to scroll to based on category index
    final categoryIndex = _internalCategories.indexOf(categoryName);
    if (categoryIndex >= 0) {
      // Each category takes approximately 98px (90px width + 8px padding)
      final scrollPosition = categoryIndex * 98.0;
      _categoryScrollController.animateTo(
        scrollPosition,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _focusOnCategory(String categoryName) {
    // Set the category as selected and scroll to it
    setState(() {
      _internalSelectedCategory = categoryName;
    });
    widget.onCategoryChanged(categoryName);
    // Scroll to the category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCategory(categoryName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Category
                Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (widget.onAddCategory != null) {
                          final result = await widget.onAddCategory!();
                          if (result != null && result['name'] != null) {
                            setState(() {
                              if (!_internalCategories.contains(
                                result['name'],
                              )) {
                                _internalCategories.add(result['name']);
                              }
                            });
                            // Focus on the newly created category
                            _focusOnCategory(result['name']);
                          }
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(Icons.add, color: Colors.black87, size: 22),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _categoryScrollController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _internalCategories.map((cat) {
                            final isSelected = cat == _internalSelectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _internalSelectedCategory = cat;
                                  });
                                  widget.onCategoryChanged(cat);
                                },
                                onLongPress: () async {
                                  if (widget.onEditCategory != null &&
                                      cat != 'Quick') {
                                    final result = await widget.onEditCategory!(
                                      cat,
                                      Colors.yellow,
                                    ); // TODO: Get actual color
                                    if (result != null) {
                                      if (result['action'] == 'save') {
                                        // Update category in internal list
                                        setState(() {
                                          final idx = _internalCategories
                                              .indexOf(cat);
                                          if (idx >= 0) {
                                            _internalCategories[idx] =
                                                result['name'];
                                            if (_internalSelectedCategory ==
                                                cat) {
                                              _internalSelectedCategory =
                                                  result['name'];
                                            }
                                          }
                                        });
                                        // Focus on the edited category
                                        _focusOnCategory(result['name']);
                                      } else if (result['action'] == 'delete') {
                                        // Remove category from internal list
                                        setState(() {
                                          _internalCategories.remove(cat);
                                          if (_internalSelectedCategory ==
                                              cat) {
                                            _internalSelectedCategory = 'Quick';
                                          }
                                        });
                                        widget.onCategoryChanged('Quick');
                                      }
                                    }
                                  }
                                },
                                child: Container(
                                  width: 90,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color:
                                        (widget.categoryColors[cat] ??
                                                Colors.grey)
                                            .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? (widget.categoryColors[cat] ??
                                                    Colors.grey)
                                                .withOpacity(0.8)
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: Colors.black,
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
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tags
                Text(
                  'Tags',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: InputDecoration(hintText: 'Add tag'),
                        onSubmitted: (tag) {
                          final trimmed = tag.trim();
                          if (trimmed.isNotEmpty &&
                              !_internalTags.contains(trimmed)) {
                            setState(() {
                              _internalTags.add(trimmed);
                            });
                            widget.onAddTag(trimmed);
                            tagController.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        final tag = tagController.text.trim();
                        if (tag.isNotEmpty && !_internalTags.contains(tag)) {
                          setState(() {
                            _internalTags.add(tag);
                          });
                          widget.onAddTag(tag);
                          tagController.clear();
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: LoggitColors.teal,
                        shape: CircleBorder(),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: _internalTags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setState(() {
                              _internalTags.remove(tag);
                            });
                            widget.onRemoveTag(tag);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                // Export
                Text(
                  'Export',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Export as text
                          Navigator.of(context).pop('export_text');
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description,
                                size: 18,
                                color: Colors.blue[700],
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Export as Text',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Export as PDF
                          Navigator.of(context).pop('export_pdf');
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                size: 18,
                                color: Colors.red[700],
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Export as PDF',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Share via email
                    Navigator.of(context).pop('share_email');
                  },
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, size: 18, color: Colors.green[700]),
                        SizedBox(width: 8),
                        Text(
                          'Share via Email',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
