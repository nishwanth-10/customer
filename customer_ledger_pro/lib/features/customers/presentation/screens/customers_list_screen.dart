import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';
import 'package:customer_ledger_pro/features/customers/presentation/providers/customers_provider.dart';
import 'package:customer_ledger_pro/shared/widgets/shimmer_loader.dart';
import 'package:customer_ledger_pro/shared/widgets/customer_tile.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final _searchController = TextEditingController();
  String? _filterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or mobile...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customersSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (val) =>
                  ref.read(customersSearchProvider.notifier).state = val,
            ),
          ),
          // Status filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: 'All', value: null),
                const SizedBox(width: 8),
                _FilterChip(label: '🔴 Pending', value: 'pending'),
                const SizedBox(width: 8),
                _FilterChip(label: '✅ Paid', value: 'paid'),
                const SizedBox(width: 8),
                _FilterChip(label: '⚠️ Overdue', value: 'overdue'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Customer list
          Expanded(
            child: customersAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 8,
                itemBuilder: (_, __) =>
                    const ShimmerLoader(height: 72, borderRadius: 12),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load customers'),
                    TextButton(
                      onPressed: () => ref.refresh(customersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: AppColors.lightTextHint),
                        const SizedBox(height: 16),
                        Text(
                          'No customers yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.lightTextSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first customer',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.lightTextHint,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(customersProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: customers.length,
                    itemBuilder: (_, i) => CustomerTile(
                      customer: customers[i],
                      onTap: () => context.push('/home/customers/${customers[i]['id']}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/customers/add'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer'),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...[
              ('name', 'Name A–Z'),
              ('due_amount', 'Highest Due'),
              ('last_payment_date', 'Last Payment'),
            ].map((s) => ListTile(
              title: Text(s.$2),
              leading: const Icon(Icons.sort),
              onTap: () {
                ref.read(customersSortProvider.notifier).state = s.$1;
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final String? value;
  const _FilterChip({required this.label, this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(customersFilterStatusProvider);
    final isSelected = current == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) =>
          ref.read(customersFilterStatusProvider.notifier).state = value,
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
    );
  }
}
