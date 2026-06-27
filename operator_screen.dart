// operator_screen.dart
// ສະເພາະສ່ວນທີ່ແກ້ໄຂ - ໃຊ້ທົດແທນສ່ວນທີ່ກ່ຽວຂ້ອງກັບການຄຳນວນໂຫລດເທົ່ານັ້ນ

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ດຶງໜ້າ Production Dialog ເຂົ້າມາໃຊ້ງານ
import 'production_dialog.dart';

// ນຳເຂົ້າໜ້າຕາຕະລາງຍາມໄຟຟ້າ
import 'shift_schedule_screen.dart';

// ນຳເຂົ້າໜ້າຄຳນວນໂຫລດ (ຕາຕະລາງບັນທຶກພະລັງງານ 24 ຊົ່ວໂມງ)
import 'load_screen.dart';

// ນຳເຂົ້າໜ້າ WaterLevelScreen ສຳລັບຕາຕະລາງປະລິມານນ້ຳ
import 'water_level_screen.dart';

// ນຳເຂົ້າໜ້າ ProductScreen ສຳລັບແຜນການຜະລິດໄຟຟ້າ
import 'product_screen.dart';

/// ໂທນສີ / ຮູບແບບ ສະເພາະໜ້າ Operator (SCADA-style instrument panel)
/// ໃຊ້ຄຽງຄູ່ກັບ AppColors ເດີມ ເພື່ອບໍ່ໃຫ້ກະທົບສ່ວນອື່ນຂອງແອັບ
class _Op {
  // ພື້ນຫຼັງ - ສີຄ້າມເຫມືອນຫ້ອງຄວບຄຸມ
  static const bg = Color(0xFF0A0F1A);
  static const panel = Color(0xFF111B2D);
  static const panelAlt = Color(0xFF0E1726);
  static const stroke = Color(0xFF223149);
  static const strokeSoft = Color(0xFF1A2638);

  // ສີຂໍ້ຄວາມ
  static const textHi = Color(0xFFEAF1FB);
  static const textLo = Color(0xFF7E93AE);
  static const textFaint = Color(0xFF50617A);

  // ສີສະຖານະ (instrument colors)
  static const live = Color(0xFF2EE6C5);   // online / healthy - teal
  static const info = Color(0xFF5AA7FF);   // blue
  static const warn = Color(0xFFFFC15E);   // amber
  static const violet = Color(0xFFB18CFF);
  static const lime = Color(0xFFB7E36B);

