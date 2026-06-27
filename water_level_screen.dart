// water_level_screen.dart
// ຕາຕະລາງປະລິມານນ້ຳ ອີງຕາມ volume.html ສະບັບຕົ້ນສະບັບ
// ໂທນສີ: ພື້ນຫລັງສີດຳ + ຕົວອັກສອນ/ຕົວເລກສີເຫລືອງ
// ປັບປຸງ: ເພີ່ມປຸ່ມ "ປະຈຳວັນ" ເພື່ອເປີດໜ້າບັນທຶກປະຈຳວັນ

import 'package:flutter/material.dart';
import 'water_management_app.dart'; // ນຳເຂົ້າໜ້າບັນທຶກປະຈຳວັນ

/// ໂທນສີ ສະເພາະໜ້ານີ້ (ພື້ນດຳ - ໂຕໜັງສືເຫລືອງ)
class _Dk {
  static const bg = Colors.black;            // ພື້ນຫລັງຫຼັກ
  static const panel = Color(0xFF0A0A0A);    // ພື້ນຂອງກ່ອງຕາຕະລາງ (ດຳເກືອບເທົ່າ bg)
  static const text = Colors.white;           // ໂຕໜັງສື/ຕົວເລກຫຼັກ
  static const textDim = Color(0xFFAAAAAA);   // ໂຕໜັງສືສີຂາວໂທນອ່ອນ (ສຳລັບຂໍ້ຄວາມສຳຮອງ)
  static const divider = Color(0xFF262626);   // ສາຍແບ່ງລະຫວ່າງແຖວ
  static const border = Color(0xFF7A5C00);    // ຂອບສີຄຳ/ເຫລືອງເຂັ້ມ
  static const highlightBg = Colors.yellow;   // ພື້ນຫລັງແຖວທີ່ຄົ້ນເຫັນ (ໂດດເດັ່ນ)
  static const highlightText = Colors.black;  // ໂຕໜັງສືເທິງແຖວທີ່ຄົ້ນເຫັນ
  static const surfaceRowBg = Color(0xFF332B00); // ພື້ນຫລັງແຖວທີ່ມີຂໍ້ມູນພື້ນທີ່ຜິວນ້ຳ
}

class WaterLevelScreen extends StatefulWidget {
  const WaterLevelScreen({super.key});

  @override
  State<WaterLevelScreen> createState() => _WaterLevelScreenState();
}

class _WaterLevelScreenState extends State<WaterLevelScreen> {
  late List<Map<String, dynamic>> _volumeData;
  double? _filterLevel;
  final TextEditingController _searchController = TextEditingController();

  // ສຳລັບເຮັດໃຫ້ຫົວຂໍ້ຕາຕະລາງຄ້າງຢູ່ ບໍ່ເລື່ອນຕາມຕັ້ງ ແຕ່ເລື່ອນຕາມລວງນອນພ້ອມກັນກັບຂໍ້ມູນ
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();

  // ຄວາມກວ້າງຂັ້ນຕ່ຳຂອງແຕ່ລະຄໍລັມ (ຈະຖືກຍືດໃຫ້ເຕັມໜ້າຈໍ ຖ້າຈໍກວ້າງພໍ)
  final List<double> _minColumnWidths = [110, 170, 180, 180, 150];
  final List<String> _headers = [
    'ລະດັບ (masl)',
    'ປະລິມານທັງໝົດ (m³)',
    'ປະລິມານໃຊ້ງານໄດ້ (m³)',
    'ປະລິມານຕ່າງລະດັບ (m³)',
    'ພື້ນທີ່ຜິວນ້ຳ (ເຮກຕາ)',
  ];

