import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class RouteSuggestionWidget extends StatelessWidget {
  const RouteSuggestionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4DC4), Color(0xFF1A6BF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(71),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -10,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(46),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.alt_route_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Alternate Route Suggested',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Use Bittan Market Bypass',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Saves ~22 minutes vs Hamidia Road. Light traffic, no incidents.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha(204),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Route comparison
                  Row(
                    children: [
                      Expanded(
                        child: _RouteOption(
                          label: 'Current',
                          route: 'Hamidia Rd',
                          eta: '42 min',
                          isRecommended: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RouteOption(
                          label: 'Alternate',
                          route: 'Bittan Bypass',
                          eta: '20 min',
                          isRecommended: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/3d-map-screen'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Navigate via Bittan Bypass',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteOption extends StatelessWidget {
  final String label;
  final String route;
  final String eta;
  final bool isRecommended;

  const _RouteOption({
    required this.label,
    required this.route,
    required this.eta,
    required this.isRecommended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended
            ? Colors.white.withAlpha(46)
            : Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: isRecommended
            ? Border.all(color: Colors.white.withAlpha(102), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(166),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            route,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                eta,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isRecommended
                      ? const Color(0xFF7EFFB2)
                      : Colors.white.withAlpha(179),
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF7EFFB2),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
