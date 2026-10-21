import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../services/data_export_service.dart';
import 'database_provider.dart';

/// Provider for DataExportService accessing the active ObjectBox store asynchronously.
final dataExportServiceProvider = FutureProvider<DataExportService>((ref) async {
  if (AppDatabase.isOpen) {
    return DataExportService(AppDatabase.instance);
  }
  final store = await ref.watch(objectBoxStoreProvider.future);
  return DataExportService(store);
});

/// Synchronous provider for DataExportService when store is already open.
final currentDataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService(AppDatabase.instance);
});
