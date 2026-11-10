import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/auth_controller.dart';
import '../controllers/attachment_controller.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/system_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/vacancy_controller.dart';
import '../controllers/candidate_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/import_controller.dart';
import 'route_guard.dart';

/// All HTTP contracts live here. Controllers adapt HTTP to application services.
Router apiRoutes(
    {required RouteGuard guard,
    required SystemController system,
    required AuthController auth,
    required CatalogController catalogs,
    required UserController users,
    required SettingsController settings,
    required TaskController tasks,
    required AttachmentController attachments,
    required VacancyController vacancies,
    required CandidateController candidates,
    required DashboardController dashboard,
    required ImportController imports}) {
  final router = Router();
  router.get('/api', system.index);
  router.get('/api/health', system.health);
  router.post('/api/auth/login', auth.login);
  router.post('/api/auth/recuperar-senha', auth.recover);
  router.post('/api/auth/redefinir-senha', auth.reset);
  router.post(
      '/api/auth/logout', (Request r) => guard(r, (u) => auth.logout(r, u)));
  router.get(
      '/api/usuarios/me', (Request r) => guard(r, (u) => auth.profile(r, u)));
  router.patch('/api/usuarios/me',
      (Request r) => guard(r, (u) => auth.updateProfile(r, u)));
  for (final name in [
    'cargos',
    'projetos',
    'prioridades',
    'permissoes',
    'clientes',
    'divulgacoes'
  ]) {
    router.get('/api/$name',
        (Request r) => guard(r, (u) => catalogs.list(r, u, name)));
  }
  router.post('/api/clientes',
      (Request r) => guard(r, (u) => catalogs.createClient(r, u)));
  router.post('/api/divulgacoes',
      (Request r) => guard(r, (u) => catalogs.createChannel(r, u)));
  router.get('/api/usuarios', (Request r) => guard(r, (u) => users.list(r, u)));
  router.post(
      '/api/usuarios', (Request r) => guard(r, (u) => users.create(r, u)));
  router.patch('/api/usuarios/<id>',
      (Request r, String id) => guard(r, (u) => users.update(r, u, id)));
  router.delete('/api/usuarios/<id>',
      (Request r, String id) => guard(r, (u) => users.deactivate(r, u, id)));
  router.get(
      '/api/configuracoes', (Request r) => guard(r, (u) => settings.get(r, u)));
  router.put(
      '/api/configuracoes', (Request r) => guard(r, (u) => settings.put(r, u)));
  router.get('/api/tarefas', (Request r) => guard(r, (u) => tasks.list(r, u)));
  router.post(
      '/api/tarefas', (Request r) => guard(r, (u) => tasks.create(r, u)));
  router.get('/api/tarefas/<id>',
      (Request r, String id) => guard(r, (u) => tasks.get(r, u, id)));
  router.patch('/api/tarefas/<id>',
      (Request r, String id) => guard(r, (u) => tasks.update(r, u, id)));
  router.patch('/api/tarefas/<id>/status',
      (Request r, String id) => guard(r, (u) => tasks.move(r, u, id)));
  router.post('/api/tarefas/<id>/avancos',
      (Request r, String id) => guard(r, (u) => tasks.advance(r, u, id)));
  router.post('/api/tarefas/<id>/checklist/itens',
      (Request r, String id) => guard(r, (u) => tasks.addItem(r, u, id)));
  router.patch(
      '/api/tarefas/<id>/checklist/itens/<itemId>',
      (Request r, String id, String item) =>
          guard(r, (u) => tasks.checkItem(r, u, id, item)));
  router.post('/api/tarefas/<id>/anexos',
      (Request r, String id) => guard(r, (u) => attachments.create(r, u, id)));
  router.get(
      '/api/tarefas/<id>/anexos/<anexoId>',
      (Request r, String id, String item) =>
          guard(r, (u) => attachments.download(r, u, id, item)));
  router.delete(
      '/api/tarefas/<id>/anexos/<anexoId>',
      (Request r, String id, String item) =>
          guard(r, (u) => attachments.delete(r, u, id, item)));
  router.get(
      '/api/vagas', (Request r) => guard(r, (u) => vacancies.list(r, u)));
  router.post(
      '/api/vagas', (Request r) => guard(r, (u) => vacancies.create(r, u)));
  router.get('/api/vagas/<id>',
      (Request r, String id) => guard(r, (u) => vacancies.get(r, u, id)));
  router.patch('/api/vagas/<id>',
      (Request r, String id) => guard(r, (u) => vacancies.update(r, u, id)));
  router.get('/api/vagas/<id>/candidatos',
      (Request r, String id) => guard(r, (u) => candidates.list(r, u, id)));
  router.post('/api/vagas/<id>/candidatos',
      (Request r, String id) => guard(r, (u) => candidates.create(r, u, id)));
  router.get(
      '/api/vagas/<id>/candidatos/<candidateId>',
      (Request r, String id, String candidate) =>
          guard(r, (u) => candidates.get(r, u, id, candidate)));
  router.patch(
      '/api/vagas/<id>/candidatos/<candidateId>',
      (Request r, String id, String candidate) =>
          guard(r, (u) => candidates.update(r, u, id, candidate)));
  router.delete(
      '/api/vagas/<id>/candidatos/<candidateId>',
      (Request r, String id, String candidate) =>
          guard(r, (u) => candidates.delete(r, u, id, candidate)));
  router.post(
      '/api/importacoes', (Request r) => guard(r, (u) => imports.create(r, u)));
  router.get('/api/importacoes/<id>',
      (Request r, String id) => guard(r, (u) => imports.get(r, u, id)));
  router.get('/api/dashboard/atividades',
      (Request r) => guard(r, (u) => dashboard.activities(r, u)));
  router.get('/api/dashboard/entregas',
      (Request r) => guard(r, (u) => dashboard.deliveries(r, u)));
  return router;
}
