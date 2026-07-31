import 'package:flutter/material.dart';
import 'package:tilahan_saathi/core/theme/app_theme.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class TilahanSaathiApp extends StatelessWidget {
  const TilahanSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tilahan Saathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
    );
  }
}
