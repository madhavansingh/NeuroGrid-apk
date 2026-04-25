import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import './widgets/account_info_widget.dart';
import './widgets/notification_toggles_widget.dart';
import './widgets/preferences_widget.dart';
import './widgets/saved_locations_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  int _navIndex = 4;
  late AnimationController _entranceController;
  late List<Animation<double>> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sectionAnimations = List.generate(
      6,
      (i) => CurvedAnimation(
        parent: _entranceController,
        curve: Interval(i * 0.10, 0.55 + i * 0.08, curve: Curves.easeOutCubic),
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[0],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[0]),
                  child: _buildHeader(context),
                ),
              ),
            ),
            // Account Info Card
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[1],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[1]),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AccountInfoWidget(),
                  ),
                ),
              ),
            ),
            // Saved Locations
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[2],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[2]),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 16, left: 20, right: 20),
                    child: SavedLocationsWidget(),
                  ),
                ),
              ),
            ),
            // Notification Toggles
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[3],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[3]),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 16, left: 20, right: 20),
                    child: NotificationTogglesWidget(),
                  ),
                ),
              ),
            ),
            // Preferences
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[4],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[4]),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 16, left: 20, right: 20),
                    child: PreferencesWidget(),
                  ),
                ),
              ),
            ),
            // Account Actions
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[5],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[5]),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 20,
                      right: 20,
                    ),
                    child: _buildAccountActions(),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 0) Navigator.pushNamed(context, '/home-screen');
          if (i == 1) Navigator.pushNamed(context, '/3d-map-screen');
          if (i == 2) Navigator.pushNamed(context, '/traffic-screen');
          if (i == 3) Navigator.pushNamed(context, '/ai-assistant-screen');
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Profile',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Manage your account & preferences',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            color: AppTheme.primary,
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            color: const Color(0xFF7C3AED),
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.info_outline_rounded,
            label: 'About NeuroGrid',
            color: AppTheme.textSecondary,
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: AppTheme.error,
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isLast ? AppTheme.error : AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (!isLast)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            color: AppTheme.outlineVariant,
            height: 1,
            thickness: 1,
            indent: 60,
          ),
      ],
    );
  }
}
