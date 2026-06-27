// hr_screen.dart
// ລະບົບ HR — ຕາຕະລາງເງິນເດືອນ Namsor Hydropower
// ແກ້ໄຂບັນຫາທັງໝົດຈາກ flutter analyze
// ປັບປຸງໃຫ້ຕາຕະລາງເຕັມໜ້າຈໍ ແລະ ຕົວອັກສອນໃຫຍ່ຂຶ້ນ
// ເພີ່ມເສັ້ນຂອບຕາຕະລາງສີຂາວ ແລະ ພື້ນຫຼັງລາຍເຊັນສີຂາວ

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // ignore: deprecated_member_use

// ─── ຄົງທີ່ສີ ແລະ ຮູບແບບ ───
class HrColors {
  static const Color bg = Color(0xFF0D1117);
  static const Color bg2 = Color(0xFF161B22);
  static const Color bg3 = Color(0xFF1C2128);
  static const Color bg4 = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);
  static const Color border2 = Color(0xFF21262D);
  static const Color txt = Color(0xFFE6EDF3);
  static const Color txt2 = Color(0xFF8B949E);
  static const Color txt3 = Color(0xFF484F58);
  static const Color green = Color(0xFF3FB950);
  static const Color greenDim = Color(0x1E3FB950);
  static const Color red = Color(0xFFF85149);
  static const Color redDim = Color(0x1EF85149);
  static const Color blue = Color(0xFF58A6FF);
  static const Color blueDim = Color(0x1E58A6FF);
  static const Color yellow = Color(0xFFE3B341);
  static const Color yellowDim = Color(0x1EE3B341);
  static const Color accent = Color(0xFF238636);
  static const Color white = Color(0xFFFFFFFF);
}

// ─── ໂຄງສ້າງຂໍ້ມູນພະນັກງານ ───
class Employee {
  final String id;
  String name;
  String role;
  double basic;
  double ot;
  double living;
  double other;
  double deduct;

  Employee({
    required this.id,
    required this.name,
    this.role = '',
    this.basic = 0,
    this.ot = 0,
    this.living = 0,
    this.other = 0,
    this.deduct = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'basic': basic,
    'ot': ot,
    'living': living,
    'other': other,
    'deduct': deduct,
  };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    role: json['role'] ?? '',
    basic: (json['basic'] ?? 0).toDouble(),
    ot: (json['ot'] ?? 0).toDouble(),
    living: (json['living'] ?? 0).toDouble(),
    other: (json['other'] ?? 0).toDouble(),
    deduct: (json['deduct'] ?? 0).toDouble(),
  );
}

// ─── ຜົນການຄຳນວນ ───
class TaxResult {
  final double gross;
  final double before;
  final double exempt;
  final double b5;
  final double b10;
  final double b15;
  final double b20;
  final double b25;
  final double tax;
  final double net;

  const TaxResult({
    required this.gross,
    required this.before,
    required this.exempt,
    required this.b5,
    required this.b10,
    required this.b15,
    required this.b20,
    required this.b25,
    required this.tax,
    required this.net,
  });

  double get b15Up => b15 + b20 + b25;
}

// ─── ຟັງຊັນຄຳນວນພາສີ ───
TaxResult calcTax(double basic, double ot, double living, double other, double deduct) {
  final gross = basic + ot + living + other;
  final before = (gross - deduct).clamp(0.0, double.infinity);
  
  final exempt = before.clamp(0.0, 1300000.0);
  final b5 = (before - 1300000.0).clamp(0.0, 5000000.0 - 1300000.0);
  final b10 = (before - 5000000.0).clamp(0.0, 15000000.0 - 5000000.0);
  final b15 = (before - 15000000.0).clamp(0.0, 25000000.0 - 15000000.0);
  final b20 = (before - 25000000.0).clamp(0.0, 65000000.0 - 25000000.0);
  final b25 = (before - 65000000.0).clamp(0.0, double.infinity);
  
  final tax = (b5 * 0.05) + (b10 * 0.10) + (b15 * 0.15) + (b20 * 0.20) + (b25 * 0.25);
  final net = gross - tax;

  return TaxResult(
    gross: gross,
    before: before,
    exempt: exempt,
    b5: b5,
    b10: b10,
    b15: b15,
    b20: b20,
    b25: b25,
    tax: tax,
    net: net,
  );
}

