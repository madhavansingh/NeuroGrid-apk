// This widget is no longer used — bottom sheet is embedded in map_screen.dart
import 'package:flutter/material.dart';

class MapBottomSheetWidget extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final String activeLayer;

  const MapBottomSheetWidget({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.activeLayer,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