  @override
  void initState() {
    super.initState();
    _volumeData = _buildVolumeData();

    // ເມື່ອເລື່ອນຕາລາງຂໍ້ມູນຕາມລວງນອນ ໃຫ້ຫົວຂໍ້ເລື່ອນຕາມໄປພ້ອມກັນ
    // (ຫົວຂໍ້ເອງຈະບໍ່ສາມາດເລື່ອນຕັ້ງໄດ້ ດັ່ງນັ້ນມັນຄ້າງຢູ່ເທິງສຸດສະເໝີ)
    _bodyHorizontalController.addListener(() {
      if (_headerHorizontalController.hasClients &&
          _headerHorizontalController.offset != _bodyHorizontalController.offset) {
        _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    super.dispose();
  }

  // ─── ສ້າງຂໍ້ມູນຄືເດີມ ───
  List<Map<String, dynamic>> _buildVolumeData() {
    final data = <Map<String, dynamic>>[];

    // ແຖວທຳອິດ: ລະດັບ 513, ປະລິມານ 0
    data.add({'level': 513.0, 'total': 0, 'active': 0, 'delta': 0, 'surface': null});

    // ກຳນົດການເພີ່ມຕໍ່ 0.01 ມ ຕາມໄລຍະ
    final stepConfig = <Map<String, num>>[
      {'start': 518.0, 'end': 520.0, 'inc': 305},
      {'start': 520.0, 'end': 522.0, 'inc': 865},
      {'start': 522.0, 'end': 524.0, 'inc': 1540},
      {'start': 524.0, 'end': 526.0, 'inc': 2210},
      {'start': 526.0, 'end': 528.0, 'inc': 2785},
      {'start': 528.0, 'end': 530.0, 'inc': 3620},
      {'start': 530.0, 'end': 532.0, 'inc': 4630},
    ];

    int getIncrement(double level) {
      for (final seg in stepConfig) {
        final start = seg['start'] as double;
        final end = seg['end'] as double;
        if (level >= start && level < end) {
          return seg['inc'] as int;
        }
      }
      return 4630; // ສຳລັບລະດັບ >= 530
    }

    // ຂໍ້ມູນພື້ນທີ່ຜິວນ້ຳ (ຕາມໄຟລ໌)
    final surfaceMap = <double, double>{
      519.999: 5.81,
      521.999: 11.82,
      527.999: 30.83,
      529.999: 39.97,
      530.50: 532.0,
    };

    // ເພີ່ມລະດັບ 518 (ມີ 27,000 m³)
    data.add({'level': 518.0, 'total': 27000, 'active': 27000, 'delta': 27000, 'surface': null});

    // ສ້າງຈາກ 518.01 ຫາ 532.00 (ຂັ້ນ 0.01)
    double lvl = 518.01;
    while (lvl <= 532.00) {
      lvl = (lvl * 100).round() / 100; // ປັດໃຫ້ເປັນ 2 ຕົວທົດສະນິຍົມ

      final inc = getIncrement(lvl);
      final prev = data.last['total'] as int;
      final total = prev + inc;
      final active = total; // dead storage = 0
      final delta = total - prev;

      double? surface;
      for (final key in surfaceMap.keys) {
        if ((key - lvl).abs() < 0.0001) {
          surface = surfaceMap[key];
          break;
        }
      }

      data.add({
        'level': lvl,
        'total': total,
        'active': active,
        'delta': delta,
        'surface': surface,
      });

      lvl += 0.01;
    }

    return data;
  }

  // ─── ຟັງຊັນຊອກຫາ (interpolation) ───
  double lookupVolume(double level) {
    for (final d in _volumeData) {
      if (((d['level'] as double) - level).abs() < 0.0001) {
        return (d['total'] as int).toDouble();
      }
    }
    final lower = _volumeData.where((d) => (d['level'] as double) <= level).toList();
    final upper = _volumeData.where((d) => (d['level'] as double) >= level).toList();
    if (lower.isEmpty) return (_volumeData.first['total'] as int).toDouble();
    if (upper.isEmpty) return (_volumeData.last['total'] as int).toDouble();
    final lo = lower.last;
    final hi = upper.first;
    if ((lo['level'] as double) == (hi['level'] as double)) {
      return (lo['total'] as int).toDouble();
    }
    final frac = (level - (lo['level'] as double)) / ((hi['level'] as double) - (lo['level'] as double));
    return (lo['total'] as int) + frac * ((hi['total'] as int) - (lo['total'] as int));
  }

  double lookupLevel(double volume) {
    final lower = _volumeData.where((d) => (d['total'] as int) <= volume).toList();
    final upper = _volumeData.where((d) => (d['total'] as int) >= volume).toList();
    if (lower.isEmpty) return (_volumeData.first['level'] as double);
    if (upper.isEmpty) return (_volumeData.last['level'] as double);
    final lo = lower.last;
    final hi = upper.first;
    if ((lo['total'] as int) == (hi['total'] as int)) {
      return (lo['level'] as double);
    }
    final frac = (volume - (lo['total'] as int)) / ((hi['total'] as int) - (lo['total'] as int));
    return (lo['level'] as double) + frac * ((hi['level'] as double) - (lo['level'] as double));
  }

  // ─── ການກັ່ນຕອງ ───
  List<Map<String, dynamic>> get _filteredData {
    if (_filterLevel == null) return _volumeData;
    return _volumeData
        .where((d) => ((d['level'] as double) - _filterLevel!).abs() <= 0.005)
        .toList();
  }

  // ─── ຟັງຊັນຊ່ວຍສະແດງຕົວເລກ ───
  String _formatNumber(int number) {
    String str = number.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = ',$result';
      }
    }
    return result;
  }

  void _search() {
    final val = double.tryParse(_searchController.text.trim());
    if (val == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາປ້ອນລະດັບນ້ຳເປັນຕົວເລກ (ເຊັ່ນ 528.50)')),
      );
      return;
    }
    setState(() => _filterLevel = val);
  }

