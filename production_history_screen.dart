import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color kBg = Color(0xFF0A0E1A);
const Color kSurface = Color(0xFF111827);
const Color kSurface2 = Color(0xFF1A2236);
const Color kBorder = Color(0xFF1E3A5F);
const Color kAccent = Color(0xFF00D4FF);
const Color kAccent2 = Color(0xFF00FF9D);
const Color kAccent3 = Color(0xFFFF6B35);
const Color kText = Color(0xFFE2E8F0);
const Color kTextDim = Color(0xFF64748B);
const Color kTextBright = Color(0xFFF8FAFC);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kYellow = Color(0xFFF59E0B);
const Color kPurple = Color(0xFFA78BFA);
const Color kRowAlt = Color(0xFF0D1A2D);
const Color kHeaderBg = Color(0xFF0F1E35);

class EnergyRow {
  final int hour;
  double? mmExpKwh;
  double? mmExpKvarh;
  double? mmImpKwh;
  double? mmImpKvarh;
  double? bmExpKwh;
  double? bmExpKvarh;
  double? bmImpKwh;
  double? bmImpKvarh;
  final double unitExp;
  final double unitImp;

  EnergyRow({required this.hour})
      : unitExp = 0,
        unitImp = 0;

  String get timeLabel {
    final hh = hour.toString().padLeft(2, '0');
    return '$hh:00';
  }
}

class DailySummary {
  final DateTime date;
  final String dateKey;
  final double? lastMmExpKwh;
  final double? lastMmExpKvarh;
  final double? lastMmImpKwh;
  final double? lastMmImpKvarh;
  final double? lastBmExpKwh;
  final double? lastBmExpKvarh;
  final double? lastBmImpKwh;
  final double? lastBmImpKvarh;
  final double totalEnergyExpKwh;
  final double totalEnergyImpKwh;
  final double totalUnitExp;
  final double totalUnitImp;
  final double totalMw;
  final String lastEntryTime;

  const DailySummary({
    required this.date,
    required this.dateKey,
    this.lastMmExpKwh,
    this.lastMmExpKvarh,
    this.lastMmImpKwh,
    this.lastMmImpKvarh,
    this.lastBmExpKwh,
    this.lastBmExpKvarh,
    this.lastBmImpKwh,
    this.lastBmImpKvarh,
    required this.totalEnergyExpKwh,
    required this.totalEnergyImpKwh,
    required this.totalUnitExp,
    required this.totalUnitImp,
    required this.totalMw,
    required this.lastEntryTime,
  });

  bool get hasData =>
      lastMmExpKwh != null ||
      lastBmExpKwh != null ||
      totalEnergyExpKwh > 0;
}

class ProductionHistoryScreen extends StatefulWidget {
  final Map<String, List<EnergyRow>> dataByDate;
  final DateTime referenceDate;

  const ProductionHistoryScreen({
    super.key,
    required this.dataByDate,
    required this.referenceDate,
  });

  @override
  State<ProductionHistoryScreen> createState() =>
      _ProductionHistoryScreenState();
}

