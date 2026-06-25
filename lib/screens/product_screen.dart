// product_screen.dart
// Flutter version of the Nam Xouang Hydropower Production Plan
// Fully compatible with Excel formulas and sheet navigation
// Supports parameter passing and returning data to parent screen
// Shows ALL water level data from 513 to 532 masl (every 0.01m)
// Summary table: dark background with white text, white borders

import 'package:flutter/material.dart';
import 'dart:math';

// --------------------------------------------------------------
// Data models
// --------------------------------------------------------------
class VolumeEntry {
  final double waterLevel;
  final int totalVolume;
  final int activeVolume;
  final int diffVolume;

  VolumeEntry({
    required this.waterLevel,
    required this.totalVolume,
    required this.activeVolume,
    required this.diffVolume,
  });
}

class InflowEntry {
  final String month;
  final double value2026;
  final double value2027;

  InflowEntry({
    required this.month,
    required this.value2026,
    required this.value2027,
  });
}

class MonthlyProduction {
  final String month;
  final double startWL;
  final int startVol;
  final double inflow;
  final int inflowVol;
  final double u1p;
  final double u1q;
  final int u1vol;
  final double u2p;
  final double u2q;
  final int u2vol;
  final int totalDischarge;
  final int spill;
  final double energyMWh;
  final int energyKWh;
  final double incomeUSD;
  final int endVol;
  final double endWL;

  MonthlyProduction({
    required this.month,
    required this.startWL,
    required this.startVol,
    required this.inflow,
    required this.inflowVol,
    required this.u1p,
    required this.u1q,
    required this.u1vol,
    required this.u2p,
    required this.u2q,
    required this.u2vol,
    required this.totalDischarge,
    required this.spill,
    required this.energyMWh,
    required this.energyKWh,
    required this.incomeUSD,
    required this.endVol,
    required this.endWL,
  });
}

class YearlySummary {
  final int totalInflow;
  final int totalDischarge;
  final int totalSpill;
  final double totalEnergyMWh;
  final int totalEnergyKWh;
  final double totalIncomeUSD;

  YearlySummary({
    required this.totalInflow,
    required this.totalDischarge,
    required this.totalSpill,
    required this.totalEnergyMWh,
    required this.totalEnergyKWh,
    required this.totalIncomeUSD,
  });
}

class YearData {
  final List<MonthlyProduction> rows;
  final YearlySummary totals;
  final double startWL;
  final double endWL;
  final double price;

  YearData({
    required this.rows,
    required this.totals,
    required this.startWL,
    required this.endWL,
    required this.price,
  });
}

// --------------------------------------------------------------
// Core calculation engine (port of Excel formulas)
// --------------------------------------------------------------
class ProductionCalculator {
  static const double MAX_VOLUME = 2265000; // m³ at 530 masl
  static const double USD_TO_LAK = 21000;
  static const double ACTIVE_CAPACITY_MCM = 2.27; // used for percentage calculation

  // Volume lookup from "ปริมาณน้ำ" sheet
  static final Map<double, int> _volumeLookup = _buildVolumeLookup();

  static Map<double, int> _buildVolumeLookup() {
    final map = <double, int>{};
    map[513.00] = 0;
    map[518.00] = 27000;

    // 518.01 → 520.00 : +305 per 0.01
    for (double wl = 518.01; wl <= 520.00; wl += 0.01) {
      double prev = double.parse((wl - 0.01).toStringAsFixed(2));
      map[double.parse(wl.toStringAsFixed(2))] = map[prev]! + 305;
    }
    // 520.01 → 524.00 : +865 per 0.01
    for (double wl = 520.01; wl <= 524.00; wl += 0.01) {
      double prev = double.parse((wl - 0.01).toStringAsFixed(2));
      map[double.parse(wl.toStringAsFixed(2))] = map[prev]! + 865;
    }
    // 524.01 → 528.00 : +2210 per 0.01
    for (double wl = 524.01; wl <= 528.00; wl += 0.01) {
      double prev = double.parse((wl - 0.01).toStringAsFixed(2));
      map[double.parse(wl.toStringAsFixed(2))] = map[prev]! + 2210;
    }
    // 528.01 → 530.00 : +3620 per 0.01
    for (double wl = 528.01; wl <= 530.00; wl += 0.01) {
      double prev = double.parse((wl - 0.01).toStringAsFixed(2));
      map[double.parse(wl.toStringAsFixed(2))] = map[prev]! + 3620;
    }
    // 530.01 → 532.00 : +4630 per 0.01
    for (double wl = 530.01; wl <= 532.00; wl += 0.01) {
      double prev = double.parse((wl - 0.01).toStringAsFixed(2));
      map[double.parse(wl.toStringAsFixed(2))] = map[prev]! + 4630;
    }
    return map;
  }

