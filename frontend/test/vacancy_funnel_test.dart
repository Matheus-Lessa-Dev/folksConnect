import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/kanban/task.dart';
import 'package:frontend/features/vacancy_funnel/vacancy.dart';
import 'package:frontend/features/vacancy_funnel/vacancy_funnel_controller.dart';
import 'package:frontend/features/vacancy_funnel/vacancy_funnel_screen.dart';
import 'package:frontend/shared/widgets/folks_logo.dart';
import 'package:frontend/features/splash/splash_screen.dart';
import 'package:frontend/main.dart';

Future<void> mount(
  WidgetTester tester,
  VacancyFunnelController controller, {
  Size size = const Size(402, 874),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: FolksTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: VacancyFunnelScreen(controller: controller),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openAuthenticatedWorkspace(WidgetTester tester) async {
  await tester.pumpWidget(const FolksConnectApp());
  await tester.pump();
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(FolksLogo.asset),
      tester.element(find.byType(SplashScreen)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 901));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'joabe@gmail.com');
  await tester.enterText(find.byType(TextFormField).last, '12345');
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  test('prazo considera o dia inteiro e os limites de três dias', () {
    final now = DateTime(2026, 10, 26, 23, 59);
    FunnelVacancy vacancy(DateTime end) => FunnelVacancy(
      id: 'deadline',
      role: 'Analista',
      company: 'Meta',
      profile: 'Perfil',
      assignee: 'Eduarda - Analista',
      start: DateTime(2026, 10, 20),
      end: end,
    );
    expect(
      vacancy(DateTime(2026, 10, 25)).deadline(now),
      VacancyDeadline.overdue,
    );
    expect(
      vacancy(DateTime(2026, 10, 26)).deadline(now),
      VacancyDeadline.closing,
    );
    expect(
      vacancy(DateTime(2026, 10, 29)).deadline(now),
      VacancyDeadline.closing,
    );
    expect(
      vacancy(DateTime(2026, 10, 30)).deadline(now),
      VacancyDeadline.onTime,
    );
    expect(vacancy(DateTime(2026, 10, 30)).daysOpen(now), 6);
  });

  test(
    'cadastro rejeita prazo invertido e mantém indicadores iniciais zerados',
    () {
      final controller = VacancyFunnelController(vacancies: []);
      addTearDown(controller.dispose);
      void create(DateTime end) => controller.add(
        role: 'Analista',
        company: 'Meta',
        profile: 'Perfil',
        assignee: VacancyFunnelController.assignees.first,
        start: DateTime(2026, 10, 26),
        end: end,
        channels: ['LinkedIn'],
      );
      expect(() => create(DateTime(2026, 10, 25)), throwsArgumentError);
      expect(controller.vacancies, isEmpty);
      create(DateTime(2026, 10, 26));
      final vacancy = controller.vacancies.single;
      expect(vacancy.stage, RecruitmentStage.screening);
      expect(vacancy.applicants, 0);
      expect(vacancy.idealPercentage, 0);
      expect(() => vacancy.channels.add('Outro'), throwsUnsupportedError);
    },
  );

  testWidgets('valida, cadastra novo cliente e cria vaga no funil vazio', (
    tester,
  ) async {
    final controller = VacancyFunnelController(vacancies: []);
    addTearDown(controller.dispose);
    await mount(tester, controller);
    expect(find.text('Nenhuma vaga cadastrada.'), findsOneWidget);
    await tester.tap(find.text('+ Vaga'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Cadastrar Vagas'));
    expect(controller.vacancies, isEmpty);
    expect(find.text('Informe o cargo da vaga.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('vacancy-role')),
      'Analista de Dados',
    );
    await tapVisible(
      tester,
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.tap(find.text('+ Novo Cliente').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('client-Empresa')));
    await tester.enterText(
      find.byKey(const ValueKey('client-Empresa')),
      'Empresa Exemplo',
    );
    await tapVisible(tester, find.text('Salvar cliente'));
    expect(controller.clients.last.company, 'Empresa Exemplo');
    await tapVisible(tester, find.byKey(const Key('vacancy-profile')));
    await tester.enterText(
      find.byKey(const Key('vacancy-profile')),
      'Conhecimento em análise de dados.',
    );
    for (final key in ['vacancy-start', 'vacancy-end']) {
      await tapVisible(tester, find.byKey(Key(key)));
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();
    }
    await tapVisible(tester, find.text('LinkedIn'));
    await tapVisible(tester, find.text('Cadastrar Vagas'));
    expect(controller.vacancies, isEmpty);
    expect(
      find.text('Selecione ao menos um canal de divulgação.'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('+ Adicionar'));
    await tester.enterText(find.byType(TextFormField).last, 'Site da empresa');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Cadastrar Vagas'));
    expect(controller.vacancies.single.role, 'Analista de Dados');
    expect(controller.vacancies.single.company, 'Empresa Exemplo');
    expect(controller.vacancies.single.channels, ['Site da empresa']);
    expect(find.text('Cadastrar Vaga'), findsNothing);
    expect(find.text('Analista de Dados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fechar descarta a vaga e cancelar cliente remove o formulário', (
    tester,
  ) async {
    final controller = VacancyFunnelController(vacancies: []);
    addTearDown(controller.dispose);
    await mount(tester, controller);
    await tester.tap(find.text('+ Vaga'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.tap(find.text('+ Novo Cliente').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Cancelar cliente'));
    expect(find.byKey(const ValueKey('client-Empresa')), findsNothing);
    await tapVisible(tester, find.text('Fechar'));
    expect(controller.vacancies, isEmpty);
    expect(controller.clients.length, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navegação entre abas preserva o estado do Kanban e do funil', (
    tester,
  ) async {
    await openAuthenticatedWorkspace(tester);
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Funil de Vagas'));
    await tester.pumpAndSettle();
    expect(find.text('Funil de Vagas'), findsOneWidget);
    expect(find.text('Analista Financeiro Jr.'), findsOneWidget);
    final funnel = tester
        .widget<VacancyFunnelScreen>(find.byType(VacancyFunnelScreen))
        .controller!;
    final today = DateTime.now();
    funnel.add(
      role: 'Vaga preservada',
      company: 'Meta',
      profile: 'Perfil',
      assignee: VacancyFunnelController.assignees.first,
      start: today,
      end: today.add(const Duration(days: 7)),
      channels: ['LinkedIn'],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kanban'));
    await tester.pumpAndSettle();
    final selector = tester.widget<SegmentedButton<bool>>(
      find.byType(SegmentedButton<bool>),
    );
    expect(selector.selected, {true});
    await tester.tap(find.byTooltip('Funil de Vagas'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Vaga preservada'), 200);
    expect(find.text('Vaga preservada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'funil e cadastro ${size.width}x${size.height}, texto ampliado',
      (tester) async {
        final controller = VacancyFunnelController();
        addTearDown(controller.dispose);
        await mount(tester, controller, size: size, textScale: 2);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('+ Vaga'));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('Cadastrar Vagas'));
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text('Fechar'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
