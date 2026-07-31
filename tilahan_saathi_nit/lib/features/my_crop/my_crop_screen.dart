import 'package:flutter/material.dart';
import 'package:tilahan_saathi/features/home/main_shell.dart';

class MyCropScreen extends StatelessWidget {
  const MyCropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPlaceholder(
      title: 'My Crop',
      subtitle: 'Crop calendar, health monitoring, and weather advisories coming in Phase 3.',
      icon: Icons.eco_rounded,
    );
  }
}
