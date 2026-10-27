import 'package:flutter/material.dart';

import '../../core/theme/folks_theme.dart';
import '../../core/widgets/folks_navigation.dart';
import '../kanban/widgets/kanban_widgets.dart';
import 'vacancy.dart';
import 'vacancy_funnel_controller.dart';
import 'widgets/new_vacancy_sheet.dart';

class VacancyFunnelScreen extends StatefulWidget {
  const VacancyFunnelScreen({super.key, this.controller, this.onSignOut});
  final VacancyFunnelController? controller;
  final VoidCallback? onSignOut;

  @override
  State<VacancyFunnelScreen> createState() => _VacancyFunnelScreenState();
}

class _VacancyFunnelScreenState extends State<VacancyFunnelScreen> {
  late final _controller = widget.controller ?? VacancyFunnelController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final created = await showFolksSheet<bool>(
      context,
      NewVacancySheet(controller: _controller),
    );
    if (!mounted || created != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vaga cadastrada nesta sessão.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: FolksTheme.background),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.sizeOf(context).height < 500 ? 8 : 24,
                16,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Funil de Vagas', style: FolksTheme.heading),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _create,
                    style: TextButton.styleFrom(
                      backgroundColor: FolksColors.card,
                      minimumSize: const Size(64, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('+ Vaga'),
                  ),
                  if (widget.onSignOut != null)
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: widget.onSignOut,
                      icon: const Icon(Icons.logout, color: FolksColors.white),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final vacancies = _controller.vacancies;
                  if (vacancies.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Nenhuma vaga cadastrada.'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _create,
                              child: const Text('Cadastrar primeira vaga'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                    itemCount: vacancies.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, index) => Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: _VacancyCard(vacancies[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const FolksNavigation(selectedRoute: '/funil-vagas'),
          ],
        ),
      ),
    ),
  );
}

class _VacancyCard extends StatelessWidget {
  const _VacancyCard(this.vacancy);
  final FunnelVacancy vacancy;

  Widget _metric(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: FolksTheme.heading.copyWith(fontSize: 18)),
        Text(
          label,
          style: const TextStyle(
            color: FolksColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final deadline = vacancy.deadline(now);
    final color = switch (deadline) {
      VacancyDeadline.overdue => FolksColors.red,
      VacancyDeadline.onTime => FolksColors.blue,
      VacancyDeadline.closing => FolksColors.gold,
    };
    final days = vacancy.daysOpen(now);
    final age = days < 0
        ? 'início em ${-days} ${days == -1 ? 'dia' : 'dias'}'
        : 'aberta há $days ${days == 1 ? 'dia' : 'dias'}';
    return Container(
      key: ValueKey('vacancy-${vacancy.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FolksColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  vacancy.role,
                  style: FolksTheme.heading.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    deadline.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cliente: ${vacancy.company} · $age',
            style: const TextStyle(color: FolksColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Pipeline(vacancy.stage),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metric('${vacancy.applicants}', 'INSCRITOS'),
              const SizedBox(width: 8),
              _metric('${vacancy.idealPercentage}%', 'CANDIDATOS IDEAIS'),
              const SizedBox(width: 8),
              _metric('${vacancy.screeningErrors}', 'ERROS TRIAGEM'),
            ],
          ),
        ],
      ),
    );
  }
}