  static int getVolumeFromWL(double wl) {
    double rounded = double.parse(wl.toStringAsFixed(2));
    if (_volumeLookup.containsKey(rounded)) {
      return _volumeLookup[rounded]!;
    }
    // Interpolate
    List<double> keys = _volumeLookup.keys.toList()..sort();
    for (int i = 0; i < keys.length - 1; i++) {
      if (keys[i] <= rounded && rounded <= keys[i + 1]) {
        int v1 = _volumeLookup[keys[i]]!;
        int v2 = _volumeLookup[keys[i + 1]]!;
        double t = (rounded - keys[i]) / (keys[i + 1] - keys[i]);
        return (v1 + t * (v2 - v1)).round();
      }
    }
    return _volumeLookup[keys.last] ?? 0;
  }

  static double getWLFromVolume(int vol) {
    List<double> keys = _volumeLookup.keys.toList()..sort();
    int target = vol;
    if (target <= 0) return 513.00;
    for (int i = 0; i < keys.length - 1; i++) {
      int v1 = _volumeLookup[keys[i]]!;
      int v2 = _volumeLookup[keys[i + 1]]!;
      if (v1 <= target && target <= v2) {
        if (v2 == v1) return keys[i];
        double t = (target - v1) / (v2 - v1);
        double wl = keys[i] + t * (keys[i + 1] - keys[i]);
        return double.parse(wl.toStringAsFixed(2));
      }
    }
    return keys.last;
  }

  // Inflow data from "น้ำไหลเข้า"
  static const Map<int, Map<String, double>> _inflowData = {
    2026: {
      'Jan': 0.30, 'Feb': 0.30, 'Mar': 0.20, 'Apr': 0.25,
      'May': 0.45, 'Jun': 2.20, 'Jul': 1.69, 'Aug': 7.00,
      'Sep': 7.00, 'Oct': 2.80, 'Nov': 0.22, 'Dec': 0.21
    },
    2027: {
      'Jan': 0.32, 'Feb': 0.31, 'Mar': 0.22, 'Apr': 0.26,
      'May': 0.47, 'Jun': 2.15, 'Jul': 1.70, 'Aug': 7.00,
      'Sep': 7.00, 'Oct': 2.87, 'Nov': 0.25, 'Dec': 0.22
    }
  };

  static const List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const Map<String, int> monthDays = {
    'Jan': 31, 'Feb': 28, 'Mar': 31, 'Apr': 30,
    'May': 31, 'Jun': 30, 'Jul': 31, 'Aug': 31,
    'Sep': 30, 'Oct': 31, 'Nov': 30, 'Dec': 31
  };

