import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_ledger_pro/core/network/dio_client.dart';
import 'package:customer_ledger_pro/core/storage/local_storage.dart';

// Search query provider
final customersSearchProvider = StateProvider<String>((ref) => '');
// Filter status provider
final customersFilterStatusProvider = StateProvider<String?>((ref) => null);
// Sort provider
final customersSortProvider = StateProvider<String>((ref) => 'name');

// Main customers provider
final customersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final businessId = LocalStorage.getSetting<String>('business_id') ?? '';
  final search = ref.watch(customersSearchProvider);
  final status = ref.watch(customersFilterStatusProvider);
  final sortBy = ref.watch(customersSortProvider);

  if (businessId.isEmpty) return [];

  final dio = ref.read(dioProvider);
  final params = <String, dynamic>{'business_id': businessId, 'sort_by': sortBy};
  if (search.isNotEmpty) params['search'] = search;
  if (status != null) params['status'] = status;

  try {
    final response = await dio.get('/customers', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    
    // Cache in Hive for offline access
    await LocalStorage.cacheCustomers(items);
    return items;
  } catch (_) {
    // Return cached data if offline
    return LocalStorage.getCachedCustomers().cast<Map<String, dynamic>>();
  }
});

// Single customer provider
final customerDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/customers/$id');
  return response.data as Map<String, dynamic>;
});

// Customer notifier for CRUD
class CustomersNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createCustomer(Map<String, dynamic> data) async {
    final businessId = LocalStorage.getSetting<String>('business_id') ?? '';
    final dio = ref.read(dioProvider);
    await dio.post('/customers', data: {...data, 'business_id': businessId});
    ref.invalidate(customersProvider);
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    final dio = ref.read(dioProvider);
    await dio.put('/customers/$id', data: data);
    ref.invalidate(customersProvider);
    ref.invalidate(customerDetailProvider(id));
  }

  Future<void> deleteCustomer(String id) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/customers/$id');
    await LocalStorage.deleteCachedCustomer(id);
    ref.invalidate(customersProvider);
  }
}

final customersNotifierProvider = AsyncNotifierProvider<CustomersNotifier, void>(
  CustomersNotifier.new,
);
