import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../services/quote_service.dart';
import 'database_provider.dart';

/// Provider for QuoteService accessing the current ObjectBox store.
final quoteServiceProvider = FutureProvider<QuoteService>((ref) async {
  if (AppDatabase.isOpen) {
    return QuoteService(AppDatabase.instance);
  }
  final store = await ref.watch(objectBoxStoreProvider.future);
  return QuoteService(store);
});

/// Synchronous provider for QuoteService using AppDatabase.instance when store is already open.
final currentQuoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService(AppDatabase.instance);
});