  // Schedule for each year (Unit1 & Unit2)
  static Map<String, dynamic> _getSchedule(int year) {
    if (year == 2026) {
      return {
        'Jan': {'u1': 0.0, 'u1h': 0, 'u1d': 0, 'u2': 1.2, 'u2h': 8, 'u2d': 25},
        'Feb': {'u1': 1.2, 'u1h': 8, 'u1d': 25, 'u2': 0.0, 'u2h': 0, 'u2d': 0},
        'Mar': {'u1': 0.0, 'u1h': 0, 'u1d': 0, 'u2': 1.2, 'u2h': 8, 'u2d': 24},
        'Apr': {'u1': 1.2, 'u1h': 8, 'u1d': 25, 'u2': 0.0, 'u2h': 0, 'u2d': 0},
        'May': {'u1': 0.0, 'u1h': 0, 'u1d': 0, 'u2': 1.2, 'u2h': 16, 'u2d': 28},
        'Jun': {'u1': 2.0, 'u1h': 16, 'u1d': 27, 'u2': 2.0, 'u2h': 16, 'u2d': 27},
        'Jul': {'u1': 2.5, 'u1h': 24, 'u1d': 26, 'u2': 2.5, 'u2h': 24, 'u2d': 26},
        'Aug': {'u1': 2.7, 'u1h': 24, 'u1d': 26, 'u2': 2.7, 'u2h': 24, 'u2d': 26},
        'Sep': {'u1': 2.7, 'u1h': 24, 'u1d': 26, 'u2': 2.7, 'u2h': 24, 'u2d': 26},
        'Oct': {'u1': 2.0, 'u1h': 24, 'u1d': 25, 'u2': 2.0, 'u2h': 24, 'u2d': 25},
        'Nov': {'u1': 1.2, 'u1h': 8, 'u1d': 22, 'u2': 0.0, 'u2h': 0, 'u2d': 0},
        'Dec': {'u1': 0.0, 'u1h': 0, 'u1d': 0, 'u2': 1.2, 'u2h': 8, 'u2d': 20}
      };
    } else {
      // 2027
      return {
        'Jan': {'u1': 1.2, 'u1h': 8, 'u1d': 27, 'u2': 1.2, 'u2h': 8, 'u2d': 27},
        'Feb': {'u1': 1.2, 'u1h': 8, 'u1d': 25, 'u2': 1.2, 'u2h': 8, 'u2d': 25},
        'Mar': {'u1': 1.2, 'u1h': 8, 'u1d': 25, 'u2': 1.2, 'u2h': 8, 'u2d': 24},
        'Apr': {'u1': 1.2, 'u1h': 8, 'u1d': 25, 'u2': 1.2, 'u2h': 8, 'u2d': 25},
        'May': {'u1': 1.2, 'u1h': 8, 'u1d': 25, 'u2': 1.2, 'u2h': 16, 'u2d': 25},
        'Jun': {'u1': 2.5, 'u1h': 16, 'u1d': 26, 'u2': 2.0, 'u2h': 16, 'u2d': 26},
        'Jul': {'u1': 2.0, 'u1h': 24, 'u1d': 26, 'u2': 2.0, 'u2h': 24, 'u2d': 26},
        'Aug': {'u1': 2.7, 'u1h': 24, 'u1d': 25, 'u2': 2.7, 'u2h': 24, 'u2d': 25},
        'Sep': {'u1': 2.7, 'u1h': 24, 'u1d': 25, 'u2': 2.7, 'u2h': 24, 'u2d': 25},
        'Oct': {'u1': 2.0, 'u1h': 24, 'u1d': 24, 'u2': 2.0, 'u2h': 24, 'u2d': 24},
        'Nov': {'u1': 2.0, 'u1h': 8, 'u1d': 22, 'u2': 1.5, 'u2h': 18, 'u2d': 26},
        'Dec': {'u1': 2.0, 'u1h': 16, 'u1d': 18, 'u2': 1.2, 'u2h': 8, 'u2d': 25}
      };
    }
  }

  static const Map<int, double> _priceRate = {2026: 6.76, 2027: 6.72};

