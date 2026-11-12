import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'config/app_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/attachment_controller.dart';
import 'controllers/catalog_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/system_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/vacancy_controller.dart';
import 'controllers/candidate_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/import_controller.dart';
import 'database.dart';
import 'middleware/api_middleware.dart';
import 'repositories/system_repository.dart';
import 'routes/api_routes.dart';
import 'routes/route_guard.dart';
import 'services/auth_service.dart';
import 'services/attachments_service.dart';
import 'services/catalogs_service.dart';
import 'services/settings_service.dart';
import 'services/tasks_service.dart';
import 'services/users_service.dart';
import 'services/vacancies_service.dart';
import 'services/candidates_service.dart';
import 'services/dashboard_service.dart';
import 'services/imports_service.dart';

/// Composition root: creates dependencies; routes and business logic live in their layers.
class Application {
  final Database db;
  final Map<String, String> env;
  late final AuthService auth = AuthService(db, env);
  late final Router router = apiRoutes(
    guard: RouteGuard(auth),
    system: SystemController(SystemRepository(db)),
    auth: AuthController(auth),
    catalogs: CatalogController(CatalogService(db)),
    users: UserController(UserService(db, auth)),
    settings: SettingsController(SettingsService(db)),
    tasks: TaskController(TaskService(db)),
    attachments: AttachmentController(AttachmentService(db)),
    vacancies: VacancyController(VacancyService(db)),
    candidates: CandidateController(CandidateService(db)),
    dashboard: DashboardController(DashboardService(db)),
    imports: ImportController(ImportService(db, VacancyService(db))),
  );
  late final ApiMiddleware middleware = ApiMiddleware(router, AppConfig(env));
  Application(this.db, this.env);
  Future<Response> call(Request request) => middleware.call(request);
}
