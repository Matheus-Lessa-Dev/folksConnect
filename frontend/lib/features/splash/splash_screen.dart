import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/folks_theme.dart';
import '../../shared/widgets/folks_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: FolksColors.authBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: FolksColors.authBackground,
        body: SafeArea(child: Center(child: FolksLogo())),
      ),
    );
  }
}
