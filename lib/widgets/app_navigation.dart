import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart';

/// Premium frosted-glass floating navigation bar.
/// Active tab gets a gradient indicator dot + icon scale-up + bold label.
class AppNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with TickerProviderStateMixin {
  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Map',
    ),
    // Centre slot — VoiceFAB lives here, empty spacer
    _NavItem(
      icon: Icons.mic_none_rounded,
      activeIcon: Icons.mic_rounded,
      label: '',
      isCentre: true,
    ),
    _NavItem(
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy_rounded,
      label: 'AI',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  late final List<AnimationController> _scaleCtrl;
  late final List<Animation<double>> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = List.generate(
      _items.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
        value: 0,
      ),
    );
    _scaleAnim = _scaleCtrl.map((c) {
      return Tween<double>(begin: 1.0, end: 1.22).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack),
      );
    }).toList();

    // Trigger initial active tab
    _scaleCtrl[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scaleCtrl[oldWidget.currentIndex].reverse();
      _scaleCtrl[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _scaleCtrl) c.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (_items[index].isCentre) return; // Voice FAB handles this
    HapticFeedback.selectionClick();
    widget.onTap(index);
    // Route mapping (index offset due to centre slot)
    final routes = [
      AppRoutes.homeScreen,
      AppRoutes.mapScreen,
      null,
      AppRoutes.aiAssistantScreen,
      AppRoutes.profileScreen,
    ];
    final route = routes[index];
    if (route != null && route != AppRoutes.homeScreen) {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom * 0.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: Colors.white.withAlpha(200), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A6BF5).withAlpha(20),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                if (item.isCentre) {
                  // Spacer for the centre FAB
                  return const Expanded(child: SizedBox());
                }
                final isActive = widget.currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _handleTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: _scaleAnim[i],
                      builder: (_, __) => Transform.scale(
                        scale: isActive ? _scaleAnim[i].value : 1.0,
                        child: _TabContent(
                          item: item,
                          isActive: isActive,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab content ───────────────────────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _TabContent({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with animated switcher
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            key: ValueKey(isActive),
            size: 22,
            color: isActive
                ? const Color(0xFF1A6BF5)
                : const Color(0xFF94A3B8),
          ),
        ),

        if (item.label.isNotEmpty) ...[
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF1A6BF5)
                  : const Color(0xFF94A3B8),
            ),
            child: Text(item.label),
          ),
        ],

        const SizedBox(height: 2),

        // Active indicator dot
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isActive ? 18 : 0,
          height: isActive ? 3 : 0,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A6BF5), Color(0xFF6B9EFF)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCentre;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCentre = false,
  });
}
