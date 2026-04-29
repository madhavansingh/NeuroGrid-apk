import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/issues_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/civic_issues_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/loading_skeleton_widget.dart';
import '../../widgets/server_wake_banner.dart';
import './widgets/issue_card_widget.dart';
import './widgets/issue_tab_bar_widget.dart';

class CivicIssuesScreen extends ConsumerStatefulWidget {
  const CivicIssuesScreen({super.key});

  @override
  ConsumerState<CivicIssuesScreen> createState() => _CivicIssuesScreenState();
}

class _CivicIssuesScreenState extends ConsumerState<CivicIssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CivicIssue> _filteredIssues(List<CivicIssue> all, int tabIndex) {
    final filter = _statusFilters[tabIndex];
    if (filter == null) return all;
    return all.where((i) => i.status == filter).toList();
  }

  Future<void> _reload() => ref.read(issuesProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final issuesAsync = ref.watch(issuesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Render cold-start banner — hides once server is online
            const ServerWakeBanner(),
            // Header — use data from provider so count is always live
            issuesAsync.when(
              data: (issues) => _buildHeader(issues.length, isError: false),
              loading: () => _buildHeader(0, isError: false),
              error: (_, __) => _buildHeader(0, isError: true),
            ),
            IssueTabBarWidget(tabController: _tabController, tabs: _tabs),
            Expanded(
              child: issuesAsync.when(
                data: (issues) => TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabs.length, (index) {
                    return _buildIssueList(_filteredIssues(issues, index));
                  }),
                ),
                loading: () => _buildSkeletonList(),
                error: (err, _) => _buildErrorState(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.reportIssueScreen);
          // Refresh after returning from report screen in case WS missed it
          _reload();
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

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(int count, {required bool isError}) {
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
                  isError
                      ? 'Could not load issues'
                      : '$count total reports',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isError ? AppTheme.error : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _reload,
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

  // ── Loading skeletons ──────────────────────────────────────────────────────

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

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.errorLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 36,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not reach server',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and tap refresh',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _reload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Issue list ─────────────────────────────────────────────────────────────

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
            final issue = issues[index];
            String nextStatus;
            switch (issue.status) {
              case 'pending':
                nextStatus = 'in_progress';
                break;
              case 'in_progress':
                nextStatus = 'resolved';
                break;
              default:
                return;
            }
            await ref
                .read(issuesProvider.notifier)
                .updateStatus(issue.id, nextStatus);
          },
        );
      },
    );
  }
}