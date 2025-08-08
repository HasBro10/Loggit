import 'package:flutter/material.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';

enum InsertTab { camera, voice, insert }

class NoteInsertModal extends StatefulWidget {
  final Function(String type, {dynamic data})? onInsert;

  const NoteInsertModal({super.key, this.onInsert});

  @override
  State<NoteInsertModal> createState() => _NoteInsertModalState();
}

class _NoteInsertModalState extends State<NoteInsertModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InsertTab _selectedTab = InsertTab.camera;
  int _selectedTopButton = -1; // -1 means none selected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleInsert(String type, {dynamic data}) {
    widget.onInsert?.call(type, data: data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        maxWidth: 400,
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

          // Remove header row (Insert title and X button), but keep the space
          SizedBox(height: LoggitSpacing.lg + 40),

          // Top action buttons (Camera, Voice, Pen)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LoggitSpacing.lg,
              vertical: LoggitSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTopActionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    selected: _selectedTopButton == 0,
                    onTap: () async {
                      setState(() => _selectedTopButton = 0);
                      await _handleCameraInsert();
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTopActionButton(
                    icon: Icons.mic,
                    label: 'Voice',
                    selected: _selectedTopButton == 1,
                    onTap: () async {
                      setState(() => _selectedTopButton = 1);
                      await _handleVoiceInsert();
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTopActionButton(
                    icon: Icons.edit,
                    label: 'Pen',
                    selected: _selectedTopButton == 2,
                    onTap: () async {
                      setState(() => _selectedTopButton = 2);
                      await _handlePenInsert();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main content: always show the insert options grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                LoggitSpacing.lg,
                LoggitSpacing.lg,
                LoggitSpacing.lg,
                2.0, // further reduce bottom padding
              ),
              child: SingleChildScrollView(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: LoggitSpacing.md,
                  mainAxisSpacing: LoggitSpacing.md,
                  childAspectRatio: 1.5,
                  children: [
                    _buildInsertOption(
                      icon: Icons.image,
                      title: 'Image',
                      onTap: () => _handleInsert('image'),
                    ),
                    _buildInsertOption(
                      icon: Icons.attach_file,
                      title: 'File',
                      onTap: () => _handleInsert('file'),
                    ),
                    _buildInsertOption(
                      icon: Icons.audiotrack,
                      title: 'Audio',
                      onTap: () => _handleInsert('audio'),
                    ),
                    _buildInsertOption(
                      icon: Icons.link,
                      title: 'Link',
                      onTap: () => _handleInsert('link'),
                    ),
                    _buildInsertOption(
                      icon: Icons.table_chart,
                      title: 'Table',
                      onTap: () => _handleInsert('table'),
                    ),
                    _buildInsertOption(
                      icon: Icons.brush,
                      title: 'Drawing',
                      onTap: () => _handleInsert('drawing'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCameraInsert() async {
    // TODO: Implement camera/gallery picker logic here
    // For now, just call the onInsert callback with 'photo' or 'gallery' as needed
    // Example: widget.onInsert?.call('photo');
    // After picking, close the modal
    widget.onInsert?.call('photo');
    Navigator.of(context).pop();
  }

  Future<void> _handleVoiceInsert() async {
    // TODO: Implement voice recording logic here
    // For now, just call the onInsert callback with 'voice_record'
    widget.onInsert?.call('voice_record');
    Navigator.of(context).pop();
  }

  Future<void> _handlePenInsert() async {
    // TODO: Implement drawing/scribble logic here
    widget.onInsert?.call('drawing');
    Navigator.of(context).pop();
  }

  Widget _buildInsertOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: LoggitColors.teal.withOpacity(0.08),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: LoggitColors.teal),
            SizedBox(height: LoggitSpacing.sm),
            Text(
              title,
              style: TextStyle(
                color: LoggitColors.darkGrayText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    // Make the top buttons slightly larger than before
    final double buttonWidth =
        (400 - (LoggitSpacing.lg * 2) - LoggitSpacing.md) / 2 + 16;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: buttonWidth,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? LoggitColors.teal : Colors.transparent,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showNoteInsertModal(
  BuildContext context, {
  Function(String type, {dynamic data})? onInsert,
}) async {
  return await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black.withOpacity(0.5),
    builder: (context) => NoteInsertModal(onInsert: onInsert),
  );
}
