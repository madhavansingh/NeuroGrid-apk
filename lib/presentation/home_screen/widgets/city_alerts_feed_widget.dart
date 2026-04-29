import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Live city feed — "What's happening near you"
/// Each item has a category, headline, detail, and timestamp.
class CityAlertsFeedWidget extends StatelessWidget {
  const CityAlertsFeedWidget({super.key});

  static const _feed = [
    _FeedItem(
      icon: Icons.traffic_rounded,
      category: 'Traffic',
      title: 'Accident cleared near New Market',
      detail: 'Road fully open. Traffic flowing normally now.',
      time: '2 min ago',
      color: Color(0xFF10B981),
      bg: Color(0xFFECFDF5),
    ),
    _FeedItem(
      icon: Icons.warning_amber_rounded,
      category: 'Alert',
      title: 'Water tanker arriving — Zone 4',
      detail: 'Tanker will be at your sector between 3–4 PM.',
      time: '11 min ago',
      color: Color(0xFFF59E0B),
      bg: Color(0xFFFFFBEB),
    ),
    _FeedItem(
      icon: Icons.delete_outline_rounded,
      category: 'Civic',
      title: 'Garbage truck arriving in your area',
      detail: 'Estimated arrival: 6:30 PM. Keep bins ready.',
      time: '25 min ago',
      color: Color(0xFF8B5CF6),
      bg: Color(0xFFF5F3FF),
    ),
    _FeedItem(
      icon: Icons.local_parking_rounded,
      category: 'Parking',
      title: 'Hamidia Road parking — 8 spots opened',
      detail: 'Cleared after accident. Available for 2 hrs.',
      time: '38 min ago',
      color: Color(0xFF1A6BF5),
      bg: Color(0xFFEBF1FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Row(children: [
        Text('What\'s Happening Near You',
            style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF1FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF10B981), shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text('${_feed.length} updates',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A6BF5))),
          ]),
        ),
      ]),

      const SizedBox(height: 14),

      // Feed items
      ...List.generate(_feed.length, (i) {
        final item = _feed[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i < _feed.length - 1 ? 10 : 0),
          child: _FeedCard(item: item, isLatest: i == 0),
        );
      }),

      const SizedBox(height: 16),

      // View all button
      Center(
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFEBF1FF),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          child: Text('View all city updates',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A6BF5))),
        ),
      ),
    ]);
  }
}

class _FeedItem {
  final IconData icon;
  final String category, title, detail, time;
  final Color color, bg;
  const _FeedItem({
    required this.icon,
    required this.category,
    required this.title,
    required this.detail,
    required this.time,
    required this.color,
    required this.bg,
  });
}

class _FeedCard extends StatefulWidget {
  final _FeedItem item;
  final bool isLatest;
  const _FeedCard({required this.item, this.isLatest = false});
  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard>
    with TickerProviderStateMixin {
  late AnimationController _c;
  late AnimationController _pulseCtrl;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _c.value * 0.02, child: child),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(color: item.color, width: 3.5),
            ),
            boxShadow: [
              BoxShadow(
                  color: item.color.withAlpha(18),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
              BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: item.bg, borderRadius: BorderRadius.circular(14)),
              child: Icon(item.icon, size: 22, color: item.color),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Category pill + timestamp
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item.category,
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: item.color)),
                  ),
                  const Spacer(),
                  Text(item.time,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: const Color(0xFF94A3B8))),
                ]),

                const SizedBox(height: 6),

                // Title
                Text(item.title,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A))),

                const SizedBox(height: 4),

                // Detail
                Text(item.detail,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.45)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
