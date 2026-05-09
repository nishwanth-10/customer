import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';
import 'package:customer_ledger_pro/features/customers/presentation/providers/customers_provider.dart';
import 'package:customer_ledger_pro/shared/widgets/shimmer_loader.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (customer) => _CustomerDetailContent(customer: customer),
      ),
    );
  }
}

class _CustomerDetailContent extends ConsumerWidget {
  final Map<String, dynamic> customer;
  const _CustomerDetailContent({required this.customer});

  Color get _statusColor {
    switch (customer['payment_status']) {
      case 'paid': return AppColors.paidGreen;
      case 'overdue': return AppColors.overdueRed;
      case 'partial': return AppColors.pendingAmber;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = customer['name'] ?? '';
    final mobile = customer['mobile_number'] ?? '';
    final due = (customer['due_amount'] as num?)?.toDouble() ?? 0;
    final paid = (customer['total_paid'] as num?)?.toDouble() ?? 0;
    final monthly = (customer['monthly_payment_amount'] as num?)?.toDouble() ?? 0;

    return CustomScrollView(
      slivers: [
        // Sliver app bar with customer avatar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (customer['payment_status'] ?? '').toUpperCase(),
                      style: TextStyle(color: _statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance cards
                Row(
                  children: [
                    Expanded(
                      child: _AmountCard(
                        label: 'Pending',
                        amount: due,
                        color: due > 0 ? AppColors.error : AppColors.success,
                        icon: Icons.pending_actions_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AmountCard(
                        label: 'Total Paid',
                        amount: paid,
                        color: AppColors.secondary,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AmountCard(
                  label: 'Monthly Payment',
                  amount: monthly,
                  color: AppColors.primary,
                  icon: Icons.calendar_month_rounded,
                  fullWidth: true,
                ),
                const SizedBox(height: 20),

                // Quick Actions
                Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: AppColors.success,
                        onTap: () => launchUrl(Uri.parse('tel:$mobile')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.chat_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => launchUrl(Uri.parse(
                            'https://wa.me/${mobile.replaceAll('+', '')}?text=Hello+${Uri.encodeComponent(name)}')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add_circle_rounded,
                        label: 'Add Txn',
                        color: AppColors.primary,
                        onTap: () => context.push(
                          '/home/transactions/add?customer_id=${customer['id']}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.notifications_rounded,
                        label: 'Remind',
                        color: AppColors.warning,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Contact info
                Text('Contact Information', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _InfoTile(icon: Icons.phone, label: 'Mobile', value: mobile),
                if (customer['whatsapp_number'] != null)
                  _InfoTile(icon: Icons.chat, label: 'WhatsApp', value: customer['whatsapp_number']),
                if (customer['email'] != null)
                  _InfoTile(icon: Icons.email, label: 'Email', value: customer['email']),
                if (customer['address'] != null)
                  _InfoTile(icon: Icons.location_on, label: 'Address', value: customer['address']),
                if (customer['notes'] != null && customer['notes'].isNotEmpty)
                  _InfoTile(icon: Icons.note, label: 'Notes', value: customer['notes']),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _AmountCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 12)),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: fullWidth ? 20 : 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, required this.label, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.lightTextSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
