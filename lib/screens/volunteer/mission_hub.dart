import 'package:flutter/material.dart';
import 'mission_list_screen.dart';
import 'mission_map.dart';

class MissionHub extends StatefulWidget {
  const MissionHub({super.key});

  @override
  State<MissionHub> createState() => _MissionHubState();
}

class _MissionHubState extends State<MissionHub> {
  bool _showMap = true; // Default to map view per existing UX preference

  void _toggleView() {
    setState(() {
      _showMap = !_showMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showMap
          ? MissionMap(onToggleView: _toggleView, key: const ValueKey('map'))
          : MissionListScreen(
              onToggleView: _toggleView,
              key: const ValueKey('list'),
            ),
    );
  }
}
