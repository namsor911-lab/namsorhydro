import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class MonthlyRecord {
  final int month;
  final double outputKwh;
  final double importKwh;
  final double sellingPrice;
  double? expenses;

  MonthlyRecord({
    required this.month,
    required this.outputKwh,
    required this.importKwh,
    this.sellingPrice = 0.06,
    this.expenses,
  });

  double get revenue => outputKwh * sellingPrice;
  bool get hasOutput => outputKwh > 0;

  String get monthName {
    const names = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }

  String get quarterLabel {
    if (month <= 3) return 'Q1(Jan-Mar)';
    if (month <= 6) return 'Q2(Apr-Jun)';
    if (month <= 9) return 'Q3(July-Sep)';
    return 'Q4(Oct-Dec)';
  }
}

class YearlyReportScreen extends StatefulWidget {
  final List<Map<String, String>>? yearlyData;
  final int? currentYear;

  const YearlyReportScreen({
    super.key,
    this.yearlyData,
    this.currentYear,
  });

  @override
  State<YearlyReportScreen> createState() => _YearlyReportScreenState();
}

class _YearlyReportScreenState extends State<YearlyReportScreen> {
  late int _selectedYear;
  late List<MonthlyRecord> _records;

  final Map<int, TextEditingController> _expCtrl = {};
  final Map<int, FocusNode> _expFocus = {};
  int? _editingMonth;

