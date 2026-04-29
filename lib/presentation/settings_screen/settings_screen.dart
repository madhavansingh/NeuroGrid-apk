import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 4;
  bool _trafficAlerts = true;
  bool _wasteAlerts = true;
  bool _safetyAlerts = false;
  bool _locationAccess = true;
  late AnimationController _enter;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _enter.forward();
    _loadPrefs();
  }

  @override
  void dispose() { _enter.dispose(); super.dispose(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _trafficAlerts = p.getBool('pref_traffic_alerts') ?? true;
      _wasteAlerts   = p.getBool('pref_waste_alerts') ?? true;
      _safetyAlerts  = p.getBool('pref_safety_alerts') ?? false;
      _locationAccess = p.getBool('pref_location') ?? true;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(bottom: false, child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSection(
              'Notifications',
              Icons.notifications_outlined,
              const Color(0xFF1A6BF5),
              [
                _ToggleTile('Traffic Alerts', 'Get alerts for congestion & incidents', Icons.traffic_rounded, const Color(0xFF1A6BF5), _trafficAlerts,
                  (v) { setState(() => _trafficAlerts = v); _savePref('pref_traffic_alerts', v); }),
                _ToggleTile('Waste Pickup Alerts', 'Reminders before collection day', Icons.delete_outline_rounded, const Color(0xFF16A34A), _wasteAlerts,
                  (v) { setState(() => _wasteAlerts = v); _savePref('pref_waste_alerts', v); }),
                _ToggleTile('Safety Alerts', 'Emergency and civic alerts', Icons.shield_outlined, const Color(0xFFDC2626), _safetyAlerts,
                  (v) { setState(() => _safetyAlerts = v); _savePref('pref_safety_alerts', v); }),
              ],
            )),
            SliverToBoxAdapter(child: _buildSection(
              'Privacy & Permissions',
              Icons.privacy_tip_outlined,
              const Color(0xFF7C3AED),
              [
                _ToggleTile('Location Access', 'Required for maps & nearby alerts', Icons.location_on_outlined, const Color(0xFF7C3AED), _locationAccess,
                  (v) { setState(() => _locationAccess = v); _savePref('pref_location', v); }),
                _TapTile('Data Usage Policy', 'How NeuroGrid uses your data', Icons.policy_outlined, const Color(0xFF0891B2), () => _openUrl('https://neurogrid.in/privacy')),
              ],
            )),
            SliverToBoxAdapter(child: _buildSection(
              'Appearance',
              Icons.palette_outlined,
              const Color(0xFFD97706),
              [
                _InfoTile('Theme', 'Light mode', Icons.light_mode_rounded, const Color(0xFFD97706)),
                _InfoTile('Language', 'English', Icons.language_rounded, const Color(0xFF16A34A)),
              ],
            )),
            SliverToBoxAdapter(child: _buildSection(
              'About',
              Icons.info_outline_rounded,
              const Color(0xFF64748B),
              [
                _InfoTile('Version', '1.0.0 (build 1)', Icons.apps_rounded, const Color(0xFF64748B)),
                _TapTile('Rate the App', 'Share your feedback', Icons.star_outline_rounded, const Color(0xFFD97706), () {}),
                _TapTile('Contact Support', 'Reach our team', Icons.mail_outline_rounded, const Color(0xFF1A6BF5), () => _openUrl('mailto:support@neurogrid.in')),
                _TapTile('About NeuroGrid', 'Our mission & story', Icons.domain_rounded, const Color(0xFF7C3AED), () => _openUrl('https://neurogrid.in')),
              ],
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        )),
      ),
      bottomNavigationBar: AppNavigation(currentIndex: _navIndex, onTap: (i) {
        setState(() => _navIndex = i);
        if (i == 0) Navigator.pushNamed(context, '/home-screen');
        if (i == 1) Navigator.pushNamed(context, '/3d-map-screen');
        if (i == 2) Navigator.pushNamed(context, '/traffic-screen');
        if (i == 3) Navigator.pushNamed(context, '/ai-assistant-screen');
        if (i == 4) Navigator.pushNamed(context, '/profile-screen');
      }),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))]),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.3)),
        Text('Preferences & privacy', style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B))),
      ])),
    ]),
  );

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> tiles) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color)),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.4)),
      ]),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(children: tiles),
      ),
    ]),
  );

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ── Tile types ──────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final String title, subtitle; final IconData icon; final Color color;
  final bool value; final ValueChanged<bool> onChanged;
  const _ToggleTile(this.title, this.subtitle, this.icon, this.color, this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 17, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
        Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF64748B))),
      ])),
      Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
    ]),
  );
}

class _TapTile extends StatelessWidget {
  final String title, subtitle; final IconData icon; final Color color; final VoidCallback onTap;
  const _TapTile(this.title, this.subtitle, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
          Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF64748B))),
        ])),
        Icon(Icons.chevron_right_rounded, size: 18, color: const Color(0xFF94A3B8)),
      ]),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final String title, value; final IconData icon; final Color color;
  const _InfoTile(this.title, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 17, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)))),
      Text(value, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B))),
    ]),
  );
}
