// revenue_dashboard_screen.dart
// Dashboard ລາຍຮັບປະຈຳເດືອນ — ເຂື່ອນໄຟຟ້າ

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'create_invoice_screen.dart';
import 'invoice_list_screen.dart';

// ─────────────────────────────────────────────────────────────
// RevenueDashboardScreen
// ─────────────────────────────────────────────────────────────
class RevenueDashboardScreen extends StatefulWidget {
  const RevenueDashboardScreen({super.key});

  @override
  State<RevenueDashboardScreen> createState() => _RevenueDashboardScreenState();
}

class _RevenueDashboardScreenState extends State<RevenueDashboardScreen> {
  int _selectedYear  = 2025;
  int _selectedMonth = 5; // 0=All, 1-12=ເດືອນ

  final List<int> _years = [2023, 2024, 2025];
  final List<String> _monthNames = [
    'ທັງໝົດ', 'ມ.ກ', 'ກ.ພ', 'ມີ.ນ', 'ເມ.ສ',
    'ພ.ພ', 'ມິ.ຖ', 'ກ.ລ', 'ສ.ຫ', 'ກ.ຍ',
    'ຕ.ລ', 'ພ.ຈ', 'ທ.ວ',
  ];

  // ── Mock Data ──
  final List<_MonthlyRevenue> _data2025 = [
    const _MonthlyRevenue(month: 1,  energyUSD: 1540.0, capacityUSD: 375.0, penaltyUSD: 0,     mwh: 28300, status: 'ຊຳລະແລ້ວ'),
    const _MonthlyRevenue(month: 2,  energyUSD: 1380.0, capacityUSD: 375.0, penaltyUSD: 80.0,  mwh: 25100, status: 'ຊຳລະແລ້ວ'),
    const _MonthlyRevenue(month: 3,  energyUSD: 1620.0, capacityUSD: 375.0, penaltyUSD: 0,     mwh: 30200, status: 'ຊຳລະແລ້ວ'),
    const _MonthlyRevenue(month: 4,  energyUSD: 1710.0, capacityUSD: 375.0, penaltyUSD: 120.0, mwh: 31800, status: 'ຊຳລະແລ້ວ'),
    const _MonthlyRevenue(month: 5,  energyUSD: 1671.0, capacityUSD: 375.0, penaltyUSD: 120.0, mwh: 30770, status: 'ລໍຖ້າ'),
    const _MonthlyRevenue(month: 6,  energyUSD: 0,      capacityUSD: 0,     penaltyUSD: 0,     mwh: 0,     status: 'ຍັງບໍ່ມີ'),
    const _MonthlyRevenue(month: 7,  energyUSD: 0,      capacityUSD: 0,     penaltyUSD: 0,     mwh: 0,     status: 'ຍັງບໍ່ມີ'),
    const _MonthlyRevenue(month: 8,  energyUSD: 0,      capacityUSD: 0,     penaltyUSD: 0,     mwh: 0,     status: 'ຍັງບໍ່ມີ'),
    const _MonthlyRevenue(month: 9,  energyUSD: 0,      capacityUSD: 0,     penaltyUSD: 0,     mwh: 0,     status: 'ຍັງບໍ່ມີ'),
    const _MonthlyRevenue(month: 10, energyUSD: 0,      capacityUSD: 0,     penaltyUSD: 0,     mwh: 0,     status: 'ຍັງບໍ່ມີ'),
    const _MonthlyRevenue(month: 11, energyUSD: 0,      capacityUSD: 0,     penaltyUSD: 0,     mwh: 0,     status: 'ຍັງບໍ່ມີ'),
    const _MonthlyRevenue(month: 12, energyUSD: 0,      capacityUSD: 0,     penaltyUSD: 0,     mwh: 0,     status: 'ຍັງບໍ່ມີ'),
  ];

  List<_MonthlyRevenue> get _currentData => _data2025;

  List<_MonthlyRevenue> get _activeData =>
      _currentData.where((d) => d.energyUSD > 0).toList();