  void _clearSearch() {
    setState(() {
      _filterLevel = null;
      _searchController.clear();
    });
  }

  // ─── ສະຖິຕິ ───
  Map<String, dynamic> get _stats {
    if (_volumeData.isEmpty) return {};
    double minLevel = _volumeData.map((d) => d['level'] as double).reduce((a, b) => a < b ? a : b);
    double maxLevel = _volumeData.map((d) => d['level'] as double).reduce((a, b) => a > b ? a : b);
    int maxVol = _volumeData.map((d) => d['total'] as int).reduce((a, b) => a > b ? a : b);
    return {'minLevel': minLevel, 'maxLevel': maxLevel, 'maxVol': maxVol};
  }

  // ─── ຄິດໄລ່ຄວາມກວ້າງຂອງແຕ່ລະຄໍລັມ (ຍືດໃຫ້ເຕັມໜ້າຈໍ ຖ້າພື້ນທີ່ພໍ) ───
  List<double> _computeColumnWidths(double availableWidth) {
    final minTotal = _minColumnWidths.reduce((a, b) => a + b);
    if (availableWidth <= minTotal) {
      return _minColumnWidths;
    }
    final extraPerColumn = (availableWidth - minTotal) / _minColumnWidths.length;
    return _minColumnWidths.map((w) => w + extraPerColumn).toList();
  }

