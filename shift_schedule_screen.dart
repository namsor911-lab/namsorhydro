import 'package:flutter/material.dart';

class ShiftScheduleScreen extends StatefulWidget {
  const ShiftScheduleScreen({super.key});

  @override
  State<ShiftScheduleScreen> createState() => _ShiftScheduleScreenState();
}

class _ShiftScheduleScreenState extends State<ShiftScheduleScreen> {
  DateTime _selectedDate = DateTime(2026, 6, 1);

  // ຮອບວຽນຍາມ 28 ມື້
  final List<String> _cycle = [
    'ຊ', 'ຊ', 'ຊ', 'ຊ', 'ຊ', 'ຊ', 'ຊ',
    'ພ', 'ພ', 'ພ', 'ພ', 'ພ', 'ພ', 'ພ',
    'ດ', 'ດ', 'ດ', 'ດ', 'ດ', 'ດ', 'ດ',
    'ລ', 'ລ', 'ລ', 'ລ', 'ລ', 'ລ', 'ລ'
  ];

  // ຄ່າເລີ່ມຕົ້ນຂອງແຕ່ລະ Shift
  final List<int> _offsets = [2, 23, 16, 9];

  final List<String> _monthNames = [
    "ມັງກອນ", "ກຸມພາ", "ມີນາ", "ເມສາ", "ພຶດສະພາ", "ມິຖຸນາ",
    "ກໍລະກົດ", "ສິງຫາ", "ກັນຍາ", "ຕຸລາ", "ພະຈິກ", "ທັນວາ"
  ];

  final List<Map<String, dynamic>> _teams = [
    {"name": "Shift 1", "leader": "ທ. ພູວຽງ ຈັນສະໄໝ", "member": "ນ. ວິໄລລັກ ຄຳປະສົງ"},
    {"name": "Shift 2", "leader": "ທ. ສົມຄິດ ວິໄລວັນ", "member": "ທ. ພິທັກ ໄຊສົມຊາງ"},
    {"name": "Shift 3", "leader": "ທ. ມັງກອນ ຍອດວົງສາ", "member": "ທ. ບົວສອນ ໄຊຈະເລີນຍ"},
    {"name": "Shift 4", "leader": "ທ. ຕ໋ອກ ເພຍໄຊ", "member": "ທ. ອາເຈ່ຍ ໄຊຈະເລີນ"},
  ];

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String _getShiftType(int shiftIndex, int day) {
    final refDate = DateTime.utc(2026, 6, 1);
    final targetDate = DateTime.utc(_selectedDate.year, _selectedDate.month, day);
    int diffDays = targetDate.difference(refDate).inDays;
    
    int idx = (_offsets[shiftIndex] + diffDays) % 28;
    if (idx < 0) idx += 28;
    return _cycle[idx];
  }

  Color _getShiftColor(String type) {
    switch (type) {
      case 'ຊ': return const Color(0xFFFFF2CC);  // ສີເຫຼືອງອ່ອນ
      case 'ລ': return const Color(0xFFFCE5CD);  // ສີສົ້ມອ່ອນ
      case 'ດ': return const Color(0xFFC9DAF8);  // ສີຟ້າອ່ອນ
      case 'ພ': return const Color(0xFFE0E0E0);  // ສີເທົາອ່ອນ
      default: return Colors.white;
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      helpText: "ເລືອກເດືອນ ແລະ ປີ",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF2D2D2D),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF2D2D2D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = _getDaysInMonth(_selectedDate.year, _selectedDate.month);
    int totalDays = daysInMonth;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'ຕາຕະລາງຍາມໄຟຟ້າ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFF1A1A1A),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Main Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Text(
                      "ບໍລິສັດ ນ້ຳຊໍ້ໄຣໂດຼ ພາວເວີ ຈຳກັດ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Namsor HydroPower ComPaNy",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Divider
                    Container(
                      height: 2,
                      color: const Color(0xFF555555),
                    ),
                    const SizedBox(height: 20),

                    // Month Picker
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D3D3D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "ເລືອກເດືອນ ແລະ ປີ:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16, 
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 15),
                          InkWell(
                            onTap: () => _selectMonth(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF666666)),
                                borderRadius: BorderRadius.circular(6),
                                color: const Color(0xFF444444),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      fontSize: 16, 
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      "ຕາຕະລາງຍາມເດືອນ ${_selectedDate.month} (${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year})",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ========== TABLE ==========
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF555555)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            columnWidths: {
                              0: const FixedColumnWidth(100.0),
                              ...Map.fromIterable(
                                List.generate(totalDays, (index) => index + 1),
                                value: (i) => const FixedColumnWidth(45.0),
                              ),
                            },
                            border: TableBorder.all(
                              color: const Color(0xFF555555),
                              width: 0.5,
                            ),
                            children: [
                              // Header Row
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3D3D3D),
                                ),
                                children: [
                                  const TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                      child: Text(
                                        'Shift',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...List.generate(totalDays, (index) {
                                    return TableCell(
                                      verticalAlignment: TableCellVerticalAlignment.middle,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                                        child: Text(
                                          '${index + 1}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              
                              // Data Rows for each Shift
                              ...List.generate(4, (shiftIndex) {
                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: shiftIndex % 2 == 0 
                                        ? const Color(0xFF353535)
                                        : const Color(0xFF3A3A3A),
                                  ),
                                  children: [
                                    // Shift Name Column
                                    TableCell(
                                      verticalAlignment: TableCellVerticalAlignment.middle,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                        child: Text(
                                          'Shift ${shiftIndex + 1}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Day Columns
                                    ...List.generate(totalDays, (dayIndex) {
                                      int day = dayIndex + 1;
                                      String type = _getShiftType(shiftIndex, day);
                                      Color bgColor = _getShiftColor(type);
                                      
                                      return TableCell(
                                        verticalAlignment: TableCellVerticalAlignment.middle,
                                        child: Container(
                                          color: bgColor,
                                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                                          alignment: Alignment.center,
                                          child: Text(
                                            type,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ========== TEAM INFO ==========
                    const Text(
                      'ຂໍ້ມູນທີມງານ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: _teams.length,
                      itemBuilder: (context, index) {
                        final team = _teams[index];
                        return Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D3D3D),
                            border: Border.all(color: const Color(0xFF555555)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(bottom: 6),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF555555), 
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  team["name"],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${team["leader"]} (ຫົວໜ້າ)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${team["member"]} (ສະມາຊິກ)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ========== LEGEND ==========
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D3D3D),
                        border: Border.all(color: const Color(0xFF555555)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ໝາຍເຫດເວລາເຂົ້າວຽກ:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Wrap(
                            spacing: 20,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildLegendItem('ຊ', '08:00 - 16:00', const Color(0xFFFFF2CC)),
                              _buildLegendItem('ລ', '16:00 - 00:00', const Color(0xFFFCE5CD)),
                              _buildLegendItem('ດ', '00:00 - 08:00', const Color(0xFFC9DAF8)),
                              _buildLegendItem('ພ', 'ພັກວຽກ', const Color(0xFFE0E0E0)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Footer
                    const Text(
                      '© 2026 ຕາຕະລາງຍາມໄຟຟ້າ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String text, Color bgColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: const Color(0xFF666666)),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}