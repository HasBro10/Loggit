import 'package:flutter/material.dart';
import '../../features/notes/note_model.dart';
import '../../shared/design/color_guide.dart';

class NoteSettingsModal extends StatefulWidget {
  final NoteType selectedType;
  final ValueChanged<NoteType> onTypeChanged;
  final List<String> checklistItems;
  final ValueChanged<String> onAddChecklistItem;
  final ValueChanged<int> onRemoveChecklistItem;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategoryChanged;
  final List<String> tags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final Color selectedColor;
  final List<Color> colorOptions;
  final ValueChanged<Color> onColorSelected;
  final NotePriority selectedPriority;
  final ValueChanged<NotePriority> onPriorityChanged;
  final NoteStatus selectedStatus;
  final ValueChanged<NoteStatus> onStatusChanged;
  final Future<Map<String, dynamic>?> Function()? onAddCategory;
  final Future<Map<String, dynamic>?> Function(String, Color)? onEditCategory;

  const NoteSettingsModal({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.checklistItems,
    required this.onAddChecklistItem,
    required this.onRemoveChecklistItem,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.selectedColor,
    required this.colorOptions,
    required this.onColorSelected,
    required this.selectedPriority,
    required this.onPriorityChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.onAddCategory,
    this.onEditCategory,
  }) : super(key: key);

  @override
  State<NoteSettingsModal> createState() => _NoteSettingsModalState();
}

class _NoteSettingsModalState extends State<NoteSettingsModal> {
  late NoteType _internalSelectedType;
  late List<String> _internalCategories;
  late String _internalSelectedCategory;

  @override
  void initState() {
    super.initState();
    _internalSelectedType = widget.selectedType;
    _internalCategories = List<String>.from(widget.categories);
    _internalSelectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final tagController = TextEditingController();
    final checklistController = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note Type
                Text(
                  'Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: NoteType.values.map((type) {
                      final isSelected = type == _internalSelectedType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(_getTypeLabel(type)),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _internalSelectedType = type;
                            });
                            widget.onTypeChanged(type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_internalSelectedType == NoteType.checklist) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Checklist Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: checklistController,
                          decoration: InputDecoration(
                            hintText: 'Add checklist item',
                          ),
                          onSubmitted: widget.onAddChecklistItem,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () =>
                            widget.onAddChecklistItem(checklistController.text),
                      ),
                    ],
                  ),
                  ...widget.checklistItems.asMap().entries.map(
                    (entry) => ListTile(
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () =>
                            widget.onRemoveChecklistItem(entry.key),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
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
                              _internalSelectedCategory = result['name'];
                            });
                            widget.onCategoryChanged(result['name']);
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
                                        widget.onCategoryChanged(
                                          result['name'],
                                        );
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
                                      cat,
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                        onSubmitted: widget.onAddTag,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => widget.onAddTag(tagController.text),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: widget.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => widget.onRemoveTag(tag),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                // Priority
                Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: NotePriority.values.map((priority) {
                    final isSelected = priority == widget.selectedPriority;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(_getPriorityLabel(priority)),
                        selected: isSelected,
                        onSelected: (_) => widget.onPriorityChanged(priority),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Status
                Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: NoteStatus.values.map((status) {
                    final isSelected = status == widget.selectedStatus;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(_getStatusLabel(status)),
                        selected: isSelected,
                        onSelected: (_) => widget.onStatusChanged(status),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
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
