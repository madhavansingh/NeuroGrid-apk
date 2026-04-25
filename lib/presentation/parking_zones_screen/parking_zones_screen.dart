import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import './widgets/parking_summary_widget.dart';
import './widgets/zone_card_widget.dart';

class ParkingZonesScreen extends StatefulWidget {
  const ParkingZonesScreen({super.key});

  @override
  State<ParkingZonesScreen> createState() => _ParkingZonesScreenState();
}

class _ParkingZonesScreenState extends State<ParkingZonesScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  int _selectedFilter = 0;
  late AnimationController _entranceController;
  late List<Animation<double>> _sectionAnimations;

  static const List<String> _filters = [
    'All',
    'Available',
    'Low Demand',
    'Nearby',
  ];

  static const List<ParkingZoneData> _allZones = [
    ParkingZoneData(
      zoneName: 'New Market Plaza',
      zoneCode: 'Z-01',
      location: 'New Market, Bhopal',
      totalSlots: 40,
      availableSlots: 12,
      demand: DemandLevel.high,
      ratePerHour: 30,
      distance: '0.4 km',
      icon: Icons.store_mall_directory_rounded,
    ),
    ParkingZoneData(
      zoneName: 'MP Nagar Hub',
      zoneCode: 'Z-02',
      location: 'MP Nagar Zone II',
      totalSlots: 60,
      availableSlots: 28,
      demand: DemandLevel.moderate,
      ratePerHour: 20,
      distance: '0.8 km',
      icon: Icons.business_center_rounded,
    ),
    ParkingZoneData(
      zoneName: 'DB City Mall',
      zoneCode: 'Z-03',
      location: 'Arera Colony',
      totalSlots: 120,
      availableSlots: 5,
      demand: DemandLevel.high,
      ratePerHour: 40,
      distance: '1.2 km',
      icon: Icons.local_mall_rounded,
    ),
    ParkingZoneData(
      zoneName: 'Bittan Market',
      zoneCode: 'Z-04',
      location: 'Bittan Market Road',
      totalSlots: 30,
      availableSlots: 22,
      demand: DemandLevel.low,
      ratePerHour: 10,
      distance: '1.6 km',
      icon: Icons.storefront_rounded,
    ),
    ParkingZoneData(
      zoneName: 'Hamidia Road Lot',
      zoneCode: 'Z-05',
      location: 'Hamidia Road',
      totalSlots: 50,
      availableSlots: 0,
      demand: DemandLevel.high,
      ratePerHour: 25,
      distance: '2.1 km',
      icon: Icons.directions_car_rounded,
    ),
    ParkingZoneData(
      zoneName: 'Shyamla Hills',
      zoneCode: 'Z-06',
      location: 'Shyamla Hills',
      totalSlots: 35,
      availableSlots: 18,
      demand: DemandLevel.low,
      ratePerHour: 15,
      distance: '2.8 km',
      icon: Icons.park_rounded,
    ),
  ];

  List<ParkingZoneData> get _filteredZones {
    switch (_selectedFilter) {
      case 1:
        return _allZones.where((z) => z.availableSlots > 0).toList();
      case 2:
        return _allZones.where((z) => z.demand == DemandLevel.low).toList();
      case 3:
        return [..._allZones]..sort((a, b) => a.distance.compareTo(b.distance));
      default:
        return _allZones;
    }
  }

  int get _totalAvailable =>
      _allZones.fold(0, (sum, z) => sum + z.availableSlots);

  double get _avgRate {
    final total = _allZones.fold(0.0, (sum, z) => sum + z.ratePerHour);
    return total / _allZones.length;
  }

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
    final zones = _filteredZones;
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
            // Summary card
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[1],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[1]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ParkingSummaryWidget(
                      totalAvailable: _totalAvailable,
                      totalZones: _allZones.length,
                      avgRate: _avgRate,
                    ),
                  ),
                ),
              ),
            ),
            // Filter chips
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[2],
                child: _buildFilterRow(),
              ),
            ),
            // Section label
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[3],
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        '${zones.length} Zones',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Sorted by distance',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Zone cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final anim = CurvedAnimation(
                    parent: _entranceController,
                    curve: Interval(
                      0.3 + i * 0.06,
                      0.7 + i * 0.04,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(anim),
                      child: ZoneCardWidget(zone: zones[i], animIndex: i),
                    ),
                  );
                }, childCount: zones.length),
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
          if (i == 4) Navigator.pushNamed(context, '/profile-screen');
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
                'Parking Zones',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Bhopal · MP Nagar',
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
              Icons.map_outlined,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = _selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.outline,
                  width: 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                _filters[i],
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
