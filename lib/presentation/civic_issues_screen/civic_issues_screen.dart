import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/civic_issues_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/loading_skeleton_widget.dart';
import './widgets/issue_card_widget.dart';
import './widgets/issue_tab_bar_widget.dart';

class CivicIssuesScreen extends StatefulWidget {
  const CivicIssuesScreen({super.key});

  @override
  State<CivicIssuesScreen> createState() => _CivicIssuesScreenState();
}

class _CivicIssuesScreenState extends State<CivicIssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CivicIssue> _allIssues = [];
  bool _isLoading = true;
  dynamic _subscription;
  int _navIndex = 0;

  final List<String> _tabs = ['All', 'Pending', 'In Progress', 'Completed'];
  final List<String?> _statusFilters = [
    null,
    'pending',
    'in_progress',
    'resolved',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadIssues();
    _setupRealtime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    final issues = await CivicIssuesService.instance.fetchIssues();
    if (mounted) {
      setState(() {
        _allIssues = issues;
        _isLoading = false;
      });
    }
  }

  void _setupRealtime() {
    _subscription = CivicIssuesService.instance.subscribeToIssues(
      onEvent: (issue, eventType) {
        if (!mounted) return;
        setState(() {
          if (eventType == 'insert') {
            // Add new issue at top
            _allIssues.removeWhere((i) => i.id == issue.id);
            _allIssues.insert(0, issue);
          } else if (eventType == 'update') {
            final idx = _allIssues.indexWhere((i) => i.id == issue.id);
            if (idx != -1) {
              _allIssues[idx] = issue;
            } else {
              _allIssues.insert(0, issue);
            }
          } else if (eventType == 'delete') {
            _allIssues.removeWhere((i) => i.id == issue.id);
          }
        });
      },
    );
  }

  List<CivicIssue> _filteredIssues(int tabIndex) {
    final filter = _statusFilters[tabIndex];
    if (filter == null) return _allIssues;
    return _allIssues.where((i) => i.status == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            IssueTabBarWidget(tabController: _tabController, tabs: _tabs),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (index) {
                  return _isLoading
                      ? _buildSkeletonList()
                      : _buildIssueList(_filteredIssues(index));
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.reportIssueScreen);
          _loadIssues();
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Report Issue',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Civic Issues',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_allIssues.length} total reports',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadIssues,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 4,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadingSkeletonWidget(width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LoadingSkeletonWidget(height: 14, borderRadius: 6),
                    const SizedBox(height: 8),
                    LoadingSkeletonWidget(
                      width: 120,
                      height: 12,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 6),
                    LoadingSkeletonWidget(
                      width: 80,
                      height: 10,
                      borderRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              LoadingSkeletonWidget(width: 70, height: 22, borderRadius: 11),
              const SizedBox(width: 8),
              LoadingSkeletonWidget(width: 100, height: 12, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssueList(List<CivicIssue> issues) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.report_problem_outlined,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No issues found',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to report a new civic issue',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        return IssueCardWidget(
          issue: issues[index],
          onSimulateUpdate: () async {
            await CivicIssuesService.instance.simulateOperatorUpdate(
              issues[index].id,
              issues[index].status,
            );
          },
        );
      },
    );
  }
}