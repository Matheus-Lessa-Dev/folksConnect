import '../database.dart';
import '../dto/dashboard_filter.dart';
import '../dto/input.dart';
import '../repositories/dashboard_repository.dart';

class DashboardService {
  final Database db;
  final DashboardRepository repository = DashboardRepository();
  DashboardService(this.db);
  Future<Row> activities(QueryInput query) =>
      repository.activities(db, DashboardFilter.parse(query));
  Future<Row> deliveries(QueryInput query) =>
      repository.deliveries(db, DashboardFilter.parse(query));
}
