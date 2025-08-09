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
  final bool _hasActiveSession = true; // UI-only demo
  bool _sessionExpanded = true;
  final ScrollController _scrollController = ScrollController();
  String? _activeTemplateName;
  final List<String> _upNextQueue = <String>[
    'Incline DB Press',
    'Cable Fly',
    'Triceps Pushdown',
  ];
  String _currentExercise = '';
  final Set<String> _completed = <String>{};
  final List<_SetItem> _currentSets = <_SetItem>[
    _SetItem(
      number: 1,
      prevWeight: '40kg',
      prevReps: '8',
      weight: '40kg',
      reps: '8',
      completed: true,
    ),
    _SetItem(
      number: 2,
      prevWeight: '60kg',
      prevReps: '6',
      weight: '60kg',
      reps: '6',
    ),
    _SetItem(
      number: 3,
      prevWeight: '80kg',
      prevReps: '6',
      weight: '80kg',
      reps: '6',
    ),
    _SetItem(
      number: 4,
      prevWeight: '80kg',
      prevReps: '6',
      weight: '80kg',
      reps: '6',
    ),
  ];
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};
  // Column widths for sets table
  static const double _numColW = 24;
  static const double _weightColW = 96;
  static const double _repsColW = 48;
  String _unit = 'kg'; // 'kg' or 'lb'

  void _toggleUnit() {
    setState(() {
      final bool toLb = _unit == 'kg';
      _unit = toLb ? 'lb' : 'kg';
      for (int i = 0; i < _currentSets.length; i++) {
        final controller = _weightControllers[i];
        if (controller == null) continue;
        final numVal = double.tryParse(controller.text.trim()) ?? 0;
        final converted = toLb ? (numVal * 2.20462) : (numVal / 2.20462);
        controller.text = _formatNumber(converted);
      }
    });
  }

  String _formatNumber(double v) {
    return (v >= 10 ? v.round().toString() : v.toStringAsFixed(1)).replaceAll(
      RegExp(r"\.0$"),
      '',
    );
  }

  double _parseKg(String weightStr) {
    final match = RegExp(r"([0-9]+(?:\.[0-9]+)?)").firstMatch(weightStr);
    final numString = match?.group(1) ?? '0';
    return double.tryParse(numString) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _activeTemplateName = '${widget.workoutName} – Heavy';
    _currentExercise = '${widget.workoutName} Exercise 1';
  }

  void _onTemplateSelected(String name) {
    // Add selection to Up next without changing the header
    setState(() {
      _upNextQueue.insert(0, name);
    });
    Navigator.of(context).maybePop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _promoteNext() {
    if (_upNextQueue.isEmpty) return;
    setState(() {
      if (_currentExercise.isNotEmpty) {
        _completed.add(_currentExercise);
      }
      _currentExercise = _upNextQueue.removeAt(0);
      // Reset sets to placeholder for new exercise
      _currentSets.clear();
      _currentSets.addAll(<_SetItem>[
        _SetItem(
          number: 1,
          prevWeight: '40kg',
          prevReps: '8',
          weight: '40kg',
          reps: '8',
        ),
        _SetItem(
          number: 2,
          prevWeight: '60kg',
          prevReps: '6',
          weight: '60kg',
          reps: '6',
        ),
        _SetItem(
          number: 3,
          prevWeight: '80kg',
          prevReps: '6',
          weight: '80kg',
          reps: '6',
        ),
      ]);
      _weightControllers.clear();
      _repsControllers.clear();
    });
  }

  void _toggleSetCompleted(int index) {
    setState(() {
      _currentSets[index] = _currentSets[index].copyWith(
        completed: !_currentSets[index].completed,
      );
    });
  }

  void _addSet() {
    setState(() {
      final next = _currentSets.length + 1;
      _currentSets.add(
        _SetItem(
          number: next,
          prevWeight: '—',
          prevReps: '—',
          weight: '60kg',
          reps: '6',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoggitColors.lightGray,
      appBar: LoggitHeader(title: widget.workoutName, showBack: true),
      body: CustomScrollView(
        controller: _scrollController,
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

  Widget _summaryStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LoggitColors.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoggitColors.divider),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: LoggitColors.lighterGraySubtext),
          ),
          Text(value, style: const TextStyle(color: LoggitColors.darkGrayText)),
        ],
      ),
    );
  }

  Widget _buildSetRow(_SetItem set, int index) {
    final bool done = set.completed;
    _weightControllers.putIfAbsent(
      index,
      () => TextEditingController(text: set.weight),
    );
    _repsControllers.putIfAbsent(
      index,
      () => TextEditingController(text: set.reps),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 360;
        final double gap = isNarrow ? 4 : 6;
        final double numW = isNarrow ? 20 : _numColW;
        final double weightW = isNarrow ? (_weightColW - 12) : _weightColW;
        final double repsW = isNarrow ? (_repsColW - 8) : _repsColW;
        final TextStyle prevStyle = const TextStyle(
          color: LoggitColors.lighterGraySubtext,
          fontSize: 13,
          letterSpacing: 0.2,
        );
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 8 : 10,
            vertical: isNarrow ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: done
                ? LoggitColors.teal.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: numW,
                child: Text(
                  '${set.number}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: gap),
              // Previous (takes remaining space)
              Expanded(
                flex: 3,
                child: Text(
                  '${_formatNumber(_unit == 'kg' ? _parseKg(set.prevWeight) : _parseKg(set.prevWeight) * 2.20462)} ${_unit} x ${set.prevReps}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: prevStyle,
                ),
              ),
              SizedBox(width: gap),
              // Weight input
              Expanded(
                flex: 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 84),
                  child: TextField(
                    controller: _weightControllers[index],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (val) => setState(() {
                      final numVal = double.tryParse(val.trim()) ?? 0;
                      final kg = _unit == 'kg' ? numVal : (numVal / 2.20462);
                      _currentSets[index] = set.copyWith(
                        weight: '${_formatNumber(kg)}kg',
                      );
                    }),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'kg',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isNarrow ? 3 : 4,
                        horizontal: 6,
                      ),
                      suffix: InkWell(
                        onTap: _toggleUnit,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          child: Text(
                            _unit.toUpperCase(),
                            style: TextStyle(
                              fontSize: isNarrow ? 10 : 11,
                              color: LoggitColors.lighterGraySubtext,
                            ),
                          ),
                        ),
                      ),
                      border: const OutlineInputBorder(gapPadding: 0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: gap),
              // Reps input
              Expanded(
                flex: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 56),
                  child: TextField(
                    controller: _repsControllers[index],
                    onChanged: (val) => setState(() {
                      _currentSets[index] = set.copyWith(reps: val.trim());
                    }),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'reps',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 6,
                      ),
                      border: OutlineInputBorder(gapPadding: 0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: gap),
              IconButton(
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -2,
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                iconSize: 20,
                onPressed: () => _toggleSetCompleted(index),
                icon: Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done
                      ? LoggitColors.tealDark
                      : LoggitColors.lighterGraySubtext,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: _numColW,
            child: const Text(
              'SET',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LoggitColors.lighterGraySubtext,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              'PREVIOUS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LoggitColors.lighterGraySubtext,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: _weightColW,
            child: const Text(
              'WEIGHT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LoggitColors.lighterGraySubtext,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: _repsColW,
            child: const Text(
              'REPS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LoggitColors.lighterGraySubtext,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildTodaySessionCard() {
    final templateName = _activeTemplateName ?? '${widget.workoutName} – Heavy';
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
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: LoggitColors.lightGray,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: LoggitColors.divider),
                      ),
                      child: Text(
                        widget.workoutName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LoggitColors.lighterGraySubtext,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LoggitColors.tealDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Finish',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: LoggitColors.divider),
            Padding(
              padding: EdgeInsets.all(LoggitSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.fromBorderSide(BorderSide.none),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _currentExercise,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LoggitColors.darkGrayText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_currentExercise.isNotEmpty)
                              TextButton(
                                onPressed: _promoteNext,
                                child: const Text('Complete'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Header row for sets
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isNarrow = constraints.maxWidth < 360;
                            final double gap = isNarrow ? 4 : 6;
                            final double numW = isNarrow ? 20 : _numColW;
                            return Row(
                              children: [
                                SizedBox(
                                  width: numW,
                                  child: const Text(
                                    '#',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: gap),
                                const Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Previous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: gap),
                                const Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Weight',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: gap),
                                const Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Reps',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: gap),
                                const SizedBox(width: 28),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        // Set rows
                        Column(
                          children: List.generate(
                            _currentSets.length,
                            (i) => _buildSetRow(_currentSets[i], i),
                          ),
                        ),
                      ],
                    ),
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
              children: [
                for (final e in _upNextQueue)
                  _QueueChip(
                    label: e,
                    isCompleted: _completed.contains(e),
                    onTap: () {
                      setState(() {
                        _currentExercise = e;
                        _upNextQueue.remove(e);
                      });
                    },
                  ),
              ],
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
                              onSelect: _onTemplateSelected,
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
                            _TemplatePickerList(
                              workoutName: null,
                              suggestedOnly: false,
                              onSelect: _onTemplateSelected,
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
  final void Function(String name) onSelect;
  const _TemplatePickerList({
    required this.workoutName,
    required this.suggestedOnly,
    required this.onSelect,
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
                      onSelect(name);
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
                    onPressed: () => onSelect(name),
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
  final bool isCompleted;
  final VoidCallback? onTap;
  const _QueueChip({required this.label, this.isCompleted = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color textColor = isCompleted
        ? LoggitColors.tealDark
        : LoggitColors.darkGrayText;
    final Color bgColor = isCompleted
        ? LoggitColors.teal.withOpacity(0.15)
        : LoggitColors.lightGray;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LoggitColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted) ...[
              const Icon(
                Icons.check_circle,
                size: 16,
                color: LoggitColors.tealDark,
              ),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _SetItem {
  final int number;
  final String prevWeight;
  final String prevReps;
  final String weight;
  final String reps;
  final bool completed;
  const _SetItem({
    required this.number,
    required this.prevWeight,
    required this.prevReps,
    required this.weight,
    required this.reps,
    this.completed = false,
  });
  _SetItem copyWith({
    int? number,
    String? prevWeight,
    String? prevReps,
    String? weight,
    String? reps,
    bool? completed,
  }) {
    return _SetItem(
      number: number ?? this.number,
      prevWeight: prevWeight ?? this.prevWeight,
      prevReps: prevReps ?? this.prevReps,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
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
