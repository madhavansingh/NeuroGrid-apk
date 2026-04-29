import 'package:flutter/material.dart';

import '../presentation/3d_map_screen/map_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/traffic_screen/traffic_screen.dart';
import '../presentation/waste_pickup_screen/waste_pickup_screen.dart';
import '../presentation/parking_zones_screen/parking_zones_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/ai_assistant_screen/ai_assistant_screen.dart';
import '../presentation/emergency_screen/emergency_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/civic_issues_screen/civic_issues_screen.dart';
import '../presentation/report_issue_screen/report_issue_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/';
  static const String onboardingScreen = '/onboarding-screen';
  static const String homeScreen = '/home-screen';
  static const String mapScreen = '/3d-map-screen';
  static const String trafficScreen = '/traffic-screen';
  static const String wastePickupScreen = '/waste-pickup-screen';
  static const String parkingZonesScreen = '/parking-zones-screen';
  static const String profileScreen = '/profile-screen';
  static const String aiAssistantScreen = '/ai-assistant-screen';
  static const String emergencyScreen = '/emergency-screen';
  static const String civicIssuesScreen = '/civic-issues-screen';
  static const String reportIssueScreen = '/report-issue-screen';
  static const String settingsScreen = '/settings-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    homeScreen: (context) => const HomeScreen(),
    mapScreen: (context) => const MapScreen(),
    trafficScreen: (context) => const TrafficScreen(),
    wastePickupScreen: (context) => const WastePickupScreen(),
    parkingZonesScreen: (context) => const ParkingZonesScreen(),
    profileScreen: (context) => const ProfileScreen(),
    aiAssistantScreen: (context) => const AiAssistantScreen(),
    emergencyScreen: (context) => const EmergencyScreen(),
    civicIssuesScreen: (context) => const CivicIssuesScreen(),
    reportIssueScreen: (context) => const ReportIssueScreen(),
    settingsScreen: (context) => const SettingsScreen(),
  };
}
