// This widget is no longer used — header is embedded in map_screen.dart
// Kept as empty placeholder to avoid breaking imports
import 'package:flutter/material.dart';

class MapHeaderWidget extends StatelessWidget {
  final String activeLayer;
  final VoidCallback onBack;

  const MapHeaderWidget({
    super.key,
    required this.activeLayer,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
