import 'package:sembast_web/sembast_web.dart';

/// Thin wrapper around a sembast [Database] that persists to IndexedDB on the
/// web. All repositories share the single instance exposed by [AppDatabase].
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'lms_app.db';

  Database? _db;

  final StoreRef<String, Map<String, Object?>> users =
      stringMapStoreFactory.store('users');
  final StoreRef<String, Map<String, Object?>> courses =
      stringMapStoreFactory.store('courses');
  final StoreRef<String, Map<String, Object?>> enrollments =
      stringMapStoreFactory.store('enrollments');
  final StoreRef<String, Map<String, Object?>> notifications =
      stringMapStoreFactory.store('notifications');

  Future<Database> get database async {
    return _db ??= await databaseFactoryWeb.openDatabase(_dbName);
  }
}
