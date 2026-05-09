import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';
import 'package:customer_ledger_pro/core/storage/local_storage.dart';
import 'package:customer_ledger_pro/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;
  bool _isExporting = false;

  Future<void> _loadReport() async {
    setState(() { _isLoading = true; _reportData = null; });
    try {
      final businessId = LocalStorage.getSetting<String>('business_id') ?? '';
      final dio = ref.read(dioProvider);
      final response = await dio.get('/reports/monthly-summary', queryParameters: {
        'business_id': businessId,
        'month': _selectedMonth,
        'year': _selectedYear,
      });
      setState(() => _reportData = response.data as Map<String, dynamic>);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final businessId = LocalStorage.getSetting<String>('business_id') ?? '';
      final dio = ref.read(dioProvider);
      final response = await dio.get('/reports/export/pdf',
          queryParameters: {'business_id': businessId, 'month': _selectedMonth, 'year': _selectedYear},
          options: Options(responseType: ResponseType.bytes));
      // In real app: save to file and open with open_file package
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF downloaded ✓'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          if (_reportData != null)
            IconButton(
              icon: _isExporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _isExporting ? null : _exportPdf,
              tooltip: 'Export PDF',
            ),
        ],
      ),
      body: Column(
        children: [
          // Month / Year picker
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(months[i]),
                    )),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    items: List.generate(5, (i) {
                      final year = DateTime.now().year - i;
                      return DropdownMenuItem(value: year, child: Text('$year'));
                    }),
                    onChanged: (v) => setState(() => _selectedYear = v!),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loadReport,
                  child: const Text('Load'),
                ),
              ],
            ),
          ),
          // Report content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reportData == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bar_chart, size: 80, color: AppColors.lightTextHint),
                            const SizedBox(height: 16),
                            const Text('Select month and tap Load'),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadReport, child: const Text('Load Report')),
                          ],
                        ),
                      )
                    : _ReportContent(data: _reportData!),
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReportContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'Total Customers', value: '${data['total_customers'] ?? 0}', icon: Icons.people_rounded, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'Paid', value: '${data['paid_customers'] ?? 0}', icon: Icons.check_circle, color: AppColors.success)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'Collected', value: '₹${(data['total_collected'] as num?)?.toStringAsFixed(0) ?? 0}', icon: Icons.trending_up, color: AppColors.secondary)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'Pending', value: '₹${(data['total_pending'] as num?)?.toStringAsFixed(0) ?? 0}', icon: Icons.pending_actions, color: AppColors.warning)),
          ],
        ),
        const SizedBox(height: 20),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
              Expanded(child: Text('Due', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
              Expanded(child: Text('Paid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
              Expanded(child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center)),
            ],
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final item = entry.value as Map;
          final isEven = entry.key % 2 == 0;
          final statusColor = item['status'] == 'paid' ? AppColors.paidGreen : item['status'] == 'partial' ? AppColors.pendingAmber : AppColors.debitRed;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: isEven ? null : AppColors.lightSurfaceVariant.withOpacity(0.5),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 13))),
                Expanded(child: Text('₹${(item['monthly_due'] as num?)?.toStringAsFixed(0) ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                Expanded(child: Text('₹${(item['collected'] as num?)?.toStringAsFixed(0) ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppColors.creditGreen))),
                Expanded(child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text((item['status'] ?? '').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ))),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
