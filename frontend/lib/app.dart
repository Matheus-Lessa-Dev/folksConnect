import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/folks_theme.dart';
import 'features/auth/authentication_service.dart';
import 'features/auth/login_screen.dart';
import 'features/kanban/kanban_controller.dart';
import 'features/kanban/kanban_screen.dart';
import 'features/settings/settings_controller.dart';
import 'features/settings/settings_screen.dart';
import 'features/vacancy_funnel/vacancy_funnel_controller.dart';
import 'features/vacancy_funnel/vacancy_funnel_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/widgets/folks_logo.dart';

class FolksConnectApp extends StatefulWidget {
  const FolksConnectApp({
    super.key,
    this.authentication = const DemoAuthenticationService(),
  });

  final AuthenticationService authentication;

  @override
  State<FolksConnectApp> createState() => _FolksConnectAppState();
}

class _FolksConnectAppState extends State<FolksConnectApp> {
  static const _workspaceRoutes = {'/kanban', '/funil-vagas', '/configuracoes'};
  bool _authenticated = false;

  late final _router = GoRouter(
    redirect: (context, state) {
      final path = state.uri.path;
      if (_workspaceRoutes.contains(path) && !_authenticated) {
        return Uri(
          path: '/login',
          queryParameters: {'redirect': path},
        ).toString();
      }
      if (path == '/login' && _authenticated) return '/kanban';
      if (path != '/' && path != '/login' && !_workspaceRoutes.contains(path)) {
        return _authenticated ? '/kanban' : '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            _StartupFlow(onReady: () => context.go('/login')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          authentication: widget.authentication,
          onAuthenticated: () {
            _authenticated = true;
            final destination = state.uri.queryParameters['redirect'];
            context.go(
              _workspaceRoutes.contains(destination) ? destination! : '/kanban',
            );
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            _AuthenticatedWorkspace(child: child),
        routes: [
          GoRoute(
            path: '/kanban',
            builder: (context, state) => KanbanScreen(
              controller: _WorkspaceScope.of(context)._kanban,
              onSignOut: _signOut,
            ),
          ),
          GoRoute(
            path: '/funil-vagas',
            builder: (context, state) => VacancyFunnelScreen(
              controller: _WorkspaceScope.of(context)._funnel,
              onSignOut: _signOut,
            ),
          ),
          GoRoute(
            path: '/configuracoes',
            builder: (context, state) => SettingsScreen(
              controller: _WorkspaceScope.of(context)._settings,
            ),
          ),
        ],
      ),
    ],
  );

  void _signOut() {
    _authenticated = false;
    _router.go('/login');
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Folks Connect',
      debugShowCheckedModeBanner: false,
      theme: FolksTheme.dark,
      routerConfig: _router,
    );
  }
}

class _StartupFlow extends StatefulWidget {
  const _StartupFlow({required this.onReady});

  final VoidCallback onReady;

  @override
  State<_StartupFlow> createState() => _StartupFlowState();
}

class _StartupFlowState extends State<_StartupFlow> {
  Timer? _timer;
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
        if (mounted) widget.onReady();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

class _AuthenticatedWorkspace extends StatefulWidget {
  const _AuthenticatedWorkspace({required this.child});
  final Widget child;

  @override
  State<_AuthenticatedWorkspace> createState() =>
      _AuthenticatedWorkspaceState();
}

class _AuthenticatedWorkspaceState extends State<_AuthenticatedWorkspace> {
  final _kanban = KanbanController();
  final _funnel = VacancyFunnelController();
  final _settings = SettingsController();

  @override
  void dispose() {
    _kanban.dispose();
    _funnel.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: FolksTheme.kanban,
    child: _WorkspaceScope(workspace: this, child: widget.child),
  );
}

class _WorkspaceScope extends InheritedWidget {
  const _WorkspaceScope({required this.workspace, required super.child});

  final _AuthenticatedWorkspaceState workspace;

  static _AuthenticatedWorkspaceState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WorkspaceScope>()!.workspace;

  @override
  bool updateShouldNotify(_WorkspaceScope oldWidget) =>
      workspace != oldWidget.workspace;
}
