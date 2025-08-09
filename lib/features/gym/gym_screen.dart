import 'package:flutter/material.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/utils/responsive.dart';
import '../../shared/design/widgets/header.dart';
import '../../shared/design/spacing.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _WorkoutsTab(),
      const _TemplatesTab(),
      const _HistoryTab(),
      const _AnalyticsTab(),
      const _RunningTab(),
    ];

    return Scaffold(
      backgroundColor: LoggitColors.lightGray,
      appBar: const LoggitHeader(title: 'Gym'),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Running',
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'fab_mic',
          onPressed: () {},
          tooltip: 'Voice input',
          backgroundColor: LoggitColors.teal,
          child: const Icon(Icons.mic, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'fab_scan',
          onPressed: () {},
          tooltip: 'Scan machine',
          backgroundColor: LoggitColors.tealDark,
          child: const Icon(Icons.center_focus_strong, color: Colors.white),
        ),
      ],
    );
  }
}

class _WorkoutsTab extends StatelessWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context) {
    final isWide =
        Responsive.isTablet(context) || Responsive.isDesktop(context);
    final tiles = <String>["Bench", "Back", "Legs", "Shoulders", "Arms"];

    return Padding(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      child: GridView.count(
        crossAxisCount: isWide ? 4 : 2,
        mainAxisSpacing: LoggitSpacing.md,
        crossAxisSpacing: LoggitSpacing.md,
        children: [
          ...tiles.map((name) => _WorkoutTile(name: name)),
          _WorkoutTile(name: 'New workout', isAdd: true),
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final String name;
  final bool isAdd;
  const _WorkoutTile({required this.name, this.isAdd = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isAdd) {
          // UI-only: future add workflow
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create workout (placeholder)')),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(workoutName: name),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: LoggitColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LoggitColors.divider),
          boxShadow: const [
            BoxShadow(
              color: LoggitColors.softShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAdd ? Icons.add : Icons.grid_view,
              size: 32,
              color: LoggitColors.lighterGraySubtext,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: LoggitColors.darkGrayText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutName;
  const WorkoutDetailScreen({super.key, required this.workoutName});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final Map<String, bool> _expandedByMonth = {
    'August 2025': true,
    'July 2025': false,
  };
  String _timeframe = 'Recent';
  bool _onlyPRs = false;
  bool _hasActiveSession = true; // UI-only demo
  bool _sessionExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoggitColors.lightGray,
      appBar: LoggitHeader(title: widget.workoutName, showBack: true),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSummaryBar()),
          SliverToBoxAdapter(child: _buildFilters()),
          if (_hasActiveSession)
            SliverToBoxAdapter(child: _buildTodaySessionCard()),
          ..._buildMonthSection(
            'August 2025',
            sessions: [
              _SessionData(date: 'Aug 08', volume: '9,200 kg', pr: true),
              _SessionData(date: 'Aug 02', volume: '8,600 kg', pr: false),
              _SessionData(date: 'Aug 01', volume: '8,100 kg', pr: false),
            ],
          ),
          ..._buildMonthSection(
            'July 2025',
            sessions: [
              _SessionData(date: 'Jul 28', volume: '7,800 kg', pr: false),
              _SessionData(date: 'Jul 21', volume: '7,500 kg', pr: false),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LoggitColors.tealDark,
        foregroundColor: Colors.white,
        onPressed: () => _openAddLogModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Add log'),
      ),
    );
  }

  Widget _buildTodaySessionCard() {
    final templateName = '${widget.workoutName} – Heavy';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LoggitSpacing.lg,
        LoggitSpacing.lg,
        LoggitSpacing.lg,
        LoggitSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: LoggitColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LoggitColors.divider),
          boxShadow: const [
            BoxShadow(
              color: LoggitColors.softShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: LoggitSpacing.md,
                vertical: 4,
              ),
              title: Row(
                children: [
                  const Text(
                    "Today's session",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: LoggitColors.darkGrayText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LoggitColors.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LoggitColors.divider),
                    ),
                    child: Text(
                      templateName,
                      style: const TextStyle(
                        color: LoggitColors.lighterGraySubtext,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text(
                'Started 18:10',
                style: TextStyle(color: LoggitColors.lighterGraySubtext),
              ),
              trailing: IconButton(
                icon: Icon(
                  _sessionExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () =>
                    setState(() => _sessionExpanded = !_sessionExpanded),
              ),
            ),
            if (_sessionExpanded)
              const Divider(height: 1, color: LoggitColors.divider),
            if (_sessionExpanded)
              Padding(
                padding: EdgeInsets.all(LoggitSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current exercise (compact row, no large media)
                    const Text(
                      'Current exercise',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: LoggitColors.darkGrayText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(LoggitSpacing.md),
                      decoration: BoxDecoration(
                        color: LoggitColors.lightGray,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LoggitColors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: LoggitColors.pureWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: LoggitColors.divider),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: LoggitColors.lighterGraySubtext,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.workoutName} Exercise 1',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: LoggitColors.darkGrayText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '3 sets • 8-10 reps',
                                  style: TextStyle(
                                    color: LoggitColors.lighterGraySubtext,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openPreview(
                              context,
                              '${widget.workoutName} Exercise 1',
                            ),
                            child: const Text('Preview'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Queue
                    const Text(
                      'Up next',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: LoggitColors.darkGrayText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _QueueChip(label: 'Incline DB Press'),
                        _QueueChip(label: 'Cable Fly'),
                        _QueueChip(label: 'Triceps Pushdown'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Controls
                    Row(
                      children: [
                        const _RestTimerChip(),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Add exercise'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          child: const Text('End/Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openPreview(BuildContext context, String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: EdgeInsets.all(LoggitSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: LoggitColors.darkGrayText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: LoggitColors.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LoggitColors.divider),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: LoggitColors.lighterGraySubtext,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'How to perform: (placeholder)\nKeep core tight, control the eccentric, full ROM.',
                  style: TextStyle(color: LoggitColors.lighterGraySubtext),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LoggitColors.tealDark,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).maybePop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Template applied (placeholder)'),
                        ),
                      );
                    },
                    child: const Text('Use template'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryBar() {
    return Padding(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      child: Row(
        children: [
          _summaryMetric('Last session', 'Aug 08'),
          const SizedBox(width: 8),
          _summaryMetric('Best set', 'PR'),
          const SizedBox(width: 8),
          _summaryMetric('4‑wk volume', '33.2k'),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(LoggitSpacing.md),
        decoration: BoxDecoration(
          color: LoggitColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LoggitColors.divider),
          boxShadow: const [
            BoxShadow(
              color: LoggitColors.softShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: LoggitColors.lighterGraySubtext),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: LoggitColors.darkGrayText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, {bool selected = false}) => ChoiceChip(
      label: Text(label),
      selected: _timeframe == label,
      onSelected: (_) => setState(() => _timeframe = label),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        LoggitSpacing.lg,
        0,
        LoggitSpacing.lg,
        LoggitSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('Recent'),
                const SizedBox(width: 8),
                chip('4 weeks'),
                const SizedBox(width: 8),
                chip('3 months'),
                const SizedBox(width: 8),
                chip('Year'),
                const SizedBox(width: 8),
                chip('All'),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Only PRs'),
                  selected: _onlyPRs,
                  onSelected: (v) => setState(() => _onlyPRs = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Search sessions (placeholder)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: LoggitColors.lightGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthSection(
    String month, {
    required List<_SessionData> sessions,
  }) {
    final expanded = _expandedByMonth[month] ?? false;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: LoggitSpacing.lg),
          child: InkWell(
            onTap: () => setState(() => _expandedByMonth[month] = !expanded),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: LoggitSpacing.md),
              child: Row(
                children: [
                  Text(
                    month,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: LoggitColors.darkGrayText,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: LoggitColors.lighterGraySubtext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (expanded)
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: LoggitSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final s = sessions[index];
              return Padding(
                padding: EdgeInsets.only(bottom: LoggitSpacing.sm),
                child: _SessionCard(data: s),
              );
            }, childCount: sessions.length),
          ),
        ),
      if (expanded)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              LoggitSpacing.lg,
              0,
              LoggitSpacing.lg,
              LoggitSpacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {},
                child: const Text('Show more'),
              ),
            ),
          ),
        ),
    ];
  }

  void _openAddLogModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Container(
            decoration: const BoxDecoration(
              color: LoggitColors.pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.fromLTRB(
              LoggitSpacing.lg,
              LoggitSpacing.lg,
              LoggitSpacing.lg,
              LoggitSpacing.lg,
            ),
            child: StatefulBuilder(
              builder: (ctx, setState) {
                bool isFavOnly = false;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Add log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: LoggitColors.darkGrayText,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => isFavOnly = !isFavOnly),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: LoggitColors.lightGray,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: LoggitColors.divider),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isFavOnly ? Icons.star : Icons.star_border,
                                  color: LoggitColors.tealDark,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Favorites',
                                  style: TextStyle(
                                    color: LoggitColors.darkGrayText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Search templates or exercises (placeholder)',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: LoggitColors.lightGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: const [
                          _FilterPill(label: 'This workout'),
                          SizedBox(width: 8),
                          _FilterPill(label: 'All'),
                          SizedBox(width: 8),
                          _FilterPill(label: 'Barbell'),
                          SizedBox(width: 8),
                          _FilterPill(label: 'Dumbbell'),
                          SizedBox(width: 8),
                          _FilterPill(label: 'Machine'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suggested for ${widget.workoutName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: LoggitColors.darkGrayText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _TemplatePickerList(
                              workoutName: widget.workoutName,
                              suggestedOnly: true,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Browse templates',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: LoggitColors.darkGrayText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const _TemplatePickerList(
                              workoutName: null,
                              suggestedOnly: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  const _FilterPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LoggitColors.lightGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LoggitColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(color: LoggitColors.lighterGraySubtext),
      ),
    );
  }
}

class _SessionData {
  final String date;
  final String volume;
  final bool pr;
  const _SessionData({
    required this.date,
    required this.volume,
    this.pr = false,
  });
}

class _SessionCard extends StatefulWidget {
  final _SessionData data;
  const _SessionCard({required this.data});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Container(
      decoration: BoxDecoration(
        color: LoggitColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoggitColors.divider),
        boxShadow: const [
          BoxShadow(
            color: LoggitColors.softShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: LoggitSpacing.md),
            title: Row(
              children: [
                Text(
                  d.date,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: LoggitColors.darkGrayText,
                  ),
                ),
                const SizedBox(width: 8),
                if (d.pr)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LoggitColors.teal.withOpacity(0.1),
                      border: Border.all(
                        color: LoggitColors.teal.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PR',
                      style: TextStyle(color: LoggitColors.tealDark),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              'Volume: ${d.volume}',
              style: const TextStyle(color: LoggitColors.lighterGraySubtext),
            ),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded) const Divider(height: 1, color: LoggitColors.divider),
          if (_expanded)
            Padding(
              padding: EdgeInsets.all(LoggitSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sets',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: LoggitColors.darkGrayText,
                    ),
                  ),
                  SizedBox(height: 8),
                  _SetRowReadOnly(
                    number: 1,
                    reps: '10',
                    weight: '60 kg',
                    rpe: '8',
                  ),
                  SizedBox(height: 6),
                  _SetRowReadOnly(
                    number: 2,
                    reps: '8',
                    weight: '65 kg',
                    rpe: '8.5',
                  ),
                  SizedBox(height: 6),
                  _SetRowReadOnly(
                    number: 3,
                    reps: '6',
                    weight: '70 kg',
                    rpe: '9',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SetRowReadOnly extends StatelessWidget {
  final int number;
  final String reps;
  final String weight;
  final String rpe;
  const _SetRowReadOnly({
    required this.number,
    required this.reps,
    required this.weight,
    required this.rpe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LoggitColors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$number',
            style: const TextStyle(color: LoggitColors.darkGrayText),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              _pill('Reps: $reps'),
              _pill('Weight: $weight'),
              _pill('RPE: $rpe'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LoggitColors.lightGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LoggitColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(color: LoggitColors.lighterGraySubtext),
      ),
    );
  }
}

class _TemplatePickerList extends StatelessWidget {
  final String? workoutName;
  final bool suggestedOnly;
  const _TemplatePickerList({
    required this.workoutName,
    required this.suggestedOnly,
  });

  void _openPreview(BuildContext context, String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: EdgeInsets.all(LoggitSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: LoggitColors.darkGrayText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: LoggitColors.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LoggitColors.divider),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: LoggitColors.lighterGraySubtext,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'How to perform: (placeholder)\nKeep core tight, control the eccentric, full ROM.',
                  style: TextStyle(color: LoggitColors.lighterGraySubtext),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LoggitColors.tealDark,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).maybePop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected template: $name')),
                      );
                    },
                    child: const Text('Use template'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggested = workoutName == null
        ? const <String>[]
        : <String>[
            '$workoutName – Standard',
            '$workoutName – Heavy',
            '$workoutName – Hypertrophy',
          ];
    final browse = const ['Push', 'Pull', 'Legs', 'Upper Body', 'Lower Body'];
    final items = suggestedOnly ? suggested : browse;

    return Column(
      children: [
        ...items.map(
          (name) => InkWell(
            onTap: () => _openPreview(context, name),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: EdgeInsets.only(bottom: LoggitSpacing.sm),
              padding: EdgeInsets.all(LoggitSpacing.md),
              decoration: BoxDecoration(
                color: LoggitColors.pureWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LoggitColors.divider),
                boxShadow: const [
                  BoxShadow(
                    color: LoggitColors.softShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.view_list_outlined,
                    color: LoggitColors.lighterGraySubtext,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: LoggitColors.darkGrayText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LoggitColors.tealDark,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected template: $name')),
                      );
                    },
                    child: const Text('Select'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseCardPlaceholder extends StatelessWidget {
  final String title;
  final double mediaMaxHeight;

  const _ExerciseCardPlaceholder({
    required this.title,
    required this.mediaMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: LoggitSpacing.md),
      decoration: BoxDecoration(
        color: LoggitColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoggitColors.divider),
        boxShadow: const [
          BoxShadow(
            color: LoggitColors.softShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media box placeholder (1:1)
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              constraints: BoxConstraints(maxHeight: mediaMaxHeight),
              decoration: const BoxDecoration(
                color: LoggitColors.lightGray,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: LoggitColors.lighterGraySubtext,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add media',
                    style: TextStyle(color: LoggitColors.lighterGraySubtext),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LoggitSpacing.md,
              vertical: LoggitSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: LoggitColors.darkGrayText,
                    ),
                  ),
                ),
                const _RestTimerChip(),
              ],
            ),
          ),
          const Divider(height: 1, color: LoggitColors.divider),
          Padding(
            padding: EdgeInsets.all(LoggitSpacing.md),
            child: Column(
              children: const [
                _SetRowPlaceholder(index: 1),
                SizedBox(height: 8),
                _SetRowPlaceholder(index: 2),
                SizedBox(height: 8),
                _SetRowPlaceholder(index: 3),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              LoggitSpacing.md,
              0,
              LoggitSpacing.md,
              LoggitSpacing.md,
            ),
            child: TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Notes (placeholder)',
                prefixIcon: const Icon(Icons.edit_note_outlined),
                filled: true,
                fillColor: LoggitColors.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRowPlaceholder extends StatelessWidget {
  final int index;
  const _SetRowPlaceholder({required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LoggitColors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$index',
            style: const TextStyle(color: LoggitColors.darkGrayText),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [_pill('Reps'), _pill('Weight (kg)'), _pill('RPE')],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.more_horiz,
            color: LoggitColors.lighterGraySubtext,
          ),
        ),
      ],
    );
  }

  Widget _pill(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LoggitColors.lightGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LoggitColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(color: LoggitColors.lighterGraySubtext),
      ),
    );
  }
}

class _RestTimerChip extends StatelessWidget {
  const _RestTimerChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LoggitColors.teal.withOpacity(0.08),
        border: Border.all(color: LoggitColors.teal.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.timer_outlined, size: 16, color: LoggitColors.tealDark),
          SizedBox(width: 6),
          Text('Rest 90s', style: TextStyle(color: LoggitColors.tealDark)),
        ],
      ),
    );
  }
}

class _QueueChip extends StatelessWidget {
  final String label;
  const _QueueChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LoggitColors.lightGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LoggitColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(color: LoggitColors.darkGrayText),
      ),
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      children: [
        _templateCard('Push'),
        _templateCard('Pull'),
        _templateCard('Legs'),
        _templateCard('Upper Body'),
        _templateCard('Lower Body'),
      ],
    );
  }

  Widget _templateCard(String name) {
    return Container(
      margin: EdgeInsets.only(bottom: LoggitSpacing.md),
      padding: EdgeInsets.all(LoggitSpacing.md),
      decoration: BoxDecoration(
        color: LoggitColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoggitColors.divider),
        boxShadow: const [
          BoxShadow(
            color: LoggitColors.softShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: LoggitColors.lightGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LoggitColors.divider),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: LoggitColors.lighterGraySubtext,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Template',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: LoggitColors.darkGrayText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LoggitColors.tealDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () {},
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      children: [
        _historyCard('Legs Day', 'Today'),
        _historyCard('Push Day', '2d ago'),
        _historyCard('Pull Day', '1w ago'),
      ],
    );
  }

  Widget _historyCard(String title, String when) {
    return Container(
      margin: EdgeInsets.only(bottom: LoggitSpacing.md),
      padding: EdgeInsets.all(LoggitSpacing.md),
      decoration: BoxDecoration(
        color: LoggitColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoggitColors.divider),
        boxShadow: const [
          BoxShadow(
            color: LoggitColors.softShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.event_note_outlined, color: LoggitColors.indigo),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Workout title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: LoggitColors.darkGrayText,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: LoggitColors.lighterGraySubtext),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      children: [
        _filterRow(),
        const SizedBox(height: 12),
        _analyticsCard('PRs', 'Heaviest lifts and best reps (placeholder)'),
        _analyticsCard('Consistency', 'Weeks trained, streaks (placeholder)'),
        _analyticsCard('Volume', 'Per exercise/muscle over time (placeholder)'),
        _analyticsCard('Trends', 'This month vs last month (placeholder)'),
      ],
    );
  }

  Widget _filterRow() {
    Widget pill(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LoggitColors.lightGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LoggitColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(color: LoggitColors.lighterGraySubtext),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          pill('This month'),
          const SizedBox(width: 8),
          pill('Chest'),
          const SizedBox(width: 8),
          pill('Bench Press'),
        ],
      ),
    );
  }

  Widget _analyticsCard(String title, String subtitle) {
    return Container(
      margin: EdgeInsets.only(bottom: LoggitSpacing.md),
      padding: EdgeInsets.all(LoggitSpacing.md),
      decoration: BoxDecoration(
        color: LoggitColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoggitColors.divider),
        boxShadow: const [
          BoxShadow(
            color: LoggitColors.softShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LoggitColors.darkGrayText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: LoggitColors.lighterGraySubtext),
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: LoggitColors.lightGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LoggitColors.divider),
            ),
            child: const Center(
              child: Text(
                'Chart placeholder',
                style: TextStyle(color: LoggitColors.lighterGraySubtext),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningTab extends StatelessWidget {
  const _RunningTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(LoggitSpacing.lg),
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: LoggitColors.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LoggitColors.divider),
            boxShadow: const [
              BoxShadow(
                color: LoggitColors.softShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Map placeholder',
              style: TextStyle(color: LoggitColors.lighterGraySubtext),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _metric('Distance', '0.00 km'),
            _metric('Pace', '0:00 /km'),
            _metric('Time', '00:00'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoggitColors.tealDark,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text('Start'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Pause'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(onPressed: () {}, child: const Text('End')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _splitsCard(),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(LoggitSpacing.md),
        decoration: BoxDecoration(
          color: LoggitColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LoggitColors.divider),
          boxShadow: const [
            BoxShadow(
              color: LoggitColors.softShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: LoggitColors.lighterGraySubtext),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: LoggitColors.darkGrayText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _splitsCard() {
    return Container(
      padding: EdgeInsets.all(LoggitSpacing.md),
      decoration: BoxDecoration(
        color: LoggitColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoggitColors.divider),
        boxShadow: const [
          BoxShadow(
            color: LoggitColors.softShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Splits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LoggitColors.darkGrayText,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            3,
            (i) => _splitRow(i + 1),
          ).expand((w) => [w, const SizedBox(height: 6)]),
        ],
      ),
    );
  }

  Widget _splitRow(int km) {
    return Row(
      children: const [
        Text('1 km', style: TextStyle(color: LoggitColors.darkGrayText)),
        SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: 0.0,
            minHeight: 8,
            backgroundColor: LoggitColors.lightGray,
            color: LoggitColors.indigo,
          ),
        ),
        SizedBox(width: 12),
        Text('0:00', style: TextStyle(color: LoggitColors.lighterGraySubtext)),
      ],
    );
  }
}
