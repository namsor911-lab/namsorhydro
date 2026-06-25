import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// Model
// ============================================================

class WaterRecord {
  String time;
  String weirLevel;
  String forebay;
  String volume;
  String usable;
  String gate;
  String diff;
  String area;
  String note;

  WaterRecord({
    required this.time,
    this.weirLevel = '',
    this.forebay = '',
    this.volume = '',
    this.usable = '',
    this.gate = '',
    this.diff = '',
    this.area = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'weirLevel': weirLevel,
        'forebay': forebay,
        'volume': volume,
        'usable': usable,
        'gate': gate,
        'diff': diff,
        'area': area,
        'note': note,
      };

  factory WaterRecord.fromJson(Map<String, dynamic> json) => WaterRecord(
        time: json['time'] ?? '',
        weirLevel: json['weirLevel'] ?? '',
        forebay: json['forebay'] ?? '',
        volume: json['volume'] ?? '',
        usable: json['usable'] ?? '',
        gate: json['gate'] ?? '',
        diff: json['diff'] ?? '',
        area: json['area'] ?? '',
        note: json['note'] ?? '',
      );
}

// ============================================================
// Main
// ============================================================

void main() {
  runApp(const WaterManagementApp());
}

class WaterManagementApp extends StatelessWidget {
  const WaterManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ບັນທຶກລະດັບນ້ຳ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF0D1B2A),
          primary: Color(0xFF0D84C8),
          secondary: Color(0xFF1565A8),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        fontFamily: 'NotoSansLao',
      ),
      home: const WaterLevelHomePage(),
    );
  }
}

// ============================================================
// Home Page
// ============================================================

class WaterLevelHomePage extends StatefulWidget {
  const WaterLevelHomePage({super.key});

  @override
  State<WaterLevelHomePage> createState() => _WaterLevelHomePageState();
}

class _WaterLevelHomePageState extends State<WaterLevelHomePage> {
  Map<String, List<WaterRecord>> records = {};
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  // 🔧 ສ້າງບ່ອນເກັບ TextEditingController ເພື່ອ reuse ແທນສ້າງໃໝ່ທຸກຄັ້ງ
  // Key = "dateKey_rowIndex_fieldName"
  final Map<String, TextEditingController> _controllers = {};

  static const List<String> _hours = [
    '00:00','01:00','02:00','03:00','04:00','05:00','06:00','07:00',
    '08:00','09:00','10:00','11:00','12:00','13:00','14:00','15:00',
    '16:00','17:00','18:00','19:00','20:00','21:00','22:00','23:00',
  ];

  static const List<String> _fieldKeys = [
    'weirLevel', 'forebay', 'volume', 'usable',
    'gate', 'diff', 'area', 'note',
  ];

  // ປ້າຍຊື່ພາສາລາວສຳລັບກຣາຟ
  final Map<String, String> _fieldLabels = {
    'weirLevel': 'ລະດັບ Weir (m)',
    'forebay': 'Forebay (m)',
    'volume': 'ນ້ຳໃນອ່າງ',
    'usable': 'ນ້ຳທີ່ໃຊ້',
    'gate': 'ເປີດ Weir',
    'diff': 'ຕ່າງກັນ',
    'area': 'ເນື້ອທີ່ (km²)',
  };

