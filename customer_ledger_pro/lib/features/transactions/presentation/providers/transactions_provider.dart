import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_ledger_pro/core/network/dio_client.dart';
import 'package:customer_ledger_pro/core/storage/local_storage.dart';

final transactionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, customerId) async {
  final businessId = LocalStorage.getSetting<String>('business_id') ?? '';
  if (businessId.isEmpty) return [];

  final dio = ref.read(dioProvider);
  final params = <String, dynamic>{'business_id': businessId};
  if (customerId != null) params['customer_id'] = customerId;

  try {
    final response = await dio.get('/transactions', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return LocalStorage.getCachedTransactions().cast<Map<String, dynamic>>();
  }
});

class TransactionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addTransaction({
    required String customerId,
    required String type,
    required double amount,
    String? description,
    String? referenceNumber,
    required String date,
  }) async {
    final businessId = LocalStorage.getSetting<String>('business_id') ?? '';
    final dio = ref.read(dioProvider);
    await dio.post('/transactions', data: {
      'business_id': businessId,
      'customer_id': customerId,
      'transaction_type': type,
      'amount': amount,
      'description': description,
      'reference_number': referenceNumber,
      'transaction_date': date,
    });
    ref.invalidate(transactionsProvider);
  }
}

final transactionNotifierProvider = AsyncNotifierProvider<TransactionNotifier, void>(
  TransactionNotifier.new,
);
