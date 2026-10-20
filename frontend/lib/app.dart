import 'dart:async';

import 'package:flutter/material.dart';

import 'core/theme/folks_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/widgets/folks_logo.dart';

class FolksConnectApp extends StatelessWidget {
  const FolksConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folks Connect',
      debugShowCheckedModeBanner: false,
      theme: FolksTheme.dark,
      home: const _StartupFlow(),
    );
  }
}

class _StartupFlow extends StatefulWidget {
  const _StartupFlow();

  @override
  State<_StartupFlow> createState() => _StartupFlowState();
}

class _StartupFlowState extends State<_StartupFlow> {
  Timer? _timer;
  bool _loading = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final delay = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 900);
    precacheImage(const AssetImage(FolksLogo.asset), context).then((_) {
      if (!mounted) return;
      _timer = Timer(delay, () {
        if (mounted) setState(() => _loading = false);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? const SplashScreen() : const LoginScreen();
  }
}
