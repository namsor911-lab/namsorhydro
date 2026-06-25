// invoice_list_screen.dart
// ທະບຽນໃບແຈ້ງໜີ້ທັງໝົດ

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────
class _InvoiceItem {
  final String no;
  final String buyer;
  final String amount;
  final String status;
  final String dueDate;
  final String issueDate;

  const _InvoiceItem({
    required this.no,
    required this.buyer,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.issueDate,
  });
}

// ─────────────────────────────────────────────────────────────
// InvoiceListScreen
// ─────────────────────────────────────────────────────────────
class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _searchQuery = '';
  String _filterStatus = 'ທັງໝົດ';

  final List<_InvoiceItem> _invoices = const [
    _InvoiceItem(
      no: 'INV-2025-05-0042',
      buyer: 'EDL',
      amount: 'USD 2,118.60',
      status: 'ລໍຖ້າ',
      dueDate: '30/06/2025',
      issueDate: '01/06/2025',
    ),
    _InvoiceItem(
      no: 'INV-2025-04-0038',
      buyer: 'EDL',
      amount: 'USD 1,965.00',
      status: 'ຊຳລະແລ້ວ',
      dueDate: '30/05/2025',
      issueDate: '01/05/2025',
    ),
    _InvoiceItem(
      no: 'INV-2025-03-0031',
      buyer: 'EDL',
      amount: 'USD 2,210.50',
      status: 'ຊຳລະແລ້ວ',
      dueDate: '30/04/2025',
      issueDate: '01/04/2025',
    ),
    _InvoiceItem(
      no: 'INV-2025-02-0024',
      buyer: 'EDL',
      amount: 'USD 1,898.00',
      status: 'ຊຳລະແລ້ວ',
      dueDate: '31/03/2025',
      issueDate: '01/03/2025',
    ),
    _InvoiceItem(
      no: 'INV-2025-01-0018',
      buyer: 'EDL',
      amount: 'USD 2,052.50',
      status: 'ຊຳລະແລ້ວ',
      dueDate: '28/02/2025',
      issueDate: '01/02/2025',
    ),
  ];

  List<_InvoiceItem> get _filtered {
    return _invoices.where((inv) {
      final matchSearch = _searchQuery.isEmpty ||
          inv.no.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inv.buyer.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus =
          _filterStatus == 'ທັງໝົດ' || inv.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ຊຳລະແລ້ວ':
        return AppColors.success;
      case 'ລໍຖ້າ':
        return const Color(0xFFFFB74D);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ທະບຽນໃບແຈ້ງໜີ້',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Invoice Registry',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // ── Search & Filter ──
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.bgSecondary,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'ຄົ້ນຫາເລກໃບແຈ້ງໜີ້...',
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textMuted, size: 18),
                      filled: true,
                      fillColor: AppColors.bgPrimary,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      isDense: true,
                      dropdownColor: AppColors.bgSecondary,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                      items: ['ທັງໝົດ', 'ຊຳລະແລ້ວ', 'ລໍຖ້າ']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _filterStatus = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Count ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  'ພົບ ${_filtered.length} ລາຍການ',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // ── List ──
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'ບໍ່ພົບໃບແຈ້ງໜີ້',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildCard(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_InvoiceItem inv) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF4FC3F7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined,
                size: 18, color: Color(0xFF4FC3F7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.no,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${inv.buyer} · ອອກ ${inv.issueDate} · ຄົບ ${inv.dueDate}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                inv.amount,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(inv.status)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  inv.status,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(inv.status)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}