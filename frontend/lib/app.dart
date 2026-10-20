import 'package:flutter/material.dart';

import 'core/theme/folks_theme.dart';
import 'features/splash/splash_screen.dart';

class FolksConnectApp extends StatelessWidget {
  const FolksConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folks Connect',
      debugShowCheckedModeBanner: false,
      theme: FolksTheme.dark,
      home: const SplashScreen(),
    );
  }
}
