import 'package:flutter/material.dart';
import 'package:tilahan_saathi/features/home/main_shell.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPlaceholder(
      title: 'Market',
      subtitle: 'Mandi prices, price trends, and sell/hold recommendations coming in Phase 3.',
      icon: Icons.storefront_rounded,
    );
  }
}