  // ─── ແຖວຫົວຂໍ້ (ຄ້າງຢູ່ເທິງສຸດ) ───
  Widget _buildHeaderRow(List<double> widths, double totalWidth) {
    return Container(
      width: totalWidth,
      decoration: const BoxDecoration(
        color: _Dk.panel,
        border: Border(bottom: BorderSide(color: _Dk.border, width: 1)),
      ),
      child: Row(
        children: List.generate(_headers.length, (i) {
          return Container(
            width: widths[i],
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            alignment: Alignment.centerLeft,
            child: Text(
              _headers[i],
              style: const TextStyle(
                color: _Dk.text,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── ແຖວຂໍ້ມູນ ───
  Widget _buildDataRow(Map<String, dynamic> d, List<double> widths, int index) {
    final isHighlight = _filterLevel != null &&
        ((d['level'] as double) - _filterLevel!).abs() < 0.001;
    final isSurface = d['surface'] != null && (d['surface'] as double) > 0;

    final Color bgColor;
    final Color textColor;
    if (isHighlight) {
      bgColor = _Dk.highlightBg;
      textColor = _Dk.highlightText;
    } else if (isSurface) {
      bgColor = _Dk.surfaceRowBg;
      textColor = _Dk.text;
    } else {
      bgColor = _Dk.bg;
      textColor = _Dk.text;
    }

    final values = <String>[
      (d['level'] as double).toStringAsFixed(2),
      _formatNumber(d['total'] as int),
      _formatNumber(d['active'] as int),
      _formatNumber(d['delta'] as int),
      '${d['surface'] ?? '-'}',
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(bottom: BorderSide(color: _Dk.divider)),
      ),
      child: Row(
        children: List.generate(values.length, (i) {
          return Container(
            width: widths[i],
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              values[i],
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── UI ───
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredData;
    final stats = _stats;

    return Scaffold(
      backgroundColor: _Dk.bg,
      appBar: AppBar(
        title: const Text('📊 ຕາຕະລາງປະລິມານນ້ຳ ເຂື່ອນນ້ຳຊໍ້'),
        backgroundColor: _Dk.panel,
        foregroundColor: _Dk.text,
        iconTheme: const IconThemeData(color: _Dk.text),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              // ແຖບເຄື່ອງມື
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: _Dk.text),
                      decoration: const InputDecoration(
                        hintText: 'ຄົ້ນຫາລະດັບ (ເຊັ່ນ 528.50)',
                        hintStyle: TextStyle(color: _Dk.textDim),
                        filled: true,
                        fillColor: _Dk.panel,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: _Dk.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _Dk.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _Dk.text, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Dk.panel,
                      foregroundColor: _Dk.text,
                      side: const BorderSide(color: _Dk.border),
                    ),
                    child: const Text('ຄົ້ນຫາ'),
                  ),
                  const SizedBox(width: 8),

                  // ✅ ປຸ່ມ "ປະຈຳວັນ" ເປີດໜ້າບັນທຶກປະຈຳວັນ
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WaterLevelHomePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Dk.panel,
                      foregroundColor: _Dk.text,
                      side: const BorderSide(color: _Dk.border),
                    ),
                    child: const Text('ປະຈຳວັນ'),
                  ),

                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _clearSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Dk.panel,
                      foregroundColor: _Dk.text,
                      side: const BorderSide(color: _Dk.border),
                    ),
                    child: const Text('ສະແດງທັງໝົດ'),
                  ),
                  const Spacer(),
                  Text(
                    'ຈຳນວນລາຍການ: ${filtered.length}',
                    style: const TextStyle(fontSize: 14, color: _Dk.text),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ຕາຕະລາງ ທີ່ມີຫົວຂໍ້ຄ້າງຢູ່ ແລະ ຍືດເຕັມໜ້າຈໍ
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final colWidths = _computeColumnWidths(constraints.maxWidth);
                    final totalWidth = colWidths.reduce((a, b) => a + b);

                    return Container(
                      decoration: BoxDecoration(
                        color: _Dk.panel,
                        border: Border.all(color: _Dk.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // ຫົວຂໍ້: ເລື່ອນຕາມລວງນອນພ້ອມກັບຂໍ້ມູນ ແຕ່ບໍ່ສາມາດເລື່ອນຕັ້ງໄດ້
                          SingleChildScrollView(
                            controller: _headerHorizontalController,
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: _buildHeaderRow(colWidths, totalWidth),
                          ),
                          // ຂໍ້ມູນ: ເລື່ອນໄດ້ທັງລວງນອນ ແລະ ລວງຕັ້ງ
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _bodyHorizontalController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: totalWidth,
                                child: filtered.isEmpty
                                    ? const SizedBox(
                                        height: 120,
                                        child: Center(
                                          child: Text(
                                            'ບໍ່ພົບຂໍ້ມູນ',
                                            style: TextStyle(color: _Dk.textDim),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          return _buildDataRow(filtered[index], colWidths, index);
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ສະຖິຕິ
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _Dk.divider)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Chip(
                        label: Text(
                          'ລະດັບຕ່ຳສຸດ: ${stats['minLevel']?.toStringAsFixed(2) ?? '-'} masl',
                          style: const TextStyle(color: _Dk.text),
                        ),
                        backgroundColor: _Dk.panel,
                        side: const BorderSide(color: _Dk.border),
                      ),
                      const SizedBox(width: 16),
                      Chip(
                        label: Text(
                          'ລະດັບສູງສຸດ: ${stats['maxLevel']?.toStringAsFixed(2) ?? '-'} masl',
                          style: const TextStyle(color: _Dk.text),
                        ),
                        backgroundColor: _Dk.panel,
                        side: const BorderSide(color: _Dk.border),
                      ),
                      const SizedBox(width: 16),
                      Chip(
                        label: Text(
                          'ປະລິມານສູງສຸດ: ${stats['maxVol'] != null ? _formatNumber(stats['maxVol'] as int) : '-'} m³',
                          style: const TextStyle(color: _Dk.text),
                        ),
                        backgroundColor: _Dk.panel,
                        side: const BorderSide(color: _Dk.border),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}