class _ProductionHistoryScreenState extends State<ProductionHistoryScreen> {
  late List<DailySummary> _summaries;
  int? _selectedIdx;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _summaries = _buildSummaries();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  List<DailySummary> _buildSummaries() {
    final ref = widget.referenceDate;
    final daysInMonth = DateTime(ref.year, ref.month + 1, 0).day;
    final List<DailySummary> result = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(ref.year, ref.month, day);
      final key = DateFormat('yyyy-MM-dd').format(date);
      final rows = widget.dataByDate[key];

      if (rows == null || rows.isEmpty) {
        result.add(DailySummary(
          date: date,
          dateKey: key,
          totalEnergyExpKwh: 0,
          totalEnergyImpKwh: 0,
          totalUnitExp: 0,
          totalUnitImp: 0,
          totalMw: 0,
          lastEntryTime: '—',
        ));
        continue;
      }

      EnergyRow? lastFilledRow;
      for (int r = rows.length - 1; r >= 0; r--) {
        if (rows[r].mmExpKwh != null || rows[r].bmExpKwh != null) {
          lastFilledRow = rows[r];
          break;
        }
      }

      double totalEExpKwh = 0,
          totalEImpKwh = 0,
          totalUnitExp = 0,
          totalUnitImp = 0,
          totalMw = 0;

      for (int r = 1; r < rows.length; r++) {
        final cur = rows[r];
        final prv = rows[r - 1];
        double? diff(double? c, double? p) {
          if (c == null || p == null) return null;
          final d = c - p;
          return d < 0 ? 0 : d;
        }

        final eExp = diff(cur.mmExpKwh, prv.mmExpKwh) ?? 0;
        final eImp = diff(cur.mmImpKwh, prv.mmImpKwh) ?? 0;
        totalEExpKwh += eExp;
        totalEImpKwh += eImp;
        totalUnitExp += cur.unitExp;
        totalUnitImp += cur.unitImp;
        totalMw += eExp / 1000;
      }

      result.add(DailySummary(
        date: date,
        dateKey: key,
        lastMmExpKwh: lastFilledRow?.mmExpKwh,
        lastMmExpKvarh: lastFilledRow?.mmExpKvarh,
        lastMmImpKwh: lastFilledRow?.mmImpKvarh,
        lastMmImpKvarh: lastFilledRow?.mmImpKvarh,
        lastBmExpKwh: lastFilledRow?.bmExpKwh,
        lastBmExpKvarh: lastFilledRow?.bmExpKvarh,
        lastBmImpKwh: lastFilledRow?.bmImpKvarh,
        lastBmImpKvarh: lastFilledRow?.bmImpKvarh,
        totalEnergyExpKwh: totalEExpKwh,
        totalEnergyImpKwh: totalEImpKwh,
        totalUnitExp: totalUnitExp,
        totalUnitImp: totalUnitImp,
        totalMw: totalMw,
        lastEntryTime: lastFilledRow != null ? lastFilledRow.timeLabel : '—',
      ));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kAccent, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRODUCTION HISTORY',
              style: TextStyle(
                color: kAccent,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              '👑 ຂໍ້ມູນການຜະລິດ ປະຈຳເດືອນ ${DateFormat('MM/yyyy').format(widget.referenceDate)}',
              style: const TextStyle(color: kTextDim, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_summaries.length} ວັນ',
                  style: const TextStyle(color: kAccent, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Column(
            children: [
              _buildLegend(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryTotals(),
                      const SizedBox(height: 16),
                      _buildTableCard(),
                      if (_selectedIdx != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailCard(_summaries[_selectedIdx!]),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: kSurface2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Wrap(
        spacing: 20,
        runSpacing: 6,
        children: [
          _LegendDot(color: kAccent, text: 'ຕົວເລກ Meter ລ່າສຸດ ທີ່ປ້ອນເຂົ້າ'),
          _LegendDot(color: kAccent2, text: 'ຍອດ Energy ລວມທັງວັນ'),
          _LegendDot(color: kYellow, text: 'ຍອດ Unit ທັງໝົດ'),
          _LegendDot(color: kPurple, text: 'ຍອດ Mw ລວມ'),
        ],
      ),
    );
  }

  Widget _buildSummaryTotals() {
    double grand30ExpKwh = 0,
        grand30ImpKwh = 0,
        grand30UnitExp = 0,
        grand30UnitImp = 0,
        grand30Mw = 0;

    int daysWithData = 0;
    for (final s in _summaries) {
      if (s.hasData) {
        daysWithData++;
        grand30ExpKwh += s.totalEnergyExpKwh;
        grand30ImpKwh += s.totalEnergyImpKwh;
        grand30UnitExp += s.totalUnitExp;
        grand30UnitImp += s.totalUnitImp;
        grand30Mw += s.totalMw;
      }
    }

    final numFmt = NumberFormat('0.###');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 16, color: kAccent),
              const SizedBox(width: 8),
              Text(
                'ສະຫຼຸບລວມເດືອນ ${DateFormat('MM/yyyy').format(widget.referenceDate)}',
                style: const TextStyle(
                    color: kAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '$daysWithData / ${_summaries.length} ວັນ ມີຂໍ້ມູນ',
                  style: const TextStyle(color: kAccent, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniStat(
                label: 'Energy Export',
                value: numFmt.format(grand30ExpKwh),
                unit: 'Kw/h',
                color: kAccent,
              ),
              _MiniStat(
                label: 'Energy Import',
                value: numFmt.format(grand30ImpKwh),
                unit: 'Kw/h',
                color: kAccent2,
              ),
              _MiniStat(
                label: 'Unit Export',
                value: numFmt.format(grand30UnitExp),
                unit: 'ຫົວໜ່ວຍ',
                color: kYellow,
              ),
              _MiniStat(
                label: 'Unit Import',
                value: numFmt.format(grand30UnitImp),
                unit: 'ຫົວໜ່ວຍ',
                color: kYellow,
              ),
              _MiniStat(
                label: 'Total Mw',
                value: grand30Mw.toStringAsFixed(3),
                unit: 'Mw',
                color: kPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool fitsFullWidth = constraints.maxWidth >= _tableTotalWidth;

        Widget header() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: kHeaderBg,
              child: const Row(
                children: [
                  Text(
                    '📋  ຕາຕະລາງການຜະລິດລາຍວັນ',
                    style: TextStyle(
                        color: kTextBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Text(
                    'ກົດແຖວເພື່ອດູລາຍລະອຽດ',
                    style: TextStyle(color: kTextDim, fontSize: 10),
                  ),
                ],
              ),
            );

        final card = Container(
          width: fitsFullWidth ? constraints.maxWidth : _tableTotalWidth,
          decoration: BoxDecoration(
            color: kSurface,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header(),
              _buildTable(useFlex: fitsFullWidth),
            ],
          ),
        );

        if (fitsFullWidth) {
          return card;
        }

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 12),
            child: card,
          ),
        );
      },
    );
  }

  static const double _dateW = 100;
  static const double _timeW = 65;
  static const double _numW = 90;
  static const double _smallW = 75;

  double get _tableTotalWidth => _dateW + _timeW + (8 * _numW) + (5 * _smallW);

  Widget _buildTable({bool useFlex = false}) {
    final numFmt = NumberFormat('0.##');
    const double dateW = _dateW;
    const double timeW = _timeW;
    const double numW = _numW;
    const double smallW = _smallW;

    final Map<int, TableColumnWidth> columnWidths = useFlex
        ? {
            0: const FlexColumnWidth(dateW),
            1: const FlexColumnWidth(timeW),
            for (int i = 2; i <= 9; i++) i: const FlexColumnWidth(numW),
            for (int i = 10; i <= 14; i++) i: const FlexColumnWidth(smallW),
          }
        : {
            0: const FixedColumnWidth(dateW),
            1: const FixedColumnWidth(timeW),
            for (int i = 2; i <= 9; i++) i: const FixedColumnWidth(numW),
            for (int i = 10; i <= 14; i++) i: const FixedColumnWidth(smallW),
          };

    return Table(
      columnWidths: columnWidths,
      border: TableBorder.all(color: const Color(0x4D1E3A5F), width: 0.5),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF060D1A)),
          children: [
            _th('ວັນທີ', color: kTextBright),
            _th('ເວລາ\nລ່າສຸດ', color: kTextDim),
            ..._thSpan('Main Meter (ລ່າສຸດ)', kAccent, 4),
            ..._thSpan('Backup Meter (ລ່າສຸດ)', kAccent2, 4),
            _th('Energy\nExp Kw/h', color: kAccent2),
            _th('Energy\nImp Kw/h', color: kAccent2),
            _th('Unit\nExp', color: kYellow),
            _th('Unit\nImp', color: kYellow),
            _th('Mw\nລວມ', color: kPurple),
          ],
        ),
        TableRow(
          decoration: const BoxDecoration(color: kHeaderBg),
          children: [
            _th(''),
            _th(''),
            _th('Exp Kw/h', color: kTextDim, small: true),
            _th('Exp Kvar/h', color: kTextDim, small: true),
            _th('Imp Kw/h', color: kTextDim, small: true),
            _th('Imp Kvar/h', color: kTextDim, small: true),
            _th('Exp Kw/h', color: kTextDim, small: true),
            _th('Exp Kvar/h', color: kTextDim, small: true),
            _th('Imp Kw/h', color: kTextDim, small: true),
            _th('Imp Kvar/h', color: kTextDim, small: true),
            _th(''),
            _th(''),
            _th(''),
            _th(''),
            _th(''),
          ],
        ),
        for (int i = 0; i < _summaries.length; i++) _buildRow(i, numFmt),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  TableRow _buildRow(int i, NumberFormat numFmt) {
    final s = _summaries[i];
    final isToday = _isSameDay(s.date, DateTime.now());
    final isSelected = _selectedIdx == i;
    final hasData = s.hasData;

    Color rowBg = i % 2 == 0 ? kRowAlt : kSurface;
    if (isToday) rowBg = kAccent.withValues(alpha: 0.05);
    if (isSelected) rowBg = kAccent.withValues(alpha: 0.12);
    if (!hasData) rowBg = kBg.withValues(alpha: 0.4);

    String fmt(double? v) => numFmt.format(v ?? 0);

    final dateLabel = DateFormat('dd/MM').format(s.date);

    return TableRow(
      decoration: BoxDecoration(color: rowBg),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: InkWell(
            onTap: () => setState(() {
              _selectedIdx = isSelected ? null : i;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Row(
                children: [
                  if (isToday)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
                    ),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        color: isToday ? kAccent : kText,
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _cell(s.lastEntryTime, color: hasData ? kAccent3 : kTextDim, bold: false),
        _cell(fmt(s.lastMmExpKwh), color: s.lastMmExpKwh != null ? kAccent : kTextDim),
        _cell(fmt(s.lastMmExpKvarh), color: s.lastMmExpKvarh != null ? kAccent : kTextDim),
        _cell(fmt(s.lastMmImpKwh), color: s.lastMmImpKwh != null ? kAccent : kTextDim),
        _cell(fmt(s.lastMmImpKvarh), color: s.lastMmImpKvarh != null ? kAccent : kTextDim),
        _cell(fmt(s.lastBmExpKwh), color: s.lastBmExpKwh != null ? kAccent2 : kTextDim),
        _cell(fmt(s.lastBmExpKvarh), color: s.lastBmExpKvarh != null ? kAccent2 : kTextDim),
        _cell(fmt(s.lastBmImpKwh), color: s.lastBmImpKwh != null ? kAccent2 : kTextDim),
        _cell(fmt(s.lastBmImpKvarh), color: s.lastBmImpKvarh != null ? kAccent2 : kTextDim),
        _cell(numFmt.format(s.totalEnergyExpKwh), color: hasData ? kAccent2 : kTextDim, bold: hasData),
        _cell(numFmt.format(s.totalEnergyImpKwh), color: hasData ? kAccent2 : kTextDim, bold: hasData),
        _cell(numFmt.format(s.totalUnitExp), color: hasData ? kYellow : kTextDim, bold: hasData),
        _cell(numFmt.format(s.totalUnitImp), color: hasData ? kYellow : kTextDim, bold: hasData),
        _cell(s.totalMw.toStringAsFixed(3), color: hasData ? kPurple : kTextDim, bold: hasData),
      ],
    );
  }

  Widget _buildDetailCard(DailySummary s) {
    final numFmt = NumberFormat('0.###');
    final dateStr = DateFormat('dd/MM/yyyy').format(s.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kAccent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: kAccent.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: kAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ລາຍລະອຽດ: $dateStr',
                  style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedIdx = null),
                child: const Icon(Icons.close, color: kTextDim, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!s.hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ບໍ່ມີຂໍ້ມູນສຳລັບວັນທີ່ນີ້',
                  style: TextStyle(color: kTextDim, fontSize: 13),
                ),
              ),
            )
          else ...[
            Text('ຕົວເລກ Meter ລ່າສຸດ (ເວລາ ${s.lastEntryTime}):', style: const TextStyle(color: kTextDim, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DetailTile(label: 'MM Exp Kw/h', value: numFmt.format(s.lastMmExpKwh ?? 0), color: kAccent),
                _DetailTile(label: 'MM Exp Kvar/h', value: numFmt.format(s.lastMmExpKvarh ?? 0), color: kAccent),
                _DetailTile(label: 'MM Imp Kw/h', value: numFmt.format(s.lastMmImpKwh ?? 0), color: kAccent),
                _DetailTile(label: 'MM Imp Kvar/h', value: numFmt.format(s.lastMmImpKvarh ?? 0), color: kAccent),
                _DetailTile(label: 'BM Exp Kw/h', value: numFmt.format(s.lastBmExpKwh ?? 0), color: kAccent2),
                _DetailTile(label: 'BM Exp Kvar/h', value: numFmt.format(s.lastBmExpKvarh ?? 0), color: kAccent2),
                _DetailTile(label: 'BM Imp Kw/h', value: numFmt.format(s.lastBmImpKwh ?? 0), color: kAccent2),
                _DetailTile(label: 'BM Imp Kvar/h', value: numFmt.format(s.lastBmImpKvarh ?? 0), color: kAccent2),
              ],
            ),
            const Divider(color: kBorder, height: 20),
            const Text('ຍອດລວມທັງວັນ:', style: TextStyle(color: kTextDim, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DetailTile(label: 'Energy Export', value: numFmt.format(s.totalEnergyExpKwh), unit: 'Kw/h', color: kAccent2),
                _DetailTile(label: 'Energy Import', value: numFmt.format(s.totalEnergyImpKwh), unit: 'Kw/h', color: kAccent2),
                _DetailTile(label: 'Unit Export', value: numFmt.format(s.totalUnitExp), unit: 'ຫົວໜ່ວຍ', color: kYellow),
                _DetailTile(label: 'Unit Import', value: numFmt.format(s.totalUnitImp), unit: 'ຫົວໜ່ວຍ', color: kYellow),
                _DetailTile(label: 'Total Mw', value: s.totalMw.toStringAsFixed(3), unit: 'Mw', color: kPurple),
              ],
            ),
          ],
        ],
      ),
    );
  }

  TableCell _cell(String text, {Color color = kTextDim, bool bold = false}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  TableCell _th(String text, {Color color = kTextDim, bool small = false}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: small ? 9 : 10,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<TableCell> _thSpan(String text, Color color, int span) {
    return List.generate(span, (i) {
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: i == 0
              ? Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
      );
    });
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendDot({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10, color: kTextDim, fontFamily: 'monospace')),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kBg,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: kTextDim, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
          Text(unit, style: const TextStyle(fontSize: 9, color: kTextDim)),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _DetailTile({
    required this.label,
    required this.value,
    this.unit = '',
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kBg,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: kTextDim, fontFamily: 'monospace')),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
          if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 9, color: kTextDim)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAccent.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}