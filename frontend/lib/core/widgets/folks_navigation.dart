import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/folks_theme.dart';
import 'folks_mark.dart';

class FolksNavigation extends StatelessWidget {
  const FolksNavigation({super.key, required this.selectedRoute});
  final String selectedRoute;

  Widget _destination(
    BuildContext context,
    String route,
    String label,
    IconData icon,
  ) => Semantics(
    selected: selectedRoute == route,
    child: IconButton(
      tooltip: label,
      onPressed: () {
        if (selectedRoute != route) {
          context.go(route);
        }
      },
      color: selectedRoute == route ? FolksColors.orange : FolksColors.white,
      icon: Icon(icon, size: 26),
    ),
  );

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(padding: const EdgeInsets.only(top: 24), child: _bar(context)),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Center(child: _dashboardButton(context)),
      ),
    ],
  );

  Widget _dashboardButton(BuildContext context) {
    final selected = selectedRoute == '/dashboard';
    return Semantics(
      selected: selected,
      child: Material(
        color: FolksColors.brandOrange,
        elevation: 4,
        shadowColor: const Color(0x54FF671D),
        shape: CircleBorder(
          side: BorderSide(
            color: selected ? FolksColors.white : FolksColors.boardOrange,
            width: selected ? 2 : 1,
          ),
        ),
        child: SizedBox.square(
          dimension: 62,
          child: IconButton(
            tooltip: 'Dashboard',
            onPressed: () {
              if (!selected) context.go('/dashboard');
            },
            icon: const FolksMark(),
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: FolksColors.navigation,
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    child: SafeArea(
      top: false,
      minimum: EdgeInsets.only(
        bottom: MediaQuery.orientationOf(context) == Orientation.portrait
            ? 24
            : 0,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _destination(context, '/inicio', 'Início', Icons.home_rounded),
            _destination(context, '/kanban', 'Kanban', Icons.assignment),
            const SizedBox(width: 62),
            _destination(
              context,
              '/funil-vagas',
              'Funil de Vagas',
              Icons.edit_square,
            ),
            _destination(
              context,
              '/configuracoes',
              'Configurações',
              Icons.settings,
            ),
          ],
        ),
      ),
    ),
  );
}
