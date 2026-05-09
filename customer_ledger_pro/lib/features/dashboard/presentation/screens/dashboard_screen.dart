import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';
import 'package:customer_ledger_pro/core/router/app_router.dart';
import 'package:customer_ledger_pro/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:customer_ledger_pro/shared/widgets/stat_card.dart';
import 'package:customer_ledger_pro/shared/widgets/shimmer_loader.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashAsync.when(
          loading: () => const DashboardShimmer(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load: $e'),
                TextButton(
                  onPressed: () => ref.refresh(dashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (data) => _DashboardContent(data: data),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/transactions/add'),
        icon: const Icon(Icons.add),
        label: const Text('New Transaction'),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final monthlyTrend = (data['monthly_trend'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Today\'s Collection',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${_fmt(data['today_collection'])}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stats grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StatCard(
              title: 'Total Customers',
              value: '${data['total_customers'] ?? 0}',
              icon: Icons.people_rounded,
              color: AppColors.primary,
              subtitle: '${data['pending_customers'] ?? 0} pending',
            ),
            StatCard(
              title: 'Pending Amount',
              value: '₹${_fmt(data['total_pending_amount'])}',
              icon: Icons.pending_actions_rounded,
              color: AppColors.warning,
              subtitle: 'Total dues',
            ),
            StatCard(
              title: 'This Month',
              value: '₹${_fmt(data['monthly_collection'])}',
              icon: Icons.calendar_month_rounded,
              color: AppColors.secondary,
              subtitle: 'Collected',
            ),
            StatCard(
              title: 'Total Income',
              value: '₹${_fmt(data['total_income'])}',
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
              subtitle: 'All time',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Monthly trend chart
        if (monthlyTrend.isNotEmpty) ...[
          Text(
            'Monthly Collections',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: BarChart(
              BarChartData(
                barGroups: monthlyTrend.asMap().entries.map((e) {
                  final value = (e.value['collection'] as num?)?.toDouble() ?? 0;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < monthlyTrend.length) {
                          return Text(
                            monthlyTrend[idx]['month_name'] ?? '',
                            style: const TextStyle(fontSize: 11),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Recent Transactions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(data['recent_transactions'] as List? ?? []).map((t) {
          final isCredit = t['type'] == 'credit';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isCredit ? AppColors.creditGreen : AppColors.debitRed).withOpacity(0.1),
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? AppColors.creditGreen : AppColors.debitRed,
                ),
              ),
              title: Text(t['description'] ?? (isCredit ? 'Payment received' : 'Debit'),
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(t['date'] ?? ''),
              trailing: Text(
                '${isCredit ? '+' : '-'}₹${_fmt(t['amount'])}',
                style: TextStyle(
                  color: isCredit ? AppColors.creditGreen : AppColors.debitRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  String _fmt(dynamic value) {
    if (value == null) return '0';
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 100000) return '${(num / 100000).toStringAsFixed(1)}L';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }
}

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerLoader(height: 120, borderRadius: 20),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: List.generate(4, (_) => ShimmerLoader(height: 100, borderRadius: 16)),
        ),
      ],
    );
  }
}
