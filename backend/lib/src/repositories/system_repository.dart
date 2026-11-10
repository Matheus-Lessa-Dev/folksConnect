import '../database.dart';

class SystemRepository {
  final Database db;
  SystemRepository(this.db);
  Future<void> health() async {
    await db.one('SELECT 1');
  }
}
