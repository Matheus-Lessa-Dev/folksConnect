import 'dart:async';

import 'package:flutter/material.dart';

import 'core/theme/folks_theme.dart';
import 'features/auth/authentication_service.dart';
import 'features/auth/login_screen.dart';
import 'features/kanban/kanban_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/widgets/folks_logo.dart';

class FolksConnectApp extends StatelessWidget {
  const FolksConnectApp({
    super.key,
    this.authentication = const DemoAuthenticationService(),
  });

  final AuthenticationService authentication;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folks Connect',
      debugShowCheckedModeBanner: false,
      theme: FolksTheme.dark,
      home: _StartupFlow(authentication: authentication),
    );
  }
}

class _StartupFlow extends StatefulWidget {
  const _StartupFlow({required this.authentication});

  final AuthenticationService authentication;

  @override
  State<_StartupFlow> createState() => _StartupFlowState();
}

class _StartupFlowState extends State<_StartupFlow> {
  Timer? _timer;
  bool _loading = true;
  bool _started = false;
  bool _authenticated = false;

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
    if (_loading) return const SplashScreen();
    if (_authenticated) {
      return Theme(
        data: FolksTheme.kanban,
        child: KanbanScreen(
          onSignOut: () => setState(() => _authenticated = false),
        ),
      );
    }
    return LoginScreen(
      authentication: widget.authentication,
      onAuthenticated: () => setState(() => _authenticated = true),
    );
  }
}
