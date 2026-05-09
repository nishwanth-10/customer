import 'package:flutter/material.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';

class CustomerTile extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback? onTap;

  const CustomerTile({super.key, required this.customer, this.onTap});

  Color get _statusColor {
    switch (customer['payment_status']) {
      case 'paid': return AppColors.paidGreen;
      case 'overdue': return AppColors.overdueRed;
      case 'partial': return AppColors.pendingAmber;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (customer['name'] as String?) ?? '';
    final mobile = (customer['mobile_number'] as String?) ?? '';
    final due = (customer['due_amount'] as num?)?.toDouble() ?? 0;
    final status = (customer['payment_status'] as String?) ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    Text(mobile, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightTextSecondary)),
                  ],
                ),
              ),
              // Due amount + status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${due.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: due > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
