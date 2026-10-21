import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/database/app_database.dart';
import '../../objectbox.g.dart';

part 'database_provider.g.dart';

// Instantiates and provides the ObjectBox database connection (Store).
// 3.
@Riverpod(keepAlive: true)
Future<Store> objectBoxStore(ObjectBoxStoreRef ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final store = await AppDatabase.openStore(directory: dir.path);
  ref.onDispose(() => AppDatabase.closeStore());
  return store;
}
