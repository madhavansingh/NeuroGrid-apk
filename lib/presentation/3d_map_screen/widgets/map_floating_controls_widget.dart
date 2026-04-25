// This widget is no longer used — floating controls are embedded in map_screen.dart
import 'package:flutter/material.dart';

class MapFloatingControlsWidget extends StatelessWidget {
  final VoidCallback onMyLocation;
  final VoidCallback onLayersToggle;
  final bool showLayers;
  final String activeLayer;
  final Function(String) onLayerSelect;

  const MapFloatingControlsWidget({
    super.key,
    required this.onMyLocation,
    required this.onLayersToggle,
    required this.showLayers,
    required this.activeLayer,
    required this.onLayerSelect,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