  static YearData calculateYear(int year) {
    final inflow = _inflowData[year]!;
    final schedule = _getSchedule(year);
    final price = _priceRate[year]!;
    final List<MonthlyProduction> rows = [];

    double prevWL = (year == 2026) ? 528.00 : 527.78;
    int prevVol = getVolumeFromWL(prevWL);

    for (int i = 0; i < 12; i++) {
      String m = monthNames[i];
      int days = monthDays[m]!;
      double infl = inflow[m] ?? 0;
      Map<String, dynamic> sch = schedule[m];

      double u1p = (sch['u1'] ?? 0.0).toDouble();
      int u1h = (sch['u1h'] ?? 0).toInt();
      int u1d = (sch['u1d'] ?? 0).toInt();
      double u2p = (sch['u2'] ?? 0.0).toDouble();
      int u2h = (sch['u2h'] ?? 0).toInt();
      int u2d = (sch['u2d'] ?? 0).toInt();

      double u1q = (u1p > 0) ? (u1p * 2.52 / 2.7) : 0;
      double u2q = (u2p > 0) ? (u2p * 2.52 / 2.7) : 0;

      int u1vol = (u1p > 0 && u1h > 0 && u1d > 0)
          ? (u1q * 3600 * u1h * u1d).round()
          : 0;
      int u2vol = (u2p > 0 && u2h > 0 && u2d > 0)
          ? (u2q * 3600 * u2h * u2d).round()
          : 0;

      int inflowVol = (infl * 3600 * 24 * days).round();
      int totalDischarge = u1vol + u2vol;

      int spill = 0;
      int endVol = prevVol + inflowVol - totalDischarge;
      if (endVol > MAX_VOLUME) {
        spill = endVol - MAX_VOLUME.toInt();
        endVol = MAX_VOLUME.toInt();
      }
      if (endVol < 0) endVol = 0;
      double endWL = getWLFromVolume(endVol);

      double energyMWh = (u1p * u1h * u1d) + (u2p * u2h * u2d);
      int energyKWh = (energyMWh * 1000).round();
      double incomeUSD = energyKWh * (price / 100);

      rows.add(MonthlyProduction(
        month: m,
        startWL: prevWL,
        startVol: prevVol,
        inflow: infl,
        inflowVol: inflowVol,
        u1p: u1p,
        u1q: u1q,
        u1vol: u1vol,
        u2p: u2p,
        u2q: u2q,
        u2vol: u2vol,
        totalDischarge: totalDischarge,
        spill: spill,
        energyMWh: energyMWh,
        energyKWh: energyKWh,
        incomeUSD: incomeUSD,
        endVol: endVol,
        endWL: endWL,
      ));

      prevWL = endWL;
      prevVol = endVol;
    }

    int totalInflow = rows.fold(0, (sum, r) => sum + r.inflowVol);
    int totalDischarge = rows.fold(0, (sum, r) => sum + r.totalDischarge);
    int totalSpill = rows.fold(0, (sum, r) => sum + r.spill);
    double totalEnergyMWh = rows.fold(0.0, (sum, r) => sum + r.energyMWh);
    int totalEnergyKWh = rows.fold(0, (sum, r) => sum + r.energyKWh);
    double totalIncomeUSD = rows.fold(0.0, (sum, r) => sum + r.incomeUSD);

    return YearData(
      rows: rows,
      totals: YearlySummary(
        totalInflow: totalInflow,
        totalDischarge: totalDischarge,
        totalSpill: totalSpill,
        totalEnergyMWh: totalEnergyMWh,
        totalEnergyKWh: totalEnergyKWh,
        totalIncomeUSD: totalIncomeUSD,
      ),
      startWL: (year == 2026) ? 528.00 : 527.78,
      endWL: rows.isNotEmpty ? rows.last.endWL : 528.00,
      price: price,
    );
  }

  // Volume table for the volume sheet - returns ALL water levels from 513 to 532
  static List<VolumeEntry> getVolumeTable() {
    List<double> keys = _volumeLookup.keys.toList()..sort();
    int deadStorage = 27000; // Volume at 518.00 masl
    int baseVol = _volumeLookup[513.00] ?? 0;
    return keys.map((wl) {
      int vol = _volumeLookup[wl]!;
      return VolumeEntry(
        waterLevel: wl,
        totalVolume: vol,
        activeVolume: vol - deadStorage,
        diffVolume: vol - baseVol,
      );
    }).toList();
  }

  // Inflow table for the inflow sheet
  static List<InflowEntry> getInflowTable() {
    return monthNames.map((m) {
      return InflowEntry(
        month: m,
        value2026: _inflowData[2026]![m] ?? 0,
        value2027: _inflowData[2027]![m] ?? 0,
      );
    }).toList();
  }
}

// --------------------------------------------------------------
// Flutter Widgets
// --------------------------------------------------------------

class ProductScreen extends StatefulWidget {
  final int initialYear;
  final String initialCurrency;

  const ProductScreen({
    Key? key,
    this.initialYear = 2027,
    this.initialCurrency = 'USD',
  }) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late int _selectedYear;
  late String _currency;
  String _activeSheet = 'year'; // 'year', 'volume', 'inflow'

