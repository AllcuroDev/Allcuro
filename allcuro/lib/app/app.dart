import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class AllcuroApp extends StatelessWidget {
  const AllcuroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ALLCURO — Healthcare, Made Simple.',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      // Real phones often run a system font size above 100%. Honour it, but
      // cap it so the compact cards and grids keep their shape; layouts are
      // built to stay overflow-free up to this cap.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
    );
  }
}
