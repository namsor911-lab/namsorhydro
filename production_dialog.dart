import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';

// ─────────────────────────────────────────────
// ໂທນສີ SCADA
// ─────────────────────────────────────────────
class _Op {
  static const bg         = Color(0xFF0A0F1A);
  static const panel      = Color(0xFF111B2D);
  static const panelAlt   = Color(0xFF0E1726);
  static const stroke     = Color(0xFF223149);
  static const strokeSoft = Color(0xFF1A2638);
  static const textHi     = Color(0xFFEAF1FB);
  static const textLo     = Color(0xFF7E93AE);
  static const textFaint  = Color(0xFF50617A);
  static const live       = Color(0xFF2EE6C5);
  static const info       = Color(0xFF5AA7FF);
  static const warn       = Color(0xFFFFC15E);
  static const danger     = Color(0xFFFF6B6B);
  static const violet     = Color(0xFFB18CFF);
  static const lime       = Color(0xFFB7E36B);
  static const green      = Color(0xFF4ADE80);
  static const orange     = Color(0xFFFF9F40);
  static const display    = 'monospace';
}

// ══════════════════════════════════════════════════════════════════════════════
// MODELS
// ══════════════════════════════════════════════════════════════════════════════
class MinuteMeterReading {
  final double exportKwh; final double exportKvarh; final double importKwh; final double importKvarh;
  const MinuteMeterReading({required this.exportKwh, required this.exportKvarh, required this.importKwh, required this.importKvarh});
}

class HourlyMeterReading {
  final int hour; final double exportKwh; final double exportKvarh; final double importKwh; final double importKvarh; final bool isComplete;
  const HourlyMeterReading({required this.hour, required this.exportKwh, required this.exportKvarh, required this.importKwh, required this.importKvarh, this.isComplete = false});
  factory HourlyMeterReading.empty(int hour) => HourlyMeterReading(hour: hour, exportKwh: 0, exportKvarh: 0, importKwh: 0, importKvarh: 0, isComplete: false);
}

class ManualMeterEntry {
  final DateTime timestamp;
  final double mainExpKwh, mainExpKvarh, mainImpKwh, mainImpKvarh;
  final double backupExpKwh, backupExpKvarh, backupImpKwh, backupImpKvarh;
  const ManualMeterEntry({
    required this.timestamp,
    required this.mainExpKwh, required this.mainExpKvarh, required this.mainImpKwh, required this.mainImpKvarh,
    required this.backupExpKwh, required this.backupExpKvarh, required this.backupImpKwh, required this.backupImpKvarh,
  });
}

class DailyMeterData {
  final DateTime date; final List<HourlyMeterReading> mainMeterHours; final List<HourlyMeterReading> backupMeterHours;
  DailyMeterData({required this.date, required this.mainMeterHours, required this.backupMeterHours});
  factory DailyMeterData.empty(DateTime date) => DailyMeterData(date: DateTime(date.year, date.month, date.day), mainMeterHours: List.generate(24, (i) => HourlyMeterReading.empty(i)), backupMeterHours: List.generate(24, (i) => HourlyMeterReading.empty(i)));
  HourlyMeterReading get dailyMainTotal { double eK=0, eV=0, iK=0, iV=0; for (final h in mainMeterHours) { eK+=h.exportKwh; eV+=h.exportKvarh; iK+=h.importKwh; iV+=h.importKvarh; } return HourlyMeterReading(hour: -1, exportKwh: eK, exportKvarh: eV, importKwh: iK, importKvarh: iV, isComplete: true); }
  HourlyMeterReading get dailyBackupTotal { double eK=0, eV=0, iK=0, iV=0; for (final h in backupMeterHours) { eK+=h.exportKwh; eV+=h.exportKvarh; iK+=h.importKwh; iV+=h.importKvarh; } return HourlyMeterReading(hour: -1, exportKwh: eK, exportKvarh: eV, importKwh: iK, importKvarh: iV, isComplete: true); }

  double manualMainExpKwh = 0, manualMainExpKvarh = 0, manualMainImpKwh = 0, manualMainImpKvarh = 0;
  double manualBackupExpKwh = 0, manualBackupExpKvarh = 0, manualBackupImpKwh = 0, manualBackupImpKvarh = 0;
  ManualMeterEntry? lastManualEntry;
}

class ProductionRecord {
  final DateTime timestamp; final double activePowerMW; final double powerFactor; final double apparentPowerMVA; final double reactivePowerMVar; final double energyMWh; final double energyMVarh; final MinuteMeterReading mainMeter; final MinuteMeterReading backupMeter;
  ProductionRecord._({required this.timestamp, required this.activePowerMW, required this.powerFactor, required this.apparentPowerMVA, required this.reactivePowerMVar, required this.energyMWh, required this.energyMVarh, required this.mainMeter, required this.backupMeter});

