import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/storage_service.dart';
import '../widgets/stats/stats_tab_body.dart';

class StatsScreen extends StatefulWidget {
  final StorageService storage;

  const StatsScreen({super.key, required this.storage});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'All',
    ...['Beginner', 'Easy', 'Medium', 'Hard', 'Expert', 'Master'],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, _) {
        final stats = widget.storage.stats;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Statistics'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final label in _tabs) Tab(text: label)],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              StatsTabBody(store: stats),
              for (final d in Difficulty.values)
                StatsTabBody(store: stats, difficulty: d),
            ],
          ),
        );
      },
    );
  }
}
