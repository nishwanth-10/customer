import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';
import 'package:customer_ledger_pro/features/customers/presentation/providers/customers_provider.dart';
import 'package:customer_ledger_pro/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:customer_ledger_pro/shared/widgets/app_text_field.dart';
import 'package:customer_ledger_pro/shared/widgets/loading_button.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const AddTransactionScreen({super.key, this.customerId});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _type = 'credit';
  DateTime _selectedDate = DateTime.now();
  String? _selectedCustomerId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(transactionNotifierProvider.notifier).addTransaction(
        customerId: _selectedCustomerId!,
        type: _type,
        amount: double.parse(_amountCtrl.text),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        referenceNumber: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved ✓'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Credit / Debit toggle
              Text('Transaction Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: '+ Credit',
                      subtitle: 'Payment received',
                      icon: Icons.south_west_rounded,
                      color: AppColors.creditGreen,
                      isSelected: _type == 'credit',
                      onTap: () => setState(() => _type = 'credit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      label: '- Debit',
                      subtitle: 'Amount given',
                      icon: Icons.north_east_rounded,
                      color: AppColors.debitRed,
                      isSelected: _type == 'debit',
                      onTap: () => setState(() => _type = 'debit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Customer selector (if not preset)
              if (widget.customerId == null) ...[
                Text('Customer', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                customersAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Failed to load customers'),
                  data: (customers) => DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    hint: const Text('Select customer'),
                    decoration: const InputDecoration(),
                    items: customers.map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name'] as String),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCustomerId = v),
                    validator: (v) => v == null ? 'Select a customer' : null,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Amount
              AppTextField(
                controller: _amountCtrl,
                label: 'Amount (₹) *',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      const Spacer(),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _descCtrl,
                label: 'Description (optional)',
                prefixIcon: Icons.note_outlined,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _refCtrl,
                label: 'Reference Number (optional)',
                prefixIcon: Icons.tag,
                hintText: 'UPI/cheque number etc.',
              ),
              const SizedBox(height: 32),

              LoadingButton(onPressed: _save, isLoading: _isLoading, label: 'Save Transaction'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label, required this.subtitle, required this.icon,
    required this.color, required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.lightTextSecondary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? color : null)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
          ],
        ),
      ),
    );
  }
}
