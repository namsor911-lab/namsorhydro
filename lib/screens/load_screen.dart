import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'production_history_screen.dart' as ph;
// ✅ ເພີ່ມການນຳເຂົ້າ YearlyReportScreen
import 'yearly_report_screen.dart';

// =========================================================
// MODEL
// =========================================================

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
  double unitExp;
  double unitImp;

  EnergyRow({required this.hour})
      : unitExp = 0,
        unitImp = 0;

  String get timeLabel {
    final hh = hour.toString().padLeft(2, '0');
    return '$hh:00';
  }
}

class ComputedEnergy {
  final double? eExpKwh;
  final double? eExpKvarh;
  final double? eImpKwh;
  final double? eImpKvarh;
  final double? mw;

  const ComputedEnergy({
    this.eExpKwh,
    this.eExpKvarh,
    this.eImpKwh,
    this.eImpKvarh,
    this.mw,
  });
}

// =========================================================
// COLOURS
// =========================================================

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

// =========================================================
// SCREEN
// =========================================================

class LoadScreen extends StatefulWidget {
  const LoadScreen({super.key});

  @override
  State<LoadScreen> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  List<EnergyRow> _rows = [];
  bool _tableVisible = false;

  final Map<String, List<EnergyRow>> _dataByDate = {};

  int? _editRow;
  String? _editField;
  final TextEditingController _editCtrl = TextEditingController();
  final FocusNode _editFocus = FocusNode();

  final List<String> _editableCols = [
    'mm_exp_kwh',
    'mm_exp_kvarh',
    'mm_imp_kwh',
    'mm_imp_kvarh',
    'bm_exp_kwh',
    'bm_exp_kvarh',
    'bm_imp_kwh',
    'bm_imp_kvarh',
    'unit_exp',
    'unit_imp',
  ];