  double get _totalEnergy   => _activeData.fold(0, (s, d) => s + d.energyUSD);
  double get _totalCapacity => _activeData.fold(0, (s, d) => s + d.capacityUSD);
  double get _totalPenalty  => _activeData.fold(0, (s, d) => s + d.penaltyUSD);
  double get _totalRevenue  => _totalEnergy + _totalCapacity - _totalPenalty;
  double get _totalMWh      => _activeData.fold(0, (s, d) => s + d.mwh);

  double get _maxBar {
    double max = 0;
    for (final d in _activeData) {
      final t = d.energyUSD + d.capacityUSD;
      if (t > max) max = t;
    }
    return max == 0 ? 1 : max;
  }

  String _fmt(double v) => v.toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtMWh(double v) => v.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color _statusColor(String s) {
    switch (s) {
      case 'ຊຳລະແລ້ວ': return AppColors.success;
      case 'ລໍຖ້າ':    return const Color(0xFFFFB74D);
      default:          return AppColors.textMuted;
    }
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          // Year / Month filter
          _buildFilters(),
          const SizedBox(height: 14),

          // KPI Cards
          _buildKpiRow(),
          const SizedBox(height: 14),

          // Bar Chart
          _buildBarChart(),
          const SizedBox(height: 14),

          // Donut / Breakdown
          _buildBreakdownRow(),
          const SizedBox(height: 14),

          // Monthly Table
          _buildMonthlyTable(),
          const SizedBox(height: 14),

          // Recent Invoices
          _buildRecentInvoices(),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen())),
        backgroundColor: const Color(0xFF81C784),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ສ້າງໃບແຈ້ງໜີ້',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgSecondary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.accent),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF81C784).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF81C784), size: 20),
        ),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dashboard ລາຍຮັບ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text('Revenue Dashboard — Hydropower',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.list_alt_outlined, color: AppColors.accent),
          tooltip: 'ທະບຽນໃບແຈ້ງໜີ້',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const InvoiceListScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: AppColors.accent),
          tooltip: 'Export Report',
          onPressed: _exportReport,
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }

  // ── Filters ──
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        const Icon(Icons.filter_list_outlined, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        const Text('ສະແດງ:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        // Year
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedYear,
            isDense: true,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.accent),
            dropdownColor: AppColors.bgSecondary,
            icon: const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.accent),
            items: _years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) => setState(() => _selectedYear = v!),
          ),
        ),
        const SizedBox(width: 12),
        // Month chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(13, (i) {
                final sel = _selectedMonth == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMonth = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF81C784).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFF81C784)
                              : AppColors.border),
                    ),
                    child: Text(_monthNames[i],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                            color: sel ? const Color(0xFF4CAF50) : AppColors.textSecondary)),
                  ),
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }

  // ── KPI Cards ──
  Widget _buildKpiRow() {
    return LayoutBuilder(builder: (ctx, cons) {
      final cols = cons.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: cols == 4 ? 2.2 : 2.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _kpiCard('ລາຍຮັບລວມ', 'Total Revenue', 'USD ${_fmt(_totalRevenue)}',
              Icons.account_balance_wallet_outlined, const Color(0xFF81C784)),
          _kpiCard('ພະລັງງານ', 'Energy Revenue', 'USD ${_fmt(_totalEnergy)}',
              Icons.bolt_outlined, const Color(0xFF4FC3F7)),
          _kpiCard('MWh ຜະລິດ', 'Total Generated', '${_fmtMWh(_totalMWh)} MWh',
              Icons.electric_meter_outlined, const Color(0xFFFFB74D)),
          _kpiCard('ຫັກ Penalty', 'Deductions', 'USD ${_fmt(_totalPenalty)}',
              Icons.remove_circle_outline, const Color(0xFFF06292)),
        ],
      );
    });
  }

  Widget _kpiCard(String label, String sub, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10,
                fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
            Text(sub, style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis),
          ])),
        ]),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
            color: color), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Bar Chart ──
  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart_outlined, size: 16, color: Color(0xFF81C784)),
          const SizedBox(width: 8),
          const Text('ລາຍຮັບລາຍເດືອນ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const Spacer(),
          // Legend
          _legendDot('Energy', const Color(0xFF4FC3F7)),
          const SizedBox(width: 8),
          _legendDot('Capacity', const Color(0xFF81C784)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _currentData.map((d) {
              final energyH  = d.energyUSD   / _maxBar * 110;
              final capH     = d.capacityUSD / _maxBar * 110;
              final hasData  = d.energyUSD > 0;
              final isSel    = _selectedMonth == d.month;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMonth = d.month),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (hasData && isSel)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF81C784).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_fmt(d.energyUSD + d.capacityUSD - d.penaltyUSD),
                              style: const TextStyle(fontSize: 7, color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w700)),
                        ),
                      const SizedBox(height: 2),
                      // Bars stacked
                      Container(
                        height: hasData ? energyH + capH : 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: hasData
                              ? (isSel ? const Color(0xFF4FC3F7) : const Color(0xFF4FC3F7).withValues(alpha: 0.5))
                              : AppColors.border,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        child: hasData
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  height: capH,
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF81C784) : const Color(0xFF81C784).withValues(alpha: 0.6),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(_monthNames[d.month],
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                              color: isSel ? const Color(0xFF4CAF50) : AppColors.textMuted)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }

  // ── Breakdown Row ──
  Widget _buildBreakdownRow() {
    final subtotal = _totalEnergy + _totalCapacity;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Breakdown bars
      Expanded(
        flex: 3,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ສ່ວນປະກອບລາຍຮັບ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Text('Revenue Breakdown',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            _breakdownBar('ພະລັງງານ (Energy)', _totalEnergy, subtotal, const Color(0xFF4FC3F7)),
            const SizedBox(height: 10),
            _breakdownBar('ກຳລັງ (Capacity)', _totalCapacity, subtotal, const Color(0xFF81C784)),
            const SizedBox(height: 10),
            _breakdownBar('ຫັກ (Penalty)', _totalPenalty, subtotal, const Color(0xFFF06292)),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      // Status Summary
      Expanded(
        flex: 2,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ສະຖານະໃບແຈ້ງໜີ້',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Text('Invoice Status',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            _statusStat('ຊຳລະແລ້ວ', '4 ໃບ', AppColors.success),
            const SizedBox(height: 8),
            _statusStat('ລໍຖ້າຊຳລະ', '1 ໃບ', const Color(0xFFFFB74D)),
            const SizedBox(height: 8),
            _statusStat('ຍັງບໍ່ອອກ', '7 ໃບ', AppColors.textMuted),
            const Divider(height: 20, color: AppColors.border),
            _statusStat('ລວມທັງໝົດ', '12 ໃບ/ປີ', AppColors.accent),
          ]),
        ),
      ),
    ]);
  }

  Widget _breakdownBar(String label, double value, double total, Color color) {
    final pct = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text('USD ${_fmt(value)}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 6,
          backgroundColor: color.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      const SizedBox(height: 2),
      Text('${(pct * 100).toStringAsFixed(1)}% ຂອງລາຍຮັບລວມ',
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
    ]);
  }

  Widget _statusStat(String label, String value, Color color) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  // ── Monthly Table ──
  Widget _buildMonthlyTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            const Icon(Icons.table_chart_outlined, size: 16, color: Color(0xFF81C784)),
            const SizedBox(width: 8),
            const Text('ຕາຕະລາງລາຍຮັບລາຍເດືອນ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Text('ປີ $_selectedYear',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Header
        _tableHeader(),
        const Divider(height: 1, color: AppColors.border),
        // Rows
        ..._currentData.map((d) => _tableRow(d)),
        // Total
        const Divider(height: 1, color: AppColors.border),
        _tableTotalRow(),
      ]),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.bgPrimary,
      child: const Row(children: [
        Expanded(flex: 2, child: Text('ເດືອນ',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text('Energy (USD)',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text('Capacity (USD)',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('MWh',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text('ລວມ (USD)',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary))),
        SizedBox(width: 60, child: Text('ສະຖານະ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary))),
      ]),
    );
  }

  Widget _tableRow(_MonthlyRevenue d) {
    final isSel = _selectedMonth == d.month;
    final total = d.energyUSD + d.capacityUSD - d.penaltyUSD;
    final hasData = d.energyUSD > 0;
    return GestureDetector(
      onTap: () => setState(() => _selectedMonth = d.month),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: isSel ? const Color(0xFF81C784).withValues(alpha: 0.07) : null,
        child: Row(children: [
          Expanded(flex: 2, child: Text(_monthNames[d.month],
              style: TextStyle(fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? const Color(0xFF4CAF50) : AppColors.textPrimary))),
          Expanded(flex: 3, child: Text(hasData ? _fmt(d.energyUSD) : '—',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: hasData ? const Color(0xFF4FC3F7) : AppColors.textMuted))),
          Expanded(flex: 3, child: Text(hasData ? _fmt(d.capacityUSD) : '—',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: hasData ? const Color(0xFF81C784) : AppColors.textMuted))),
          Expanded(flex: 2, child: Text(hasData ? _fmtMWh(d.mwh) : '—',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: hasData ? AppColors.textPrimary : AppColors.textMuted))),
          Expanded(flex: 3, child: Text(hasData ? _fmt(total) : '—',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: hasData ? AppColors.textPrimary : AppColors.textMuted))),
          SizedBox(
            width: 60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(d.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(d.status,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                        color: _statusColor(d.status))),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tableTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF81C784).withValues(alpha: 0.08),
      child: Row(children: [
        const Expanded(flex: 2, child: Text('ລວມ YTD',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: Color(0xFF4CAF50)))),
        Expanded(flex: 3, child: Text(_fmt(_totalEnergy),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFF4FC3F7)))),
        Expanded(flex: 3, child: Text(_fmt(_totalCapacity),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFF81C784)))),
        Expanded(flex: 2, child: Text(_fmtMWh(_totalMWh),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary))),
        Expanded(flex: 3, child: Text(_fmt(_totalRevenue),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                color: Color(0xFF4CAF50)))),
        const SizedBox(width: 60),
      ]),
    );
  }

  // ── Recent Invoices ──
  Widget _buildRecentInvoices() {
    final recent = [
      const _InvoiceRef('INV-2025-05-0042', 'EDL', 'USD 2,118.60', 'ລໍຖ້າ',   '30/06/2025'),
      const _InvoiceRef('INV-2025-04-0038', 'EDL', 'USD 1,965.00', 'ຊຳລະແລ້ວ', '30/05/2025'),
      const _InvoiceRef('INV-2025-03-0031', 'EDL', 'USD 2,210.50', 'ຊຳລະແລ້ວ', '30/04/2025'),
      const _InvoiceRef('INV-2025-02-0024', 'EDL', 'USD 1,898.00', 'ຊຳລະແລ້ວ', '31/03/2025'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF4FC3F7)),
            const SizedBox(width: 8),
            const Text('ໃບແຈ້ງໜີ້ລ່າສຸດ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const InvoiceListScreen())),
              child: const Text('ເບິ່ງທັງໝົດ →',
                  style: TextStyle(fontSize: 11, color: AppColors.accent)),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        ...recent.map((inv) => _invoiceRefRow(inv)),
      ]),
    );
  }

  Widget _invoiceRefRow(_InvoiceRef inv) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF4FC3F7)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(inv.no, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
          Text('${inv.buyer} · ຄົບ ${inv.due}',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(inv.amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(inv.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(inv.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: _statusColor(inv.status))),
          ),
        ]),
      ]),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('ກຳລັງສ້າງ PDF Report... ໃຊ້ printing package', style: TextStyle(fontSize: 12)),
      backgroundColor: Color(0xFF81C784),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ─────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────
class _MonthlyRevenue {
  final int    month;
  final double energyUSD;
  final double capacityUSD;
  final double penaltyUSD;
  final double mwh;
  final String status;

  const _MonthlyRevenue({
    required this.month,
    required this.energyUSD,
    required this.capacityUSD,
    required this.penaltyUSD,
    required this.mwh,
    required this.status,
  });
}

class _InvoiceRef {
  final String no, buyer, amount, status, due;
  const _InvoiceRef(this.no, this.buyer, this.amount, this.status, this.due);
}