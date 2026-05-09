import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';
import 'package:customer_ledger_pro/core/network/dio_client.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/admin/stats');
      setState(() { _stats = response.data as Map<String, dynamic>; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Admin notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Super Admin Area', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats grid
                if (_stats != null) ...[
                  Text('Platform Statistics', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _AdminStatCard('Total Users', '${_stats!['total_users'] ?? 0}', Icons.people, AppColors.primary),
                      _AdminStatCard('Total Businesses', '${_stats!['total_businesses'] ?? 0}', Icons.business, AppColors.secondary),
                      _AdminStatCard('Active Businesses', '${_stats!['active_businesses'] ?? 0}', Icons.check_circle, AppColors.success),
                      _AdminStatCard('Suspended', '${_stats!['suspended_businesses'] ?? 0}', Icons.block, AppColors.error),
                      _AdminStatCard('Total Customers', '${_stats!['total_customers'] ?? 0}', Icons.people_outline, AppColors.accent),
                      _AdminStatCard('Total Transactions', '${_stats!['total_transactions'] ?? 0}', Icons.receipt_long, AppColors.warning),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _AdminActionTile(icon: Icons.business_outlined, label: 'Manage Businesses', onTap: () {}),
                _AdminActionTile(icon: Icons.people_outlined, label: 'Manage Users', onTap: () {}),
                _AdminActionTile(icon: Icons.subscriptions_outlined, label: 'Subscriptions', onTap: () {}),
                _AdminActionTile(icon: Icons.bar_chart_rounded, label: 'Platform Analytics', onTap: () {}),
                _AdminActionTile(icon: Icons.notifications_outlined, label: 'Broadcast Notification', onTap: () {}),
              ],
            ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _AdminStatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