  factory ProductionRecord.calculate({required DateTime timestamp, required double activePowerMW, required double powerFactor, DateTime? previousTimestamp}) {
    if (activePowerMW < 0) throw Exception('ກຳລັງການຜະລິດຕ້ອງ ≥ 0 MW');
    if (activePowerMW > 6.0) throw Exception('ກຳລັງການຜະລິດເກີນພິກັດ! (ໂຮງງານຂະໜາດ 5.5 MW, ກະລຸນາປ້ອນຄ່າເປັນ MW ບໍ່ແມ່ນ kW)');
    if (powerFactor.abs() > 1.0 || powerFactor.abs() < 0.001) throw Exception('Power Factor ຕ້ອງຢູ່ລະຫວ່າງ -1.0 ຫາ 1.0 (ຫ້າມ 0)');

    final pf = powerFactor;
    final mva = activePowerMW / pf.abs();
    double mvar = math.sqrt(math.max(0.0, (mva * mva) - (activePowerMW * activePowerMW)));
    if (pf < 0) mvar = -mvar; 

    double elapsedHours = 1.0 / 60.0;
    if (previousTimestamp != null) {
      final elapsedMs = timestamp.difference(previousTimestamp).inMilliseconds;
      if (elapsedMs > 0) {
        elapsedHours = elapsedMs / (1000 * 60 * 60);
        if (elapsedHours > (5.0 / 60.0)) elapsedHours = 5.0 / 60.0;
      }
    }

    final mwhThisPeriod = activePowerMW * elapsedHours;
    final mvarhThisPeriod = mvar.abs() * elapsedHours; 

    double incExpKwh = 0, incImpKwh = 0, incExpKvarh = 0, incImpKvarh = 0;
    if (activePowerMW >= 0) { incExpKwh = mwhThisPeriod * 1000.0; } else { incImpKwh = -mwhThisPeriod * 1000.0; }
    if (mvar >= 0) { incExpKvarh = mvarhThisPeriod * 1000.0; } else { incImpKvarh = mvarhThisPeriod * 1000.0; }

    final random = math.Random(timestamp.millisecondsSinceEpoch);
    final errFactor = 1 + (random.nextDouble() * 0.003 - 0.0015);

    return ProductionRecord._(
      timestamp: timestamp, activePowerMW: activePowerMW, powerFactor: pf, apparentPowerMVA: mva, reactivePowerMVar: mvar, energyMWh: mwhThisPeriod, energyMVarh: mvarhThisPeriod,
      mainMeter: MinuteMeterReading(exportKwh: incExpKwh, exportKvarh: incExpKvarh, importKwh: incImpKwh, importKvarh: incImpKvarh),
      backupMeter: MinuteMeterReading(exportKwh: incExpKwh * errFactor, exportKvarh: incExpKvarh * errFactor, importKwh: incImpKwh * errFactor, importKvarh: incImpKvarh * errFactor),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SESSION (SINGLETON)
// ══════════════════════════════════════════════════════════════════════════════
class _ProductionSession {
  _ProductionSession._internal();
  static final _ProductionSession instance = _ProductionSession._internal();

  final mwController = TextEditingController();
  final pfController = TextEditingController(text: '0.95');

  final manualMainExpKwhCtrl = TextEditingController();
  final manualMainExpKvarhCtrl = TextEditingController();
  final manualMainImpKwhCtrl = TextEditingController();
  final manualMainImpKvarhCtrl = TextEditingController();
  final manualBackupExpKwhCtrl = TextEditingController();
  final manualBackupExpKvarhCtrl = TextEditingController();
  final manualBackupImpKwhCtrl = TextEditingController();
  final manualBackupImpKvarhCtrl = TextEditingController();

  ManualMeterEntry? lastManualEntry;
  final List<ManualMeterEntry> manualEntries = [];
  String manualMeterMsg = '';
  bool manualMeterMsgIsError = false;

  bool isRecording = false;
  String errorMsg = '';

  final List<ProductionRecord> records = [];
  DateTime? lastRecordTimestamp;

  DailyMeterData? currentDailyData;
  final Map<DateTime, DailyMeterData> historicalData = {};

  int currentHour = -1;
  double currentHourMainExpKwh = 0, currentHourMainExpKvarh = 0, currentHourMainImpKwh = 0, currentHourMainImpKvarh = 0;
  double currentHourBackupExpKwh = 0, currentHourBackupExpKvarh = 0, currentHourBackupImpKwh = 0, currentHourBackupImpKvarh = 0;
  int minuteCountInCurrentHour = 0;

  final int maxLivePoints = 60;
  final List<FlSpot> liveMwSpots = [];
  final List<FlSpot> liveMvarSpots = [];
  final List<FlSpot> livePfSpots = [];
  double liveTimeX = 0;

  final List<FlSpot> cumExpKwhSpots = [];
  final List<FlSpot> cumExpKvarhSpots = [];
  final List<FlSpot> cumImpKwhSpots = [];
  final List<FlSpot> cumImpKvarhSpots = [];
  double cumExpKwh = 0, cumExpKvarh = 0, cumImpKwh = 0, cumImpKvarh = 0;

  Timer? recordTimer;
  Timer? clockTimer;
  DateTime now = DateTime.now();
  VoidCallback? onTick;
  bool _initialized = false;

  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _initNewDay(DateTime.now());
    currentHour = now.hour;
    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final n = DateTime.now();
    if (isRecording) {
      liveTimeX += 1;

      final rand = math.Random();
      final noiseMw = (rand.nextDouble() - 0.5) * 0.04;
      double currentMw = _liveMW + noiseMw;
      if (currentMw < 0) currentMw = 0;
      if (currentMw > 6.0) currentMw = 6.0;

      final pf = _livePF;
      final mva = currentMw / (pf.abs() < 0.001 ? 1 : pf.abs());
      double currentMvar = math.sqrt(math.max(0.0, (mva * mva) - (currentMw * currentMw)));
      if (pf < 0) currentMvar = -currentMvar;
      currentMvar += (rand.nextDouble() - 0.5) * 0.02;

      liveMwSpots.add(FlSpot(liveTimeX, currentMw));
      liveMvarSpots.add(FlSpot(liveTimeX, currentMvar));
      livePfSpots.add(FlSpot(liveTimeX, pf));

      if (liveMwSpots.length > maxLivePoints) {
        liveMwSpots.removeAt(0);
        liveMvarSpots.removeAt(0);
        livePfSpots.removeAt(0);
      }

      const secInHour = 1.0 / 3600.0;
      final mwhThisSec = currentMw * secInHour;
      final mvarhThisSec = currentMvar.abs() * secInHour;
      if (currentMw >= 0) {
        cumExpKwh += mwhThisSec * 1000.0;
      } else {
        cumImpKwh += mwhThisSec.abs() * 1000.0;
      }
      if (currentMvar >= 0) {
        cumExpKvarh += mvarhThisSec * 1000.0;
      } else {
        cumImpKvarh += mvarhThisSec * 1000.0;
      }

      cumExpKwhSpots.add(FlSpot(liveTimeX, cumExpKwh));
      cumExpKvarhSpots.add(FlSpot(liveTimeX, cumExpKvarh));
      cumImpKwhSpots.add(FlSpot(liveTimeX, cumImpKwh));
      cumImpKvarhSpots.add(FlSpot(liveTimeX, cumImpKvarh));

      const maxCumPoints = 3600 * 6;
      if (cumExpKwhSpots.length > maxCumPoints) {
        cumExpKwhSpots.removeAt(0);
        cumExpKvarhSpots.removeAt(0);
        cumImpKwhSpots.removeAt(0);
        cumImpKvarhSpots.removeAt(0);
      }
    }
    now = n;
    onTick?.call();
  }

  double get _livePF {
    final pf = double.tryParse(pfController.text) ?? 0.95;
    if (pf.abs() > 1) return pf > 0 ? 1 : -1;
    if (pf.abs() < 0.001) return 0.001;
    return pf;
  }

  double get _liveMW {
    final mw = double.tryParse(mwController.text) ?? 0;
    if (mw < 0) return 0;
    if (mw > 6.0) return 6.0;
    return mw;
  }

  void initNewDay(DateTime date) => _initNewDay(date);

  void _initNewDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    currentDailyData = DailyMeterData.empty(startOfDay);
    historicalData[startOfDay] = currentDailyData!;
    resetCurrentHourAccumulators();
    minuteCountInCurrentHour = 0;
    currentHour = now.hour;
  }

  void resetCurrentHourAccumulators() {
    currentHourMainExpKwh = 0; currentHourMainExpKvarh = 0;
    currentHourMainImpKwh = 0; currentHourMainImpKvarh = 0;
    currentHourBackupExpKwh = 0; currentHourBackupExpKvarh = 0;
    currentHourBackupImpKwh = 0; currentHourBackupImpKvarh = 0;
  }

  void startNewHour(int hour, DateTime ts) {
    if (hour == 0 && currentHour == 23) _initNewDay(ts);
    currentHour = hour;
    resetCurrentHourAccumulators();
    minuteCountInCurrentHour = 0;
  }

  void finalizeCurrentHour() {
    if (currentDailyData == null) return;
    currentDailyData!.mainMeterHours[currentHour] = HourlyMeterReading(hour: currentHour, exportKwh: currentHourMainExpKwh, exportKvarh: currentHourMainExpKvarh, importKwh: currentHourMainImpKwh, importKvarh: currentHourMainImpKvarh, isComplete: minuteCountInCurrentHour >= 60);
    currentDailyData!.backupMeterHours[currentHour] = HourlyMeterReading(hour: currentHour, exportKwh: currentHourBackupExpKwh, exportKvarh: currentHourBackupExpKvarh, importKwh: currentHourBackupImpKwh, importKvarh: currentHourBackupImpKvarh, isComplete: minuteCountInCurrentHour >= 60);
  }

  void _addMinuteToHour(ProductionRecord rec) {
    if (!isRecording) return;
    final recordHour = rec.timestamp.hour;
    if (recordHour != currentHour) { finalizeCurrentHour(); startNewHour(recordHour, rec.timestamp); }
    currentHourMainExpKwh += rec.mainMeter.exportKwh; currentHourMainExpKvarh += rec.mainMeter.exportKvarh; currentHourMainImpKwh += rec.mainMeter.importKwh; currentHourMainImpKvarh += rec.mainMeter.importKvarh;
    currentHourBackupExpKwh += rec.backupMeter.exportKwh; currentHourBackupExpKvarh += rec.backupMeter.exportKvarh; currentHourBackupImpKwh += rec.backupMeter.importKwh; currentHourBackupImpKvarh += rec.backupMeter.importKvarh;
    minuteCountInCurrentHour++;
  }

  ProductionRecord? addRecord() {
    final mw = double.tryParse(mwController.text) ?? 0;
    final pf = double.tryParse(pfController.text) ?? 0.95;

    try {
      final ts = DateTime.now();
      final rec = ProductionRecord.calculate(timestamp: ts, activePowerMW: mw, powerFactor: pf, previousTimestamp: lastRecordTimestamp);
      lastRecordTimestamp = ts;
      _addMinuteToHour(rec);
      records.insert(0, rec);
      onTick?.call();
      return rec;
    } catch (e) {
      errorMsg = e.toString().replaceAll('Exception: ', '');
      stopRecording();
      onTick?.call();
      return null;
    }
  }

  void stopRecording() {
    recordTimer?.cancel();
    recordTimer = null;
    lastRecordTimestamp = null;
    finalizeCurrentHour();
    isRecording = false;
  }

  bool saveManualMeterReading() {
    final mEK = double.tryParse(manualMainExpKwhCtrl.text);
    final mEV = double.tryParse(manualMainExpKvarhCtrl.text);
    final mIK = double.tryParse(manualMainImpKwhCtrl.text);
    final mIV = double.tryParse(manualMainImpKvarhCtrl.text);
    final bEK = double.tryParse(manualBackupExpKwhCtrl.text);
    final bEV = double.tryParse(manualBackupExpKvarhCtrl.text);
    final bIK = double.tryParse(manualBackupImpKwhCtrl.text);
    final bIV = double.tryParse(manualBackupImpKvarhCtrl.text);

    if ([mEK, mEV, mIK, mIV, bEK, bEV, bIK, bIV].any((v) => v == null)) {
      manualMeterMsg = 'ກະລຸນາປ້ອນຄ່າມິເຕີໃຫ້ຄົບທັງ 8 ຊ່ອງ (Main + Backup)';
      manualMeterMsgIsError = true;
      return false;
    }
    if ([mEK!, mEV!, mIK!, mIV!, bEK!, bEV!, bIK!, bIV!].any((v) => v < 0)) {
      manualMeterMsg = 'ຄ່າມິເຕີຕ້ອງ ≥ 0';
      manualMeterMsgIsError = true;
      return false;
    }

    final entry = ManualMeterEntry(
      timestamp: DateTime.now(),
      mainExpKwh: mEK, mainExpKvarh: mEV, mainImpKwh: mIK, mainImpKvarh: mIV,
      backupExpKwh: bEK, backupExpKvarh: bEV, backupImpKwh: bIK, backupImpKvarh: bIV,
    );

    currentDailyData ??= DailyMeterData.empty(DateTime.now());
    final prev = lastManualEntry;
    if (prev == null) {
      manualMeterMsg = 'ບັນທຶກຄ່າຕັ້ງຕົ້ນແລ້ວ (ການອ່ານຄັ້ງຕໍ່ໄປຈະຄຳນວນຜົນຕ່າງໂດຍອັດຕະໂນມັດ)';
      manualMeterMsgIsError = false;
    } else {
      double d(double curr, double last) => curr >= last ? curr - last : 0;
      currentDailyData!.manualMainExpKwh += d(mEK, prev.mainExpKwh);
      currentDailyData!.manualMainExpKvarh += d(mEV, prev.mainExpKvarh);
      currentDailyData!.manualMainImpKwh += d(mIK, prev.mainImpKwh);
      currentDailyData!.manualMainImpKvarh += d(mIV, prev.mainImpKvarh);
      currentDailyData!.manualBackupExpKwh += d(bEK, prev.backupExpKwh);
      currentDailyData!.manualBackupExpKvarh += d(bEV, prev.backupExpKvarh);
      currentDailyData!.manualBackupImpKwh += d(bIK, prev.backupImpKwh);
      currentDailyData!.manualBackupImpKvarh += d(bIV, prev.backupImpKvarh);
      manualMeterMsg = 'ບັນທຶກຄ່າມິເຕີສຳເລັດ';
      manualMeterMsgIsError = false;
    }

    lastManualEntry = entry;
    currentDailyData!.lastManualEntry = entry;
    manualEntries.insert(0, entry);
    onTick?.call();
    return true;
  }

  void clearManualReadings() {
    lastManualEntry = null;
    manualEntries.clear();
    manualMeterMsg = '';
    manualMeterMsgIsError = false;
    manualMainExpKwhCtrl.clear(); manualMainExpKvarhCtrl.clear(); manualMainImpKwhCtrl.clear(); manualMainImpKvarhCtrl.clear();
    manualBackupExpKwhCtrl.clear(); manualBackupExpKvarhCtrl.clear(); manualBackupImpKwhCtrl.clear(); manualBackupImpKvarhCtrl.clear();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class ProductionDialog extends StatefulWidget {
  const ProductionDialog({super.key});
  @override
  State<ProductionDialog> createState() => _ProductionDialogState();
}

class _ProductionDialogState extends State<ProductionDialog> with SingleTickerProviderStateMixin {
  final _ProductionSession _s = _ProductionSession.instance;

  TextEditingController get _mwController => _s.mwController;
  TextEditingController get _pfController => _s.pfController;
  TextEditingController get _manualMainExpKwhCtrl => _s.manualMainExpKwhCtrl;
  TextEditingController get _manualMainExpKvarhCtrl => _s.manualMainExpKvarhCtrl;
  TextEditingController get _manualMainImpKwhCtrl => _s.manualMainImpKwhCtrl;
  TextEditingController get _manualMainImpKvarhCtrl => _s.manualMainImpKvarhCtrl;
  TextEditingController get _manualBackupExpKwhCtrl => _s.manualBackupExpKwhCtrl;
  TextEditingController get _manualBackupExpKvarhCtrl => _s.manualBackupExpKvarhCtrl;
  TextEditingController get _manualBackupImpKwhCtrl => _s.manualBackupImpKwhCtrl;
  TextEditingController get _manualBackupImpKvarhCtrl => _s.manualBackupImpKvarhCtrl;
  String get _manualMeterMsg => _s.manualMeterMsg;
  bool get _manualMeterMsgIsError => _s.manualMeterMsgIsError;
  bool get _isRecording => _s.isRecording;
  String get _errorMsg => _s.errorMsg;
  List<ProductionRecord> get _records => _s.records;
  DailyMeterData? get _currentDailyData => _s.currentDailyData;
  Map<DateTime, DailyMeterData> get _historicalData => _s.historicalData;
  int get _currentHour => _s.currentHour;
  List<FlSpot> get _liveMwSpots => _s.liveMwSpots;
  List<FlSpot> get _liveMvarSpots => _s.liveMvarSpots;
  List<FlSpot> get _livePfSpots => _s.livePfSpots;
  double get _liveTimeX => _s.liveTimeX;
  List<FlSpot> get _cumExpKwhSpots => _s.cumExpKwhSpots;
  List<FlSpot> get _cumExpKvarhSpots => _s.cumExpKvarhSpots;
  List<FlSpot> get _cumImpKwhSpots => _s.cumImpKwhSpots;
  List<FlSpot> get _cumImpKvarhSpots => _s.cumImpKvarhSpots;
  double get _cumExpKwh => _s.cumExpKwh;
  double get _cumExpKvarh => _s.cumExpKvarh;
  double get _cumImpKwh => _s.cumImpKwh;
  double get _cumImpKvarh => _s.cumImpKvarh;
  DateTime get _now => _s.now;
  int get _maxLivePoints => _s.maxLivePoints;

  bool _exporting = false;

  DateTime _selectedViewDate = DateTime.now();
  DailyMeterData? get _viewingData {
    final date = DateTime(_selectedViewDate.year, _selectedViewDate.month, _selectedViewDate.day);
    if (date == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)) return _currentDailyData;
    return _historicalData[date];
  }

  late TabController _tabController;
  final _scrollGenCtrl = ScrollController();
  final _scrollHourlyCtrl = ScrollController();
  DateTime? _lastAutoScrollDate;
  int? _lastAutoScrollHour;

  DateTime _selectedMinuteViewDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _s.ensureInitialized();
    _s.onTick = () { if (mounted) setState(() {}); };
    _mwController.addListener(_onCtrlChange);
    _pfController.addListener(_onCtrlChange);
  }

  void _onCtrlChange() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _mwController.removeListener(_onCtrlChange);
    _pfController.removeListener(_onCtrlChange);
    if (_s.onTick != null) _s.onTick = null;
    _scrollGenCtrl.dispose();
    _scrollHourlyCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleRecording() => _isRecording ? _stopRecording() : _startRecording();

  void _startRecording() {
    final mw = double.tryParse(_mwController.text);
    final pf = double.tryParse(_pfController.text);
    
    if (mw == null || mw < 0) { setState(() => _s.errorMsg = 'ກະລຸນາປ້ອນກຳລັງການຜະລິດ (MW) ທີ່ຖືກຕ້ອງ (≥ 0)'); return; }
    if (mw > 6.0) { setState(() => _s.errorMsg = 'ກຳລັງການຜະລິດເກີນພິກັດ (Over 6.0 MW)! ກະລຸນາປ້ອນຫົວໜ່ວຍເປັນ MW'); return; }
    if (pf == null || pf.abs() > 1 || pf.abs() < 0.01) { setState(() => _s.errorMsg = 'Power Factor ຕ້ອງຢູ່ລະຫວ່າງ -1.00 ຫາ 1.00 (ຫ້າມ 0)'); return; }
    
    setState(() {
      _s.errorMsg = '';
      _s.isRecording = true;
      _s.liveTimeX = 0;
      _liveMwSpots.clear(); _liveMvarSpots.clear(); _livePfSpots.clear();
      _s.cumExpKwh = 0; _s.cumExpKvarh = 0; _s.cumImpKwh = 0; _s.cumImpKvarh = 0;
      _cumExpKwhSpots.clear(); _cumExpKvarhSpots.clear(); _cumImpKwhSpots.clear(); _cumImpKvarhSpots.clear();
    });
    
    _addRecord();
    _s.recordTimer = Timer.periodic(const Duration(minutes: 1), (_) => _addRecord());
  }

  void _stopRecording() {
    _s.stopRecording();
    if (mounted) setState(() {});
  }

  void _addRecord() {
    final rec = _s.addRecord();
    if (rec == null) return; 

    if (!mounted) return;
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollGenCtrl.hasClients) _scrollGenCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      if (_scrollHourlyCtrl.hasClients) _scrollHourlyCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _saveManualReading() {
    setState(() => _s.saveManualMeterReading());
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Op.panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _Op.stroke)),
        title: const Text('ລຶບຂໍ້ມູນທັງໝົດ?', style: TextStyle(color: _Op.textHi, fontSize: 15)),
        content: const Text('ຂໍ້ມູນທີ່ຖືກລຶບຈະບໍ່ສາມາດກູ້ຄືນໄດ້', style: TextStyle(color: _Op.textLo, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ', style: TextStyle(color: _Op.textFaint))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _Op.danger),
            onPressed: () {
              _stopRecording(); 
              setState(() {
                _records.clear();
                _s.lastRecordTimestamp = null;
                _liveMwSpots.clear(); _liveMvarSpots.clear(); _livePfSpots.clear(); _s.liveTimeX = 0;
                _s.cumExpKwh = 0; _s.cumExpKvarh = 0; _s.cumImpKwh = 0; _s.cumImpKvarh = 0;
                _cumExpKwhSpots.clear(); _cumExpKvarhSpots.clear(); _cumImpKwhSpots.clear(); _cumImpKvarhSpots.clear();
                _s.initNewDay(DateTime.now());
                _s.currentHour = _now.hour;
                _s.resetCurrentHourAccumulators();
                _s.minuteCountInCurrentHour = 0;
                _s.clearManualReadings();
              });
              Navigator.pop(ctx);
            },
            child: const Text('ລຶບ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  double get _liveMW => double.tryParse(_mwController.text) ?? 0;
  double get _livePF => double.tryParse(_pfController.text) ?? 0.95;
  double get _liveMVA { final absPf = _livePF.abs(); return absPf < 0.001 ? 0 : _liveMW / absPf; }
  double get _liveMVar { final pf = _livePF; if (pf.abs() < 0.001) return 0; double mvar = math.sqrt(math.max(0.0, (_liveMVA * _liveMVA) - (_liveMW * _liveMW))); return pf >= 0 ? mvar : -mvar; }
  double get _liveAmps => _liveMVA == 0 ? 0 : (_liveMVA * 1000) / (math.sqrt(3) * 22.0);
  double get _liveMWh => _liveMW / 60.0;
  double get _liveMVarh => _liveMVar.abs() / 60.0;
  double get _liveExpKwh => _liveMW >= 0 ? _liveMWh * 1000.0 : 0;
  double get _liveImpKwh => _liveMW < 0 ? _liveMWh.abs() * 1000.0 : 0;
  double get _liveExpKvarh => _liveMVar >= 0 ? _liveMVarh * 1000.0 : 0;
  double get _liveImpKvarh => _liveMVar < 0 ? _liveMVarh * 1000.0 : 0;

  Future<void> _exportExcel() async {
    if (_records.isEmpty && (_currentDailyData == null || _currentDailyData!.dailyMainTotal.exportKwh == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ບໍ່ມີຂໍ້ມູນໃຫ້ Export'), backgroundColor: _Op.warn));
      return;
    }
    setState(() => _exporting = true);

    try {
      final excel = Excel.createExcel();
      final defaultSheetName = excel.getDefaultSheet(); 
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy').format(now);

      final meterSheet = excel['Meter Report (ຊົ່ວໂມງ)'];
      if (_currentDailyData != null) _fillCombinedMeterSheet(meterSheet, _currentDailyData!.mainMeterHours, _currentDailyData!.backupMeterHours, dateStr);

      final genSheet = excel['ການຜະລິດ (ນາທີ)'];
      _fillMinuteSheet(genSheet, dateStr);

      if (defaultSheetName != null && defaultSheetName != 'Meter Report (ຊົ່ວໂມງ)' && defaultSheetName != 'ການຜະລິດ (ນາທີ)') {
        excel.delete(defaultSheetName);
      }
      
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel encode failed');

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/production_${DateFormat('yyyyMMdd_HHmm').format(now)}.xlsx');
      await file.writeAsBytes(bytes);

      if (mounted) await Share.shareXFiles([XFile(file.path)], subject: 'ລາຍງານການຜະລິດໄຟຟ້າ - $dateStr', text: 'ລາຍງານການຜະລິດ (ຊົ່ວໂມງ)');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export ບໍ່ສຳເລັດ: $e'), backgroundColor: _Op.danger));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _fillCombinedMeterSheet(Sheet sheet, List<HourlyMeterReading> mainHours, List<HourlyMeterReading> backupHours, String dateStr) {
    void txt(String col, int row, String val) => sheet.cell(CellIndex.indexByString('$col$row')).value = TextCellValue(val);
    void num(int col, int row, double val) => sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row - 1)).value = DoubleCellValue(double.parse(val.toStringAsFixed(3)));

    txt('A', 1, 'ລາຍງານ Meter ການຜະລິດໄຟຟ້າ - $dateStr');
    txt('A', 2, ''); txt('B', 2, '━━━ MAIN METER ━━━'); txt('F', 2, '━━━ BACKUP METER ━━━');
    txt('A', 3, 'ຊົ່ວໂມງ'); txt('B', 3, 'EXPORT kWh'); txt('C', 3, 'EXPORT kVarh'); txt('D', 3, 'IMPORT kWh'); txt('E', 3, 'IMPORT kVarh');
    txt('F', 3, 'EXPORT kWh'); txt('G', 3, 'EXPORT kVarh'); txt('H', 3, 'IMPORT kWh'); txt('I', 3, 'IMPORT kVarh'); txt('J', 3, 'ສະຖານະ');

    double cmEK=0, cmEV=0, cmIK=0, cmIV=0, cbEK=0, cbEV=0, cbIK=0, cbIV=0;
    for (int i = 0; i < 24; i++) {
      final mh = mainHours[i]; final bh = backupHours[i]; final r = i + 4;
      cmEK += mh.exportKwh; cmEV += mh.exportKvarh; cmIK += mh.importKwh; cmIV += mh.importKvarh;
      cbEK += bh.exportKwh; cbEV += bh.exportKvarh; cbIK += bh.importKwh; cbIV += bh.importKvarh;
      final hasData = mh.exportKwh > 0 || mh.importKwh > 0 || mh.importKvarh > 0 || bh.exportKwh > 0;
      final status = mh.isComplete ? 'ຄົບ' : (hasData ? 'ກຳລັງ...' : '-');
      txt('A', r, '${i.toString().padLeft(2, '0')}:00 - ${i.toString().padLeft(2, '0')}:59');
      num(1, r, cmEK); num(2, r, cmEV); num(3, r, cmIK); num(4, r, cmIV);
      num(5, r, cbEK); num(6, r, cbEV); num(7, r, cbIK); num(8, r, cbIV); txt('J', r, status);
    }
    const t = 28; txt('A', t, 'ລວມທັງໝົດ');
    num(1, t, cmEK); num(2, t, cmEV); num(3, t, cmIK); num(4, t, cmIV); num(5, t, cbEK); num(6, t, cbEV); num(7, t, cbIK); num(8, t, cbIV);
  }

  void _fillMinuteSheet(Sheet sheet, String dateStr) {
    void txt(String col, int row, String val) => sheet.cell(CellIndex.indexByString('$col$row')).value = TextCellValue(val);
    txt('A', 1, 'ລາຍງານຄ່ານາທີ - $dateStr'); txt('A', 3, 'ເວລາ'); txt('B', 3, 'MW'); txt('C', 3, 'MVA'); txt('D', 3, 'MVar'); txt('E', 3, 'Power Factor'); txt('F', 3, 'MWh (ນາທີ)'); txt('G', 3, 'MVarh (ນາທີ)');
    final sorted = [..._records]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i]; final row = i + 4;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row - 1)).value = TextCellValue(DateFormat('HH:mm:ss').format(r.timestamp));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1)).value = DoubleCellValue(double.parse(r.activePowerMW.toStringAsFixed(4)));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row - 1)).value = DoubleCellValue(double.parse(r.apparentPowerMVA.toStringAsFixed(4)));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row - 1)).value = DoubleCellValue(double.parse(r.reactivePowerMVar.toStringAsFixed(4)));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row - 1)).value = DoubleCellValue(double.parse(r.powerFactor.toStringAsFixed(4)));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row - 1)).value = DoubleCellValue(double.parse(r.energyMWh.toStringAsFixed(6)));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row - 1)).value = DoubleCellValue(double.parse(r.energyMVarh.toStringAsFixed(6)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ────────── ປັບປຸງໂຄງສ້າງຫຼັກເພື່ອແກ້ໄຂ UI ທີ່ຖືກຕັດ ──────────
    // ໃຊ້ Scaffold + SafeArea ເພື່ອຮັບປະກັນວ່າເນື້ອຫາຈະບໍ່ຖືກບັງດ້ວຍ System Navigation ດ້ານລຸ່ມ
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: _Op.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildInputTab(),
                    _buildRealtimeGraphTab(),
                    _buildTableTab(),
                    _buildCombinedMeterTab()
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final ts = '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: const BoxDecoration(color: _Op.panel, borderRadius: BorderRadius.vertical(top: Radius.circular(18)), border: Border(bottom: BorderSide(color: _Op.stroke))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _Op.live.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: _Op.live.withValues(alpha: 0.35))), child: const Icon(Icons.electric_bolt, color: _Op.live, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ການຜະລິດໄຟຟ້າ (5.5 MW, 22 kV)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _Op.textHi)),
          Text('POWER PRODUCTION LOG · $ts', style: const TextStyle(fontSize: 9, color: _Op.textFaint, letterSpacing: 0.8)),
        ])),
        if (_isRecording) _recBadge(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: _Op.textFaint, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
      ]),
    );
  }

  Widget _recBadge() => Container(
    margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: _Op.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: _Op.danger.withValues(alpha: 0.5))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: _Op.danger)), const SizedBox(width: 4),
      const Text('REC', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _Op.danger, letterSpacing: 1)),
    ]),
  );

  Widget _buildTabBar() => Container(
    color: _Op.panel,
    child: TabBar(
      controller: _tabController, indicatorColor: _Op.live, indicatorWeight: 2, labelColor: _Op.live, unselectedLabelColor: _Op.textFaint, isScrollable: true, labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      tabs: const [
        Tab(icon: Icon(Icons.input, size: 14), text: 'ປ້ອນຂໍ້ມູນ'), 
        Tab(icon: Icon(Icons.show_chart, size: 14), text: 'ກຣາຟ Real-time'),
        Tab(icon: Icon(Icons.table_rows, size: 14), text: 'ຕາຕະລາງ (ນາທີ)'),
        Tab(icon: Icon(Icons.electric_meter, size: 14), text: 'Meter ລວມ')
      ],
    ),
  );

  Widget _buildInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('ກຳລັງການຜະລິດ', 'ACTIVE POWER (MW)', _Op.live), const SizedBox(height: 8),
        _inputField(ctrl: _mwController, label: 'ກຳລັງຈິງ (MW)', hint: 'ສູງສຸດ 5.50 MW', icon: Icons.electric_bolt, color: _Op.live, unit: 'MW'),
        const SizedBox(height: 14),
        _sectionLabel('Power Factor', 'cos φ  (-1.00 – 1.00)', _Op.violet), const SizedBox(height: 8),
        _inputField(ctrl: _pfController, label: 'Power Factor', hint: 'ເຊັ່ນ: 0.95 ຫຼື -0.85', icon: Icons.show_chart, color: _Op.violet, unit: 'cos φ'),
        const SizedBox(height: 14),
        _liveCalcCard(),
        const SizedBox(height: 14),
        _manualMeterCard(),
        if (_errorMsg.isNotEmpty) ...[const SizedBox(height: 10), _errorBox()],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton.icon(
            onPressed: _toggleRecording,
            style: ElevatedButton.styleFrom(backgroundColor: _isRecording ? _Op.danger : _Op.live, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            icon: Icon(_isRecording ? Icons.stop_circle : Icons.play_circle, color: Colors.black, size: 20),
            label: Text(_isRecording ? 'ຢຸດການບັນທຶກ · STOP' : 'ເລີ່ມບັນທຶກ · START RECORDING', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _liveCalcCard() {
    final pf = _livePF; final pfSign = pf >= 0 ? 'Lagging (ຈ່າຍ MVar)' : 'Leading (ດູດ MVar)';
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _Op.panelAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _Op.stroke)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.calculate_outlined, color: _Op.info, size: 13), SizedBox(width: 6), Text('ຜົນຄຳນວນ (Live)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Op.textLo))]), const SizedBox(height: 10),
        _subLabel('⚡ Generation (22 kV Grid)'),
        _calcRow('ກຳລັງຈິງ (P)', '${_liveMW.toStringAsFixed(3)} MW', _Op.live), _calcRow('Power Factor', '${pf.toStringAsFixed(4)} ($pfSign)', _pfColor(pf)),
        _calcRow('ກຳລັງປາກົດ (S)', '${_liveMVA.toStringAsFixed(3)} MVA', _Op.info), _calcRow('ກຳລັງຮຽກຮ້ອງ (Q)', '${_liveMVar.toStringAsFixed(3)} MVar', _pfColor(pf)),
        _calcRow('ກະແສໄຟຟ້າ (Current)', '${_liveAmps.toStringAsFixed(2)} A', _Op.lime), 
        const Divider(color: _Op.stroke, height: 16), _subLabel('🔵 Meter (per minute increment)'),
        _calcRow('Export kWh', '${_liveExpKwh.toStringAsFixed(2)} kWh', _Op.green), _calcRow('Export kVarh', '${_liveExpKvarh.toStringAsFixed(2)} kVarh', _Op.green),
        _calcRow('Import kWh', '${_liveImpKwh.toStringAsFixed(2)} kWh', _Op.orange), _calcRow('Import kVarh', '${_liveImpKvarh.toStringAsFixed(2)} kVarh', _Op.orange),
      ]),
    );
  }

  Color _pfColor(double pf) => pf >= 0 ? _Op.live : _Op.orange;

  Widget _manualMeterCard() {
    final last = _s.lastManualEntry;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _Op.panelAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _Op.stroke)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.speed, color: _Op.lime, size: 13), SizedBox(width: 6), Expanded(child: Text('ປ້ອນຄ່າມິເຕີ (ເລກສະສົມ/odometer ຈາກໜ້າປັດ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Op.textLo)))]),
        const SizedBox(height: 2),
        const Text('ປ້ອນເລກລ່າສຸດທີ່ອ່ານໄດ້ຈາກໜ້າປັດມິເຕີຈິງ - ລະບົບຈະຄຳນວນຜົນຕ່າງກັບຄັ້ງກ່ອນເອງ', style: TextStyle(fontSize: 9.5, color: _Op.textFaint, height: 1.4)),
        const SizedBox(height: 10),

        _subLabel('🟢 MAIN METER'),
        Row(children: [
          Expanded(child: _inputField(ctrl: _manualMainExpKwhCtrl, label: 'Export', hint: '0.00', icon: Icons.arrow_upward, color: _Op.green, unit: 'kWh')),
          const SizedBox(width: 8),
          Expanded(child: _inputField(ctrl: _manualMainExpKvarhCtrl, label: 'Export', hint: '0.00', icon: Icons.arrow_upward, color: _Op.green, unit: 'kVarh')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _inputField(ctrl: _manualMainImpKwhCtrl, label: 'Import', hint: '0.00', icon: Icons.arrow_downward, color: _Op.orange, unit: 'kWh')),
          const SizedBox(width: 8),
          Expanded(child: _inputField(ctrl: _manualMainImpKvarhCtrl, label: 'Import', hint: '0.00', icon: Icons.arrow_downward, color: _Op.orange, unit: 'kVarh')),
        ]),

        const SizedBox(height: 14),
        _subLabel('🔵 BACKUP METER'),
        Row(children: [
          Expanded(child: _inputField(ctrl: _manualBackupExpKwhCtrl, label: 'Export', hint: '0.00', icon: Icons.arrow_upward, color: _Op.green, unit: 'kWh')),
          const SizedBox(width: 8),
          Expanded(child: _inputField(ctrl: _manualBackupExpKvarhCtrl, label: 'Export', hint: '0.00', icon: Icons.arrow_upward, color: _Op.green, unit: 'kVarh')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _inputField(ctrl: _manualBackupImpKwhCtrl, label: 'Import', hint: '0.00', icon: Icons.arrow_downward, color: _Op.orange, unit: 'kWh')),
          const SizedBox(width: 8),
          Expanded(child: _inputField(ctrl: _manualBackupImpKvarhCtrl, label: 'Import', hint: '0.00', icon: Icons.arrow_downward, color: _Op.orange, unit: 'kVarh')),
        ]),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 42,
          child: ElevatedButton.icon(
            onPressed: _saveManualReading,
            style: ElevatedButton.styleFrom(backgroundColor: _Op.lime, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            icon: const Icon(Icons.save_outlined, color: Colors.black, size: 18),
            label: const Text('ບັນທຶກຄ່າມິເຕີ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),

        if (_manualMeterMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(_manualMeterMsgIsError ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: _manualMeterMsgIsError ? _Op.danger : _Op.lime, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(_manualMeterMsg, style: TextStyle(fontSize: 11, color: _manualMeterMsgIsError ? _Op.danger : _Op.lime))),
          ]),
        ],
        if (last != null) ...[
          const SizedBox(height: 6),
          Text('ອ່ານຄັ້ງລ່າສຸດ: ${DateFormat('HH:mm:ss', 'lo').format(last.timestamp)}', style: const TextStyle(fontSize: 9.5, color: _Op.textFaint)),
        ],
      ]),
    );
  }

  Widget _buildRealtimeGraphTab() {
    const double mwMin = 0;
    const double mwMax = 6.0;
    const double mvarMin = -4.0;
    const double mvarMax = 4.0;
    const double pfMin = -1.2;
    const double pfMax = 1.2;

    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _Op.panelAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _Op.stroke)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SCADA REAL-TIME TREND (60s)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _Op.textHi, letterSpacing: 1)),
              Row(children: [_legendDot(_Op.live, 'MW'), const SizedBox(width: 12), _legendDot(_Op.warn, 'MVar'), const SizedBox(width: 12), _legendDot(_Op.violet, 'PF')]),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _Op.panel, borderRadius: BorderRadius.circular(8), border: Border.all(color: _Op.strokeSoft)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryChip('EXPORT kWh (ສະສົມ)', _cumExpKwh.toStringAsFixed(3), _Op.green),
                _summaryChip('EXPORT kVarh (ສະສົມ)', _cumExpKvarh.toStringAsFixed(3), _Op.green),
                _summaryChip('IMPORT kWh (ສະສົມ)', _cumImpKwh.toStringAsFixed(3), _Op.orange),
                _summaryChip('IMPORT kVarh (ສະສົມ)', _cumImpKvarh.toStringAsFixed(3), _Op.orange),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 5,
            child: _buildLiveGraphCard(title: 'Active Power (MW)', spots: _liveMwSpots, color: _Op.live, minY: mwMin, maxY: mwMax),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(child: _buildLiveGraphCard(title: 'Reactive Power (MVar)', spots: _liveMvarSpots, color: _Op.warn, minY: mvarMin, maxY: mvarMax)),
                const SizedBox(width: 12),
                Expanded(child: _buildLiveGraphCard(title: 'Power Factor (cos φ)', spots: _livePfSpots, color: _Op.violet, minY: pfMin, maxY: pfMax)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(child: _buildHourlyBarCard(title: 'Export kWh (ຕໍ່ຊົ່ວໂມງ)', color: _Op.green, getValue: (h) => h.exportKwh)),
                const SizedBox(width: 12),
                Expanded(child: _buildHourlyBarCard(title: 'Export kVarh (ຕໍ່ຊົ່ວໂມງ)', color: _Op.green, getValue: (h) => h.exportKvarh)),
                const SizedBox(width: 12),
                Expanded(child: _buildHourlyBarCard(title: 'Import kWh (ຕໍ່ຊົ່ວໂມງ)', color: _Op.orange, getValue: (h) => h.importKwh)),
                const SizedBox(width: 12),
                Expanded(child: _buildHourlyBarCard(title: 'Import kVarh (ຕໍ່ຊົ່ວໂມງ)', color: _Op.orange, getValue: (h) => h.importKvarh)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyBarCard({required String title, required Color color, required double Function(HourlyMeterReading) getValue}) {
    final data = _currentDailyData;
    final List<double> values = List.generate(24, (i) {
      if (data == null) return 0.0;
      return getValue(data.mainMeterHours[i]);
    });

    final numFmt = NumberFormat('#,##0.00');

    double maxY = values.fold<double>(0.0, (p, v) => v > p ? v : p);
    maxY = maxY <= 0 ? 1.0 : (maxY * 1.15);
    final lastNonZeroIdx = () {
      for (int i = 23; i >= 0; i--) { if (values[i] > 0) return i; }
      return -1;
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _Op.textLo)),
            if (lastNonZeroIdx >= 0)
              Text(numFmt.format(values[lastNonZeroIdx]), style: TextStyle(fontFamily: _Op.display, fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: lastNonZeroIdx < 0
              ? const Center(child: Text('ກຳລັງລໍຖ້າການບັນທຶກ...', style: TextStyle(color: _Op.textFaint, fontSize: 11)))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4 <= 0 ? 1.0 : maxY / 4,
                      getDrawingHorizontalLine: (value) => FlLine(color: _Op.stroke.withValues(alpha: 0.3), strokeWidth: 0.5),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 18,
                          interval: 4,
                          getTitlesWidget: (value, meta) {
                            final h = value.toInt();
                            if (h < 0 || h > 23) return const SizedBox();
                            return Text(h.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 9, color: _Op.textFaint));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 56,
                          getTitlesWidget: (value, meta) => Text(numFmt.format(value), style: const TextStyle(fontSize: 9, color: _Op.textFaint)),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: _Op.stroke.withValues(alpha: 0.5))),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => _Op.panel,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                          numFmt.format(rod.toY),
                          TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ),
                    barGroups: List.generate(24, (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: i == _currentHour && _isRecording ? _Op.live : color,
                          width: 5,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    )),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLiveGraphCard({required String title, required List<FlSpot> spots, required Color color, required double minY, required double maxY}) {
    double minX = math.max(0.0, _liveTimeX - _maxLivePoints);
    double maxX = math.max((_maxLivePoints).toDouble(), _liveTimeX);
    double yInterval = (maxY - minY) <= 0 ? 1.0 : (maxY - minY) / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _Op.textLo)),
        const SizedBox(height: 6),
        Expanded(
          child: spots.isEmpty
              ? const Center(child: Text('ກຳລັງລໍຖ້າການບັນທຶກ...', style: TextStyle(color: _Op.textFaint, fontSize: 11)))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: yInterval,
                      verticalInterval: 10,
                      getDrawingHorizontalLine: (value) => FlLine(color: _Op.stroke.withValues(alpha: 0.3), strokeWidth: 0.5),
                      getDrawingVerticalLine: (value) => FlLine(color: _Op.stroke.withValues(alpha: 0.1), strokeWidth: 0.5),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 36,
                          getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: _Op.textFaint)),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: _Op.stroke.withValues(alpha: 0.5))),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.15,
                        color: color,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.15)),
                      ),
                    ],
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => _Op.panel,
                        getTooltipItems: (touchedSpots) => touchedSpots.map((s) => LineTooltipItem(
                          s.y.toStringAsFixed(2),
                          TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                        )).toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<ProductionRecord> _getRecordsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _records.where((record) {
      return record.timestamp.isAfter(startOfDay) && 
             record.timestamp.isBefore(endOfDay);
    }).toList();
  }

  Widget _buildTableTab() {
    final filteredRecords = _getRecordsForDate(_selectedMinuteViewDate);
    
    if (filteredRecords.isEmpty) {
      return Column(
        children: [
          _buildMinuteDateSelector(),
          Expanded(
            child: _emptyState('ບໍ່ມີຂໍ້ມູນ\nສຳລັບວັນທີ ${DateFormat('dd/MM/yyyy').format(_selectedMinuteViewDate)}'),
          ),
        ],
      );
    }

    const colWeights = [70.0, 58.0, 58.0, 58.0, 58.0, 72.0, 78.0, 70.0, 70.0, 70.0, 70.0];
    const colLabels = ['ເວລາ', 'MW', 'PF', 'MVA', 'MVar', 'MWh/min', 'MVarh/min', 'EXP kWh', 'EXP kVarh', 'IMP kWh', 'IMP kVarh'];
    const colColors = [_Op.live, _Op.live, _Op.live, _Op.live, _Op.live, _Op.lime, _Op.violet, _Op.green, _Op.green, _Op.orange, _Op.orange];
    final totalWeight = colWeights.reduce((a, b) => a + b);

    return LayoutBuilder(builder: (ctx, constraints) {
      final availableW = constraints.maxWidth;
      final scale = math.max(1.0, availableW / totalWeight);
      final colWidths = colWeights.map((w) => w * scale).toList();

      return Column(
        children: [
          _buildMinuteDateSelector(),
          _hScroll([
            for (int c = 0; c < colLabels.length; c++) 
              _hCell(colLabels[c], colWidths[c], colColors[c]),
          ]),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollGenCtrl,
              child: Column(
                children: filteredRecords.asMap().entries.map((e) {
                  final r = e.value;
                  final i = e.key;
                  final values = [
                    DateFormat('HH:mm:ss').format(r.timestamp), 
                    r.activePowerMW.toStringAsFixed(3),
                    r.powerFactor.toStringAsFixed(4), 
                    r.apparentPowerMVA.toStringAsFixed(3),
                    r.reactivePowerMVar.toStringAsFixed(3), 
                    r.energyMWh.toStringAsFixed(6),
                    r.energyMVarh.toStringAsFixed(6),
                    r.mainMeter.exportKwh.toStringAsFixed(4), 
                    r.mainMeter.exportKvarh.toStringAsFixed(4),
                    r.mainMeter.importKwh.toStringAsFixed(4), 
                    r.mainMeter.importKvarh.toStringAsFixed(4),
                  ];
                  final colors = [_Op.textHi, _Op.live, _pfColor(r.powerFactor), _Op.info, _Op.warn, _Op.lime, _Op.violet, _Op.green, _Op.green, _Op.orange, _Op.orange];
                  return _hScroll([
                    for (int c = 0; c < values.length; c++) 
                      _dCell(values[c], colWidths[c], colors[c], i),
                  ]);
                }).toList(),
              ),
            ),
          ),
          _buildMinuteSummaryBar(filteredRecords),
        ],
      );
    });
  }

  Widget _buildMinuteDateSelector() {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
      color: _Op.panelAlt,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => setState(() {
              _selectedMinuteViewDate = _selectedMinuteViewDate.subtract(const Duration(days: 1));
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollGenCtrl.hasClients) _scrollGenCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
              });
            }),
            icon: const Icon(Icons.chevron_left, color: _Op.textHi, size: 20),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedMinuteViewDate,
                firstDate: DateTime(2024, 1, 1),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(primary: _Op.live, surface: _Op.panel)
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                if (!picked.isAfter(today)) {
                  setState(() {
                    _selectedMinuteViewDate = picked;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollGenCtrl.hasClients) _scrollGenCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                  });
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _Op.panel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _Op.stroke),
              ),
              child: Text(
                DateFormat('EEEE dd/MM/yyyy', 'lo').format(_selectedMinuteViewDate),
                style: const TextStyle(color: _Op.textHi, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _selectedMinuteViewDate.isBefore(today) 
              ? () => setState(() {
                  _selectedMinuteViewDate = _selectedMinuteViewDate.add(const Duration(days: 1));
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollGenCtrl.hasClients) _scrollGenCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                  });
                })
              : null,
            icon: Icon(
              Icons.chevron_right, 
              color: _selectedMinuteViewDate.isBefore(today) 
                ? _Op.textHi 
                : _Op.textFaint,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinuteSummaryBar(List<ProductionRecord> records) {
    if (records.isEmpty) return const SizedBox();
    double totalEnergyMWh = 0, totalEnergyMVarh = 0, totalMW = 0;
    double minMW = records.first.activePowerMW, maxMW = records.first.activePowerMW;
    double minMVA = records.first.apparentPowerMVA, maxMVA = records.first.apparentPowerMVA;
    double minMVar = records.first.reactivePowerMVar, maxMVar = records.first.reactivePowerMVar;
    double minPF = records.first.powerFactor, maxPF = records.first.powerFactor;
    for (final r in records) {
      totalEnergyMWh += r.energyMWh;
      totalEnergyMVarh += r.energyMVarh;
      totalMW += r.activePowerMW;
      if (r.activePowerMW < minMW) minMW = r.activePowerMW;
      if (r.activePowerMW > maxMW) maxMW = r.activePowerMW;
      if (r.apparentPowerMVA < minMVA) minMVA = r.apparentPowerMVA;
      if (r.apparentPowerMVA > maxMVA) maxMVA = r.apparentPowerMVA;
      if (r.reactivePowerMVar < minMVar) minMVar = r.reactivePowerMVar;
      if (r.reactivePowerMVar > maxMVar) maxMVar = r.reactivePowerMVar;
      if (r.powerFactor < minPF) minPF = r.powerFactor;
      if (r.powerFactor > maxPF) maxPF = r.powerFactor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
      decoration: const BoxDecoration(color: _Op.panel, border: Border(top: BorderSide(color: _Op.stroke))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _summaryChip('ສະເລ່ຍ MW', (totalMW / records.length).toStringAsFixed(3), _Op.live),
          _summaryChip('ພະລັງງານສະສົມ (MWh)', totalEnergyMWh.toStringAsFixed(3), _Op.lime),
          _summaryChip('Reactive Energy (MVarh)', totalEnergyMVarh.toStringAsFixed(3), _Op.violet),
          _summaryChip('ຈຳນວນນາທີ', '${records.length}', _Op.info),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _summaryRangeChip('MW (ນ້ອຍສຸດ-ໃຫຍ່ສຸດ)', minMW, maxMW, 3, _Op.live),
          _summaryRangeChip('MVA (ນ້ອຍສຸດ-ໃຫຍ່ສຸດ)', minMVA, maxMVA, 3, _Op.info),
          _summaryRangeChip('MVar (ນ້ອຍສຸດ-ໃຫຍ່ສຸດ)', minMVar, maxMVar, 3, _Op.warn),
          _summaryRangeChip('PF (ນ້ອຍສຸດ-ໃຫຍ່ສຸດ)', minPF, maxPF, 4, _Op.violet),
        ]),
      ]),
    );
  }

  Widget _legendDot(Color color, String label) => Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 9, color: _Op.textLo))]);

  Widget _buildCombinedMeterTab() {
    final data = _viewingData;

    // ──────────────────────────────────────────────────────
    // ຄວາມກວ້າງ column ພື້ນຖານ (px) → ຖ້າຈໍກວ້າງພໍ ຈະຂະຫຍາຍໃຫ້ເຕັມຈໍ
    // ໂດຍບໍ່ຕ້ອງ scroll ລວງນອນ, ຖ້າຈໍແຄບ ຈະ scroll ລວງນອນແທນ
    // ──────────────────────────────────────────────────────
    const double baseColTime   = 68.0;
    const double baseColVal    = 78.0;
    const double baseColStatus = 72.0;
    const double baseTotal     = baseColTime + baseColVal * 8 + baseColStatus; // 764 px

    return Column(children: [
      _buildDateSelector(data),
      // ສ່ວນຕາຕະລາງ ກິນພື້ນທີ່ທີ່ເຫຼືອທັງໝົດ → ບໍ່ລົ້ນຈໍ ແລະ ເຫັນຄົບທຸກສ່ວນ
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool fitsScreen = constraints.maxWidth >= baseTotal;
            final double scale = fitsScreen ? (constraints.maxWidth / baseTotal) : 1.0;
            final double colTime   = baseColTime   * scale;
            final double colVal    = baseColVal    * scale;
            final double colStatus = baseColStatus * scale;

            Widget cell(String t, double w, Color c, {bool header = false, int row = 0, TextAlign align = TextAlign.center}) => Container(
              width: w, height: header ? 32 : 36, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: header ? _Op.panel : (row % 2 == 0 ? _Op.bg : _Op.panelAlt),
                border: const Border(bottom: BorderSide(color: _Op.stroke, width: 0.5)),
              ),
              child: Text(t, textAlign: align,
                style: TextStyle(fontFamily: _Op.display, fontSize: header ? 10 : 11,
                  fontWeight: header ? FontWeight.w600 : FontWeight.normal, color: c),
                overflow: TextOverflow.ellipsis),
            );

            Widget groupHeader(String label, double w, Color c) => Container(
              width: w, height: 28, alignment: Alignment.center,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), border: Border(bottom: BorderSide(color: c.withValues(alpha: 0.5)))),
              child: Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c, letterSpacing: 1)),
            );

            Widget groupLabel(String label, double w, Color c) => Container(
              width: w, height: 24, alignment: Alignment.center, color: c.withValues(alpha: 0.07),
              child: Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            );

            // ── Header ──────────────────────────────────────────
            Widget buildHeaderSection() => Column(children: [
              Row(children: [
                Container(width: colTime, height: 28, color: _Op.panel),
                groupHeader('MAIN METER',   colVal * 4, _Op.green),
                groupHeader('BACKUP METER', colVal * 4, _Op.live),
                Container(width: colStatus, height: 28, color: _Op.panel),
              ]),
              Row(children: [
                Container(width: colTime, height: 24, color: _Op.panel),
                groupLabel('EXPORT', colVal * 2, _Op.green),
                groupLabel('IMPORT', colVal * 2, _Op.orange),
                groupLabel('EXPORT', colVal * 2, _Op.green),
                groupLabel('IMPORT', colVal * 2, _Op.orange),
                Container(width: colStatus, height: 24, color: _Op.panel),
              ]),
              Container(
                decoration: const BoxDecoration(color: _Op.panel, border: Border(bottom: BorderSide(color: _Op.stroke, width: 1.5))),
                child: Row(children: [
                  cell('ຊົ່ວໂມງ',  colTime,   _Op.textHi,   header: true),
                  cell('kWh',     colVal,    _Op.green,    header: true),
                  cell('kVarh',   colVal,    _Op.green,    header: true),
                  cell('kWh',     colVal,    _Op.orange,   header: true),
                  cell('kVarh',   colVal,    _Op.orange,   header: true),
                  cell('kWh',     colVal,    _Op.green,    header: true),
                  cell('kVarh',   colVal,    _Op.green,    header: true),
                  cell('kWh',     colVal,    _Op.orange,   header: true),
                  cell('kVarh',   colVal,    _Op.orange,   header: true),
                  cell('ສະຖານະ', colStatus, _Op.textFaint, header: true),
                ]),
              ),
            ]);

            // ── Data Rows — ສະແດງຄ່າ per-hour (ບໍ່ສະສົມ) ──────
            Widget buildDataRows() {
              if (data == null) return _emptyState('ບໍ່ມີຂໍ້ມູນ');

              final isToday = _selectedViewDate.year  == DateTime.now().year  &&
                              _selectedViewDate.month == DateTime.now().month &&
                              _selectedViewDate.day   == DateTime.now().day;

              // ຫາຊົ່ວໂມງລ່າສຸດທີ່ມີຂໍ້ມູນ (ສຳລັບ scroll-to)
              int latestHourWithData = _currentHour;
              for (int i = 23; i >= 0; i--) {
                if (data.mainMeterHours[i].exportKwh > 0 ||
                    data.mainMeterHours[i].importKwh > 0 ||
                    data.backupMeterHours[i].exportKwh > 0) {
                  latestHourWithData = i;
                  break;
                }
              }

              // scroll ໄປຫາຊົ່ວໂມງລ່າສຸດ ສະເພາະຄັ້ງທຳອິດ ຫຼື ເມື່ອມື້/ຊົ່ວໂມງປ່ຽນ
              // (ບໍ່ scroll ຊ້ຳທຸກຄັ້ງທີ່ build ເພື່ອບໍ່ໃຫ້ລົບກວນການເລື່ອນເບິ່ງແຕ່ລະຊົ່ວໂມງດ້ວຍມືຂອງຜູ້ໃຊ້)
              if (_lastAutoScrollDate != _selectedViewDate || _lastAutoScrollHour != latestHourWithData) {
                _lastAutoScrollDate = _selectedViewDate;
                _lastAutoScrollHour = latestHourWithData;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollHourlyCtrl.hasClients) {
                    final targetOffset = latestHourWithData * 36.0;
                    _scrollHourlyCtrl.animateTo(
                      targetOffset.clamp(0.0, _scrollHourlyCtrl.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }

              return Column(
                children: List.generate(24, (i) {
                  final mh = data.mainMeterHours[i];
                  final bh = data.backupMeterHours[i];

                  // ✅ ໃຊ້ຄ່າ per-hour (ຂອງຊົ່ວໂມງນັ້ນໆ) ບໍ່ສະສົມ
                  final cmEK = mh.exportKwh;
                  final cmEV = mh.exportKvarh;
                  final cmIK = mh.importKwh;
                  final cmIV = mh.importKvarh;
                  final cbEK = bh.exportKwh;
                  final cbEV = bh.exportKvarh;
                  final cbIK = bh.importKwh;
                  final cbIV = bh.importKvarh;

                  final isCurrent    = isToday && _isRecording && i == _currentHour;
                  final notYetReached = isToday && i > _currentHour;
                  final hasData = cmEK > 0 || cmIK > 0 || cbEK > 0 || cmIV > 0;
                  final status  = mh.isComplete ? 'ຄົບ' : isCurrent ? 'ກຳລັງ...' : (hasData ? 'ບາງສ່ວນ' : '-');

                  // ຊົ່ວໂມງລ່າສຸດ highlight ພິເສດ
                  final isLatest = i == latestHourWithData && hasData;
                  final bg = isCurrent
                      ? _Op.live.withValues(alpha: 0.10)
                      : isLatest
                          ? _Op.info.withValues(alpha: 0.07)
                          : (i % 2 == 0 ? _Op.bg : _Op.panelAlt);

                  f(double v) => v.toStringAsFixed(1);
                  d(String v) => notYetReached ? '-' : v;

                  return Container(
                    color: bg,
                    child: Row(children: [
                      // ຊົ່ວໂມງ — ສະແດງ range HH:00-HH:59
                      cell('${i.toString().padLeft(2,'0')}:00\n–${i.toString().padLeft(2,'0')}:59',
                          colTime, isCurrent ? _Op.live : isLatest ? _Op.info : _Op.textHi, row: i),
                      cell(d(f(cmEK)), colVal, _Op.green,  row: i),
                      cell(d(f(cmEV)), colVal, _Op.green,  row: i),
                      cell(d(f(cmIK)), colVal, _Op.orange, row: i),
                      cell(d(f(cmIV)), colVal, _Op.orange, row: i),
                      cell(d(f(cbEK)), colVal, _Op.green,  row: i),
                      cell(d(f(cbEV)), colVal, _Op.green,  row: i),
                      cell(d(f(cbIK)), colVal, _Op.orange, row: i),
                      cell(d(f(cbIV)), colVal, _Op.orange, row: i),
                      cell(notYetReached ? '-' : status, colStatus,
                          mh.isComplete ? _Op.lime : isCurrent ? _Op.live : isLatest ? _Op.info : _Op.textFaint,
                          row: i),
                    ]),
                  );
                }),
              );
            }

            // ── Summary row ──────────────────────────────────────
            Widget buildSummary() {
              if (data == null) return const SizedBox();
              final m = data.dailyMainTotal, b = data.dailyBackupTotal;
              g(double v) => v.toStringAsFixed(1);
              return Container(
                padding: const EdgeInsets.only(bottom: 6),
                decoration: const BoxDecoration(color: _Op.panelAlt, border: Border(top: BorderSide(color: _Op.stroke, width: 2.0))),
                child: Row(children: [
                  cell('ລວມທັງໝົດ', colTime,   _Op.warn,   header: true),
                  cell(g(m.exportKwh),   colVal,    _Op.green,  header: true),
                  cell(g(m.exportKvarh), colVal,    _Op.green,  header: true),
                  cell(g(m.importKwh),   colVal,    _Op.orange, header: true),
                  cell(g(m.importKvarh), colVal,    _Op.orange, header: true),
                  cell(g(b.exportKwh),   colVal,    _Op.green,  header: true),
                  cell(g(b.exportKvarh), colVal,    _Op.green,  header: true),
                  cell(g(b.importKwh),   colVal,    _Op.orange, header: true),
                  cell(g(b.importKvarh), colVal,    _Op.orange, header: true),
                  cell('',               colStatus, _Op.textFaint, header: true),
                ]),
              );
            }

            final Widget table = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeaderSection(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollHourlyCtrl,
                    scrollDirection: Axis.vertical,
                    child: buildDataRows(),
                  ),
                ),
                buildSummary(),
              ],
            );

            // ຈໍກວ້າງພໍ → ບໍ່ scroll ລວງນອນ, ເຫັນ Main+Backup Meter ຄົບໃນຄັ້ງດຽວ
            if (fitsScreen) return table;

            // ຈໍແຄບ → scroll ລວງນອນ
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: baseTotal, child: table),
            );
          },
        ),
      ),
    ]);
  }

  void _showComparisonDialog(DailyMeterData data) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(color: _Op.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: _Op.stroke)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 4),
                child: Row(children: [
                  const Icon(Icons.compare_arrows, color: _Op.info, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('ປຽບທຽບ: ອັດຕະໂນມັດ vs ມິເຕີ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _Op.textHi))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: _Op.textFaint, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
                ]),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10), child: _buildManualVsAutoCard(data)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _tabController.animateTo(0); },
                    icon: const Icon(Icons.edit_note, size: 16, color: Colors.white),
                    label: const Text('ປ້ອນຄ່າມິເຕີ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: _Op.info, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildManualVsAutoCard(DailyMeterData? data) {
    if (data == null) return const SizedBox();
    final autoM = data.dailyMainTotal, autoB = data.dailyBackupTotal;

    Widget headerRow() => const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 64, child: Text('', style: TextStyle(fontSize: 9))),
        Expanded(child: Text('ອັດຕະໂນມັດ', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: _Op.textFaint, letterSpacing: 0.3))),
        Expanded(child: Text('ມິເຕີ (ມື)', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: _Op.textFaint, letterSpacing: 0.3))),
        Expanded(child: Text('Δ ຜົນຕ່າງ', textAlign: TextAlign.end, style: TextStyle(fontSize: 9, color: _Op.textFaint, letterSpacing: 0.3))),
      ]),
    );

    Widget compareRow(String label, double autoV, double manualV, Color color) {
      final diff = manualV - autoV;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(children: [
          SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 9.5, color: _Op.textLo))),
          Expanded(child: Text(autoV.toStringAsFixed(0), textAlign: TextAlign.center, style: TextStyle(fontFamily: _Op.display, fontSize: 11, color: color.withValues(alpha: 0.65)))),
          Expanded(child: Text(manualV.toStringAsFixed(0), textAlign: TextAlign.center, style: TextStyle(fontFamily: _Op.display, fontSize: 12, fontWeight: FontWeight.w800, color: color))),
          Expanded(child: Text('${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(0)}', textAlign: TextAlign.end, style: const TextStyle(fontFamily: _Op.display, fontSize: 9.5, color: _Op.textFaint))),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _Op.panelAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: _Op.stroke)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.compare_arrows, color: _Op.info, size: 13), SizedBox(width: 6), Text('ປຽບທຽບ: ອັດຕະໂນມັດ vs ມິເຕີ (ປ້ອນດ້ວຍມື)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _Op.textLo))]),
        const SizedBox(height: 8),
        headerRow(),
        _subLabel('🟢 MAIN METER'),
        compareRow('Exp kWh', autoM.exportKwh, data.manualMainExpKwh, _Op.green),
        compareRow('Exp kVarh', autoM.exportKvarh, data.manualMainExpKvarh, _Op.green),
        compareRow('Imp kWh', autoM.importKwh, data.manualMainImpKwh, _Op.orange),
        compareRow('Imp kVarh', autoM.importKvarh, data.manualMainImpKvarh, _Op.orange),
        const Divider(color: _Op.stroke, height: 14),
        _subLabel('🔵 BACKUP METER'),
        compareRow('Exp kWh', autoB.exportKwh, data.manualBackupExpKwh, _Op.green),
        compareRow('Exp kVarh', autoB.exportKvarh, data.manualBackupExpKvarh, _Op.green),
        compareRow('Imp kWh', autoB.importKwh, data.manualBackupImpKwh, _Op.orange),
        compareRow('Imp kVarh', autoB.importKvarh, data.manualBackupImpKvarh, _Op.orange),
        if (data.lastManualEntry != null) ...[
          const SizedBox(height: 6),
          Text('ອ່ານຄ່າມິເຕີຄັ້ງລ່າສຸດ: ${DateFormat('dd/MM/yyyy HH:mm:ss', 'lo').format(data.lastManualEntry!.timestamp)}', style: const TextStyle(fontSize: 9, color: _Op.textFaint)),
        ] else ...[
          const SizedBox(height: 6),
          const Text('ຍັງບໍ່ມີຄ່າມິເຕີປ້ອນດ້ວຍມືສຳລັບມື້ນີ້', style: TextStyle(fontSize: 9, color: _Op.textFaint, fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }

  Widget _buildDateSelector(DailyMeterData? data) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: _Op.panelAlt,
      child: Row(children: [
        _buildComparisonChip(data),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => setState(() => _selectedViewDate = _selectedViewDate.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_left, color: _Op.textHi, size: 20)),
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _selectedViewDate, firstDate: DateTime(2024, 1, 1), lastDate: DateTime.now(), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: _Op.live, surface: _Op.panel)), child: child!));
                if (picked != null && !picked.isAfter(today)) setState(() => _selectedViewDate = picked);
              },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: _Op.panel, borderRadius: BorderRadius.circular(8), border: Border.all(color: _Op.stroke)), child: Text(DateFormat('EEEE dd/MM/yyyy', 'lo').format(_selectedViewDate), style: const TextStyle(color: _Op.textHi, fontSize: 13))),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: _selectedViewDate.isBefore(today) ? () => setState(() => _selectedViewDate = _selectedViewDate.add(const Duration(days: 1))) : null, icon: Icon(Icons.chevron_right, color: _selectedViewDate.isBefore(today) ? _Op.textHi : _Op.textFaint, size: 20)),
          ]),
        ),
        // ບ່ອນຫວ່າງດ້ານຂວາ ເພື່ອຖ່ວງດຸ່ນຫົວປຸ່ມປຽບທຽບທາງຊ້າຍ ໃຫ້ວັນທີ່ຢູ່ກາງແທ້ໆ
        SizedBox(width: _comparisonChipWidth(data)),
      ]),
    );
  }

  double _comparisonChipWidth(DailyMeterData? data) => data == null ? 0 : 100;

  Widget _buildComparisonChip(DailyMeterData? data) {
    if (data == null) return const SizedBox();
    final autoM = data.dailyMainTotal, autoB = data.dailyBackupTotal;
    final diffTotal = (data.manualMainExpKwh - autoM.exportKwh) + (data.manualBackupExpKwh - autoB.exportKwh);
    final hasManual = data.lastManualEntry != null;
    return InkWell(
      onTap: () => _showComparisonDialog(data),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: _comparisonChipWidth(data),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(color: _Op.panel, borderRadius: BorderRadius.circular(8), border: Border.all(color: _Op.stroke)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.compare_arrows, color: _Op.info, size: 14),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              hasManual ? 'Δ ${diffTotal >= 0 ? '+' : ''}${diffTotal.toStringAsFixed(0)}' : 'ປຽບທຽບ',
              style: const TextStyle(fontFamily: _Op.display, fontSize: 10.5, fontWeight: FontWeight.w700, color: _Op.textHi),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(color: _Op.panel, border: Border(top: BorderSide(color: _Op.stroke)), borderRadius: BorderRadius.vertical(bottom: Radius.circular(18))),
      child: Row(children: [
        if (_records.isNotEmpty) IconButton(onPressed: _isRecording ? null : _clearData, icon: Icon(Icons.delete_outline, color: _isRecording ? _Op.textFaint : _Op.danger, size: 20), tooltip: 'ລຶບຂໍ້ມູນທັງໝົດ', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: (_records.isEmpty && (_currentDailyData == null || _currentDailyData!.dailyMainTotal.exportKwh == 0)) || _exporting ? null : _exportExcel,
          style: ElevatedButton.styleFrom(backgroundColor: (_records.isEmpty && (_currentDailyData == null || _currentDailyData!.dailyMainTotal.exportKwh == 0)) ? _Op.strokeSoft : const Color(0xFF1D7A3C), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
          icon: _exporting ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.download, size: 16, color: Colors.white),
          label: Text(_exporting ? 'ກຳລັງ Export...' : 'Export Excel', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  String _two(int v) => v.toString().padLeft(2, '0');
  Widget _hScroll(List<Widget> children) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: children));
  Widget _hCell(String text, double width, Color color) => Container(width: width, padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4), alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.4), textAlign: TextAlign.center));
  Widget _dCell(String text, double width, Color color, int rowIdx) => Container(width: width, padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4), color: rowIdx % 2 == 0 ? _Op.panel : _Op.panelAlt, alignment: Alignment.center, child: Text(text, style: TextStyle(fontFamily: _Op.display, fontSize: 10, color: color)));
  Widget _calcRow(String label, String value, Color color) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 11, color: _Op.textLo)), Text(value, style: TextStyle(fontFamily: _Op.display, fontSize: 12, fontWeight: FontWeight.w700, color: color))]));
  Widget _subLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 4, top: 2), child: Text(text, style: const TextStyle(fontSize: 10, color: _Op.textFaint, letterSpacing: 0.3)));
  Widget _sectionLabel(String lo, String hi, Color color) => Row(children: [Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Text(lo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _Op.textHi)), const SizedBox(width: 6), Text('· $hi', style: const TextStyle(fontSize: 9, color: _Op.textFaint, letterSpacing: 0.5))]);
  Widget _inputField({required TextEditingController ctrl, required String label, required String hint, required IconData icon, required Color color, required String unit}) => TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(fontFamily: _Op.display, fontSize: 15, fontWeight: FontWeight.w700, color: color), decoration: InputDecoration(labelText: label, hintText: hint, labelStyle: const TextStyle(color: _Op.textLo, fontSize: 12), hintStyle: const TextStyle(color: _Op.textFaint, fontSize: 12), prefixIcon: Icon(icon, color: color, size: 18), suffixText: unit, suffixStyle: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12), filled: true, fillColor: _Op.panelAlt, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _Op.stroke)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)));
  Widget _errorBox() => Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _Op.danger.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: _Op.danger.withValues(alpha: 0.4))), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: _Op.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_errorMsg, style: const TextStyle(color: _Op.danger, fontSize: 12)))]));
  Widget _emptyState(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.table_chart_outlined, color: _Op.textFaint, size: 44), const SizedBox(height: 10), Text(msg, style: const TextStyle(color: _Op.textFaint, fontSize: 13, height: 1.5), textAlign: TextAlign.center)]));
  Widget _summaryChip(String label, String value, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text(label, style: const TextStyle(fontSize: 8, color: _Op.textFaint, letterSpacing: 0.5)), const SizedBox(height: 2), Text(value, style: TextStyle(fontFamily: _Op.display, fontSize: 10, fontWeight: FontWeight.w700, color: color))]);

  Widget _summaryRangeChip(String label, double minV, double maxV, int decimals, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Text(label, style: const TextStyle(fontSize: 8, color: _Op.textFaint, letterSpacing: 0.5)),
    const SizedBox(height: 2),
    Row(mainAxisSize: MainAxisSize.min, children: [
      Text(minV.toStringAsFixed(decimals), style: TextStyle(fontFamily: _Op.display, fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      Text(' → ', style: TextStyle(fontFamily: _Op.display, fontSize: 10, fontWeight: FontWeight.w400, color: color.withValues(alpha: 0.5))),
      Text(maxV.toStringAsFixed(decimals), style: TextStyle(fontFamily: _Op.display, fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    ]),
  ]);
}

void showProductionDialog(BuildContext context) {
  showDialog(context: context, barrierDismissible: false, builder: (_) => const ProductionDialog());
}