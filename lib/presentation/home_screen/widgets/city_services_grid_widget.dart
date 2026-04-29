import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_routes.dart';

/// Smart Actions grid — 5 premium tappable tiles, each navigates to a real screen.
class CityServicesGridWidget extends StatelessWidget {
  const CityServicesGridWidget({super.key});

  static const _actions = [
    _Action(
      icon: Icons.directions_rounded,
      label: 'Navigate',
      sub: 'Get directions',
      gradient: [Color(0xFF1A6BF5), Color(0xFF3A8BFF)],
      route: AppRoutes.mapScreen,
    ),
    _Action(
      icon: Icons.local_parking_rounded,
      label: 'Parking',
      sub: '12 spots near',
      gradient: [Color(0xFF059669), Color(0xFF10B981)],
      route: AppRoutes.parkingZonesScreen,
    ),
    _Action(
      icon: Icons.report_problem_rounded,
      label: 'Report',
      sub: 'Civic issue',
      gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
      route: AppRoutes.reportIssueScreen,
    ),
    _Action(
      icon: Icons.delete_outline_rounded,
      label: 'Waste',
      sub: 'Tomorrow 8 AM',
      gradient: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
      route: AppRoutes.wastePickupScreen,
    ),
    _Action(
      icon: Icons.smart_toy_rounded,
      label: 'AI Chat',
      sub: 'Ask anything',
      gradient: [Color(0xFFDB2777), Color(0xFFEC4899)],
      route: AppRoutes.aiAssistantScreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Smart Actions',
            style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A6BF5), Color(0xFF3A8BFF)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('5 services',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 14),
      // 2-row layout: 3 + 2 centred
      _buildRow(context, _actions.sublist(0, 3)),
      const SizedBox(height: 12),
      _buildRow(context, _actions.sublist(3, 5), centred: true),
    ]);
  }

  Widget _buildRow(BuildContext context, List<_Action> items,
      {bool centred = false}) {
    final tiles = items
        .map((a) => Expanded(child: _ActionTile(action: a)))
        .toList();
    final gaps = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      gaps.add(tiles[i]);
      if (i < tiles.length - 1) gaps.add(const SizedBox(width: 12));
    }
    if (centred) {
      return Row(children: [
        const Expanded(flex: 1, child: SizedBox()),
        const SizedBox(width: 6),
        ...gaps,
        const SizedBox(width: 6),
        const Expanded(flex: 1, child: SizedBox()),
      ]);
    }
    return Row(children: gaps);
  }
}

class _Action {
  final IconData icon;
  final String label, sub, route;
  final List<Color> gradient;
  const _Action({
    required this.icon,
    required this.label,
    required this.sub,
    required this.gradient,
    required this.route,
  });
}

class _ActionTile extends StatefulWidget {
  final _Action action;
  const _ActionTile({required this.action});
  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return GestureDetector(
      onTapDown: (_) {
        _c.forward();
        HapticFeedback.lightImpact();
        setState(() => _hovered = true);
      },
      onTapUp: (_) {
        _c.reverse();
        setState(() => _hovered = false);
        Navigator.pushNamed(context, a.route);
      },
      onTapCancel: () {
        _c.reverse();
        setState(() => _hovered = false);
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _c.value * 0.05, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: a.gradient.first.withAlpha(_hovered ? 45 : 22),
                  blurRadius: _hovered ? 24 : 16,
                  offset: const Offset(0, 6)),
              BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gradient icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: a.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: a.gradient.first.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(a.icon, size: 23, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(a.label,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(a.sub,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
