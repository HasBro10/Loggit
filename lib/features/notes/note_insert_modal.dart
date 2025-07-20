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
  InsertTab _selectedTab = InsertTab.camera;

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

          // Header
          Padding(
            padding: EdgeInsets.all(LoggitSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Insert',
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

          // Tab bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: LoggitSpacing.lg),
            decoration: BoxDecoration(
              color: LoggitColors.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: LoggitColors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: LoggitColors.darkGrayText,
              tabs: const [
                Tab(icon: Icon(Icons.camera_alt, size: 20), text: 'Camera'),
                Tab(icon: Icon(Icons.mic, size: 20), text: 'Voice'),
                Tab(icon: Icon(Icons.add, size: 20), text: 'Insert'),
              ],
            ),
          ),

          // Tab content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCameraTab(),
                _buildVoiceTab(),
                _buildInsertTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraTab() {
    return Padding(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      child: Column(
        children: [
          // Camera preview placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: LoggitColors.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: LoggitColors.lighterGraySubtext,
                ),
                SizedBox(height: LoggitSpacing.sm),
                Text(
                  'Camera Preview',
                  style: TextStyle(
                    color: LoggitColors.lighterGraySubtext,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: LoggitSpacing.lg),

          // Camera buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleInsert('photo'),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LoggitColors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: LoggitSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: LoggitSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleInsert('gallery'),
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: LoggitColors.teal,
                    padding: EdgeInsets.symmetric(vertical: LoggitSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: LoggitColors.teal),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceTab() {
    return Padding(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      child: Column(
        children: [
          // Voice recording visualization
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: LoggitColors.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic,
                  size: 48,
                  color: LoggitColors.lighterGraySubtext,
                ),
                SizedBox(height: LoggitSpacing.sm),
                Text(
                  'Tap to start recording',
                  style: TextStyle(
                    color: LoggitColors.lighterGraySubtext,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: LoggitSpacing.lg),

          // Recording controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleInsert('voice_record'),
                icon: Icon(Icons.mic),
                label: Text('Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoggitColors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: LoggitSpacing.lg,
                    vertical: LoggitSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsertTab() {
    return Padding(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      child: Column(
        children: [
          // Insert options grid
          GridView.count(
            shrinkWrap: true,
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
        ],
      ),
    );
  }

  Widget _buildInsertOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: LoggitColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: LoggitColors.darkGrayText),
            SizedBox(height: LoggitSpacing.xs),
            Text(
              title,
              style: TextStyle(
                color: LoggitColors.darkGrayText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
