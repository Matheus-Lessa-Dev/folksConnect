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
  Widget build(BuildContext context) => DecoratedBox(
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
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const IconButton(
              tooltip: 'Início (em breve)',
              onPressed: null,
              disabledColor: FolksColors.white,
              icon: Icon(Icons.home_rounded),
            ),
            _destination(context, '/kanban', 'Kanban', Icons.assignment),
            Transform.translate(
              offset: const Offset(0, -36),
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: FolksColors.brandOrange,
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFF86117)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x54FF671D),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(child: FolksMark()),
              ),
            ),
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
