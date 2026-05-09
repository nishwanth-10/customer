import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_ledger_pro/core/network/dio_client.dart';
import 'package:customer_ledger_pro/core/storage/local_storage.dart';

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final businessId = LocalStorage.getSetting<String>('business_id') ?? '';
  if (businessId.isEmpty) return {};

  final dio = ref.read(dioProvider);
  final response = await dio.get('/dashboard', queryParameters: {
    'business_id': businessId,
  });
  return response.data as Map<String, dynamic>;
});