// ─── ການກຳນົດຖັນຕາຕະລາງ (ສຳລັບເຮັດໃຫ້ຕາຕະລາງສົມດຸນ ແລະ ເຕັມຈໍ) ───
// weight = ສ່ວນແບ່ງພື້ນທີ່ທີ່ເຫຼືອ, minWidth = ກວ້າງນ້ອຍສຸດ (ກັນບໍ່ໃຫ້ບີບແໜ້ນຈົນອ່ານບໍ່ອອກ)
class _ColSpec {
  final String label;
  final Color color;
  final double weight;
  final double minWidth;
  final Alignment align;

  const _ColSpec(
    this.label,
    this.color,
    this.weight,
    this.minWidth, {
    this.align = Alignment.centerLeft,
  });
}

// ─── ໜ້າຫຼັກ HR ───
class HrScreen extends StatefulWidget {
  const HrScreen({super.key});

  @override
  State<HrScreen> createState() => _HrScreenState();
}

class _HrScreenState extends State<HrScreen> {
  // ─── ຕົວແປສຳຄັນ ───
  Map<String, List<Employee>> _db = {};
  Map<String, String> _signatures = {};
  String _selectedMonth = '';
  String _selectedYear = '';
  List<Employee> _currentEmployees = [];
  final DateTime _now = DateTime.now();

  // ຕົວແປສຳລັບ Modal
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _basicController = TextEditingController();
  final _otController = TextEditingController();
  final _livingController = TextEditingController();
  final _otherController = TextEditingController();
  final _deductController = TextEditingController();
  int _editingIndex = -1;

  // ຕົວແປສຳລັບ Signature
  int _sigIndex = -1;
  final List<Offset> _sigPoints = <Offset>[];
  final GlobalKey _sigCanvasKey = GlobalKey();