  // ຟອນ
  static const display = 'monospace'; // ໃຊ້ສະແດງຄ່າຕົວເລກແບບ instrument
}

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  // ຕົວແປສຳລັບຈົດອຸນຫະພູມ
  final TextEditingController _tempController = TextEditingController();
  String _temperatureLog = '';

  // ຕົວແປສຳລັບລະດັບນ້ຳ
  final double _waterLevel = 125.5;
  final TextEditingController _waterLevelController = TextEditingController();

  // ຂໍ້ມູນສຳລັບກຣາຟການຜະລິດ
  final List<double> _productionData = [2.5, 2.7, 2.75, 2.8, 2.75, 2.7, 2.65, 2.75, 2.8, 2.75, 2.7, 2.72];
  final List<String> _timeLabels = ['00', '02', '04', '06', '08', '10', '12', '14', '16', '18', '20', '22'];

  // ໂມງ ສຳລັບແຖບສະຖານະ
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // ===== ຕົວແປສຳລັບການເຊື່ອມຕໍ່ກັບ ProductScreen =====
  int _selectedYear = 2027;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _tempController.dispose();
    _waterLevelController.dispose();
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  // ================= ເປີດ ProductScreen ພ້ອມສົ່ງ ແລະ ຮັບຂໍ້ມູນ =================
  void _openProductScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductScreen(
          initialYear: _selectedYear,
          initialCurrency: _selectedCurrency,
        ),
      ),
    );

    // ຖ້າມີຂໍ້ມູນກັບຄືນ (ຈາກ ProductScreen ເມື່ອຜູ້ໃຊ້ປ່ຽນປີ ຫຼື ສະກຸນເງິນ)
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedYear = result['year'] ?? _selectedYear;
        _selectedCurrency = result['currency'] ?? _selectedCurrency;
        // ສາມາດອັບເດດ KPI ອື່ນໆ ເຊັ່ນ: ລາຍຮັບທັງໝົດ ຖ້າຕ້ອງການ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';

    return Scaffold(
      backgroundColor: _Op.bg,
      body: CustomScrollView(
        slivers: [
          // ===== ສ່ວນຫົວ ແບບ instrument strip =====
          SliverToBoxAdapter(child: _buildHeader(timeStr)),

          // ===== ແຖບສະຖານະລະບົບ (signature strip) =====
          SliverToBoxAdapter(child: _buildSystemStatusStrip()),

          // ===== ຫົວຂໍ້ ກ່ອນ grid ປຸ່ມ =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _Op.live,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ຄຳສັ່ງດ່ວນ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _Op.textHi,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '· QUICK CONTROLS',
                    style: TextStyle(
                      fontSize: 9,
                      color: _Op.textFaint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== ປຸ່ມຕ່າງໆ ຈັດເປັນຫຼາຍຖັນ (ປຸ່ມນ້ອຍໆແບບ Square) =====
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140, // ຄວາມກວ້າງສູງສຸດຂອງແຕ່ລະປຸ່ມ
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0, // ໃຫ້ເປັນຮູບຈະຕຸລັດເພື່ອປ້ອງກັນ Overflow
              ),
              delegate: SliverChildListDelegate([
                _buildOperatorCard(
                  title: 'ການຜະລິດໄຟຟ້າ',
                  subtitle: 'Production',
                  icon: Icons.electric_bolt,
                  color: _Op.live,
                  onTap: () => showProductionDialog(context),
                ),
                _buildOperatorCard(
                  title: 'ຄຳນວນໂຫລດ',
                  subtitle: 'Load Calc',
                  icon: Icons.calculate,
                  color: _Op.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoadScreen(),
                      ),
                    );
                  },
                ),
                _buildOperatorCard(
                  title: 'ຈົດອຸນຫະພູມ',
                  subtitle: 'Temp Log',
                  icon: Icons.thermostat,
                  color: _Op.warn,
                  onTap: () => _showTemperatureDialog(),
                ),
                _buildOperatorCard(
                  title: 'ສະຖານີທ່າສາລາ',
                  subtitle: 'Weather',
                  icon: Icons.cloud_queue,
                  color: _Op.info,
                  onTap: () => _showDevelopmentDialog('ສະຖານີທ່າສາລາ'),
                ),
                _buildOperatorCard(
                  title: 'ລະດັບນ້ຳ',
                  subtitle: 'Water Level',
                  icon: Icons.water_drop,
                  color: _Op.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WaterLevelScreen(),
                      ),
                    );
                  },
                ),
                _buildOperatorCard(
                  title: 'ແຮງດັນໄຟຟ້າ',
                  subtitle: 'Voltage',
                  icon: Icons.flash_on,
                  color: _Op.warn,
                  onTap: () => _showDevelopmentDialog('ແຮງດັນໄຟຟ້າ'),
                ),
                _buildOperatorCard(
                  title: 'ຄວາມຖີ່ລະບົບ',
                  subtitle: 'Frequency',
                  icon: Icons.tune,
                  color: _Op.violet,
                  onTap: () => _showDevelopmentDialog('ຄວາມຖີ່ລະບົບ'),
                ),
                _buildOperatorCard(
                  title: 'ລາຍງານການຜະລິດ',
                  subtitle: 'Report',
                  icon: Icons.description,
                  color: _Op.live,
                  onTap: () => _showDevelopmentDialog('ລາຍງານການຜະລິດ'),
                ),
                _buildOperatorCard(
                  title: 'ຕາຕະລາງຜະລິດ',
                  subtitle: 'Schedule',
                  icon: Icons.schedule,
                  color: _Op.violet,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShiftScheduleScreen(),
                      ),
                    );
                  },
                ),
                _buildOperatorCard(
                  title: 'ສະຖານະເຄື່ອງຈັກ',
                  subtitle: 'Status',
                  icon: Icons.settings,
                  color: _Op.textLo,
                  onTap: () => _showDevelopmentDialog('ສະຖານະເຄື່ອງຈັກ'),
                ),
                _buildOperatorCard(
                  title: 'ແຜນການຜະລິດ',
                  subtitle: 'Production Plan',
                  icon: Icons.event_note,
                  color: _Op.lime,
                  onTap: _openProductScreen,
                ),
                _buildOperatorCard(
                  title: 'ຂໍ້ມູນປະຫວັດ',
                  subtitle: 'History',
                  icon: Icons.history,
                  color: _Op.textLo,
                  onTap: () => _showDevelopmentDialog('ຂໍ້ມູນປະຫວັດ'),
                ),
              ]),
            ),
          ),

          // ===== KPI gauge tiles =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildGaugeTile('ການຜະລິດທັງໝົດ', 'TOTAL OUTPUT', '5.50', 'MW', Icons.electric_bolt, _Op.live)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildGaugeTile('ໂຫຼດປັດຈຸບັນ', 'CURRENT LOAD', '4.82', 'MW', Icons.speed, _Op.info)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildGaugeTile('ຄວາມຖີ່', 'FREQUENCY', '50.02', 'Hz', Icons.tune, _Op.lime)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildGaugeTile('ລະດັບນ້ຳ', 'WATER LEVEL', _waterLevel.toStringAsFixed(1), 'm', Icons.water_drop, _Op.info)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildGaugeTile('ອຸນຫະພູມເຄື່ອງ', 'UNIT TEMP', '55', '°C', Icons.thermostat, _Op.warn)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildGaugeTile('ປະສິດທິພາບ', 'EFFICIENCY', '94', '%', Icons.trending_up, _Op.violet)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ===== ກຣາຟການຜະລິດ =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: _buildProductionChart(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ສ່ວນຫົວ =================
  Widget _buildHeader(String timeStr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: _Op.panel,
        border: Border(bottom: BorderSide(color: _Op.stroke, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _Op.live.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Op.live.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.bolt, color: _Op.live, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATOR CONTROL PANEL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _Op.textHi,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ໜ້າຈໍຄວບຄຸມ - ໂຮງງານໄຟຟ້າ',
                  style: TextStyle(fontSize: 11, color: _Op.textLo),
                ),
              ],
            ),
          ),
          // ໂມງ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _Op.panelAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Op.strokeSoft),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                fontFamily: _Op.display,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _Op.textHi,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ແຖບສະຖານະລະບົບ (signature element) =================
  Widget _buildSystemStatusStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _Op.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Op.stroke),
      ),
      child: Row(
        children: [
          const _LivePulseDot(color: _Op.live),
          const SizedBox(width: 8),
          const Text(
            'SCADA ONLINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _Op.live,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 16, color: _Op.strokeSoft),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statusReadout('GEN', '02/02', _Op.live),
                _statusReadout('FREQ', '50.02 Hz', _Op.lime),
                _statusReadout('LOAD', '4.82 MW', _Op.info),
                _statusReadout('LEVEL', '${_waterLevel.toStringAsFixed(1)} m', _Op.info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusReadout(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: _Op.textFaint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: _Op.display,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ================= Gauge tile (KPI) =================
  Widget _buildGaugeTile(String labelLo, String labelHi, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: _Op.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Op.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const Spacer(),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: _Op.display,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _Op.textHi,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _Op.textLo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            labelLo,
            style: const TextStyle(fontSize: 10, color: _Op.textHi, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            labelHi,
            style: const TextStyle(fontSize: 8, color: _Op.textFaint, letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ================= ກຣາຟການຜະລິດ =================
  Widget _buildProductionChart() {
    return Container(
      decoration: BoxDecoration(
        color: _Op.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Op.stroke),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _Op.live.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.show_chart, color: _Op.live, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ການຜະລິດຍ້ອນຫຼັງ 24h',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _Op.textHi,
                  ),
                ),
              ),
              const Text(
                'MW',
                style: TextStyle(fontSize: 9, color: _Op.textFaint, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: _Op.strokeSoft,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontFamily: _Op.display,
                            fontSize: 9,
                            color: _Op.textFaint,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _timeLabels.length && index % 2 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _timeLabels[index],
                              style: const TextStyle(
                                fontFamily: _Op.display,
                                fontSize: 9,
                                color: _Op.textFaint,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(_productionData.length, (index) {
                      return FlSpot(index.toDouble(), _productionData[index]);
                    }),
                    isCurved: true,
                    color: _Op.live,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _Op.live.withValues(alpha: 0.22),
                          _Op.live.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: _Op.strokeSoft),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChartInfo('ສູງສຸດ', '2.80', _Op.lime),
              _buildChartInfo('ຕ່ຳສຸດ', '2.50', _Op.warn),
              _buildChartInfo('ສະເລ່ຍ', '2.72', _Op.live),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartInfo(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ',
          style: const TextStyle(fontSize: 10, color: _Op.textLo),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: _Op.display,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ================= ປຸ່ມ Operator (ປັບປຸງຂະໜາດໃຫ້ເໝາະສົມ) =================
  Widget _buildOperatorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.10),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10), // ປັບ padding ເພື່ອໃຫ້ພໍດີ
          decoration: BoxDecoration(
            color: _Op.panel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ໄອຄອນຢູ່ກາງ
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 26,  // ປັບເປັນ 26 ເພື່ອໃຫ້ກົມກຽວ
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 6), // ໄລຍະຫ່າງລະຫວ່າງໄອຄອນ ແລະ ຂໍ້ຄວາມ
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,  // ປັບຫຼຸດລົງເລັກນ້ອຍເພື່ອໃຫ້ສົມດຸນ
                  fontWeight: FontWeight.w700,
                  color: _Op.textHi,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 8.5,  // ປັບເລັກນ້ອຍ
                  color: _Op.textLo,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= Dialog ຕ່າງໆ =================

  void _showTemperatureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Op.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _Op.stroke),
        ),
        title: const Row(
          children: [
            Icon(Icons.thermostat, color: _Op.warn),
            SizedBox(width: 8),
            Text('ຈົດອຸນຫະພູມ', style: TextStyle(color: _Op.textHi)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tempController,
              decoration: const InputDecoration(
                labelText: 'ອຸນຫະພູມ (°C)',
                labelStyle: TextStyle(color: _Op.textLo),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _Op.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _Op.warn),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: _Op.stroke),
                ),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _Op.textHi),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Op.warn.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _Op.warn.withValues(alpha: 0.25)),
              ),
              child: Text(
                _temperatureLog.isEmpty
                    ? 'ຍັງບໍ່ມີຂໍ້ມູນ'
                    : _temperatureLog,
                style: const TextStyle(color: _Op.textHi, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _tempController.clear();
              Navigator.pop(context);
            },
            child: const Text('ຍົກເລີກ', style: TextStyle(color: _Op.textFaint)),
          ),
          ElevatedButton(
            onPressed: () {
              final double? temp = double.tryParse(_tempController.text);
              if (temp != null) {
                final now = DateTime.now();
                final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                setState(() {
                  _temperatureLog = '[$timeStr] ອຸນຫະພູມ: ${temp.toStringAsFixed(1)}°C\n$_temperatureLog';
                  if (_temperatureLog.split('\n').length > 10) {
                    _temperatureLog = _temperatureLog.split('\n').sublist(0, 10).join('\n');
                  }
                });
                _tempController.clear();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _Op.warn,
            ),
            child: const Text('ບັນທຶກ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDevelopmentDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Op.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _Op.stroke),
        ),
        title: const Row(
          children: [
            Icon(Icons.construction, color: _Op.warn),
            SizedBox(width: 8),
            Text('ກຳລັງພັດທະນາ', style: TextStyle(color: _Op.textHi)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.build, size: 48, color: _Op.warn),
            const SizedBox(height: 16),
            Text(
              'ຟີດເຈີ "$feature" ກຳລັງຢູ່ໃນການພັດທະນາ',
              style: const TextStyle(color: _Op.textHi, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'ທ່ານສາມາດຕິດຕາມການອັບເດດໄດ້ພາຍຫຼັງ',
              style: TextStyle(color: _Op.textFaint, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Op.live,
            ),
            child: const Text('ຕົກລົງ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

/// ຈຸດໄຟກະພິບ ສະແດງສະຖານະ "online" / live
class _LivePulseDot extends StatefulWidget {
  final Color color;
  const _LivePulseDot({required this.color});

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * (1 - t)),
                blurRadius: 6 + (6 * t),
                spreadRadius: 1 + (2 * t),
              ),
            ],
          ),
        );
      },
    );
  }
}