  @override
  void initState() {
    super.initState();
    _generateTable();
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  // ---- Data helpers ----

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  List<EnergyRow> _getRowsForDate(DateTime d) {
    final key = _dateKey(d);
    return _dataByDate.putIfAbsent(
      key,
      () => List.generate(25, (h) => EnergyRow(hour: h)),
    );
  }

  ComputedEnergy _computeEnergy(int idx) {
    if (idx == 0) return const ComputedEnergy();
    final cur = _rows[idx];
    final prv = _rows[idx - 1];

    double? diff(double? c, double? p) {
      if (c == null || p == null) return null;
      final d = c - p;
      return d < 0 ? 0 : d;
    }

    final eExpKwh = diff(cur.mmExpKwh, prv.mmExpKwh);
    final eExpKvarh = diff(cur.mmExpKvarh, prv.mmExpKvarh);
    final eImpKwh = diff(cur.mmImpKwh, prv.mmImpKwh);
    final eImpKvarh = diff(cur.mmImpKvarh, prv.mmImpKvarh);
    final mw = eExpKwh != null ? eExpKwh / 1000 : null;

    return ComputedEnergy(
      eExpKwh: eExpKwh,
      eExpKvarh: eExpKvarh,
      eImpKwh: eImpKwh,
      eImpKvarh: eImpKvarh,
      mw: mw,
    );
  }

  // Totals
  ({
    double eExpKwh,
    double eExpKvarh,
    double eImpKwh,
    double eImpKvarh,
    double unitExp,
    double unitImp,
    double mw
  }) get _totals {
    double eExpKwh = 0,
        eExpKvarh = 0,
        eImpKwh = 0,
        eImpKvarh = 0,
        unitExp = 0,
        unitImp = 0,
        mw = 0;
    for (int i = 1; i < _rows.length; i++) {
      final c = _computeEnergy(i);
      eExpKwh += c.eExpKwh ?? 0;
      eExpKvarh += c.eExpKvarh ?? 0;
      eImpKwh += c.eImpKwh ?? 0;
      eImpKvarh += c.eImpKvarh ?? 0;
      unitExp += _rows[i].unitExp;
      unitImp += _rows[i].unitImp;
      mw += c.mw ?? 0;
    }
    return (
      eExpKwh: eExpKwh,
      eExpKvarh: eExpKvarh,
      eImpKwh: eImpKwh,
      eImpKvarh: eImpKvarh,
      unitExp: unitExp,
      unitImp: unitImp,
      mw: mw
    );
  }

  // ---- Actions ----

  void _generateTable() {
    setState(() {
      _rows = _getRowsForDate(_selectedDate);
      _tableVisible = true;
    });
  }

  void _exportCSV() {
    if (_rows.isEmpty) return;
    final buf = StringBuffer();
    buf.write(
        'Time,MM Export Kw/h,MM Export Kvar/h,MM Import Kw/h,MM Import Kvar/h,');
    buf.write(
        'BM Export Kw/h,BM Export Kvar/h,BM Import Kw/h,BM Import Kvar/h,');
    buf.write(
        'Energy Export Kw/h,Energy Export Kvar/h,Energy Import Kw/h,Energy Import Kvar/h,');
    buf.writeln('Unit Running Export,Unit Running Import,Mw');

    for (int i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      final c = _computeEnergy(i);
      buf.writeln([
        r.timeLabel,
        r.mmExpKwh ?? '',
        r.mmExpKvarh ?? '',
        r.mmImpKwh ?? '',
        r.mmImpKvarh ?? '',
        r.bmExpKwh ?? '',
        r.bmExpKvarh ?? '',
        r.bmImpKwh ?? '',
        r.bmImpKvarh ?? '',
        i == 0 ? '-' : (c.eExpKwh ?? 0),
        i == 0 ? '-' : (c.eExpKvarh ?? 0),
        i == 0 ? '-' : (c.eImpKwh ?? 0),
        i == 0 ? '-' : (c.eImpKvarh ?? 0),
        i == 0 ? '-' : r.unitExp,
        i == 0 ? '-' : r.unitImp,
        i == 0 ? '-' : (c.mw?.toStringAsFixed(3) ?? '0'),
      ].join(','));
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final path = '/tmp/energy_record_$dateStr.csv';
    File(path).writeAsStringSync('\uFEFF${buf.toString()}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kSurface2,
        content: Text('ບັນທຶກ CSV ແລ້ວ: $path',
            style: const TextStyle(color: kAccent2)),
      ),
    );
  }

  // ---- ໄປໜ້າປະຫວັດການຜະລິດ (Production History) ----

  List<ph.EnergyRow> _convertRows(List<EnergyRow> rows) {
    return rows.map((r) {
      final pr = ph.EnergyRow(hour: r.hour);
      pr.mmExpKwh = r.mmExpKwh;
      pr.mmExpKvarh = r.mmExpKvarh;
      pr.mmImpKwh = r.mmImpKwh;
      pr.mmImpKvarh = r.mmImpKvarh;
      pr.bmExpKwh = r.bmExpKwh;
      pr.bmExpKvarh = r.bmExpKvarh;
      pr.bmImpKwh = r.bmImpKwh;
      pr.bmImpKvarh = r.bmImpKvarh;
      return pr;
    }).toList();
  }

  Map<String, List<ph.EnergyRow>> _convertDataByDate() {
    return _dataByDate.map((key, rows) => MapEntry(key, _convertRows(rows)));
  }

  void _openProductionHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ph.ProductionHistoryScreen(
          dataByDate: _convertDataByDate(),
          referenceDate: _selectedDate,
        ),
      ),
    );
  }

  // ✅ ເພີ່ມຟັງຊັນຄຳນວນຂໍ້ມູນລາຍປີ
  List<Map<String, String>> _computeYearlyData() {
    // ກຽມຕົວເກັບຂໍ້ມູນລວມຕາມເດືອນ
    Map<int, double> monthlyExport = {};
    Map<int, double> monthlyImport = {};
    Map<int, double> monthlyNet = {};

    // ເລື່ອນທຸກວັນທີ່ມີຂໍ້ມູນ
    _dataByDate.forEach((dateKey, rows) {
      if (rows.isEmpty) return;
      // ວັນທີຈາກ key
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      final month = date.month;

      // ຄິດໄລ່ຜົນລວມປະຈຳວັນ (ໃຊ້ວິທີດຽວກັບ _totals ແຕ່ສຳລັບລາຍວັນ)
      double dayExport = 0, dayImport = 0;
      for (int i = 1; i < rows.length; i++) {
        final cur = rows[i];
        final prv = rows[i - 1];
        double? diff(double? c, double? p) {
          if (c == null || p == null) return null;
          final d = c - p;
          return d < 0 ? 0 : d;
        }
        final eExp = diff(cur.mmExpKwh, prv.mmExpKwh) ?? 0;
        final eImp = diff(cur.mmImpKwh, prv.mmImpKwh) ?? 0;
        dayExport += eExp;
        dayImport += eImp;
      }

      // ສະສົມເຂົ້າເດືອນ
      monthlyExport[month] = (monthlyExport[month] ?? 0) + dayExport;
      monthlyImport[month] = (monthlyImport[month] ?? 0) + dayImport;
      monthlyNet[month] = (monthlyNet[month] ?? 0) + (dayExport - dayImport);
    });

    // ສ້າງລາຍການ 12 ເດືອນ
    List<Map<String, String>> result = [];
    for (int m = 1; m <= 12; m++) {
      final export = monthlyExport[m] ?? 0.0;
      final import = monthlyImport[m] ?? 0.0;
      final net = monthlyNet[m] ?? 0.0;
      result.add({
        'month': m.toString().padLeft(2, '0'),
        'export': export.toStringAsFixed(2),
        'import': import.toStringAsFixed(2),
        'total': net.toStringAsFixed(2),
      });
    }
    return result;
  }

  void _openYearlyReport() {
    final yearlyData = _computeYearlyData();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YearlyReportScreen(
          yearlyData: yearlyData,
          currentYear: _selectedDate.year,
        ),
      ),
    );
  }

  // ---- Inline edit helpers ----

  void _startEdit(int rowIdx, String field) {
    _finishEdit();
    final val = _getFieldValue(rowIdx, field);
    setState(() {
      _editRow = rowIdx;
      _editField = field;
      _editCtrl.text = val != null ? val.toString() : '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_editFocus);
    });
  }

  void _finishEdit() {
    if (_editRow == null || _editField == null) return;
    final text = _editCtrl.text.trim();
    final val = text.isEmpty ? null : double.tryParse(text);
    _setFieldValue(_editRow!, _editField!, val);
    setState(() {
      _editRow = null;
      _editField = null;
    });
  }

  void _moveEdit(int rowDelta, int colDelta) {
    if (_editRow == null || _editField == null) return;

    final currentRow = _editRow!;
    final currentCol = _editableCols.indexOf(_editField!);

    final text = _editCtrl.text.trim();
    final val = text.isEmpty ? null : double.tryParse(text);
    _setFieldValue(currentRow, _editField!, val);

    final nextRow = currentRow + rowDelta;
    final nextCol = currentCol + colDelta;

    if (nextRow >= 0 &&
        nextRow < _rows.length &&
        nextCol >= 0 &&
        nextCol < _editableCols.length) {
      final nextField = _editableCols[nextCol];
      final nextVal = _getFieldValue(nextRow, nextField);
      setState(() {
        _editRow = nextRow;
        _editField = nextField;
        _editCtrl.text = nextVal != null ? nextVal.toString() : '';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_editFocus);
      });
    } else {
      setState(() {
        _editRow = null;
        _editField = null;
      });
    }
  }

  double? _getFieldValue(int rowIdx, String field) {
    final r = _rows[rowIdx];
    switch (field) {
      case 'mm_exp_kwh':
        return r.mmExpKwh;
      case 'mm_exp_kvarh':
        return r.mmExpKvarh;
      case 'mm_imp_kwh':
        return r.mmImpKwh;
      case 'mm_imp_kvarh':
        return r.mmImpKvarh;
      case 'bm_exp_kwh':
        return r.bmExpKwh;
      case 'bm_exp_kvarh':
        return r.bmExpKvarh;
      case 'bm_imp_kwh':
        return r.bmImpKwh;
      case 'bm_imp_kvarh':
        return r.bmImpKvarh;
      case 'unit_exp':
        return r.unitExp;
      case 'unit_imp':
        return r.unitImp;
      default:
        return null;
    }
  }

  void _setFieldValue(int rowIdx, String field, double? val) {
    final r = _rows[rowIdx];
    switch (field) {
      case 'mm_exp_kwh':
        r.mmExpKwh = val;
        break;
      case 'mm_exp_kvarh':
        r.mmExpKvarh = val;
        break;
      case 'mm_imp_kwh':
        r.mmImpKwh = val;
        break;
      case 'mm_imp_kvarh':
        r.mmImpKvarh = val;
        break;
      case 'bm_exp_kwh':
        r.bmExpKwh = val;
        break;
      case 'bm_exp_kvarh':
        r.bmExpKvarh = val;
        break;
      case 'bm_imp_kwh':
        r.bmImpKwh = val;
        break;
      case 'bm_imp_kvarh':
        r.bmImpKvarh = val;
        break;
      case 'unit_exp':
        r.unitExp = val ?? 0;
        break;
      case 'unit_imp':
        r.unitImp = val ?? 0;
        break;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent && _editRow != null) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _moveEdit(-1, 0);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _moveEdit(1, 0);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _moveEdit(0, -1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _moveEdit(0, 1);
            } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              _moveEdit(1, 0);
            }
          }
        },
        child: Stack(
          children: [
            _buildGrid(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildControls(),
                    const SizedBox(height: 24),
                    if (_tableVisible) ...[
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildTable(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Grid background ----
  Widget _buildGrid() {
    return Positioned.fill(
      child: CustomPaint(painter: _GridPainter()),
    );
  }

  // ---- Header ----
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder, width: 1)),
      ),
      child: Column(
        children: [
          Text(
            'DAILY ENERGY RECORD',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kAccent,
              letterSpacing: 3,
              shadows: [
                Shadow(
                    color: kAccent.withValues(alpha: 0.5),
                    blurRadius: 20)
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ບັນທຶກພະລັງງານປະຈຳວັນ',
            style: TextStyle(fontSize: 14, color: kTextDim),
          ),
        ],
      ),
    );
  }

  // ---- Controls ----
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          // Date picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📅 ວັນທີ (DATE)',
                  style: TextStyle(
                      fontSize: 11,
                      color: kAccent,
                      letterSpacing: 1.2)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: kAccent,
                            onSurface: kTextBright),
                        dialogTheme: const DialogThemeData(
                            backgroundColor: kSurface),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null) {
                    setState(() {
                      _selectedDate = d;
                      if (_tableVisible) {
                        _rows = _getRowsForDate(d);
                      }
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kBg,
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                    style: const TextStyle(
                        color: kTextBright,
                        fontSize: 13,
                        fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),

          // Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildButton(
                label: '⚡ ສ້າງຕາຕະລາງ',
                bg: kAccent,
                fg: kBg,
                onTap: _generateTable,
              ),
              _buildButton(
                label: '💾 Export CSV',
                bg: kAccent2,
                fg: kBg,
                onTap: _exportCSV,
              ),
              _buildButton(
                label: '📊 ປະຫວັດການຜະລິດ',
                bg: kPurple,
                fg: kBg,
                onTap: _openProductionHistory,
              ),
              // ✅ ເພີ່ມປຸ່ມໄປຍັງລາຍງານປະຈຳປີ
              _buildButton(
                label: '📅 ລາຍງານປະຈຳປີ',
                bg: const Color(0xFFFF6B35),
                fg: kBg,
                onTap: _openYearlyReport,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color bg,
    required Color fg,
    Color? border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: border != null
              ? Border.all(color: border)
              : null,
          borderRadius: BorderRadius.circular(4),
          boxShadow: bg == kAccent
              ? [
                  BoxShadow(
                      color: kAccent.withValues(alpha: 0.3),
                      blurRadius: 16)
                ]
              : bg == kAccent2
                  ? [
                      BoxShadow(
                          color: kAccent2.withValues(alpha: 0.3),
                          blurRadius: 16)
                    ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8),
        ),
      ),
    );
  }

  // ---- Summary Cards ----
  Widget _buildSummaryCards() {
    final t = _totals;
    final numFmt = NumberFormat('0.###');
    final cards = [
      (label: '⬆ Energy Export Total', value: numFmt.format(t.eExpKwh), unit: 'Kw/h', color: kAccent),
      (label: '⬆ Export Kvar/h Total', value: numFmt.format(t.eExpKvarh), unit: 'Kvar/h', color: const Color(0xFF38BDF8)),
      (label: '⬇ Energy Import Total', value: numFmt.format(t.eImpKwh), unit: 'Kw/h', color: kAccent2),
      (label: '⬇ Import Kvar/h Total', value: numFmt.format(t.eImpKvarh), unit: 'Kvar/h', color: const Color(0xFF6EE7B7)),
      (label: '🔌 Unit Running Export', value: numFmt.format(t.unitExp), unit: 'ຫົວໜ່ວຍ', color: kYellow),
      (label: '🔌 Unit Running Import', value: numFmt.format(t.unitImp), unit: 'ຫົວໜ່ວຍ', color: kYellow),
      (label: '⚡ Total Mw', value: t.mw.toStringAsFixed(3), unit: 'Mw', color: kAccent3),
    ];

    final cardWidgets = cards
        .map((c) => _SummaryCard(
              label: c.label,
              value: c.value,
              unit: c.unit,
              accentColor: c.color,
            ))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const minCardWidth = 108.0;
        const gap = 8.0;
        final totalMinWidth =
            minCardWidth * cardWidgets.length + gap * (cardWidgets.length - 1);

        if (constraints.maxWidth >= totalMinWidth) {
          return Row(
            children: [
              for (int i = 0; i < cardWidgets.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: cardWidgets[i]),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < cardWidgets.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(width: minCardWidth, child: cardWidgets[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---- Table ----
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _buildInfoBar(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: kSurface2,
      child: const Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _TipDot(
              color: kAccent,
              text: 'ຄລິກຊ່ອງ Meter ເພື່ອປ້ອນຄ່າ (ກົດລູກສອນຍ້າຍ Cell ໄດ້ຄື Excel)'),
          _TipDot(
              color: kAccent2,
              text: 'Energy/Mw ຈະຄິດໄລ່ອັດຕະໂນມັດ'),
          _TipDot(
              color: kAccent3,
              text:
                  'Unit Running = ຈຳນວນ unit ທີ່ເດີນໃນຊ່ວງເວລານັ້ນ'),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final numFmt = NumberFormat('0.###');
    final t = _totals;

    const double timeW = 72;
    const double cellW = 90;

    return Table(
      defaultColumnWidth: const FixedColumnWidth(cellW),
      columnWidths: const {0: FixedColumnWidth(timeW)},
      border: TableBorder.all(
          color: const Color(0x4D1E3A5F), width: 0.5),
      children: [
        // Group header row
        TableRow(
          decoration:
              const BoxDecoration(color: Color(0xFF060D1A)),
          children: [
            _th('Time', rowspan: true),
            ..._thGroup('Main Meter', kAccent, 4),
            ..._thGroup('Backup Meter', kAccent2, 4),
            ..._thGroup('Energy', kYellow, 4),
            ..._thGroup('Unit Running', kAccent3, 2),
            _th('Mw', color: kPurple, rowspan: true),
          ],
        ),
        // Sub header
        TableRow(
          decoration:
              const BoxDecoration(color: kHeaderBg),
          children: [
            ..._thSub(''),
            ..._thSub('Export', leftBorder: kAccent, span: 2),
            ..._thSub('Import', span: 2),
            ..._thSub('Export', leftBorder: kAccent2, span: 2),
            ..._thSub('Import', span: 2),
            ..._thSub('Export', leftBorder: kYellow, span: 2),
            ..._thSub('Import', span: 2),
            ..._thSub('Export', leftBorder: kAccent3),
            ..._thSub('Import'),
            ..._thSub('', leftBorder: kPurple),
          ],
        ),
        // Unit header
        TableRow(
          decoration:
              const BoxDecoration(color: kHeaderBg),
          children: [
            _thUnit(''),
            _thUnit('Kw/h', leftBorder: kAccent),
            _thUnit('Kvar/h'),
            _thUnit('Kw/h'),
            _thUnit('Kvar/h'),
            _thUnit('Kw/h', leftBorder: kAccent2),
            _thUnit('Kvar/h'),
            _thUnit('Kw/h'),
            _thUnit('Kvar/h'),
            _thUnit('Kw/h', leftBorder: kYellow),
            _thUnit('Kvar/h'),
            _thUnit('Kw/h'),
            _thUnit('Kvar/h'),
            _thUnit('', leftBorder: kAccent3),
            _thUnit(''),
            _thUnit('Mw', leftBorder: kPurple),
          ],
        ),

        // Data rows
        for (int i = 0; i < _rows.length; i++)
          _buildDataRow(i, numFmt),

        // Total row
        _buildTotalRow(t, numFmt),
      ],
    );
  }

  TableRow _buildDataRow(int i, NumberFormat numFmt) {
    final r = _rows[i];
    final c = _computeEnergy(i);
    final isInit = i == 0;

    Color? eExpColor = (!isInit && (c.eExpKwh ?? 0) > 0)
        ? kAccent
        : kTextDim.withValues(alpha: 0.4);
    Color? eImpColor = (!isInit && (c.eImpKwh ?? 0) > 0)
        ? kAccent
        : kTextDim.withValues(alpha: 0.4);

    Color rowBg = i % 2 == 0 ? kRowAlt : kSurface;
    if (isInit) rowBg = kAccent.withValues(alpha: 0.03);

    return TableRow(
      decoration: BoxDecoration(color: rowBg),
      children: [
        // Time
        _td(r.timeLabel, color: kAccent, bold: true,
            align: TextAlign.left),
        // Main Meter
        _editableCell(i, 'mm_exp_kwh', r.mmExpKwh, numFmt,
            leftBorder: kAccent.withValues(alpha: 0.3)),
        _editableCell(i, 'mm_exp_kvarh', r.mmExpKvarh, numFmt),
        _editableCell(i, 'mm_imp_kwh', r.mmImpKwh, numFmt),
        _editableCell(i, 'mm_imp_kvarh', r.mmImpKvarh, numFmt),
        // Backup Meter
        _editableCell(i, 'bm_exp_kwh', r.bmExpKwh, numFmt,
            leftBorder: kAccent2.withValues(alpha: 0.3)),
        _editableCell(i, 'bm_exp_kvarh', r.bmExpKvarh, numFmt),
        _editableCell(i, 'bm_imp_kwh', r.bmImpKwh, numFmt),
        _editableCell(i, 'bm_imp_kvarh', r.bmImpKvarh, numFmt),
        // Energy Export (computed)
        _computed(
            isInit ? null : c.eExpKwh, numFmt, eExpColor,
            leftBorder: kYellow.withValues(alpha: 0.3)),
        _computed(isInit ? null : c.eExpKvarh, numFmt, eExpColor),
        // Energy Import (computed)
        _computed(isInit ? null : c.eImpKwh, numFmt, eImpColor),
        _computed(isInit ? null : c.eImpKvarh, numFmt, eImpColor),
        // Unit Running
        isInit
            ? _td('-', color: kTextDim.withValues(alpha: 0.4),
                leftBorder: kAccent3.withValues(alpha: 0.3))
            : _editableCell(i, 'unit_exp', r.unitExp, numFmt,
                color: kAccent3,
                leftBorder: kAccent3.withValues(alpha: 0.3)),
        isInit
            ? _td('-', color: kTextDim.withValues(alpha: 0.4))
            : _editableCell(i, 'unit_imp', r.unitImp, numFmt,
                color: kAccent3),
        // Mw
        _td(
          isInit
              ? '-'
              : (c.mw != null
                  ? c.mw!.toStringAsFixed(3)
                  : '0'),
          color: kPurple,
          bold: true,
          leftBorder: kPurple.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  TableRow _buildTotalRow(dynamic t, NumberFormat numFmt) {
    return TableRow(
      decoration: const BoxDecoration(
        color: kHeaderBg,
        border: Border(top: BorderSide(color: kAccent, width: 2)),
      ),
      children: [
        _td('TOTAL',
            color: kAccent, bold: true, align: TextAlign.left),
        _td('—',
            color: kTextDim,
            leftBorder: kAccent.withValues(alpha: 0.3)),
        _td('—', color: kTextDim),
        _td('—', color: kTextDim),
        _td('—', color: kTextDim),
        _td('—',
            color: kTextDim,
            leftBorder: kAccent2.withValues(alpha: 0.3)),
        _td('—', color: kTextDim),
        _td('—', color: kTextDim),
        _td('—', color: kTextDim),
        _td(numFmt.format(t.eExpKwh),
            color: kAccent,
            bold: true,
            leftBorder: kYellow.withValues(alpha: 0.3)),
        _td(numFmt.format(t.eExpKvarh), color: kAccent, bold: true),
        _td(numFmt.format(t.eImpKwh), color: kAccent2, bold: true),
        _td(numFmt.format(t.eImpKvarh),
            color: kAccent2, bold: true),
        _td(numFmt.format(t.unitExp),
            color: kAccent3,
            bold: true,
            leftBorder: kAccent3.withValues(alpha: 0.3)),
        _td(numFmt.format(t.unitImp), color: kAccent3, bold: true),
        _td(t.mw.toStringAsFixed(3),
            color: kPurple,
            bold: true,
            leftBorder: kPurple.withValues(alpha: 0.3)),
      ],
    );
  }

  // =========================================================
  // Cell builders
  // =========================================================

  Widget _editableCell(
      int rowIdx, String field, double? val, NumberFormat numFmt,
      {Color color = kTextBright, Color? leftBorder}) {
    final isEditing =
        _editRow == rowIdx && _editField == field;

    if (isEditing) {
      return TableCell(
        child: Container(
          color: kAccent.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(4),
          child: TextField(
            focusNode: _editFocus,
            controller: _editCtrl,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[\d.]'))
            ],
            style: const TextStyle(
                color: kTextBright,
                fontSize: 12,
                fontFamily: 'monospace'),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: kAccent)),
              enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: kAccent)),
              focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: kAccent, width: 1.5)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 6, vertical: 4),
            ),
            cursorColor: Colors.transparent,
            cursorWidth: 0,
          ),
        ),
      );
    }

    return TableCell(
      child: GestureDetector(
        onTap: () => _startEdit(rowIdx, field),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: leftBorder != null
              ? BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: leftBorder, width: 2)))
              : null,
          child: Text(
            val != null ? numFmt.format(val) : '—',
            style: TextStyle(
                color: val != null ? color : kTextDim.withValues(alpha: 0.4),
                fontSize: 12,
                fontFamily: 'monospace'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _computed(double? val, NumberFormat numFmt, Color color,
      {Color? leftBorder}) {
    return TableCell(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: leftBorder != null
            ? BoxDecoration(
                border: Border(
                    left:
                        BorderSide(color: leftBorder, width: 2)))
            : null,
        child: Text(
          val != null ? numFmt.format(val) : '—',
          style: TextStyle(
              color: color, fontSize: 12, fontFamily: 'monospace'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _td(String text,
      {Color color = kTextDim,
      bool bold = false,
      TextAlign align = TextAlign.center,
      Color? leftBorder}) {
    return TableCell(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: leftBorder != null
            ? BoxDecoration(
                border: Border(
                    left:
                        BorderSide(color: leftBorder, width: 2)))
            : null,
        child: Text(
          text,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.normal,
              fontFamily: 'monospace'),
          textAlign: align,
        ),
      ),
    );
  }

  // ---- Table header helpers ----

  Widget _th(String text,
      {Color color = kTextDim, bool rowspan = false}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 1),
            textAlign: TextAlign.center),
      ),
    );
  }

  List<Widget> _thGroup(String text, Color color, int span) {
    return List.generate(span, (i) {
      return TableCell(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: i == 0
              ? Text(text,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontFamily: 'monospace',
                      letterSpacing: 1),
                  textAlign: TextAlign.center)
              : const SizedBox.shrink(),
        ),
      );
    });
  }

  List<Widget> _thSub(String text,
      {Color? leftBorder, int span = 1}) {
    return List.generate(span, (i) {
      final isFirst = i == 0;
      return TableCell(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: (isFirst && leftBorder != null)
              ? BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: leftBorder.withValues(alpha: 0.5),
                          width: 2)))
              : null,
          child: isFirst
              ? Text(text,
                  style: const TextStyle(
                      color: kTextDim,
                      fontSize: 10,
                      fontFamily: 'monospace'),
                  textAlign: TextAlign.center)
              : const SizedBox.shrink(),
        ),
      );
    });
  }

  Widget _thUnit(String text, {Color? leftBorder}) {
    return TableCell(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: leftBorder != null
            ? BoxDecoration(
                border: Border(
                    left: BorderSide(
                        color: leftBorder.withValues(alpha: 0.4),
                        width: 1)))
            : null,
        child: Text(text,
            style: const TextStyle(
                color: kTextDim,
                fontSize: 9,
                fontFamily: 'monospace'),
            textAlign: TextAlign.center),
      ),
    );
  }
}

// =========================================================
// HELPER WIDGETS
// =========================================================

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color accentColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                accentColor,
                Colors.transparent
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9,
                  color: kTextDim,
                  letterSpacing: 0.4,
                  fontFamily: 'monospace')),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9, color: kTextDim)),
        ],
      ),
    );
  }
}

class _TipDot extends StatelessWidget {
  final Color color;
  final String text;
  const _TipDot({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                color: kTextDim,
                fontFamily: 'monospace')),
      ],
    );
  }
}

// =========================================================
// GRID PAINTER
// =========================================================

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.03)
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