  late YearData _yearData;
  List<VolumeEntry> _volumeData = [];
  List<InflowEntry> _inflowData = [];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _currency = widget.initialCurrency;
    _yearData = ProductionCalculator.calculateYear(_selectedYear);
    _volumeData = ProductionCalculator.getVolumeTable();
    _inflowData = ProductionCalculator.getInflowTable();
  }

  void _updateYear(int year) {
    setState(() {
      _selectedYear = year;
      _yearData = ProductionCalculator.calculateYear(year);
    });
    Navigator.pop(context, {'year': year, 'currency': _currency});
  }

  void _updateCurrency(String currency) {
    setState(() {
      _currency = currency;
    });
    Navigator.pop(context, {'year': _selectedYear, 'currency': currency});
  }

  void _switchSheet(String sheet) {
    setState(() {
      _activeSheet = sheet;
    });
  }

  String _formatNumber(int n, {int decimals = 0}) {
    if (n == 0) return '0';
    if (n.abs() >= 1e9) return '${(n / 1e9).toStringAsFixed(2)}B';
    if (n.abs() >= 1e6) return '${(n / 1e6).toStringAsFixed(2)}M';
    if (decimals == 0) return n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return n.toStringAsFixed(decimals);
  }

  String _formatCurrency(double usd) {
    if (_currency == 'LAK') {
      double lak = usd * ProductionCalculator.USD_TO_LAK;
      if (lak >= 1e9) return '${(lak / 1e9).toStringAsFixed(2)} ຕື້ກີບ';
      if (lak >= 1e6) return '${(lak / 1e6).toStringAsFixed(2)} ລ້ານກີບ';
      return '${lak.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ກີບ';
    } else {
      if (usd >= 1e6) return '${(usd / 1e6).toStringAsFixed(2)}M USD';
      if (usd >= 1e3) return '${(usd / 1e3).toStringAsFixed(2)}K USD';
      return '${usd.toStringAsFixed(2)} USD';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ແຜນການຜະລິດເຂື່ອນໄຟຟ້ານ້ຳຊໍ້'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, {'year': _selectedYear, 'currency': _currency});
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Text(
                'ສະແດງທຸກແຜ່ນຂໍ້ມູນຄື Excel — ຄຳນວນຕາມສູດ 100%',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Tabs
            Row(
              children: [
                _buildSheetTab('year', '📊 ປີ 2026-2027'),
                _buildSheetTab('volume', '📦 ປະລິມານນ້ຳ'),
                _buildSheetTab('inflow', '💧 ນ້ຳໄຫຼເຂົ້າ'),
              ],
            ),
            const SizedBox(height: 12),

            // Toolbar (only for year sheet)
            if (_activeSheet == 'year')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Text('ປີ: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: const [
                        DropdownMenuItem(value: 2026, child: Text('2026')),
                        DropdownMenuItem(value: 2027, child: Text('2027')),
                      ],
                      onChanged: (val) {
                        if (val != null) _updateYear(val);
                      },
                    ),
                    const SizedBox(width: 24),
                    const Text('ສະກຸນເງິນ: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _currency,
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'LAK', child: Text('LAK (ກີບ)')),
                      ],
                      onChanged: (val) {
                        if (val != null) _updateCurrency(val);
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '✅ ຄຳນວນສຳເລັດ — $_selectedYear',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Sheet content
            Expanded(
              child: _buildSheetContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetTab(String sheetId, String label) {
    bool isActive = _activeSheet == sheetId;
    return GestureDetector(
      onTap: () => _switchSheet(sheetId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[200],
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.white : Colors.grey[400]!,
              width: 2,
            ),
            top: BorderSide(
              color: isActive ? Colors.blue[800]! : Colors.grey[400]!,
              width: 1,
            ),
            left: BorderSide(
              color: isActive ? Colors.blue[800]! : Colors.grey[400]!,
              width: 1,
            ),
            right: BorderSide(
              color: isActive ? Colors.blue[800]! : Colors.grey[400]!,
              width: 1,
            ),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue[800] : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSheetContent() {
    switch (_activeSheet) {
      case 'year':
        return _buildYearSheet();
      case 'volume':
        return _buildVolumeSheet();
      case 'inflow':
        return _buildInflowSheet();
      default:
        return const SizedBox.shrink();
    }
  }

  // --------------------------------------------------------------
  // YEAR SHEET (full width, compact)
  // --------------------------------------------------------------
  Widget _buildYearSheet() {
    final rows = _yearData.rows;
    final totals = _yearData.totals;

    return Column(
      children: [
        // Main table - full width, reduced spacing
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 4,
                    horizontalMargin: 0,
                    headingRowColor: MaterialStateProperty.all(Colors.blue[800]),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    dataRowMaxHeight: 28,
                    dataRowMinHeight: 24,
                    dataTextStyle: const TextStyle(fontSize: 12),
                    columns: const [
                      DataColumn(label: Text('ເດືອນ', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ລະດັບນ້ຳ\n(masl)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ປະລິມານ\n(m³)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ນ້ຳເຂົ້າ\n(m³/s)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ນ້ຳເຂົ້າ\n(m³)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Unit1\n(MW)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Unit1\n(m³/s)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Unit1\n(m³)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Unit2\n(MW)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Unit2\n(m³/s)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Unit2\n(m³)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ລວມລະບາຍ\n(m³)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ສະປິວ\n(m³)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ພະລັງງານ\n(MWh)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ພະລັງງານ\n(kWh)', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('ລາຍຮັບ', style: TextStyle(fontSize: 12))),
                    ],
                    rows: [
                      ...rows.map((r) {
                        bool u1on = r.u1p > 0;
                        bool u2on = r.u2p > 0;
                        bool spillActive = r.spill > 0;
                        return DataRow(
                          cells: [
                            DataCell(Text(r.month, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(r.startWL.toStringAsFixed(2))),
                            DataCell(Text(_formatNumber(r.startVol))),
                            DataCell(Text(r.inflow.toStringAsFixed(2))),
                            DataCell(Text(_formatNumber(r.inflowVol))),
                            DataCell(Text(u1on ? r.u1p.toStringAsFixed(1) : '—')),
                            DataCell(Text(u1on ? r.u1q.toStringAsFixed(3) : '—')),
                            DataCell(Text(u1on ? _formatNumber(r.u1vol) : '—')),
                            DataCell(Text(u2on ? r.u2p.toStringAsFixed(1) : '—')),
                            DataCell(Text(u2on ? r.u2q.toStringAsFixed(3) : '—')),
                            DataCell(Text(u2on ? _formatNumber(r.u2vol) : '—')),
                            DataCell(Text(_formatNumber(r.totalDischarge))),
                            DataCell(Text(spillActive ? _formatNumber(r.spill) : '—')),
                            DataCell(Text(r.energyMWh.toStringAsFixed(1), style: const TextStyle(color: Colors.blue))),
                            DataCell(Text(_formatNumber(r.energyKWh), style: const TextStyle(color: Colors.blue))),
                            DataCell(Text(_formatCurrency(r.incomeUSD), style: const TextStyle(color: Colors.green))),
                          ],
                        );
                      }),
                      // Total row
                      DataRow(
                        color: MaterialStateProperty.all(Colors.grey[200]),
                        cells: [
                          const DataCell(Text('ລວມ', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataCell(Text('—')),
                          const DataCell(Text('—')),
                          const DataCell(Text('—')),
                          DataCell(Text(_formatNumber(totals.totalInflow))),
                          const DataCell(Text('—')),
                          const DataCell(Text('—')),
                          const DataCell(Text('—')),
                          const DataCell(Text('—')),
                          const DataCell(Text('—')),
                          const DataCell(Text('—')),
                          DataCell(Text(_formatNumber(totals.totalDischarge))),
                          DataCell(Text(totals.totalSpill > 0 ? _formatNumber(totals.totalSpill) : '—')),
                          DataCell(Text(totals.totalEnergyMWh.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          DataCell(Text(_formatNumber(totals.totalEnergyKWh), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          DataCell(Text(_formatCurrency(totals.totalIncomeUSD), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Summary table (dark background, white text, full width)
        _buildSummaryPlanTable(),

        const SizedBox(height: 8),

        // Summary cards (light background, kept as is)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildSummaryItem('ລະດັບນ້ຳຕົ້ນປີ', '${_yearData.startWL.toStringAsFixed(2)} masl'),
              _buildSummaryItem('ລະດັບນ້ຳທ້າຍປີ', '${_yearData.endWL.toStringAsFixed(2)} masl'),
              _buildSummaryItem('ນ້ຳເຂົ້າທັງໝົດ', '${_formatNumber(totals.totalInflow)} m³'),
              _buildSummaryItem('ລະບາຍທັງໝົດ', '${_formatNumber(totals.totalDischarge)} m³'),
              _buildSummaryItem('ພະລັງງານທັງໝົດ', '${totals.totalEnergyMWh.toStringAsFixed(1)} MWh',
                  color: Colors.blue),
              _buildSummaryItem('ລາຍຮັບທັງໝົດ', _formatCurrency(totals.totalIncomeUSD),
                  color: Colors.green),
              _buildSummaryItem('ລາຄາຂາຍ', '${_yearData.price.toStringAsFixed(2)} ¢/kWh'),
              _buildSummaryItem(
                  'ສະພາບ',
                  _yearData.endWL >= 527.5 ? '✅ ປົກກະຕິ' : '⚠️ ລະດັບນ້ຳຕໍ່າ',
                  color: _yearData.endWL >= 527.5 ? Colors.green : Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '⚙️ ຄຳນວນຕາມສູດ: ກຳລັງ (MW) × 2.52 ÷ 2.7 = ອັດຕາລະບາຍ (m³/s)  |  ລາຄາຂາຍ 6.76¢/kWh (2026) · 6.72¢/kWh (2027)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // --------------------------------------------------------------
  // SUMMARY PLAN TABLE (Dark background, white text, white borders, full width)
  // --------------------------------------------------------------
  Widget _buildSummaryPlanTable() {
    final rows = _yearData.rows;
    const double activeCapacityMCM = ProductionCalculator.ACTIVE_CAPACITY_MCM;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Water Discharge and Power Production Plan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          // Table - compact spacing
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 8,
              horizontalMargin: 4,
              headingRowColor: MaterialStateProperty.all(Colors.grey[800]),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.white,
              ),
              dataRowMaxHeight: 28,
              dataRowMinHeight: 24,
              dataTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              columns: const [
                DataColumn(label: Text('ເດືອນ', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('ລະດັບນ້ຳຕົ້ນ\n(masl)', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('Active Storage\nຕົ້ນ (MCM)', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('%', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('Inflow\n(MCM)', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('Discharge\n(MCM)', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('Spillway\n(MCM)', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('Evap\n(MCM)', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('Active Storage\nທ້າຍ (MCM)', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('%', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('ລະດັບນ້ຳທ້າຍ\n(masl)', style: TextStyle(fontSize: 11, color: Colors.white))),
                DataColumn(label: Text('ການຜະລິດ\n(GWh)', style: TextStyle(fontSize: 11, color: Colors.white))),
              ],
              rows: rows.asMap().entries.map((entry) {
                var r = entry.value;
                double activeStartMCM = (r.startVol - 27000) / 1e6;
                double activeEndMCM = (r.endVol - 27000) / 1e6;
                double percentStart = (activeStartMCM / activeCapacityMCM) * 100;
                double percentEnd = (activeEndMCM / activeCapacityMCM) * 100;
                double inflowMCM = r.inflowVol / 1e6;
                double dischargeMCM = r.totalDischarge / 1e6;
                double spillMCM = r.spill / 1e6;
                double gwh = r.energyKWh / 1e6;

                if (activeStartMCM < 0) activeStartMCM = 0;
                if (activeEndMCM < 0) activeEndMCM = 0;
                if (percentStart < 0) percentStart = 0;
                if (percentEnd < 0) percentEnd = 0;

                return DataRow(
                  cells: [
                    DataCell(Text(r.month, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                    DataCell(Text(r.startWL.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(activeStartMCM.toStringAsFixed(3), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(percentStart.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(inflowMCM.toStringAsFixed(3), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(dischargeMCM.toStringAsFixed(3), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(spillMCM > 0 ? spillMCM.toStringAsFixed(3) : '—', style: const TextStyle(fontSize: 11))),
                    const DataCell(Text('—', style: TextStyle(fontSize: 11))),
                    DataCell(Text(activeEndMCM.toStringAsFixed(3), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(percentEnd.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(r.endWL.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(gwh.toStringAsFixed(3), style: const TextStyle(fontSize: 11, color: Colors.blueAccent))),
                  ],
                );
              }).toList(),
            ),
          ),
          // Total row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('ລວມ: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                Text(
                  'ນ້ຳເຂົ້າ ${(rows.fold(0.0, (s, r) => s + r.inflowVol) / 1e6).toStringAsFixed(3)} MCM  |  '
                  'ລະບາຍ ${(rows.fold(0.0, (s, r) => s + r.totalDischarge) / 1e6).toStringAsFixed(3)} MCM  |  '
                  'ສະປິວ ${(rows.fold(0.0, (s, r) => s + r.spill) / 1e6).toStringAsFixed(3)} MCM  |  '
                  'ການຜະລິດ ${(rows.fold(0.0, (s, r) => s + r.energyKWh) / 1e6).toStringAsFixed(3)} GWh',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // VOLUME SHEET - Shows ALL water levels from 513 to 532 masl
  // --------------------------------------------------------------
  Widget _buildVolumeSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'ຕາຕະລາງຄວາມສຳພັນລະດັບນ້ຳ – ປະລິມານ (ຈາກແຜ່ນ "ປະລິມານນ້ຳ")',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_volumeData.length} ແຖວ',
                  style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12,
                  headingRowColor: MaterialStateProperty.all(Colors.blue[800]),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  dataRowMaxHeight: 28,
                  dataRowMinHeight: 24,
                  columns: const [
                    DataColumn(label: Text('ລະດັບນ້ຳ (masl)')),
                    DataColumn(label: Text('ປະລິມານທັງໝົດ (m³)')),
                    DataColumn(label: Text('ປະລິມານທີ່ໃຊ້ງານໄດ້ (m³)')),
                    DataColumn(label: Text('ຄວາມຕ່າງລະດັບ (m³)')),
                  ],
                  rows: _volumeData.map((entry) {
                    Color? rowColor;
                    if (entry.waterLevel == 513.00) {
                      rowColor = Colors.grey[300];
                    } else if (entry.waterLevel == 518.00) {
                      rowColor = Colors.blue[50];
                    } else if (entry.waterLevel == 530.00) {
                      rowColor = Colors.green[50];
                    }
                    return DataRow(
                      color: rowColor != null ? MaterialStateProperty.all(rowColor) : null,
                      cells: [
                        DataCell(Text(
                          entry.waterLevel.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: entry.waterLevel == 513.00 || entry.waterLevel == 530.00
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        )),
                        DataCell(Text(_formatNumber(entry.totalVolume))),
                        DataCell(Text(_formatNumber(entry.activeVolume))),
                        DataCell(Text(_formatNumber(entry.diffVolume))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 6),
            const Text('= 513.00 (ພື້ນຖານ)', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              color: Colors.blue[50],
            ),
            const SizedBox(width: 6),
            const Text('= 518.00 (Dead Storage)', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              color: Colors.green[50],
            ),
            const SizedBox(width: 6),
            const Text('= 530.00 (Max Level)', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '* ສະແດງຂໍ້ມູນຕັ້ງແຕ່ລະດັບ 513 – 532 masl ທຸກຂັ້ນ 0.01 ແມັດ ຕາມໄຟລ໌ Excel (ທັງໝົດ ${_volumeData.length} ແຖວ)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // --------------------------------------------------------------
  // INFLOW SHEET
  // --------------------------------------------------------------
  Widget _buildInflowSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Text(
            'ຕາຕະລາງນ້ຳໄຫຼເຂົ້າປະຈຳເດືອນ (ຈາກແຜ່ນ "ນ້ຳໄຫຼເຂົ້າ")',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: MaterialStateProperty.all(Colors.blue[800]),
              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              columns: const [
                DataColumn(label: Text('ເດືອນ')),
                DataColumn(label: Text('2026 (m³/s)')),
                DataColumn(label: Text('2027 (m³/s)')),
              ],
              rows: _inflowData.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(Text(entry.month, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(entry.value2026.toStringAsFixed(2))),
                    DataCell(Text(entry.value2027.toStringAsFixed(2))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}