  final Map<String, Color> _fieldColors = {
    'weirLevel': Colors.blue,
    'forebay': Colors.cyan,
    'volume': Colors.green,
    'usable': Colors.teal,
    'gate': Colors.orange,
    'diff': Colors.purple,
    'area': Colors.pink,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // 🔧 ຕ້ອງ dispose controller ທຸກອັນເມື່ອ widget ຖືກທຳລາຍ
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  // 🔧 ສ້າງຫຼື reuse controller ຕາມ key
  TextEditingController _getController(String dateKey, int rowIdx, String field, String value) {
    final key = '${dateKey}_$rowIdx _$field';
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: value);
    }
    // 🔧 ອັບເດດຄ່າໃນ controller ຖ້າຂໍ້ມູນຖືກປ່ຽນຈາກພາຍນອກ (ຄືການລ້າງຂໍ້ມູນ)
    final ctrl = _controllers[key]!;
    if (ctrl.text != value) {
      ctrl.text = value;
      ctrl.selection = TextSelection.collapsed(offset: value.length);
    }
    return ctrl;
  }

  // 🔧 ລ້າງ controller ເມື່ອປ່ຽນວັນທີ ຫຼື ລ້າງຂໍ້ມູນ
  void _clearControllers() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _controllers.clear();
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _displayDate(String key) {
    final p = key.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : key;
  }

  // 🔧 ປ່ຽນຈາກ getter ທີ່ມີ side effect ເປັນ method ທີ່ຊັດເຈນ
  List<WaterRecord> _getCurrentRows() {
    final key = _dateKey(_selectedDate);
    if (!records.containsKey(key)) {
      records[key] = _hours.map((t) => WaterRecord(time: t)).toList();
    }
    return records[key]!;
  }

  String _getField(WaterRecord rec, String field) {
    switch (field) {
      case 'weirLevel': return rec.weirLevel;
      case 'forebay':   return rec.forebay;
      case 'volume':    return rec.volume;
      case 'usable':    return rec.usable;
      case 'gate':      return rec.gate;
      case 'diff':      return rec.diff;
      case 'area':      return rec.area;
      case 'note':      return rec.note;
      default:          return '';
    }
  }

  void _setField(WaterRecord rec, String field, String value) {
    switch (field) {
      case 'weirLevel': rec.weirLevel = value; break;
      case 'forebay':   rec.forebay   = value; break;
      case 'volume':    rec.volume    = value; break;
      case 'usable':    rec.usable    = value; break;
      case 'gate':      rec.gate      = value; break;
      case 'diff':      rec.diff      = value; break;
      case 'area':      rec.area      = value; break;
      case 'note':      rec.note      = value; break;
    }
  }

  int get _filledCells {
    int n = 0;
    for (final r in _getCurrentRows()) {
      for (final f in _fieldKeys) {
        if (_getField(r, f).isNotEmpty) n++;
      }
    }
    return n;
  }

  int get _totalCells => _getCurrentRows().length * _fieldKeys.length;

  Future<void> _saveData() async {
    if (_isSaving) return; // 🔧 ປ້ອງການກົດຊ້ຳ
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      records.removeWhere(
          (k, v) => v.every((r) => _fieldKeys.every((f) => _getField(r, f).isEmpty)));
      final encoded = jsonEncode(
        records.map((k, v) => MapEntry(k, v.map((r) => r.toJson()).toList())),
      );
      await prefs.setString('waterLevelData', encoded);
      await Future.delayed(const Duration(milliseconds: 700));
    } catch (e) {
      // 🔧 ຈັບ error ແທນໃຫ້ crash
      if (mounted) _snack('ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກ');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadData() async {
    try { // 🔧 ເພີ່ມ try-catch ປ້ອງກັນ crash ເມື່ອ JSON ເສຍ
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('waterLevelData');
      if (saved != null) {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        setState(() {
          records = decoded.map((k, v) => MapEntry(
                k,
                (v as List).map((r) => WaterRecord.fromJson(r as Map<String, dynamic>)).toList(),
              ));
        });
      }
    } catch (e) {
      // ຖ້າຂໍ້ມູນເສຍ, ເລີ່ມດ້ວຍ records ວ່າງ
      if (mounted) _snack('ບໍ່ສາມາດໂຫຼດຂໍ້ມູນເກົ່າໄດ້');
    }
  }

  Future<void> _clearCurrentDay() async {
    final confirmed = await _confirmDialog(
      'ລ້າງຂໍ້ມູນວັນທີ ${_displayDate(_dateKey(_selectedDate))}',
      'ທ່ານຕ້ອງການລ້າງຂໍ້ມູນຂອງວັນທີນີ້ທັງໝົດບໍ?',
    );
    if (!confirmed) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _dateKey(_selectedDate);
    _clearControllers(); // 🔧 ລ້າງ controller ເກົ່າ
    setState(() {
      records.remove(key);
    });
    await prefs.setString(
      'waterLevelData',
      jsonEncode(records.map((k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()))),
    );
  }

  Future<void> _exportCSV() async {
    final key = _dateKey(_selectedDate);
    final headers = [
      'ວ/ດ/ປ', 'ເວລາ', 'ລະດັບ Weir (m)', 'Forebay (m)',
      'ປະລິມານໃນອ່າງ', 'ນ້ຳທີ່ໃຊ້', 'ເປີດ Weir (Cm)',
      'ຕ່າງກັນ', 'ເນື້ອທີ່ (km²)', 'ໝາຍເຫດ',
    ];
    final lines = <String>[headers.join(',')];
    for (final r in _getCurrentRows()) {
      // 🔧 ຄອມມາໃນ field ທັງໝົດທີ່ອາດມີ comma ໄດ້ດ້ວຍການຫໍ້ດ້ວຍ ""
      lines.add([
        _displayDate(key), r.time,
        r.weirLevel, r.forebay, r.volume, r.usable,
        r.gate, r.diff, r.area,
        '"${r.note.replaceAll('"', '""')}"', // 🔧 escape double-quote ໃນ note
      ].join(','));
    }
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    _snack('CSV ຄັດລອກໄປຄລິບບອດແລ້ວ');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF0A3D6B),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<bool> _confirmDialog(String title, String body) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF132840),
        title: Text(title, style: const TextStyle(color: Color(0xFF90C2E8))),
        content: Text(body, style: const TextStyle(color: Color(0xFFC5DDF0))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Color(0xFF7FAAC8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ຢືນຢັນ'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF0D84C8),
            onPrimary: Colors.white,
            surface: Color(0xFF132840),
          ),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      _clearControllers(); // 🔧 ລ້າງ controller ເກົ່າເມື່ອປ່ຽນວັນທີ
      setState(() => _selectedDate = result);
    }
  }

  void _prevDay() {
    _clearControllers(); // 🔧 ລ້າງ controller ເກົ່າ
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  }
  void _nextDay() {
    _clearControllers(); // 🔧 ລ້າງ controller ເກົ່າ
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final currentRows = _getCurrentRows();

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildToolbar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 🔧 ປ່ຽນເປັນ responsive ແທນກຳນົດຄວາມກ້ວາງຕາຍ
                final bool showSideBySide = constraints.maxWidth >= 900;
                if (showSideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ດ້ານຊ້າຍ: ຕາຕະລາງຂໍ້ມູນ - ໃຊ້ ratio ແທນຄວາມກ້ວາງຕາຍ
                      SizedBox(
                        width: constraints.maxWidth * 0.6,
                        child: _buildTableArea(currentRows),
                      ),
                      Container(width: 2, color: const Color(0xFF2A5070)),
                      Expanded(
                        child: _buildChartArea(currentRows),
                      ),
                    ],
                  );
                } else {
                  // 🔧 ໜ້າຈໍນ້ອຍ: ສະແດງແບບ stack (ຕາຕະລາງເທິງ, ກຣາຟລຸ່ມ)
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: constraints.maxHeight * 0.55,
                          child: _buildTableArea(currentRows),
                        ),
                        Container(height: 2, color: const Color(0xFF2A5070)),
                        SizedBox(
                          height: constraints.maxHeight * 0.45,
                          child: _buildChartArea(currentRows),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          _buildStatsBar(),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D6B), Color(0xFF1565A8), Color(0xFF0D84C8)],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('💧', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💧 ບັນທຶກລະດັບນ້ຳ ແລະ ປະລິມານນ້ຳ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  'Water Level & Volume Recording System',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Toolbar ─────────────────────────────────────────────────

  Widget _buildToolbar() {
    final key = _dateKey(_selectedDate);
    final hasData = records.containsKey(key) &&
        records[key]!.any((r) => _fieldKeys.any((f) => _getField(r, f).isNotEmpty));

    return Container(
      color: const Color(0xFF132840),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _iconBtn(Icons.chevron_left, _prevDay),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A5070)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 15, color: Color(0xFF5BBDF5)),
                  const SizedBox(width: 8),
                  Text(
                    _displayDate(key),
                    style: const TextStyle(
                      color: Color(0xFF5BBDF5),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _iconBtn(Icons.chevron_right, _nextDay),
          if (hasData)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.5)),
              ),
              child: const Text('● ມີຂໍ້ມູນ', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11)),
            ),
          const Spacer(),
          _toolBtn(label: 'ວັນນີ້', color: const Color(0xFF1E3D5C),
              border: const Color(0xFF2A5070),
              onTap: () {
                _clearControllers(); // 🔧 ລ້າງ controller ເມື່ອປ່ຽນວັນ
                setState(() => _selectedDate = DateTime.now());
              }),
          const SizedBox(width: 6),
          _toolBtn(label: '⬇ CSV', color: const Color(0xFFD97706), onTap: _exportCSV),
          const SizedBox(width: 6),
          // 🔧 ປິດການກົດປຸ່ມເມື່ອກຳລັງບັນທຶກ
          _toolBtn(
            label: _isSaving ? '✅ ບັນທຶກສຳເລັດ' : '💾 ບັນທຶກ',
            color: const Color(0xFF16A34A),
            onTap: _isSaving ? () {} : _saveData, // 🔧 ປ້ອງການກົດຊ້ຳ
          ),
          const SizedBox(width: 6),
          _toolBtn(label: '🗑 ລ້າງ', color: const Color(0xFFDC2626), onTap: _clearCurrentDay),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFF90C2E8)),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF0D1B2A),
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _toolBtn({
    required String label,
    required Color color,
    Color? border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }

  // ── Table Area ──────────────────────────────────────────────

  Widget _buildTableArea(List<WaterRecord> rows) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // 🔧 ເພີ່ມ scroll ແນວນອນ ສຳລັບໜ້າຈໍນ້ອຍ
          child: _buildDataTable(rows),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<WaterRecord> rows) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFF0A3D6B)),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFF0D84C8).withValues(alpha: 0.12);
        }
        return Colors.transparent;
      }),
      border: TableBorder.all(color: const Color(0xFF3A6080), width: 1.2),
      columnSpacing: 0,
      headingRowHeight: 46,
      dataRowMinHeight: 38,
      dataRowMaxHeight: 38,
      columns: [
        _col('ເວລາ',           width: 55),
        _col('Weir\n(m)',       width: 75),
        _col('Forebay\n(m)',    width: 80),
        _col('ນ້ຳໃນ\nອ່າງ',    width: 80),
        _col('ນ້ຳທີ່ໃຊ້',      width: 80),
        _col('ເປີດ\nWeir',     width: 75),
        _col('ຕ່າງກັນ',        width: 75),
        _col('ເນື້ອທີ່\n(km²)', width: 80),
        _col('ໝາຍເຫດ',         width: 140),
      ],
      rows: List.generate(rows.length, (i) => _buildRow(rows, i)),
    );
  }

  DataColumn _col(String label, {double width = 80}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE2EFF9), fontWeight: FontWeight.w700, fontSize: 12, height: 1.2),
        ),
      ),
    );
  }

  DataRow _buildRow(List<WaterRecord> rows, int i) {
    final key = _dateKey(_selectedDate);
    final rec = rows[i];
    return DataRow(cells: [
      DataCell(Container(
        width: 55,
        color: const Color(0xFF0B2236),
        alignment: Alignment.center,
        child: Text(rec.time, style: const TextStyle(color: Color(0xFF94B9D5), fontWeight: FontWeight.bold, fontSize: 13)),
      )),
      ..._fieldKeys.sublist(0, 7).map((f) => DataCell(
            _editCell(key, i, rec, f, isNumeric: true),
          )),
      DataCell(_editCell(key, i, rec, 'note', isNumeric: false)),
    ]);
  }

  Widget _editCell(String dateKey, int idx, WaterRecord rec, String field,
      {required bool isNumeric}) {
    // 🔧 ໃຊ້ controller ທີ່ reuse ໄດ້ຈາກ Map ແທນສ້າງໃໝ່ທຸກຄັ້ງ
    final ctrl = _getController(dateKey, idx, field, _getField(rec, field));
    final isNote = field == 'note';

    return SizedBox(
      width: isNote ? 140 : (field == 'weirLevel' || field == 'gate' || field == 'diff' ? 75 : 80),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        textAlign: isNumeric ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: isNumeric ? const Color(0xFFE2EFF9) : const Color(0xFFA0BCD0),
          fontSize: 13,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          hintText: '-',
          hintStyle: TextStyle(color: Color(0xFF2A5070)),
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          isDense: true,
        ),
        onChanged: (v) {
          _setField(rec, field, v);
          // 🔧 ບໍ່ຕ້ອງ setState ທັງໝົດ, ອັບເດດພຽງກຣາຟ
          // ຂໍ້ມູນໃນ model ຖືກອັບເດດແລ້ວຈາກ _setField
          // ພຽງແຕ່ຕ້ອງ repaint ກຣາຟ
          _chartKey.currentState?.requestPaint(); // 🔧 ອັບເດດກຣາຟໂດຍກົງ
          _updateStats(); // 🔧 ອັບເດດ stats bar
        },
      ),
    );
  }

  // 🔧 ໃຊ້ GlobalKey ສຳລັບກຣາຟ ເພື່ອ repaint ໂດຍກົງໂດຍບໍ່ຕ້ອງ setState ທັງໝົດ
  final GlobalKey<_ChartWidgetState> _chartKey = GlobalKey();
  // 🔧 ສຳລັບ stats bar
  final GlobalKey<_StatsBarState> _statsKey = GlobalKey();

  void _updateStats() {
    _statsKey.currentState?.update();
  }

  // ── ສ່ວນສະແດງກຣາຟ (Chart Area) ──────────────────────────

  Widget _buildChartArea(List<WaterRecord> rows) {
    return Container(
      color: const Color(0xFF0A1520),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 ກຣາຟສະແດງທ່າອ່ຽງລາຍຊົ່ວໂມງ (ທຸກເສັ້ນຂໍ້ມູນ)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          
          // ຄຳອະທິບາຍສີຂອງແຕ່ລະເສັ້ນກຣາຟ (Legend)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: _fieldLabels.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _fieldColors[e.key],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    e.value,
                    style: const TextStyle(color: Color(0xFF6C8EA7), fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          
          // 🔧 ໃຊ້ StatefulWidget wrapper ເພື່ອ repaint ແບບ targeted
          Expanded(
            child: _ChartWidget(
              key: _chartKey,
              rows: rows,
              hours: _hours,
              fieldKeys: _fieldColors.keys.toList(),
              fieldColors: _fieldColors,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Bar ──────────────────────────────────────────────

  Widget _buildStatsBar() {
    final key = _dateKey(_selectedDate);
    final hasData = records.containsKey(key);

    return _StatsBar(
      key: _statsKey,
      dateKey: key,
      displayDate: _displayDate(key),
      rowsCount: _getCurrentRows().length,
      filledCells: _filledCells,
      totalCells: _totalCells,
      hasData: hasData,
    );
  }
}

// ============================================================
// 🔧 Chart Widget wrapper (StatefulWidget) ເພື່ອສາມາດ repaint ໄດ້ໂດຍກົງ
// ============================================================

class _ChartWidget extends StatefulWidget {
  final List<WaterRecord> rows;
  final List<String> hours;
  final List<String> fieldKeys;
  final Map<String, Color> fieldColors;

  const _ChartWidget({
    super.key,
    required this.rows,
    required this.hours,
    required this.fieldKeys,
    required this.fieldColors,
  });

  @override
  State<_ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<_ChartWidget> {
  int _repaintVersion = 0;

  void requestPaint() {
    if (mounted) {
      setState(() {
        _repaintVersion++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ການອ້າງອີງ _repaintVersion ປ້ອງກັນ tree shaking
    debugPrint('chart repaint v$_repaintVersion');
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: MultiLineChartPainter(
            rows: widget.rows,
            hours: widget.hours,
            fieldKeys: widget.fieldKeys,
            fieldColors: widget.fieldColors,
          ),
        );
      },
    );
  }
}

// ============================================================
// 🔧 Stats Bar Widget (StatefulWidget) ເພື່ອສາມາດອັບເດດແບບ targeted
// ============================================================

class _StatsBar extends StatefulWidget {
  final String dateKey;
  final String displayDate;
  final int rowsCount;
  final int filledCells;
  final int totalCells;
  final bool hasData;

  const _StatsBar({
    super.key,
    required this.dateKey,
    required this.displayDate,
    required this.rowsCount,
    required this.filledCells,
    required this.totalCells,
    required this.hasData,
  });

  @override
  State<_StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<_StatsBar> {
  void update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E2237),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _stat('📅 ວັນທີ:', widget.displayDate),
          const SizedBox(width: 20),
          _stat('⏱ ເວລາ:', '${widget.rowsCount} ຊ່ວງ'),
          const SizedBox(width: 20),
          _stat('📝 ກໍາລັງຂຽນ:', '${widget.filledCells} / ${widget.totalCells} ຊ່ອງ'),
          const Spacer(),
          if (!widget.hasData)
            const Text('(ຍັງບໍ່ໄດ້ບັນທຶກ)', style: TextStyle(color: Color(0xFF3A6080), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF7FAAC8), fontSize: 12)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Color(0xFF5BBDF5), fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

// ============================================================
// Custom Painter ສຳລັບແຕ້ມກຣາຟລວມທຸກເສັ້ນ (Multi-Line Painter)
// ============================================================

class MultiLineChartPainter extends CustomPainter {
  final List<WaterRecord> rows;
  final List<String> hours;
  final List<String> fieldKeys;
  final Map<String, Color> fieldColors;

  MultiLineChartPainter({
    required this.rows,
    required this.hours,
    required this.fieldKeys,
    required this.fieldColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 45.0;
    const double paddingRight = 20.0;
    const double paddingTop = 20.0;
    const double paddingBottom = 30.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // 1. ຄິດໄລ່ຫາຄ່າສູງສຸດ ແລະ ຕ່ຳສຸດ ຈາກທຸກໆຟີລດ໌ຕົວເລກພ້ອມກັນ
    double maxVal = -double.infinity;
    double minVal = double.infinity;
    bool hasValidData = false;

    for (final key in fieldKeys) {
      for (final r in rows) {
        final valStr = _getValueStr(r, key);
        final val = double.tryParse(valStr);
        if (val != null) {
          hasValidData = true;
          if (val > maxVal) maxVal = val;
          if (val < minVal) minVal = val;
        }
      }
    }

    if (!hasValidData) {
      maxVal = 10.0;
      minVal = 0.0;
    } else if (maxVal == minVal) {
      maxVal += 1.0;
      minVal = (minVal - 1.0).clamp(0.0, double.infinity); // 🔧 ບໍ່ໃຫ້ຕ່ຳກວ່າ 0 ຖ້າຂໍ້ມູນບໍ່ມີຄ່າລົບ
    }

    // ເພີ່ມ Buffer ຂອບເທິງລຸ່ມ
    double buffer = (maxVal - minVal) * 0.15;
    if (buffer == 0) buffer = 1.0;
    maxVal += buffer;
    minVal -= buffer;
    // 🔧 ປ້ອງກັນ minVal ຕ່ຳກວ່າ 0 ຖ້າຂໍ້ມູນບໍ່ມີຄ່າລົບ
    if (minVal < 0 && !hasValidData) minVal = 0.0;

    // 2. ແຕ້ມເສັ້ນຕາຕະລາງພື້ນຫຼັງ (ແກນ Y)
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF1E2E3D)
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    const int yDivisions = 5;
    for (int i = 0; i <= yDivisions; i++) {
      double yRatio = i / yDivisions;
      double yPos = paddingTop + chartHeight * (1 - yRatio);
      
      canvas.drawLine(Offset(paddingLeft, yPos), Offset(size.width - paddingRight, yPos), gridPaint);

      double currentYVal = minVal + (maxVal - minVal) * yRatio;
      textPainter.text = TextSpan(
        text: currentYVal.toStringAsFixed(1),
        style: const TextStyle(color: Color(0xFF6C8EA7), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, yPos - textPainter.height / 2));
    }

    // 3. ແຕ້ມເສັ້ນແນວຕັ້ງ ແລະ ເວລາ (ແກນ X)
    final double xStep = rows.length > 1 ? chartWidth / (rows.length - 1) : chartWidth;
    for (int i = 0; i < rows.length; i++) {
      double xPos = paddingLeft + (i * xStep);

      if (i % 4 == 0 || i == rows.length - 1) {
        canvas.drawLine(Offset(xPos, paddingTop), Offset(xPos, paddingTop + chartHeight), gridPaint);

        textPainter.text = TextSpan(
          text: hours[i],
          style: const TextStyle(color: Color(0xFF6C8EA7), fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, paddingTop + chartHeight + 6));
      }
    }

    if (!hasValidData) return;

    // 4. ວົງລູບແຕ້ມກຣາຟແຕ່ລະເສັ້ນຕາມສີທີ່ກຳນົດໄວ້
    for (final key in fieldKeys) {
      final Color color = fieldColors[key] ?? Colors.white;

      final Paint linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Paint dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // 🔧 ແຕ້ມເສັ້ນເປັນສ່ວນໆ (segments) ເພື່ອຕັດເສັ້ນເມື່ອຂໍ້ມູນຫວ່າງ
      List<Offset> validPoints = [];

      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final valStr = _getValueStr(r, key);
        final val = double.tryParse(valStr);
        if (val == null) continue;

        double xPos = paddingLeft + (i * xStep);
        double yRatio = (val - minVal) / (maxVal - minVal);
        double yPos = paddingTop + chartHeight * (1 - yRatio);
        validPoints.add(Offset(xPos, yPos));
      }

      // 🔧 ແຕ້ມເສັ້ນກຣາຟແບບຕໍ່ເນື່ອງຈາກຈຸດທີ່ມີຂໍ້ມູນ
      if (validPoints.length >= 2) {
        Path strokePath = Path();
        strokePath.moveTo(validPoints[0].dx, validPoints[0].dy);
        for (int i = 1; i < validPoints.length; i++) {
          strokePath.lineTo(validPoints[i].dx, validPoints[i].dy);
        }
        canvas.drawPath(strokePath, linePaint);
      } else if (validPoints.length == 1) {
        // ມີພຽງຈຸດດຽວ, ແຕ້ມຈຸດໃຫຍ່
        canvas.drawCircle(validPoints[0], 5.0, dotPaint);
      }

      // ແຕ້ມຈຸດຂໍ້ມູນ
      for (final point in validPoints) {
        canvas.drawCircle(point, 3.0, dotPaint);
      }
    }
  }

  // 🔧 ສ້າງ helper method ເພື່ອຫຼຸດການຊ້ຳຂອງ if-else
  String _getValueStr(WaterRecord r, String key) {
    switch (key) {
      case 'weirLevel': return r.weirLevel;
      case 'forebay':   return r.forebay;
      case 'volume':    return r.volume;
      case 'usable':    return r.usable;
      case 'gate':      return r.gate;
      case 'diff':      return r.diff;
      case 'area':      return r.area;
      default:          return '';
    }
  }

  @override
  bool shouldRepaint(covariant MultiLineChartPainter oldDelegate) {
    // 🔧 ປຽບທຽບເນື້ອຫາຂອງ rows ແທນ reference
    if (oldDelegate.rows.length != rows.length) return true;
    if (oldDelegate.fieldKeys.length != fieldKeys.length) return true;

    for (int i = 0; i < rows.length && i < oldDelegate.rows.length; i++) {
      if (oldDelegate.rows[i].weirLevel != rows[i].weirLevel ||
          oldDelegate.rows[i].forebay != rows[i].forebay ||
          oldDelegate.rows[i].volume != rows[i].volume ||
          oldDelegate.rows[i].usable != rows[i].usable ||
          oldDelegate.rows[i].gate != rows[i].gate ||
          oldDelegate.rows[i].diff != rows[i].diff ||
          oldDelegate.rows[i].area != rows[i].area) {
        return true;
      }
    }
    return false;
  }
}
