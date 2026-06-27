import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ==========================================
// 1. ໜ້າຫຼັກສຳລັບຈັດການ Navigation
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OrgChartScreen(),
    const DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.bgCard,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'ໂຄງສ້າງອົງກອນ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'ພາບລວມລະບົບ',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. ໂມເດວຂໍ້ມູນພະນັກງານ
// ==========================================
class Employee {
  final String name;
  final String position;
  final String bio;

  Employee({
    required this.name,
    required this.position,
    required this.bio,
  });
}

Color _avatarColor(String name) {
  final colors = [
    const Color(0xFF1976D2), const Color(0xFF388E3C),
    const Color(0xFF7B1FA2), const Color(0xFFF57C00),
    const Color(0xFFC62828), const Color(0xFF00796B),
  ];
  return colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
}

String _avatarInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return parts[1][0].toUpperCase();
  return parts[0][0].toUpperCase();
}

// ==========================================
// 3. ໜ້າໂຄງສ້າງອົງກອນ (Org Chart Screen)
// ==========================================
class OrgChartScreen extends StatelessWidget {
  const OrgChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Employee> employees = [
      Employee(
        name: 'ທ່ານ ສົມພອນ ພົມມະຈັນ',
        position: 'ຜູ້ອຳນວຍການໃຫຍ່ (CEO)',
        bio: 'ມີປະສົບການດ້ານການບໍລິຫານໂຮງໄຟຟ້າຫຼາຍກວ່າ 20 ປີ. ຈົບການສຶກສາລະດັບປະລິນຍາໂທ ດ້ານວິສະວະກຳພະລັງງານ.',
      ),
      Employee(
        name: 'ທ່ານ ນາງ ມະນີວັນ ສີປະເສີດ',
        position: 'ຫົວໜ້າຝ່າຍປະຕິບັດການ (COO)',
        bio: 'ຊ່ຽວຊານດ້ານການຄວບຄຸມລະບົບ SCADA ແລະ ການຄຸ້ມຄອງທີມງານວິສະວະກອນ.',
      ),
      Employee(
        name: 'ທ່ານ ບຸນມີ ໄຊຍະວົງ',
        position: 'ຫົວໜ້າວິສະວະກອນບຳລຸງຮັກສາ',
        bio: 'ຮັບຜິດຊອບການກວດກາ ແລະ ບຳລຸງຮັກສາເຄື່ອງຈັກທຸກໜ່ວຍໃນສະຖານີ A ແລະ B.',
      ),
      Employee(
        name: 'ທ່ານ ນາງ ອານຸສອນ ວົງພະຈັນ',
        position: 'ນັກວິເຄາະຂໍ້ມູນພະລັງງານ',
        bio: 'ຮັບຜິດຊອບວິເຄາະປະລິມານນໍ້າ ແລະ ປະເມີນກຳລັງການຜະລິດລາຍວັນ.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgCard, // 🟢 ແກ້ໄຂ: ປ່ຽນຈາກ bgBackground ທີ່ບໍ່ມີ
      appBar: AppBar(
        title: const Text('ໂຄງສ້າງອົງກອນ', style: TextStyle(fontFamily: 'PhetsarathOT')),
        backgroundColor: AppColors.bgCard,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final emp = employees[index];
          // 🟢 ແກ້ໄຂ: ໃຊ້ Padding ຫໍ່ແທນການໃຊ້ margin ພາຍໃນ AppCard
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _avatarColor(emp.name),
                    child: Text(
                      _avatarInitials(emp.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'PhetsarathOT',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            emp.position,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'PhetsarathOT',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emp.bio,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontFamily: 'PhetsarathOT',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. ໜ້າ DashboardScreen 
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalMW     = 486;
  final int _onlineUnits = 6;
  double _waterLevel  = 217.4;
  double _dailyGen    = 11.2;
  double _resLevel    = 72;

  final List<FlSpot> _mwData   = [];
  final List<FlSpot> _flowData = [];
  final _rng = Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initChartData();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;
      setState(() {
        _totalMW  = 460 + _rng.nextDouble() * 40;
        _resLevel = (_resLevel + (_rng.nextDouble() - 0.5) * 0.8).clamp(55, 95);
        _waterLevel = 215 + _resLevel * 0.05;
        _dailyGen   = 11.2 + _rng.nextDouble() * 0.2;

        for (int i = 0; i < _mwData.length - 1; i++) {
          _mwData[i]   = FlSpot(i.toDouble(), _mwData[i + 1].y);
          _flowData[i] = FlSpot(i.toDouble(), _flowData[i + 1].y);
        }
        _mwData.last   = FlSpot((_mwData.length - 1).toDouble(), _totalMW);
        _flowData.last = FlSpot((_flowData.length - 1).toDouble(), 280 + _rng.nextDouble() * 60);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initChartData() {
    for (int i = 0; i < 20; i++) {
      _mwData.add(FlSpot(i.toDouble(), 450 + _rng.nextDouble() * 60));
      _flowData.add(FlSpot(i.toDouble(), 280 + _rng.nextDouble() * 60));
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: AppColors.textPrimary, fontFamily: 'PhetsarathOT')),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard, // 🟢 ແກ້ໄຂ: ປ່ຽນຈາກ bgBackground ທີ່ບໍ່ມີ
      appBar: AppBar(
        title: const Text('ພາບລວມລະບົບ', style: TextStyle(fontFamily: 'PhetsarathOT')),
        backgroundColor: AppColors.bgCard,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LayoutBuilder(builder: (ctx, cst) {
              final cols = cst.maxWidth > 700 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: cols == 4 ? 1.8 : 1.6,
                children: [
                  StatCard(
                    label: 'ກຳລັງຜະລິດລວມ',
                    value: _totalMW.toStringAsFixed(0),
                    unit: 'MW',
                    icon: const Icon(Icons.bolt, size: 16, color: AppColors.accent),
                    iconBg: AppColors.accent.withValues(alpha: 0.15),
                    progressValue: _totalMW / 600,
                    progressColor: AppColors.accent,
                    progressMin: '0 MW',
                    progressMax: '600 MW Max',
                  ),
                  StatCard(
                    label: 'ໜ່ວຍທີ່ Online',
                    value: '$_onlineUnits',
                    unit: '/ 8',
                    change: '↑ Capacity 75%',
                    icon: const Icon(Icons.radio_button_on, size: 16, color: AppColors.success),
                    iconBg: AppColors.success.withValues(alpha: 0.15),
                  ),
                  StatCard(
                    label: 'ລະດັບນໍ້າອ່າງ',
                    value: _waterLevel.toStringAsFixed(1),
                    unit: 'masl',
                    change: 'ສູງສຸດ 220 masl',
                    icon: const Icon(Icons.water, size: 16, color: AppColors.info),
                    iconBg: AppColors.info.withValues(alpha: 0.15),
                  ),
                  StatCard(
                    label: 'ການຜະລິດມື້ນີ້',
                    value: _dailyGen.toStringAsFixed(1),
                    unit: 'GWh',
                    change: '↑ +4.3% ຈາກມື້ວານ',
                    icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.warning),
                    iconBg: AppColors.warning.withValues(alpha: 0.15),
                  ),
                ],
              );
            }),

            const SizedBox(height: 18),

            LayoutBuilder(builder: (ctx, cst) {
              if (cst.maxWidth > 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildPowerChart()),
                    const SizedBox(width: 14),
                    SizedBox(width: 220, child: _buildReservoirCard()),
                  ],
                );
              }
              return Column(children: [
                _buildPowerChart(),
                const SizedBox(height: 14),
                _buildReservoirCard(),
              ]);
            }),

            const SizedBox(height: 18),

            AppCard(
              title: 'ໜ່ວຍຜະລິດ — ສະຖານະ',
              trailing: AppButton(
                label: 'ເບິ່ງທັງໝົດ',
                onPressed: () {},
              ),
              padding: EdgeInsets.zero,
              child: _buildUnitTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerChart() {
    return AppCard(
      title: 'ກຳລັງຜະລິດ (Real-time)',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: AppColors.accent),
          SizedBox(width: 4),
          Text('Output MW', style: TextStyle(fontSize: 11, color: AppColors.accent)),
          SizedBox(width: 12),
          Icon(Icons.circle, size: 8, color: AppColors.warning),
          SizedBox(width: 4),
          Text('Water Flow', style: TextStyle(fontSize: 11, color: AppColors.warning)),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppColors.border, strokeWidth: 0.5),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted)),
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _mwData,
                isCurved: true,
                color: AppColors.accent,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.accent.withValues(alpha: 0.08),
                ),
              ),
              LineChartBarData(
                spots: _flowData,
                isCurved: true,
                color: AppColors.warning,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.warning.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }

  Widget _buildReservoirCard() {
    return AppCard(
      title: 'ອ່າງເກັບນໍ້າ',
      child: Column(
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 130 * (_resLevel / 100),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.3),
                          AppColors.info.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${_resLevel.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const Text('Nam Sor Reservoir',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'ທົດສອບທຸກໜ່ວຍ',
            style: AppButtonStyle.primary,
            fullWidth: true,
            icon: const Icon(Icons.play_arrow, size: 14),
            onPressed: () => _showToast('ກຳລັງທົດສອບທຸກໜ່ວຍ...'),
          ),
          const SizedBox(height: 6),
          AppButton(
            label: 'Sync SCADA',
            fullWidth: true,
            icon: const Icon(Icons.sync, size: 14),
            onPressed: () => _showToast('SCADA Sync ສຳເລັດ'),
          ),
          const SizedBox(height: 6),
          AppButton(
            label: 'Export Report',
            fullWidth: true,
            icon: const Icon(Icons.upload, size: 14),
            onPressed: () => _showToast('ດາວໂຫຼດລາຍງານ...'),
          ),
          const SizedBox(height: 6),
          AppButton(
            label: 'Emergency Stop',
            style: AppButtonStyle.danger,
            fullWidth: true,
            icon: const Icon(Icons.warning, size: 14),
            onPressed: () => _showToast('⚠️ Emergency Stop — ແຈ້ງ Operator'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitTable() {
    final units = [
      {'name': 'Unit 01', 'station': 'Station A', 'mw': '2.7', 'hz': '49.98', 'temp': '62°C', 'status': 'online'},
      {'name': 'Unit 02', 'station': 'Station A', 'mw': '2.7', 'hz': '50.01', 'temp': '61°C', 'status': 'online'},
    ];

    Color statusColor(String s) {
      switch (s) {
        case 'online':      return AppColors.success;
        case 'standby':     return AppColors.warning;
        case 'maintenance': return AppColors.info;
        default:            return AppColors.danger;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.6),
        dataTextStyle: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
        dividerThickness: 1,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('ໜ່ວຍ')),
          DataColumn(label: Text('ສະຖານີ')),
          DataColumn(label: Text('ກຳລັງ (MW)')),
          DataColumn(label: Text('ຄວາມຖີ່ (Hz)')),
          DataColumn(label: Text('ອຸນຫະພູມ')),
          DataColumn(label: Text('ສະຖານະ')),
        ],
        rows: units.map((u) {
          final sc = statusColor(u['status']!);
          return DataRow(cells: [
            DataCell(Text(u['name']!,
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(u['station']!,
                  style: const TextStyle(
                      color: AppColors.accent, fontSize: 11)),
            )),
            DataCell(Text(u['mw']!)),
            DataCell(Text(u['hz']!)),
            DataCell(Text(u['temp']!)),
            DataCell(StatusBadge(
                label: u['status']!.toUpperCase(), color: sc)),
          ]);
        }).toList(),
      ),
    );
  }
}