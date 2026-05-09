import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';
import 'package:customer_ledger_pro/features/customers/presentation/providers/customers_provider.dart';
import 'package:customer_ledger_pro/shared/widgets/app_text_field.dart';
import 'package:customer_ledger_pro/shared/widgets/loading_button.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  final _openingBalCtrl = TextEditingController();
  bool _sameAsPhone = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _mobileCtrl.dispose(); _whatsappCtrl.dispose();
    _emailCtrl.dispose(); _addressCtrl.dispose(); _notesCtrl.dispose();
    _monthlyCtrl.dispose(); _openingBalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(customersNotifierProvider.notifier).createCustomer({
        'name': _nameCtrl.text.trim(),
        'mobile_number': _mobileCtrl.text.trim(),
        'whatsapp_number': _sameAsPhone ? _mobileCtrl.text.trim() : _whatsappCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'monthly_payment_amount': double.tryParse(_monthlyCtrl.text) ?? 0,
        'opening_balance': double.tryParse(_openingBalCtrl.text) ?? 0,
        'due_amount': double.tryParse(_openingBalCtrl.text) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer added successfully ✓'), backgroundColor: AppColors.success),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, 'Personal Information'),
              AppTextField(controller: _nameCtrl, label: 'Full Name *', prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Name required' : null),
              const SizedBox(height: 12),
              AppTextField(controller: _mobileCtrl, label: 'Mobile Number *', keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => v == null || v.length < 10 ? 'Enter valid mobile' : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _sameAsPhone,
                    onChanged: (v) => setState(() => _sameAsPhone = v!),
                    activeColor: AppColors.primary,
                  ),
                  const Text('WhatsApp same as mobile'),
                ],
              ),
              if (!_sameAsPhone) ...[
                AppTextField(controller: _whatsappCtrl, label: 'WhatsApp Number', keyboardType: TextInputType.phone,
                    prefixIcon: Icons.chat_outlined),
                const SizedBox(height: 12),
              ],
              AppTextField(controller: _emailCtrl, label: 'Email (optional)', keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined),
              const SizedBox(height: 12),
              AppTextField(controller: _addressCtrl, label: 'Address (optional)', prefixIcon: Icons.location_on_outlined,
                  maxLines: 3),
              const SizedBox(height: 20),

              _sectionHeader(context, 'Payment Information'),
              AppTextField(controller: _monthlyCtrl, label: 'Monthly Payment Amount (₹)',
                  keyboardType: TextInputType.number, prefixIcon: Icons.currency_rupee,
                  hintText: 'e.g. 500'),
              const SizedBox(height: 12),
              AppTextField(controller: _openingBalCtrl, label: 'Opening Balance / Pending Dues (₹)',
                  keyboardType: TextInputType.number, prefixIcon: Icons.account_balance_outlined,
                  hintText: 'Leave 0 if no prior dues'),
              const SizedBox(height: 20),

              _sectionHeader(context, 'Additional Notes'),
              AppTextField(controller: _notesCtrl, label: 'Notes (optional)', prefixIcon: Icons.note_outlined,
                  maxLines: 3),
              const SizedBox(height: 32),

              LoadingButton(onPressed: _save, isLoading: _isLoading, label: 'Save Customer'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w600,
            )),
      );
}
