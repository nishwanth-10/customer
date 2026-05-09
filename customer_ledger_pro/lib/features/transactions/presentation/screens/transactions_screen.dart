import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';
import 'package:customer_ledger_pro/features/transactions/presentation/providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
        ],
      ),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.lightTextHint),
                  const SizedBox(height: 16),
                  const Text('No transactions yet'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (_, i) => _TransactionCard(transaction: transactions[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/home/transactions/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction['transaction_type'] == 'credit';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final color = isCredit ? AppColors.creditGreen : AppColors.debitRed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: color, size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['description'] ?? (isCredit ? 'Payment Received' : 'Debit'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    transaction['transaction_date'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightTextSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  'Bal: ₹${(transaction['balance_after'] as num?)?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