  final ScrollController _scrollCtrl = ScrollController();
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = widget.currentYear ?? now.year;
    _years = List.generate(10, (i) => now.year - 4 + i);
    _buildRecords();
    _initControllers();
  }

  @override
  void dispose() {
    for (final c in _expCtrl.values) { c.dispose(); }
    for (final f in _expFocus.values) { f.dispose(); }
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _buildRecords() {
    final data = widget.yearlyData;
    _records = [];
    for (int m = 1; m <= 12; m++) {
      double output = 0, imp = 0;
      if (data != null && data.length == 12) {
        output = double.tryParse(data[m - 1]['export'] ?? '') ?? 0;
        imp = double.tryParse(data[m - 1]['import'] ?? '') ?? 0;
      }
      _records.add(MonthlyRecord(
        month: m,
        outputKwh: output,
        importKwh: imp,
      ));
    }
  }

  void _initControllers() {
    for (int m = 1; m <= 12; m++) {
      _expCtrl[m] = TextEditingController();
      _expFocus[m] = FocusNode();
    }
  }

  void _commitExpense(int month) {
    final text = _expCtrl[month]!.text.trim();
    final val = text.isEmpty ? null : double.tryParse(text);
    setState(() {
      _records[month - 1].expenses = val;
      _editingMonth = null;
    });
  }

  double get _totalOutput => _records.fold(0.0, (s, r) => s + r.outputKwh);
  double get _totalImport => _records.fold(0.0, (s, r) => s + r.importKwh);
  double get _totalRevenue => _records.fold(0.0, (s, r) => s + r.revenue);
  double get _totalExpenses => _records.fold(0.0, (s, r) => s + (r.expenses ?? 0));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_editingMonth != null) _commitExpense(_editingMonth!);
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: kBg,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildGrid(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildYearSelector(),
                          const SizedBox(width: 10),
                          _buildSummaryCards(),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildTable(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: _buildGraph(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: kSurface,
      elevation: 0,
      toolbarHeight: 64,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: kAccent, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAccent, kAccent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(color: kAccent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.bolt, color: kBg, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NAMSOR HYDROPOWER',
                  style: TextStyle(
                    color: kTextBright,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'YEARLY FINANCIAL REPORT',
                      style: TextStyle(
                        color: kAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: kTextDim, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ລາຍງານການເງິນປະຈຳປີ $_selectedYear',
                        style: const TextStyle(
                          color: kTextDim,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [kAccent, kAccent2, Colors.transparent]),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Positioned.fill(
      child: CustomPaint(painter: _GridPainter()),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, color: kAccent, size: 12),
          const SizedBox(width: 6),
          const Text(
            'Select Year:',
            style: TextStyle(
              color: kTextDim,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            decoration: BoxDecoration(
              color: kBg,
              border: Border.all(color: kAccent, width: 1.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                dropdownColor: kSurface2,
                style: const TextStyle(
                  color: kTextBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: kAccent, size: 16),
                items: _years.map((y) => DropdownMenuItem(
                  value: y,
                  child: Text(y.toString()),
                )).toList(),
                onChanged: (y) {
                  if (y != null) {
                    setState(() {
                      _selectedYear = y;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final cards = [
      (label: '⚡ Total Output', value: _fmt(_totalOutput), unit: 'Kwh', color: kGreen),
      (label: '⬇ Total Import', value: _fmt(_totalImport), unit: 'Kwh', color: kYellow),
      (label: '💵 Total Revenue', value: '\$${_totalRevenue.toStringAsFixed(2)}', unit: 'USD', color: kAccent),
      (label: '💸 Total Expenses', value: '\$${_totalExpenses.toStringAsFixed(2)}', unit: 'USD', color: kAccent3),
    ];

    return Row(
      children: cards.map((c) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _SummaryCard(
          label: c.label,
          value: c.value,
          unit: c.unit,
          color: c.color,
        ),
      )).toList(),
    );
  }

  Widget _buildTable() {
    const double wQ = 120.0;
    const double wM = 110.0;
    const double wOut = 160.0;
    const double wImp = 160.0;
    const double wPrc = 90.0;
    const double wRev = 130.0;
    const double wExp = 130.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Scrollbar(
        controller: _scrollCtrl,
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollCtrl,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(wQ, wM, wOut, wImp, wPrc, wRev, wExp),
                ..._buildAllRows(wQ, wM, wOut, wImp, wPrc, wRev, wExp),
                _buildTotalRow(wQ, wM, wOut, wImp, wPrc, wRev, wExp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double wQ, double wM, double wOut, double wImp, double wPrc, double wRev, double wExp) {
    return Container(
      decoration: const BoxDecoration(
        color: kHeaderBg,
        border: Border(bottom: BorderSide(color: kBorder, width: 1)),
      ),
      child: Row(
        children: [
          _hCell('Quarter', wQ),
          _hCell('Month', wM),
          _hCell('Electrical Current\nOutput (Kwh)', wOut),
          _hCell('Electricity\nImported For Use', wImp),
          _hCell('Selling\nPrice (\$)', wPrc),
          _hCell('Amount of\nmoney (\$)', wRev),
          _hCell('Expenses\n(\$)', wExp, last: true),
        ],
      ),
    );
  }

  Widget _hCell(String text, double w, {bool last = false}) {
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          right: last ? BorderSide.none : const BorderSide(color: kBorder, width: 0.5),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kTextBright,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
    );
  }

  List<Widget> _buildAllRows(double wQ, double wM, double wOut, double wImp, double wPrc, double wRev, double wExp) {
    List<Widget> rows = [];
    const quarters = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      [10, 11, 12],
    ];

    for (final qMonths in quarters) {
      final qLabel = _records[qMonths[0] - 1].quarterLabel;
      const double rowH = 38.0;

      for (int i = 0; i < qMonths.length; i++) {
        final m = qMonths[i];
        final r = _records[m - 1];
        final isFirst = i == 0;
        final isLast = i == qMonths.length - 1;
        final rowBg = m % 2 == 0 ? kRowAlt : kBg;

        rows.add(SizedBox(
          height: rowH,
          child: Row(
            children: [
              Container(
                width: wQ,
                height: rowH,
                decoration: BoxDecoration(
                  color: kSurface2,
                  border: Border(
                    right: const BorderSide(color: kBorder, width: 0.5),
                    bottom: isLast ? const BorderSide(color: kBorder, width: 1) : const BorderSide(color: kBorder, width: 0.5),
                  ),
                ),
                child: isFirst
                    ? Center(
                        child: Text(
                          qLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: kAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              _dCell(r.monthName, wM, rowBg, color: kText, isLast: isLast),
              _dCell(r.hasOutput ? _fmt(r.outputKwh) : '', wOut, rowBg, color: r.hasOutput ? kGreen : kTextDim, isLast: isLast),
              _dCell(r.importKwh > 0 ? _fmt(r.importKwh) : '', wImp, rowBg, color: r.importKwh > 0 ? kYellow : kTextDim, isLast: isLast),
              _dCell(r.sellingPrice.toStringAsFixed(2), wPrc, rowBg, color: kAccent3, isLast: isLast),
              _dCell(r.hasOutput ? r.revenue.toStringAsFixed(2) : '', wRev, rowBg, color: r.hasOutput ? kAccent : kTextDim, isLast: isLast),
              _expenseCell(m, wExp, rowBg, isLast: isLast),
            ],
          ),
        ));
      }
    }
    return rows;
  }

  Widget _dCell(String text, double w, Color bg, {Color color = kText, bool isLast = false}) {
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: const BorderSide(color: kBorder, width: 0.5),
          bottom: isLast ? const BorderSide(color: kBorder, width: 1) : const BorderSide(color: kBorder, width: 0.5),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _expenseCell(int month, double w, Color bg, {bool isLast = false}) {
    final r = _records[month - 1];
    final isEditing = _editingMonth == month;

    return GestureDetector(
      onTap: () {
        if (_editingMonth != null && _editingMonth != month) {
          _commitExpense(_editingMonth!);
        }
        setState(() {
          _editingMonth = month;
          _expCtrl[month]!.text = r.expenses != null ? r.expenses!.toStringAsFixed(2) : '';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_expFocus[month]);
        });
      },
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isEditing ? kSurface2 : bg,
          border: Border(
            right: BorderSide.none,
            bottom: isLast ? const BorderSide(color: kBorder, width: 1) : const BorderSide(color: kBorder, width: 0.5),
            left: isEditing ? const BorderSide(color: kAccent3, width: 1.5) : BorderSide.none,
          ),
        ),
        child: isEditing
            ? TextField(
                controller: _expCtrl[month],
                focusNode: _expFocus[month],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                style: const TextStyle(color: kTextBright, fontSize: 12, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0.00',
                  hintStyle: TextStyle(color: kTextDim, fontSize: 12),
                ),
                textAlign: TextAlign.center,
                onSubmitted: (_) => _commitExpense(month),
              )
            : Text(
                r.expenses != null ? r.expenses!.toStringAsFixed(2) : '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: r.expenses != null ? kAccent3 : kTextDim,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
      ),
    );
  }

  Widget _buildTotalRow(double wQ, double wM, double wOut, double wImp, double wPrc, double wRev, double wExp) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(color: kHeaderBg),
      child: Row(
        children: [
          Container(
            width: wQ,
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: kBorder, width: 0.5))),
          ),
          Container(
            width: wM,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: kBorder, width: 0.5))),
            child: Text(
              'Year Total\n($_selectedYear)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kAccent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          _totCell(_fmt(_totalOutput), wOut, color: kGreen),
          _totCell(_fmt(_totalImport), wImp, color: kYellow),
          _totCell('0.06', wPrc, color: kAccent3),
          _totCell(_totalRevenue.toStringAsFixed(2), wRev, color: kAccent),
          _totCell(
            _totalExpenses > 0 ? _totalExpenses.toStringAsFixed(2) : '',
            wExp,
            color: kAccent3,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _totCell(String text, double w, {Color color = kTextBright, bool last = false}) {
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(right: last ? BorderSide.none : const BorderSide(color: kBorder, width: 0.5)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildGraph() {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Monthly Revenue & Expenses',
            style: TextStyle(
              color: kAccent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: kBorder, width: 0.5),
              ),
              child: const Center(
                child: Text(
                  '// TODO: ໃສ່ Widget ກຣາຟຂອງທ່ານຢູ່ທີ່ນີ້\n\n(ແນະນຳໃຫ້ໃຊ້ package ຢ່າງເຊັ່ນ:\nfl_chart ຫຼື syncfusion_flutter_charts)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextDim,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double val) {
    if (val == 0) return '';
    final parts = val.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, Colors.transparent]),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 8.5, color: kTextDim, fontFamily: 'monospace')),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
          const SizedBox(height: 1),
          Text(unit, style: const TextStyle(fontSize: 8, color: kTextDim)),
        ],
      ),
    );
  }
}

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