  // ─── ການເກັບຂໍ້ມູນ ───
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dbStr = prefs.getString('nhr_v2');
    if (dbStr != null) {
      try {
        final Map<String, dynamic> raw = jsonDecode(dbStr);
        _db = raw.map((key, value) {
          final list = (value as List).map((e) => Employee.fromJson(e)).toList();
          return MapEntry(key, list);
        });
      } catch (_) {}
    }
    final sigStr = prefs.getString('nhr_sigs_v1');
    if (sigStr != null) {
      try {
        _signatures = Map<String, String>.from(jsonDecode(sigStr));
      } catch (_) {}
    }
    _updateCurrent();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final dbJson = _db.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()));
    await prefs.setString('nhr_v2', jsonEncode(dbJson));
    await prefs.setString('nhr_sigs_v1', jsonEncode(_signatures));
  }

  String _getKey() => '${_selectedYear}_$_selectedMonth';

  void _updateCurrent() {
    setState(() {
      _currentEmployees = _db[_getKey()] ?? <Employee>[];
    });
  }

  // ─── ການຈັດການພະນັກງານ ───
  void _addEmployee(Employee emp) {
    final key = _getKey();
    if (!_db.containsKey(key)) _db[key] = <Employee>[];
    _db[key]!.add(emp);
    _saveData();
    _updateCurrent();
  }

  void _updateEmployee(int index, Employee emp) {
    final key = _getKey();
    if (_db.containsKey(key) && index < _db[key]!.length) {
      _db[key]![index] = emp;
      _saveData();
      _updateCurrent();
    }
  }

  void _deleteEmployee(int index) {
    final key = _getKey();
    if (_db.containsKey(key) && index < _db[key]!.length) {
      _db[key]!.removeAt(index);
      _saveData();
      _updateCurrent();
    }
  }

  // ─── ສະຫຼຸບ ───
  Map<String, double> _getTotals() {
    double totalGross = 0, totalDeduct = 0, totalBefore = 0, totalTax = 0, totalNet = 0;
    for (var emp in _currentEmployees) {
      final r = calcTax(emp.basic, emp.ot, emp.living, emp.other, emp.deduct);
      totalGross += r.gross;
      totalDeduct += emp.deduct;
      totalBefore += r.exempt;
      totalTax += r.tax;
      totalNet += r.net;
    }
    return {
      'count': _currentEmployees.length.toDouble(),
      'gross': totalGross,
      'deduct': totalDeduct,
      'before': totalBefore,
      'tax': totalTax,
      'net': totalNet,
    };
  }

  // ─── ຟອຣແມັດ ───
  String _fmt(double n) {
    if (n == 0) return '0';
    return NumberFormat('#,##0').format(n);
  }

  String _fmtCurrency(double n) {
    return '${NumberFormat('#,##0').format(n.round())} ₭';
  }

  // ─── ຊື່ເດືອນ ───
  final List<String> _monthNames = const <String>[
    'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ', 'ພຶດສະພາ', 'ມິຖຸນາ',
    'ກໍລະກົດ', 'ສິງຫາ', 'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ'
  ];

  // ─── Modal ເພີ່ມ/ແກ້ໄຂ ───
  void _openAddModal() {
    _editingIndex = -1;
    _nameController.clear();
    _roleController.clear();
    _basicController.clear();
    _otController.clear();
    _livingController.clear();
    _otherController.clear();
    _deductController.clear();
    _showModal('➕ ເພີ່ມພະນັກງານ');
  }

  void _openEditModal(int index) {
    final emp = _currentEmployees[index];
    _editingIndex = index;
    _nameController.text = emp.name;
    _roleController.text = emp.role;
    _basicController.text = emp.basic.toString();
    _otController.text = emp.ot.toString();
    _livingController.text = emp.living.toString();
    _otherController.text = emp.other.toString();
    _deductController.text = emp.deduct.toString();
    _showModal('✏️ ແກ້ໄຂຂໍ້ມູນພະນັກງານ');
  }

  void _showModal(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setModalState) {
          return AlertDialog(
            backgroundColor: HrColors.bg2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: HrColors.border),
            ),
            title: Row(
              children: <Widget>[
                const Icon(Icons.person_add, color: HrColors.green),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: HrColors.txt, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // ຊື່ ແລະ ໜ້າທີ່
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildTextField('ຊື່ ແລະ ນາມສະກຸນ *', _nameController),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField('ໜ້າທີ່ຮັບຜິດຊອບ', _roleController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ລາຍຮັບ
                  _buildSectionHeader('💰 ລາຍຮັບ'),
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildNumberField('ເງິນເດືອນພື້ນຖານ', _basicController, setModalState)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildNumberField('ອັດຕາກີນ', _otController, setModalState)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildNumberField('ເງີນເດີນທາງ', _livingController, setModalState)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildNumberField('ໂອທີຕ່າງໆ', _otherController, setModalState)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ຫັກມຕ.35
                  _buildSectionHeader('📉 ຫັກອອກ — ມຕ.35'),
                  _buildNumberField('ເງີນເພີ່ມໂມງແລະຊ່ວງເວລາທີ່ບໍ່ຄືກຫັກອາກອນ', _deductController, setModalState),
                  const SizedBox(height: 16),
                  // ສະຫຼຸບການຄຳນວນ
                  _buildPreview(setModalState),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ຍົກເລີກ', style: TextStyle(color: HrColors.txt2)),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveEmployee(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HrColors.accent,
                  foregroundColor: HrColors.white,
                ),
                child: const Text('✅ ບັນທຶກ'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(color: HrColors.txt2, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: HrColors.txt, fontSize: 13),
          decoration: const InputDecoration(
            filled: true,
            fillColor: HrColors.bg3,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: HrColors.border),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: HrColors.border),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: HrColors.blue),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(color: HrColors.txt2, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: HrColors.txt, fontSize: 13),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setModalState(() {}),
          decoration: const InputDecoration(
            filled: true,
            fillColor: HrColors.bg3,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: HrColors.border),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: HrColors.border),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: HrColors.blue),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: HrColors.txt2, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPreview(StateSetter setModalState) {
    final basic = double.tryParse(_basicController.text) ?? 0;
    final ot = double.tryParse(_otController.text) ?? 0;
    final living = double.tryParse(_livingController.text) ?? 0;
    final other = double.tryParse(_otherController.text) ?? 0;
    final deduct = double.tryParse(_deductController.text) ?? 0;
    final result = calcTax(basic, ot, living, other, deduct);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HrColors.greenDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: HrColors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('📊 ສະຫຼຸບການຄຳນວນ', style: TextStyle(color: HrColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _previewRow('ເງິນເດືອນທົ່ງໝົດ:', _fmtCurrency(result.gross), HrColors.txt),
          _previewRow('ຫັກ ມ.35:', _fmtCurrency(deduct), HrColors.red),
          _previewRow('ຈຳນວນເງີນຍົກເວັ້ນອາກອນ:', _fmtCurrency(result.exempt), HrColors.txt),
          _previewRow('ຖານອາກອນ 5% (ສ່ວນ 1.3M–5M):', _fmtCurrency(result.b5), HrColors.yellow),
          _previewRow('ຖານອາກອນ 10% (ສ່ວນ 5M–15M):', _fmtCurrency(result.b10), HrColors.yellow),
          _previewRow('ຖານອາກອນ 15%++ (ສ່ວນເກີນ 15M):', _fmtCurrency(result.b15Up), HrColors.yellow),
          _previewRow('ອາກອນລວມ:', _fmtCurrency(result.tax), HrColors.red),
          const Divider(color: HrColors.border),
          _previewRow('💵 ລາຍໄດ້ສຸດທິ:', _fmtCurrency(result.net), HrColors.blue, bold: true),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: HrColors.txt2, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  void _saveEmployee(BuildContext ctx) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('⚠️ ກະລຸນາໃສ່ຊື່ພະນັກງານ'), backgroundColor: HrColors.red),
      );
      return;
    }

    final emp = Employee(
      id: _editingIndex == -1
          ? 'emp_${DateTime.now().millisecondsSinceEpoch}'
          : _currentEmployees[_editingIndex].id,
      name: name,
      role: _roleController.text.trim(),
      basic: double.tryParse(_basicController.text) ?? 0,
      ot: double.tryParse(_otController.text) ?? 0,
      living: double.tryParse(_livingController.text) ?? 0,
      other: double.tryParse(_otherController.text) ?? 0,
      deduct: double.tryParse(_deductController.text) ?? 0,
    );

    if (_editingIndex == -1) {
      _addEmployee(emp);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('✅ ເພີ່ມພະນັກງານສຳເລັດ'), backgroundColor: HrColors.green),
      );
    } else {
      _updateEmployee(_editingIndex, emp);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('✅ ແກ້ໄຂສຳເລັດ'), backgroundColor: HrColors.green),
      );
    }
    Navigator.pop(ctx);
  }

  // ─── Signature ───
  void _openSignatureModal(int index) {
    _sigIndex = index;
    _sigPoints.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: HrColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: HrColors.border),
        ),
        title: const Row(
          children: <Widget>[
            Icon(Icons.edit, color: HrColors.blue),
            SizedBox(width: 8),
            Text('✍️ ແຊັນຊື່ພະນັກງານ', style: TextStyle(color: HrColors.txt)),
          ],
        ),
        content: SizedBox(
          width: 380,
          height: 220,
          child: _buildSignatureCanvas(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              _sigPoints.clear();
              Navigator.pop(ctx);
            },
            child: const Text('ຍົກເລີກ', style: TextStyle(color: HrColors.txt2)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sigPoints.clear();
              });
            },
            child: const Text('ລຶບແຕ້ມໃໝ່', style: TextStyle(color: HrColors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              _saveSignature(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HrColors.accent,
              foregroundColor: HrColors.white,
            ),
            child: const Text('✅ ບັນທຶກລາຍເຊັນ'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCanvas() {
    return GestureDetector(
      onPanStart: (DragStartDetails details) {
        final RenderBox box = _sigCanvasKey.currentContext!.findRenderObject() as RenderBox;
        final Offset local = box.globalToLocal(details.globalPosition);
        setState(() {
          _sigPoints.add(local);
        });
      },
      onPanUpdate: (DragUpdateDetails details) {
        final RenderBox box = _sigCanvasKey.currentContext!.findRenderObject() as RenderBox;
        final Offset local = box.globalToLocal(details.globalPosition);
        setState(() {
          _sigPoints.add(local);
        });
      },
      onPanEnd: (DragEndDetails details) {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // ພື້ນຫຼັງສີຂາວ
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          key: _sigCanvasKey,
          painter: _SignaturePainter(_sigPoints),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _saveSignature(BuildContext ctx) async {
    if (_sigPoints.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('⚠️ ກະລຸນາແຕ້ມລາຍເຊັນ'), backgroundColor: HrColors.red),
      );
      return;
    }
    
    // Capture messenger ກ່ອນ await ເພື່ອຫຼີກລ່ຽງ use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(ctx);

    try {
      final RenderBox box = _sigCanvasKey.currentContext!.findRenderObject() as RenderBox;
      final Size size = box.size;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Paint paint = Paint()
        ..color = HrColors.blue
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (_sigPoints.isNotEmpty) {
        canvas.drawPath(_pointsToPath(_sigPoints), paint);
      }

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final String base64Str = base64Encode(pngBytes);

      final Employee emp = _currentEmployees[_sigIndex];
      final String sigKey = '${_getKey()}_${emp.id}';
      setState(() {
        _signatures[sigKey] = base64Str;
      });
      await _saveData();

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ ບັນທຶກລາຍເຊັນສຳເລັດ'), backgroundColor: HrColors.green),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('❌ ບັນທຶກລາຍເຊັນບໍ່ສຳເລັດ: $e'), backgroundColor: HrColors.red),
      );
    }
  }

  Path _pointsToPath(List<Offset> points) {
    final Path path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  Widget _buildSignatureWidget(int index) {
    final Employee emp = _currentEmployees[index];
    final String sigKey = '${_getKey()}_${emp.id}';
    final bool hasSig = _signatures.containsKey(sigKey);
    
    if (hasSig) {
      final String base64Str = _signatures[sigKey]!;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTap: () => _openSignatureModal(index),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white, // ພື້ນຫຼັງສີຂາວ
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Image.memory(
                base64Decode(base64Str),
                fit: BoxFit.contain,
                width: 120,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: HrColors.red),
              ),
            ),
          ),
          const SizedBox(height: 2),
          TextButton(
            onPressed: () {
              setState(() {
                _signatures.remove(sigKey);
              });
              _saveData();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('ລຶບ', style: TextStyle(color: HrColors.red, fontSize: 11)),
          ),
        ],
      );
    } else {
      return TextButton(
        onPressed: () => _openSignatureModal(index),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          backgroundColor: Colors.white, // ພື້ນຫຼັງສີຂາວ
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: const Text('✍️ ກົດເພື່ອເຊັນ', style: TextStyle(color: Colors.black, fontSize: 12)),
      );
    }
  }

  // ─── Export CSV ───
  Future<void> _exportCSV() async {
    if (_currentEmployees.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ ບໍ່ມີຂໍ້ມູນ'), backgroundColor: HrColors.red),
        );
      }
      return;
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln('\uFEFFNo,ຊື່ນາມສະກຸນ,ໜ້າທີ່ຮັບຜິດຊອບ,ເງິນເດືອນພື້ນຖານ,ອັດຕາກີນ,ເງີນເດີນທາງ,ໂອທີຕ່າງໆ,ເງິນເດືອນທົ່ງໝົດ,ເງີນເພີ່ມໂມງແລະຊ່ວງເວລາທີ່ບໍ່ຄືກຫັກອາກອນ(ມຕ.35),ຈຳນວນເງີນຍົກເວັ້ນອາກອນ,Taxable5%,Taxable10%,Taxable15%_Up,ຈຳນວນອາກອນທີ່ຕ້ອງມອບ,ລາຍໄດ້ສຸດທິ');

    for (int i = 0; i < _currentEmployees.length; i++) {
      final Employee emp = _currentEmployees[i];
      final TaxResult r = calcTax(emp.basic, emp.ot, emp.living, emp.other, emp.deduct);
      csv.writeln('${i+1},"${emp.name}","${emp.role}",${emp.basic.round()},${emp.ot.round()},${emp.living.round()},${emp.other.round()},${r.gross.round()},${emp.deduct.round()},${r.exempt.round()},${r.b5.round()},${r.b10.round()},${r.b15Up.round()},${r.tax.round()},${r.net.round()}');
    }

    try {
      final String filename = 'payroll_${_selectedYear}_$_selectedMonth.csv';
      final bytes = const Utf8Encoder().convert(csv.toString());
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Export CSV ສຳເລັດ: $filename'), backgroundColor: HrColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Export ບໍ່ສຳເລັດ: $e'), backgroundColor: HrColors.red),
        );
      }
    }
  }

  // ─── INIT ───
  @override
  void initState() {
    super.initState();
    _selectedMonth = '${_now.month}'.padLeft(2, '0');
    _selectedYear = '${_now.year}';
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _basicController.dispose();
    _otController.dispose();
    _livingController.dispose();
    _otherController.dispose();
    _deductController.dispose();
    super.dispose();
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = _getTotals();
    final String label = '${_monthNames[int.parse(_selectedMonth)-1]} $_selectedYear';

    return Scaffold(
      backgroundColor: HrColors.bg,
      appBar: AppBar(
        backgroundColor: HrColors.bg2,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HrColors.txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: <Widget>[
            Icon(Icons.arrow_back, color: HrColors.txt2, size: 20),
            SizedBox(width: 8),
            Text('💼 ລະບົບ HR — ຕາຕະລາງເງິນເດືອນ', style: TextStyle(color: HrColors.txt, fontSize: 16)),
          ],
        ),
        actions: <Widget>[
          Text(
            _now.toLocal().toString().split(' ')[0],
            style: const TextStyle(color: HrColors.txt3, fontSize: 12, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF1D6A2E), Color(0xFF238636), Color(0xFF2EA043)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('NAMSOR HYDROPOWER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('ຕາຕະລາງເງິນເດືອນພະນັກງານ — ເຂື່ອນໄຟຟ້ານ້ຳຊໍ້', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: HrColors.bg2,
              border: Border.all(color: HrColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                _buildPeriodSelector(),
                const Spacer(),
                _buildActionButton('ເພີ່ມ', Icons.add, HrColors.accent, _openAddModal),
                const SizedBox(width: 4),
                _buildActionButton('ພິມ', Icons.print, HrColors.blue, () {}),
                const SizedBox(width: 4),
                _buildActionButton('Export', Icons.download, HrColors.txt2, _exportCSV),
              ],
            ),
          ),

          // Summary
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                _summaryCard('👥', '${totals['count']?.toInt() ?? 0}', HrColors.blue),
                _summaryCard('💰', _fmtCurrencyShort(totals['gross'] ?? 0), HrColors.green),
                _summaryCard('📉', _fmtCurrencyShort(totals['deduct'] ?? 0), HrColors.red),
                _summaryCard('🏛', _fmtCurrencyShort(totals['tax'] ?? 0), HrColors.red),
                _summaryCard('✅', _fmtCurrencyShort(totals['net'] ?? 0), HrColors.blue),
              ],
            ),
          ),

          // Table - ເຕັມໜ້າຈໍ
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: HrColors.bg2,
                border: Border.all(color: HrColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: <Widget>[
                        Text('📋 ຕາຕະລາງເງິນເດືອນ — $label', style: const TextStyle(color: HrColors.txt, fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        const Text('💡 ຄລິກຕົວເລກເພື່ອແກ້ໄຂ', style: TextStyle(color: HrColors.txt3, fontSize: 11)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _currentEmployees.isEmpty
                        ? const Center(child: Text('ຍັງບໍ່ມີຂໍ້ມູນ — ກົດ "ເພີ່ມ" ເພື່ອເລີ່ມ', style: TextStyle(color: HrColors.txt3, fontSize: 16)))
                        : LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _buildPayrollTable(constraints.maxWidth),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ຟັງຊັນສຳລັບສະແດງຄ່າເງິນແບບຫຍໍ້
  String _fmtCurrencyShort(double n) {
    if (n == 0) return '0';
    if (n >= 1000000000) {
      return '${(n / 1000000000).toStringAsFixed(1)}B';
    } else if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(0)}K';
    }
    return '${n.round()}';
  }

  // ─── ຕົວເລືອກປະຈໍາເດືອນ — ແບບມືອາຊິບ (ປຸ່ມເລື່ອນເດືອນ + ເປີດໜ້າເລືອກເດືອນ/ປີ) ───
  Widget _buildPeriodSelector() {
    final String label = '${_monthNames[int.parse(_selectedMonth) - 1]} $_selectedYear';
    return Container(
      decoration: BoxDecoration(
        color: HrColors.bg3,
        border: Border.all(color: HrColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _periodArrow(Icons.chevron_left, _goToPreviousMonth, 'ເດືອນກ່ອນ'),
          Container(width: 1, height: 22, color: HrColors.border),
          InkWell(
            onTap: _openPeriodPicker,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.calendar_month, size: 15, color: HrColors.blue),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: HrColors.txt, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 22, color: HrColors.border),
          _periodArrow(Icons.chevron_right, _goToNextMonth, 'ເດືອນຕໍ່ໄປ'),
        ],
      ),
    );
  }

  Widget _periodArrow(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Icon(icon, size: 18, color: HrColors.txt2),
        ),
      ),
    );
  }

  void _shiftMonth(int delta) {
    setState(() {
      int m = int.parse(_selectedMonth) + delta;
      int y = int.parse(_selectedYear);
      if (m < 1) { m = 12; y -= 1; }
      if (m > 12) { m = 1; y += 1; }
      _selectedMonth = '$m'.padLeft(2, '0');
      _selectedYear = '$y';
      _updateCurrent();
    });
  }

  void _goToPreviousMonth() => _shiftMonth(-1);
  void _goToNextMonth() => _shiftMonth(1);

  // ─── ໜ້າເລືອກເດືອນ/ປີ — ຕາລາງເດືອນ ພ້ອມເລື່ອນປີ ───
  void _openPeriodPicker() {
    int pickerYear = int.parse(_selectedYear);
    showDialog(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setPickerState) {
          return AlertDialog(
            backgroundColor: HrColors.bg2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: HrColors.border),
            ),
            title: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: HrColors.txt2),
                  onPressed: () => setPickerState(() => pickerYear--),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$pickerYear',
                      style: const TextStyle(color: HrColors.txt, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: HrColors.txt2),
                  onPressed: () => setPickerState(() => pickerYear++),
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (BuildContext c, int i) {
                  final String mVal = '${i + 1}'.padLeft(2, '0');
                  final bool isSelected = '$pickerYear' == _selectedYear && mVal == _selectedMonth;
                  final bool isToday = pickerYear == _now.year && (i + 1) == _now.month;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _selectedMonth = mVal;
                        _selectedYear = '$pickerYear';
                        _updateCurrent();
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? HrColors.accent : HrColors.bg3,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? HrColors.accent
                              : (isToday ? HrColors.blue : HrColors.border),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _monthNames[i],
                        style: TextStyle(
                          color: isSelected ? HrColors.white : HrColors.txt,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = '${_now.month}'.padLeft(2, '0');
                    _selectedYear = '${_now.year}';
                    _updateCurrent();
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('📍 ເດືອນນີ້', style: TextStyle(color: HrColors.blue)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ປິດ', style: TextStyle(color: HrColors.txt2)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _summaryCard(String icon, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: HrColors.bg2,
          border: Border.all(color: HrColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ກຳນົດຄ່າຖັນ (label, ສີ, weight, ກວ້າງນ້ອຍສຸດ, ການຈັດແຖວ) ───
  static const List<_ColSpec> _payrollColumns = <_ColSpec>[
    _ColSpec('No', HrColors.txt2, 0.5, 36, align: Alignment.center),
    _ColSpec('ຊື່ນາມສະກຸນ', HrColors.txt2, 1.8, 120),
    _ColSpec('ໜ້າທີ່', HrColors.txt2, 1.4, 95),
    _ColSpec('ເງິນເດືອນພື້ນ', HrColors.txt2, 1.0, 90, align: Alignment.centerRight),
    _ColSpec('ອັດຕາກີນ', HrColors.txt2, 1.0, 85, align: Alignment.centerRight),
    _ColSpec('ເດີນທາງ', HrColors.txt2, 1.0, 85, align: Alignment.centerRight),
    _ColSpec('ໂອທີ', HrColors.txt2, 0.8, 75, align: Alignment.centerRight),
    _ColSpec('ເງິນເດືອນທົ່ງ', HrColors.green, 1.1, 95, align: Alignment.centerRight),
    _ColSpec('ຫັກມຕ.35', HrColors.red, 1.0, 85, align: Alignment.centerRight),
    _ColSpec('ຍົກເວັ້ນ', HrColors.txt, 1.0, 90, align: Alignment.centerRight),
    _ColSpec('5%', HrColors.yellow, 0.6, 65, align: Alignment.centerRight),
    _ColSpec('10%', HrColors.yellow, 0.6, 65, align: Alignment.centerRight),
    _ColSpec('15%+', HrColors.yellow, 0.7, 70, align: Alignment.centerRight),
    _ColSpec('ອາກອນ', HrColors.red, 0.9, 85, align: Alignment.centerRight),
    _ColSpec('ສຸດທິ', HrColors.blue, 1.1, 95, align: Alignment.centerRight),
    _ColSpec('ລາຍເຊັນ', HrColors.txt2, 1.2, 134, align: Alignment.center),
    _ColSpec('ຈັດການ', HrColors.txt2, 0.8, 75, align: Alignment.center),
  ];

  // ຄິດໄລ່ກວ້າງແຕ່ລະຖັນ: ຖ້າຈໍກວ້າງພໍ ໃຫ້ແບ່ງພື້ນທີ່ທີ່ເຫຼືອຕາມ weight (ສົມດຸນ ແລະ ເຕັມຈໍ)
  // ຖ້າຈໍແຄບກວ່າຄວາມກວ້າງນ້ອຍສຸດລວມ ໃຫ້ໃຊ້ຄວາມກວ້າງນ້ອຍສຸດ ແລ້ວປ່ອຍໃຫ້ເລື່ອນຕາມແນວນອນແທນ
  List<double> _calcColumnWidths(double availableWidth) {
    final double totalMin = _payrollColumns.fold(0.0, (double sum, _ColSpec c) => sum + c.minWidth);
    final double totalWeight = _payrollColumns.fold(0.0, (double sum, _ColSpec c) => sum + c.weight);
    final double usable = availableWidth > totalMin ? availableWidth : totalMin;
    final double extra = usable - totalMin;
    return _payrollColumns
        .map((_ColSpec c) => c.minWidth + extra * (c.weight / totalWeight))
        .toList();
  }

  // ─── ຕາຕະລາງເງິນເດືອນ (ສົມດຸນຖັນ ແລະ ເຕັມຈໍໂດຍອັດຕະໂນມັດ) ───
  Widget _buildPayrollTable(double availableWidth) {
    final List<double> w = _calcColumnWidths(availableWidth);

    Widget cell(int i, Widget child) {
      return SizedBox(
        width: w[i],
        child: Align(alignment: _payrollColumns[i].align, child: child),
      );
    }

    Widget padded(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: child,
        );

    Widget numText(String text, Color color, {bool bold = false}) => padded(
          Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );

    return DataTable(
      border: TableBorder.all(color: Colors.white, width: 1), // ເພີ່ມເສັ້ນຂອບສີຂາວ
      columnSpacing: 0,
      horizontalMargin: 0,
      headingRowHeight: 42,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 48,
      headingRowColor: WidgetStateProperty.all<Color>(HrColors.bg3),
      dataRowColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        return states.contains(WidgetState.selected) ? HrColors.bg4 : HrColors.bg2;
      }),
      columns: List<DataColumn>.generate(_payrollColumns.length, (int i) {
        final _ColSpec spec = _payrollColumns[i];
        return DataColumn(
          label: cell(
            i,
            padded(
              Text(
                spec.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: spec.color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }),
      rows: _currentEmployees.asMap().entries.map<DataRow>((MapEntry<int, Employee> entry) {
        final int idx = entry.key;
        final Employee emp = entry.value;
        final TaxResult r = calcTax(emp.basic, emp.ot, emp.living, emp.other, emp.deduct);
        return DataRow(
          cells: <DataCell>[
            DataCell(cell(0, padded(Text('${idx+1}', style: const TextStyle(color: HrColors.txt3, fontSize: 14))))),
            DataCell(cell(1, padded(Text(emp.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: HrColors.txt, fontSize: 14))))),
            DataCell(cell(2, padded(Text(emp.role.isEmpty ? '' : emp.role, overflow: TextOverflow.ellipsis, style: const TextStyle(color: HrColors.txt2, fontSize: 13))))),
            DataCell(cell(3, numText(_fmt(emp.basic), HrColors.txt))),
            DataCell(cell(4, numText(_fmt(emp.ot), HrColors.txt))),
            DataCell(cell(5, numText(_fmt(emp.living), HrColors.txt))),
            DataCell(cell(6, numText(_fmt(emp.other), HrColors.txt))),
            DataCell(cell(7, numText(_fmt(r.gross), HrColors.green, bold: true))),
            DataCell(cell(8, numText(_fmt(emp.deduct), HrColors.red))),
            DataCell(cell(9, numText(_fmt(r.exempt), HrColors.txt))),
            DataCell(cell(10, numText(r.b5 > 0 ? _fmt(r.b5) : '0', HrColors.yellow))),
            DataCell(cell(11, numText(r.b10 > 0 ? _fmt(r.b10) : '0', HrColors.yellow))),
            DataCell(cell(12, numText(r.b15Up > 0 ? _fmt(r.b15Up) : '0', HrColors.yellow))),
            DataCell(cell(13, numText(r.tax > 0 ? _fmt(r.tax) : '0', HrColors.red))),
            DataCell(cell(14, numText(_fmt(r.net), HrColors.blue, bold: true))),
            DataCell(cell(15, padded(_buildSignatureWidget(idx)))),
            DataCell(
              cell(
                16,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit, color: HrColors.txt2, size: 18),
                      onPressed: () => _openEditModal(idx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: HrColors.red, size: 18),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext ctx) => AlertDialog(
                            backgroundColor: HrColors.bg2,
                            title: const Text('ລຶບພະນັກງານ', style: TextStyle(color: HrColors.txt)),
                            content: Text('ທ່ານຕ້ອງການລຶບ ${emp.name} ແທ້ບໍ່?', style: const TextStyle(color: HrColors.txt2)),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('ຍົກເລີກ', style: TextStyle(color: HrColors.txt2)),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteEmployee(idx);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('ລຶບ', style: TextStyle(color: HrColors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Signature Painter ───
class _SignaturePainter extends CustomPainter {
  final List<Offset> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final Paint paint = Paint()
      ..color = HrColors.blue
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}