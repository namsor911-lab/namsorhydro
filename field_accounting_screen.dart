// ═══════════════════════════════════════════════════════════════
//  field_accounting_screen.dart  — Flutter Web + Firestore Sync
//  ແກ້ໄຂໃຫ້ 20 ຄົນ ໃຊ້ຄອມຄົນລະເຄື່ອງ ເຫັນຂໍ້ມູນດ່ຽວກັນ Real-time
//
//  ການປ່ຽນແປງຈາກ version ເກົ່າ:
//    • SharedPreferences (local)  →  Cloud Firestore (shared)
//    • ເພີ່ມ StreamSubscription ຟັງ Firestore real-time
//    • ທຸກ CRUD ຂຽນ/ລຶບ Firestore ໂດຍກົງ
//    • Lock + Signature ກໍ່ເກັບ Firestore ດ່ຽວກັນ
//
//  pubspec.yaml — ຕ້ອງເພີ່ມ:
//    firebase_core: ^3.0.0
//    cloud_firestore: ^5.0.0
//    firebase_options.dart — ສ້າງດ້ວຍ FlutterFire CLI
//
//  Firestore Collections:
//    field_accounting/{monthKey}  → { transactions: [...] }
//    field_meta/locks             → { keys: [...] }
//    field_signatures/{key}       → { data: base64 }
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import 'accounting_screen.dart';

// ─── Categories ────────────────────────────────────────────────
const List<String> kFieldCategories = [
  'ທົ່ວໄປ', 'ອຸປະກອນ', 'ວັດສະດຸ', 'ນ້ຳມັນ', 'ແຮງງານ',
  'ຄ່າຂົນສົ່ງ', 'ອາຫານ/ນ້ຳ', 'ລາຍຮັບພາກສະໜາມ', 'ອື່ນໆ',
];

// ─── Firestore collection/document names ──────────────────────
const String kColAccounting  = 'field_accounting';
const String kColSignatures  = 'field_signatures';
const String kColMeta        = 'field_meta';
const String kDocLocks       = 'locks';

// ═══════════════════════════════════════════════════════════════
//  Model
// ═══════════════════════════════════════════════════════════════
class FieldTransaction {
  String id;
  String date;
  String desc;
  String category;
  double income;
  double expense;
  String note;

  FieldTransaction({
    required this.id,
    required this.date,
    required this.desc,
    this.category = 'ທົ່ວໄປ',
    this.income   = 0,
    this.expense  = 0,
    this.note     = '',
  });

  double get net => income - expense;

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date, 'desc': desc, 'category': category,
    'income': income, 'expense': expense, 'note': note,
  };

  factory FieldTransaction.fromJson(Map<String, dynamic> j) => FieldTransaction(
    id:       j['id']       as String? ?? '',
    date:     j['date']     as String? ?? '',
    desc:     j['desc']     as String? ?? '',
    category: j['category'] as String? ?? 'ທົ່ວໄປ',
    income:   ((j['income']  ?? 0) as num).toDouble(),
    expense:  ((j['expense'] ?? 0) as num).toDouble(),
    note:     j['note']     as String? ?? '',
  );
}

// ═══════════════════════════════════════════════════════════════
//  Firestore helpers — ແທນ SharedPreferences ທັງໝົດ
// ═══════════════════════════════════════════════════════════════
final _firestore = FirebaseFirestore.instance;

// ── ເປີດ offline persistence ຄັ້ງດຽວ ─────────────────────────
// ຮັບປະກັນ Firestore cache ຂໍ້ມູນໃສ່ disk ເມື່ອ offline / re-login
bool _firestorePersistenceEnabled = false;
void _ensureFirestorePersistence() {
  if (_firestorePersistenceEnabled) return;
  try {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    _firestorePersistenceEnabled = true;
    debugPrint('✅ Firestore offline persistence enabled');
  } catch (_) {
    // ອາດ throw ຖ້າ settings ຖືກ set ໄປແລ້ວ — ignore
  }
}

// ── SharedPreferences local cache key prefix ──────────────────
const String _kPrefPrefix = 'fa_month_';
const String _kPrefLocks  = 'fa_locked_keys';

// ── ບັນທຶກ _db ໄປ SharedPreferences (local cache) ────────────
Future<void> _saveDbToLocal(Map<String, List<FieldTransaction>> db) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in db.entries) {
      final json = jsonEncode(entry.value.map((t) => t.toJson()).toList());
      await prefs.setString('$_kPrefPrefix${entry.key}', json);
    }
  } catch (e) {
    debugPrint('⚠️ _saveDbToLocal error: $e');
  }
}

// ── ອ່ານ _db ຈາກ SharedPreferences (local cache) ─────────────
Future<Map<String, List<FieldTransaction>>> _loadDbFromLocal() async {
  final result = <String, List<FieldTransaction>>{};
  try {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_kPrefPrefix)) continue;
      final monthKey = key.substring(_kPrefPrefix.length);
      final jsonStr  = prefs.getString(key);
      if (jsonStr == null) continue;
      try {
        final list = (jsonDecode(jsonStr) as List)
            .map((j) => FieldTransaction.fromJson(j as Map<String, dynamic>))
            .toList();
        result[monthKey] = list;
      } catch (e) {
        debugPrint('⚠️ _loadDbFromLocal parse error [$monthKey]: $e');
      }
    }
    debugPrint('✅ Loaded ${result.length} months from local cache');
  } catch (e) {
    debugPrint('⚠️ _loadDbFromLocal error: $e');
  }
  return result;
}

// ── ບັນທຶກ lockedKeys ໄປ local cache ─────────────────────────
Future<void> _saveLockedKeysLocal(Set<String> keys) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefLocks, jsonEncode(keys.toList()));
  } catch (e) {
    debugPrint('⚠️ _saveLockedKeysLocal error: $e');
  }
}

// ── ອ່ານ lockedKeys ຈາກ local cache ──────────────────────────
Future<Set<String>> _loadLockedKeysLocal() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kPrefLocks);
    if (str == null) return {};
    return (jsonDecode(str) as List).cast<String>().toSet();
  } catch (e) {
    debugPrint('⚠️ _loadLockedKeysLocal error: $e');
    return {};
  }
}

String _monthKey(String year, String month) => '${year}_$month';

// ── ບັນທຶກລາຍການຂອງເດືອນນັ້ນໄປ Firestore ──────────────────────
Future<void> _saveMonthData(
    String monthKey, List<FieldTransaction> rows) async {
  try {
    await _firestore.collection(kColAccounting).doc(monthKey).set({
      'transactions': rows.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } on FirebaseException catch (e) {
    // ✅ FIX: ແຍກ FirebaseException — ລວມ code ທີ່ເຮັດໃຫ້ຂໍ້ມູນຫາຍ
    debugPrint('⚠️ _saveMonthData FirebaseException [${e.code}]: ${e.message}');
    // permission-denied = Firestore rules block → ຂໍ້ມູນ local ຍັງຢູ່, ສ່ວນ cloud ສູນ
    // unavailable = offline → ຂໍ້ມູນຈະ sync ເມື່ອ online ຄືນ (Firestore offline cache)
  } catch (e) {
    debugPrint('⚠️ _saveMonthData error: $e');
  }
}

// ── ອ່ານ locked keys ຈາກ Firestore ───────────────────────────
Future<Set<String>> _loadLockedKeys() async {
  try {
    final doc = await _firestore.collection(kColMeta).doc(kDocLocks).get();
    if (!doc.exists) return {};
    final raw = doc.data()?['keys'];
    if (raw is List) return raw.cast<String>().toSet();
    return {};
  } on FirebaseException catch (e) {
    debugPrint('⚠️ _loadLockedKeys FirebaseException [${e.code}]: ${e.message}');
    return {};
  } catch (e) {
    debugPrint('⚠️ _loadLockedKeys error: $e');
    return {};
  }
}

// ── ບັນທຶກ locked keys ໄປ Firestore ──────────────────────────
Future<void> _saveLockedKeys(Set<String> keys) async {
  try {
    await _firestore.collection(kColMeta).doc(kDocLocks).set({
      'keys': keys.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } on FirebaseException catch (e) {
    debugPrint('⚠️ _saveLockedKeys FirebaseException [${e.code}]: ${e.message}');
  } catch (e) {
    debugPrint('⚠️ _saveLockedKeys error: $e');
  }
}

// ── ບັນທຶກ Signature PNG (base64) ໄປ Firestore ───────────────
Future<void> _saveSigBytes(
    String monthKey, String title, List<int> bytes) async {
  final sigKey = '${monthKey}_$title';
  try {
    await _firestore.collection(kColSignatures).doc(sigKey).set({
      'data': base64Encode(bytes),
      'monthKey': monthKey,
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } on FirebaseException catch (e) {
    debugPrint('⚠️ _saveSigBytes FirebaseException [${e.code}]: ${e.message}');
  } catch (e) {
    debugPrint('⚠️ _saveSigBytes error: $e');
  }
}

// ── ອ່ານ Signature PNG ຈາກ Firestore ─────────────────────────
Future<List<int>?> _loadSigBytes(String monthKey, String title) async {
  final sigKey = '${monthKey}_$title';
  try {
    final doc = await _firestore.collection(kColSignatures).doc(sigKey).get();
    if (!doc.exists) return null;
    final b64 = doc.data()?['data'] as String?;
    if (b64 == null || b64.isEmpty) return null;
    return base64Decode(b64);
  } on FirebaseException catch (e) {
    debugPrint('⚠️ _loadSigBytes FirebaseException [${e.code}]: ${e.message}');
    return null;
  } catch (e) {
    debugPrint('⚠️ _loadSigBytes error: $e');
    return null;
  }
}

// ─── ID generator ──────────────────────────────────────────────
final _rng = Random();
String _genId() =>
    '${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999999)}';

// ═══════════════════════════════════════════════════════════════
//  FieldAccountingScreen
// ═══════════════════════════════════════════════════════════════
class FieldAccountingScreen extends StatefulWidget {
  const FieldAccountingScreen({super.key});
  @override
  State<FieldAccountingScreen> createState() => _FieldAccountingScreenState();
}

class _FieldAccountingScreenState extends State<FieldAccountingScreen> {
  final DateTime _now = DateTime.now();
  late String _month;
  late String _year;

  // ── ຂໍ້ມູນທີ່ຮັບຈາກ Firestore stream ──────────────────────────
  Map<String, List<FieldTransaction>> _db = {};
  Set<String> _lockedKeys = {};
  bool _loading = true;
  int  _leftTab = 0;

  // ── Real-time stream subscriptions ────────────────────────────
  // ຟັງ collection field_accounting ທັງໝົດ
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _txStream;
  // ຟັງ locks document
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _lockStream;

  final List<String> _sigTitles = const [
    'ຜູ້ອຳນວຍການ', 'ຫົວໜ້າເຂື່ອນ', 'ບັນຊີ-ການເງິນ', 'ຜູ້ສະຫຼຸບ',
  ];
  late Map<String, SignatureController> _sigControllers;
  final Map<String, List<int>?> _savedSigBytes = {};

  @override
  void initState() {
    super.initState();
    _month = _now.month.toString().padLeft(2, '0');
    _year  = _now.year.toString();
    _sigControllers = {
      for (final t in _sigTitles)
        t: SignatureController(
          penStrokeWidth: 2.5,
          penColor: Colors.blue,
          exportBackgroundColor: Colors.white,
        ),
    };
    // ✅ FIX: ເປີດ offline persistence ທຸກຄັ້ງທີ່ screen ເປີດ
    _ensureFirestorePersistence();
    // ✅ FIX: ໂຫຼດ local cache ກ່ອນ → user ເຫັນຂໍ້ມູນທັນທີ
    // ຈາກນັ້ນ Firestore stream ຈະ merge ຂໍ້ມູນໃໝ່ເຂົ້າ
    _loadLocalCacheThenListen();
  }

  @override
  void dispose() {
    _txStream?.cancel();
    _lockStream?.cancel();
    for (final c in _sigControllers.values) { c.dispose(); }
    super.dispose();
  }

  // ── ໂຫຼດ local cache ກ່ອນ ຈາກນັ້ນ subscribe Firestore ──────
  Future<void> _loadLocalCacheThenListen() async {
    // ① ໂຫຼດຈາກ SharedPreferences ກ່ອນ — UI ສະແດງທັນທີ
    final localDb     = await _loadDbFromLocal();
    final localLocked = await _loadLockedKeysLocal();
    if (mounted && localDb.isNotEmpty) {
      setState(() {
        _db          = localDb;
        _lockedKeys  = localLocked;
        _loading     = false;
      });
    }
    // ② ຈາກນັ້ນ subscribe Firestore — merge ຂໍ້ມູນໃໝ່
    _startListening();
  }

  // ── ເລີ່ມຟັງ Firestore Real-time ────────────────────────────
  // ທຸກຄັ້ງທີ່ຄົນໃດຄົນໜຶ່ງໃນ 20 ຄົນ ເພີ່ມ/ລຶບ/ແກ້ໄຂ
  // Firestore ຈະ push ຂໍ້ມູນໃໝ່ ໃຫ້ທຸກຄົນທັນທີ
  void _startListening() {
    // ── Stream 1: ຟັງ transactions ທຸກເດືອນ ──────────────────
    _txStream = _firestore
        .collection(kColAccounting)
        .snapshots()
        .listen((snapshot) {
      // ✅ FIX: ຖ້າ snapshot ຫວ່າງ — ຮັກສາ _db ເກົ່າ (local cache)
      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final Map<String, List<FieldTransaction>> newDb = {};
      for (final doc in snapshot.docs) {
        final monthKey = doc.id;
        final data = doc.data();
        final list = (data['transactions'] as List<dynamic>? ?? [])
            .map((e) => FieldTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        newDb[monthKey] = list;
      }
      if (!mounted) return;
      setState(() {
        // ✅ FIX: Merge — Firestore ຊະນະ local ສະເພາະ key ທີ່ push ມາ
        _db = {..._db, ...newDb};
        _loading = false;
      });
      // ✅ FIX: ບັນທຶກ cache ທ້ອງຖິ່ນທຸກຄັ້ງ Firestore push
      _saveDbToLocal(_db);
      _reloadSigBytesForCurrentKey();
    }, onError: (e) {
      debugPrint('⚠️ _txStream error: $e');
      // ✅ FIX: ບໍ່ລ້າງ _db ເມື່ອ error — ຮັກສາຂໍ້ມູນ local cache
      if (mounted) setState(() => _loading = false);
    });

    // ── Stream 2: ຟັງ locks document ──────────────────────────
    _lockStream = _firestore
        .collection(kColMeta)
        .doc(kDocLocks)
        .snapshots()
        .listen((doc) async {
      Set<String> keys = {};
      if (doc.exists) {
        final raw = doc.data()?['keys'];
        if (raw is List) keys = raw.cast<String>().toSet();
      }
      if (!mounted) return;
      final changed = !_setEquals(_lockedKeys, keys);
      setState(() => _lockedKeys = keys);
      // ✅ FIX: ບັນທຶກ lockedKeys ໄປ local cache ດ້ວຍ
      if (changed) {
        _saveLockedKeysLocal(keys);
        _reloadSigBytesForCurrentKey();
      }
    }, onError: (e) {
      debugPrint('⚠️ _lockStream error: $e');
    });
  }

  // ✅ FIX helper: ປຽບທຽບ Set ສອງອັນ
  bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  // ── ໂຫຼດ sig bytes ຂອງເດືອນທີ່ເລືອກ ─────────────────────────
  Future<void> _reloadSigBytesForCurrentKey() async {
    final key = _key;
    if (!_lockedKeys.contains(key)) {
      // ✅ FIX: ພຽງແຕ່ clear ເມື່ອມີຂໍ້ມູນຢູ່ ເພື່ອຫຼຸດ rebuild
      if (_savedSigBytes.isNotEmpty && mounted) {
        setState(() => _savedSigBytes.clear());
      }
      return;
    }
    // ✅ FIX: ໂຫຼດທຸກ sig ກ່ອນ ຈາກນັ້ນ setState ຄັ້ງດຽວ
    final Map<String, List<int>?> map = {};
    for (final t in _sigTitles) {
      map[t] = await _loadSigBytes(key, t);
    }
    if (!mounted) return;
    // ✅ FIX: ກວດວ່າ key ຍັງຕົງກັນ (user ອາດ switch ເດືອນລະຫວ່າງ await)
    if (_key != key) return;
    setState(() {
      _savedSigBytes
        ..clear()
        ..addAll(map);
    });
  }

  // ── Computed ─────────────────────────────────────────────────
  String get _key      => _monthKey(_year, _month);
  bool   get _isLocked => _lockedKeys.contains(_key);

  List<FieldTransaction> get _rows {
    final list = List<FieldTransaction>.from(_db[_key] ?? []);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  double get _totalIncome  => _rows.fold(0, (s, t) => s + t.income);
  double get _totalExpense => _rows.fold(0, (s, t) => s + t.expense);
  double get _totalNet     => _totalIncome - _totalExpense;
  double get _nextMonthProjected =>
      _totalNet >= 0 ? _totalIncome : _totalIncome - _totalNet;

  // ── CRUD — ຂຽນ Firestore ໂດຍກົງ ──────────────────────────────
  // ✅ FIX: Optimistic update + save local cache ທຸກຄັ້ງ
  Future<void> _addTransaction(FieldTransaction tx) async {
    final key     = _key;
    final current = List<FieldTransaction>.from(_db[key] ?? []);
    current.add(tx);
    if (mounted) setState(() => _db[key] = List.from(current));
    // ✅ FIX: save local ທັນທີ — ບໍ່ຖ້າ Firestore
    _saveDbToLocal(_db);
    await _saveMonthData(key, current);
  }

  Future<void> _deleteTransaction(String id) async {
    final key     = _key;
    final current = List<FieldTransaction>.from(_db[key] ?? []);
    current.removeWhere((t) => t.id == id);
    if (mounted) setState(() => _db[key] = List.from(current));
    _saveDbToLocal(_db);
    await _saveMonthData(key, current);
  }

  Future<void> _editTransaction(FieldTransaction updated) async {
    final key     = _key;
    final current = List<FieldTransaction>.from(_db[key] ?? []);
    final idx     = current.indexWhere((t) => t.id == updated.id);
    if (idx >= 0) current[idx] = updated;
    if (mounted) setState(() => _db[key] = List.from(current));
    _saveDbToLocal(_db);
    await _saveMonthData(key, current);
  }

  // ── Lock + ບັນທຶກ Signature ────────────────────────────────
  Future<void> _lockCurrentMonth() async {
    final key = _key;
    for (final title in _sigTitles) {
      final ctrl = _sigControllers[title];
      if (ctrl == null || ctrl.isEmpty) continue;
      try {
        final bytes = await ctrl.toPngBytes();
        if (bytes != null) {
          await _saveSigBytes(key, title, bytes);
          _savedSigBytes[title] = bytes;
        }
      } catch (e) {
        debugPrint('⚠️ saveSig [$title]: $e');
      }
    }
    // ອ່ານ lockedKeys ລ່າສຸດຈາກ Firestore ກ່ອນ ເພື່ອບໍ່ overwrite
    final latest = await _loadLockedKeys();
    latest.add(key);
    await _saveLockedKeys(latest);
    // ✅ FIX: ບັນທຶກ lockedKeys ໄປ local cache ດ້ວຍ
    await _saveLockedKeysLocal(latest);
    // _lockStream ຈະ push ກັບມາ → setState ອັດຕະໂນມັດ
  }

  // ── Quarter helpers ───────────────────────────────────────────
  List<double> _monthSummary(String year, int month) {
    final key  = _monthKey(year, month.toString().padLeft(2, '0'));
    final rows = _db[key] ?? [];
    final inc  = rows.fold<double>(0, (s, t) => s + t.income);
    final exp  = rows.fold<double>(0, (s, t) => s + t.expense);
    return [inc, exp, inc - exp];
  }

  List<double> _quarterSummary(String year, int q) {
    const months = [[1,2,3],[4,5,6],[7,8,9],[10,11,12]];
    double inc = 0, exp = 0;
    for (final m in months[q - 1]) {
      final s = _monthSummary(year, m);
      inc += s[0]; exp += s[1];
    }
    return [inc, exp, inc - exp];
  }

  List<double> _yearSummary(String year) {
    double inc = 0, exp = 0;
    for (int m = 1; m <= 12; m++) {
      final s = _monthSummary(year, m);
      inc += s[0]; exp += s[1];
    }
    return [inc, exp, inc - exp];
  }

  static const List<String> _qLabels = [
    'Q1 (ມ.ກ - ມີ.ນ)', 'Q2 (ເມ.ສ - ມິ.ຖ)',
    'Q3 (ກ.ລ - ກ.ຍ)',  'Q4 (ຕ.ລ - ທ.ວ)',
  ];
  static const List<List<String>> _qMonths = [
    ['January','February','March'],
    ['April','May','June'],
    ['July','August','September'],
    ['October','November','December'],
  ];
  static const List<List<int>> _qMonthNums = [
    [1,2,3],[4,5,6],[7,8,9],[10,11,12],
  ];

  // ── Dialog — Form ─────────────────────────────────────────────
  void _showFormDialog({FieldTransaction? existing}) {
    final descCtrl   = TextEditingController(text: existing?.desc ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null
          ? (existing.income > 0 ? existing.income : existing.expense)
              .toStringAsFixed(0)
          : '',
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    String   localType = (existing != null && existing.income > 0) ? 'income' : 'expense';
    String   localCat  = existing?.category ?? kFieldCategories.first;
    DateTime localDate = (existing != null)
        ? (DateTime.tryParse(existing.date) ?? DateTime.now())
        : DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(children: [
            Icon(
              existing == null
                  ? Icons.add_circle_outline
                  : Icons.edit_outlined,
              color: AppColors.accent, size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              existing == null ? 'ເພີ່ມລາຍການໃໝ່' : 'ແກ້ໄຂລາຍການ',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ]),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('ວັນທີ *'),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: localDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accent,
                              surface: AppColors.bgSecondary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setSt(() => localDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          '${localDate.day.toString().padLeft(2,'0')}/'
                          '${localDate.month.toString().padLeft(2,'0')}/'
                          '${localDate.year}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _label('ປະເພດ *'),
                  const SizedBox(height: 4),
                  Row(children: [
                    _typeChip('ລາຍຮັບ', 'income',  const Color(0xFF4CAF50), localType,
                        (v) => setSt(() => localType = v)),
                    const SizedBox(width: 8),
                    _typeChip('ລາຍຈ່າຍ', 'expense', const Color(0xFFEF5350), localType,
                        (v) => setSt(() => localType = v)),
                  ]),
                  const SizedBox(height: 12),
                  _label('ໝວດໝູ່'),
                  const SizedBox(height: 4),
                  _fieldDropdown(
                    value: localCat,
                    items: kFieldCategories,
                    onChanged: (v) => setSt(() => localCat = v ?? localCat),
                  ),
                  const SizedBox(height: 12),
                  _label('ເນື້ອໃນ *'),
                  const SizedBox(height: 4),
                  _fieldInput(descCtrl, hint: 'ປ້ອນເນື້ອໃນລາຍການ...'),
                  const SizedBox(height: 12),
                  _label('ຈຳນວນເງິນ (₭) *'),
                  const SizedBox(height: 4),
                  _fieldInput(amountCtrl,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      suffix: '₭'),
                  const SizedBox(height: 12),
                  _label('ໝາຍເຫດ'),
                  const SizedBox(height: 4),
                  _fieldInput(noteCtrl, hint: '...'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                descCtrl.dispose();
                amountCtrl.dispose();
                noteCtrl.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('ຍົກເລີກ',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (descCtrl.text.trim().isEmpty || amt <= 0) {
                  _showSnack(ctx, '⚠️ ກະລຸນາປ້ອນເນື້ອໃນ ແລະ ຈຳນວນເງິນ');
                  return;
                }
                final dateStr =
                    '${localDate.year}-'
                    '${localDate.month.toString().padLeft(2,'0')}-'
                    '${localDate.day.toString().padLeft(2,'0')}';
                final tx = FieldTransaction(
                  id:       existing?.id ?? _genId(),
                  date:     dateStr,
                  desc:     descCtrl.text.trim(),
                  category: localCat,
                  income:   localType == 'income'  ? amt : 0,
                  expense:  localType == 'expense' ? amt : 0,
                  note:     noteCtrl.text.trim(),
                );
                descCtrl.dispose();
                amountCtrl.dispose();
                noteCtrl.dispose();
                Navigator.pop(ctx);
                if (existing == null) {
                  _addTransaction(tx);
                } else {
                  _editTransaction(tx);
                }
              },
              child: const Text('💾 ບັນທຶກ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(FieldTransaction tx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(children: [
          Icon(Icons.warning_amber_outlined,
              color: Color(0xFFEF5350), size: 18),
          SizedBox(width: 8),
          Text('ຢືນຢັນການລຶບ',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ]),
        content: Text(
          'ລຶບລາຍການ "${tx.desc}" ອອກ?\nການກະທຳນີ້ຈະຖາວອນ.',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(tx.id);
            },
            child: const Text('🗑 ລຶບ',
                style: TextStyle(
                    color: Color(0xFFEF5350),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 12)),
      backgroundColor: AppColors.bgSecondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
    ));
  }

  // ══════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          SubScreenHeader(
            title: 'ລາຍຮັບລາຍຈ່າຍ ພາກສະໜາມ',
            subtitle:
                'Field Accounting — ${kAccMonthNames[int.parse(_month) - 1]} $_year',
            icon: Icons.terrain_outlined,
            color: const Color(0xFF26A69A),
            trailing: MonthYearPicker(
              month: _month,
              year:  _year,
              onMonthChanged: (v) {
                // ✅ FIX: setState ກ່ອນ ຈາກນັ້ນ reload — ບໍ່ໃຊ້ _key ເກົ່າ
                setState(() => _month = v);
                Future.microtask(_reloadSigBytesForCurrentKey);
              },
              onYearChanged: (v) {
                setState(() => _year = v);
                Future.microtask(_reloadSigBytesForCurrentKey);
              },
            ),
          ),

          if (!_loading) _buildKpiStrip(),

          // ── Tab bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.bgSecondary,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              _tabBtn(Icons.list_alt_outlined, 'ລາຍການ', 0),
              const SizedBox(width: 6),
              _tabBtn(Icons.bar_chart_rounded, 'Quarter', 1),
              const Spacer(),
              if (_leftTab == 0) ...[
                if (_isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: const Color(0xFF4CAF50)
                              .withValues(alpha: 0.35)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.lock_rounded,
                          size: 13, color: Color(0xFF4CAF50)),
                      SizedBox(width: 5),
                      Text('ລັອກແລ້ວ',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w700)),
                    ]),
                  )
                else
                  InkWell(
                    onTap: () => _showFormDialog(),
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.add, size: 15, color: AppColors.accent),
                        SizedBox(width: 4),
                        Text('ເພີ່ມລາຍການ',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
              ],
            ]),
          ),

          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.accent),
                        SizedBox(height: 12),
                        Text('ກຳລັງໂຫຼດຂໍ້ມູນຈາກ Server...',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 24,
                                left: 16,
                                right: 16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                _leftTab == 0
                                    ? _buildTable()
                                    : _buildQuarterPanel(),
                                if (_leftTab == 0) ...[
                                  const SizedBox(height: 32),
                                  _buildSignatureSection(),
                                ],
                              ],
                            )),
                      ),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 8, bottom: 24),
                          child: _leftTab == 1
                              ? _buildQuarterBarChart()
                              : _buildChartSection(),
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  // ─── Tab button ───────────────────────────────────────────────
  Widget _tabBtn(IconData icon, String label, int idx) {
    final active = _leftTab == idx;
    final color  = idx == 1
        ? const Color(0xFF42A5F5)
        : AppColors.accent;
    return InkWell(
      onTap: () => setState(() => _leftTab = idx),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.45)
                  : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 13,
              color: active ? color : AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: active ? color : AppColors.textMuted,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.normal)),
        ]),
      ),
    );
  }

  // ─── Quarter panel ────────────────────────────────────────────
  Widget _buildQuarterPanel() {
    final yr = _year;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bar_chart_rounded,
                color: Color(0xFF42A5F5), size: 16),
            const SizedBox(width: 6),
            Text('ສະຫຼຸບ Quarter — ປີ $yr',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              _qHeaderRow(),
              const Divider(height: 1, color: AppColors.border),
              ...List.generate(4, (qi) {
                final qData = _quarterSummary(yr, qi + 1);
                return Column(children: [
                  _qGroupRow(_qLabels[qi], qData),
                  ...List.generate(3, (mi) {
                    final mData =
                        _monthSummary(yr, _qMonthNums[qi][mi]);
                    return _qMonthRow(_qMonths[qi][mi], mData,
                        isLast: mi == 2);
                  }),
                  if (qi < 3)
                    const Divider(
                        height: 1, color: AppColors.border),
                ]);
              }),
              const Divider(height: 1, color: AppColors.border),
              _qYearTotalRow(_yearSummary(yr), yr),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _qHeaderRow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF42A5F5).withValues(alpha: 0.08),
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8)),
    ),
    child: const Row(children: [
      Expanded(flex: 4, child: Text('Quarter / ເດືອນ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF42A5F5)))),
      Expanded(flex: 3, child: Text('ລາຍຮັບ', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))),
      Expanded(flex: 3, child: Text('ລາຍຈ່າຍ', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF5350)))),
      Expanded(flex: 3, child: Text('ສຸດທິ', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
    ]),
  );

  Widget _qGroupRow(String label, List<double> data) {
    final net = data[2];
    return Container(
      color: AppColors.bgPrimary.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(children: [
        Expanded(flex: 4, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF42A5F5)))),
        Expanded(flex: 3, child: Text('${fmtKip(data[0])} ₭', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
        Expanded(flex: 3, child: Text('${fmtKip(data[1])} ₭', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, color: Color(0xFFEF5350), fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
        Expanded(flex: 3, child: Text(
          '${net < 0 ? "−" : ""}${fmtKip(net.abs())} ₭',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace',
              color: net >= 0 ? const Color(0xFF42A5F5) : const Color(0xFFEF5350)),
        )),
      ]),
    );
  }

  Widget _qMonthRow(String name, List<double> data,
      {bool isLast = false}) {
    final net = data[2];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 5, 10, 5),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: AppColors.border, width: 0.3))),
      child: Row(children: [
        Expanded(flex: 4, child: Text(name, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text(
          data[0] > 0 ? '${fmtKip(data[0])} ₭' : '—',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 9, fontFamily: 'monospace',
              color: data[0] > 0 ? const Color(0xFF4CAF50) : AppColors.textMuted),
        )),
        Expanded(flex: 3, child: Text(
          data[1] > 0 ? '${fmtKip(data[1])} ₭' : '—',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 9, fontFamily: 'monospace',
              color: data[1] > 0 ? const Color(0xFFEF5350) : AppColors.textMuted),
        )),
        Expanded(flex: 3, child: Text(
          (data[0] > 0 || data[1] > 0)
              ? '${net < 0 ? "−" : ""}${fmtKip(net.abs())} ₭'
              : '—',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 9, fontFamily: 'monospace',
              color: net >= 0 ? const Color(0xFF42A5F5) : const Color(0xFFEF5350)),
        )),
      ]),
    );
  }

  Widget _qYearTotalRow(List<double> data, String yr) {
    final net = data[2];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF42A5F5).withValues(alpha: 0.06),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8)),
      ),
      child: Row(children: [
        Expanded(flex: 4, child: Text('Year Total ($yr)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF42A5F5)))),
        Expanded(flex: 3, child: Text('${fmtKip(data[0])} ₭', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50), fontFamily: 'monospace'))),
        Expanded(flex: 3, child: Text('${fmtKip(data[1])} ₭', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFEF5350), fontFamily: 'monospace'))),
        Expanded(flex: 3, child: Text(
          '${net < 0 ? "−" : ""}${fmtKip(net.abs())} ₭',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'monospace',
              color: net >= 0 ? const Color(0xFF42A5F5) : const Color(0xFFEF5350)),
        )),
      ]),
    );
  }

  // ─── Quarter Bar Chart ────────────────────────────────────────
  Widget _buildQuarterBarChart() {
    final yr     = _year;
    final qData  = List.generate(4, (i) => _quarterSummary(yr, i + 1));
    final yearData = _yearSummary(yr);

    double maxVal = 1000000;
    for (final q in qData) {
      if (q[0] > maxVal) maxVal = q[0];
      if (q[1] > maxVal) maxVal = q[1];
    }
    final maxY = (maxVal * 1.25).ceilToDouble();

    const qShort      = ['Q1', 'Q2', 'Q3', 'Q4'];
    const incColor    = Color(0xFF4CAF50);
    const expColor    = Color(0xFFEF5350);
    const netPosColor = Color(0xFF42A5F5);
    const netNegColor = Color(0xFFFF7043);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bar_chart_rounded,
                color: Color(0xFF42A5F5), size: 16),
            const SizedBox(width: 6),
            Text('ກຣາຟ Quarter — ປີ $yr',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 4),
          const Text('ລາຍຮັບ vs ລາຍຈ່າຍ ແຕ່ລະ Quarter',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Row(children: [
            _barLegend(incColor, 'ລາຍຮັບ'),
            const SizedBox(width: 12),
            _barLegend(expColor, 'ລາຍຈ່າຍ'),
            const SizedBox(width: 12),
            _barLegend(netPosColor, 'ສຸດທິ +'),
            const SizedBox(width: 12),
            _barLegend(netNegColor, 'ສຸດທິ −'),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY, minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.bgPrimary,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, _, rod, rodIdx) {
                    const labels = ['ລາຍຮັບ', 'ລາຍຈ່າຍ', 'ສຸດທິ'];
                    return BarTooltipItem(
                      '${qShort[group.x]} ${labels[rodIdx]}\n'
                      '${fmtKip(rod.toY.abs())} ₭',
                      TextStyle(
                          color: rod.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= 4) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(qShort[i],
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF42A5F5),
                                fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (val, _) {
                      if (val == 0) {
                        return const Text('0',
                            style: TextStyle(
                                fontSize: 8,
                                color: AppColors.textMuted));
                      }
                      final label = val >= 1000000
                          ? '${(val / 1000000).toStringAsFixed(val % 1000000 == 0 ? 0 : 1)}M'
                          : val >= 1000
                              ? '${(val / 1000).toStringAsFixed(0)}K'
                              : val.toStringAsFixed(0);
                      return Text(label,
                          style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textMuted));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.4),
                    strokeWidth: 0.8),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(4, (qi) {
                final inc = qData[qi][0];
                final exp = qData[qi][1];
                final net = qData[qi][2];
                return BarChartGroupData(
                  x: qi,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                        toY: inc,
                        color: incColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4))),
                    BarChartRodData(
                        toY: exp,
                        color: expColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4))),
                    BarChartRodData(
                        toY: net.abs(),
                        color: net >= 0 ? netPosColor : netNegColor,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                        backDrawRodData:
                            BackgroundBarChartRodData(show: false)),
                  ],
                );
              }),
            )),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF42A5F5).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Text('Year Total $yr',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF42A5F5))),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('ຮັບ: ${fmtKip(yearData[0])} ₭',
                    style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF4CAF50),
                        fontFamily: 'monospace')),
                Text('ຈ່າຍ: ${fmtKip(yearData[1])} ₭',
                    style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFEF5350),
                        fontFamily: 'monospace')),
                Text(
                  'ສຸດທິ: ${yearData[2] < 0 ? "−" : ""}${fmtKip(yearData[2].abs())} ₭',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: yearData[2] >= 0
                          ? const Color(0xFF42A5F5)
                          : const Color(0xFFFF7043)),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _barLegend(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: AppColors.textSecondary)),
      ]);

  // ─── Pie Chart ────────────────────────────────────────────────
  Widget _buildChartSection() {
    final total       = _totalIncome + _totalExpense;
    final hasData     = total > 0;
    final incPct      = hasData ? _totalIncome  / total * 100 : 0.0;
    final expPct      = hasData ? _totalExpense / total * 100 : 0.0;
    final nextProj    = _nextMonthProjected;
    final netPositive = _totalNet >= 0;

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 ສັດສ່ວນ ລາຍຮັບ - ລາຍຈ່າຍ',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'ເດືອນ ${kAccMonthNames[int.parse(_month) - 1]} $_year',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          if (hasData) ...[
            Row(children: [
              Expanded(child: _miniStatBox(
                '🟢 ລາຍຮັບ', const Color(0xFF4CAF50),
                fmtKip(_totalIncome), '${incPct.toStringAsFixed(1)}%')),
              const SizedBox(width: 8),
              Expanded(child: _miniStatBox(
                '🔴 ລາຍຈ່າຍ', const Color(0xFFEF5350),
                fmtKip(_totalExpense), '${expPct.toStringAsFixed(1)}%')),
            ]),
            const SizedBox(height: 16),
          ],

          Expanded(
            child: !hasData
                ? const Center(
                    child: Text('ບໍ່ມີຂໍ້ມູນລາຍຮັບ-ລາຍຈ່າຍ',
                        style: TextStyle(color: AppColors.textMuted)))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 55,
                        startDegreeOffset: 270,
                        sections: [
                          if (_totalIncome > 0)
                            PieChartSectionData(
                              color: const Color(0xFF4CAF50),
                              value: _totalIncome,
                              title: '${incPct.toStringAsFixed(0)}%',
                              radius: 48,
                              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              badgeWidget: _sliceBadge(fmtKip(_totalIncome), const Color(0xFF4CAF50)),
                              badgePositionPercentageOffset: 1.5,
                            ),
                          if (_totalExpense > 0)
                            PieChartSectionData(
                              color: const Color(0xFFEF5350),
                              value: _totalExpense,
                              title: '${expPct.toStringAsFixed(0)}%',
                              radius: 48,
                              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              badgeWidget: _sliceBadge(fmtKip(_totalExpense), const Color(0xFFEF5350)),
                              badgePositionPercentageOffset: 1.5,
                            ),
                        ],
                      )),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('ສຸດທິ',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '${_totalNet < 0 ? '−' : ''}${fmtKip(_totalNet.abs())}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: netPositive
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0xFFEF5350),
                              fontFamily: 'monospace'),
                        ),
                        const Text('₭',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted)),
                      ]),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          if (hasData) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: netPositive
                    ? const Color(0xFF42A5F5).withValues(alpha: 0.07)
                    : const Color(0xFFEF5350).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: netPositive
                        ? const Color(0xFF42A5F5).withValues(alpha: 0.3)
                        : const Color(0xFFEF5350).withValues(alpha: 0.3)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Icon(
                    netPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 12,
                    color: netPositive
                        ? const Color(0xFF42A5F5)
                        : const Color(0xFFEF5350),
                  ),
                  const SizedBox(width: 4),
                  Text('ຍອດທີ່ຕ້ອງຮັບເດືອນໜ້າ',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: netPositive
                              ? const Color(0xFF42A5F5)
                              : const Color(0xFFEF5350))),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${nextProj < 0 ? '−' : ''}${fmtKip(nextProj.abs())} ₭',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: netPositive
                          ? const Color(0xFF42A5F5)
                          : const Color(0xFFEF5350)),
                ),
                const SizedBox(height: 3),
                Text(
                  netPositive
                      ? 'ຮັບ ${fmtKip(_totalIncome)} ₭ (ຄຸ້ມທຶນ, ກຳໄລ ${fmtKip(_totalNet)} ₭)'
                      : 'ຮັບ ${fmtKip(_totalIncome)} ₭ + ຊົດຂາດ ${fmtKip(_totalNet.abs())} ₭',
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textMuted),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildLegendItem(const Color(0xFF4CAF50), 'ລາຍຮັບ'),
              const SizedBox(width: 20),
              _buildLegendItem(const Color(0xFFEF5350), 'ລາຍຈ່າຍ'),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _miniStatBox(
          String label, Color color, String amount, String pct) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('$amount ₭',
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace')),
          Text(pct,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted)),
        ]),
      );

  Widget _sliceBadge(String amount, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.5)),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
      ],
    ),
    child: Text('$amount ₭',
        style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'monospace')),
  );

  Widget _buildLegendItem(Color color, String label) =>
      Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ]);

  // ─── KPI Strip ────────────────────────────────────────────────
  Widget _buildKpiStrip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: const BoxDecoration(
      color: AppColors.bgPrimary,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(children: [
      Expanded(child: _kpiBox('💰 ຮັບເງີນງົບພາກສະໜາມ', _totalIncome, const Color(0xFF4CAF50))),
      const SizedBox(width: 8),
      Expanded(child: _kpiBox('💸 ລາຍຈ່າຍ', _totalExpense, const Color(0xFFEF5350))),
      const SizedBox(width: 8),
      Expanded(child: _kpiBox('📊 ສຸດທິ', _totalNet,
          _totalNet >= 0 ? const Color(0xFF42A5F5) : const Color(0xFFEF5350))),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCA28).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFFFFCA28).withValues(alpha: 0.2)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('📋 ຈຳນວນລາຍການ',
                style: TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 3),
            Text('${_rows.length} ລາຍການ',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFCA28))),
          ]),
        ),
      ),
    ]),
  );

  Widget _kpiBox(String label, double value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppColors.textSecondary)),
      const SizedBox(height: 3),
      Text(
        '${value < 0 ? "−" : ""}${fmtKip(value.abs())} ₭',
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: color),
      ),
    ]),
  );

  // ─── Table ────────────────────────────────────────────────────
  Widget _buildTable() {
    double runBal = 0;
    final rowsWithBal = _rows.map((tx) {
      runBal += tx.income - tx.expense;
      return (tx: tx, bal: runBal);
    }).toList();

    return accTableWrap(
      DataTable(
        headingRowColor:
            WidgetStateProperty.all(AppColors.bgSecondary),
        dataRowColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.hovered)
                ? AppColors.accent.withValues(alpha: 0.05)
                : AppColors.bgSecondary),
        border: TableBorder.all(color: AppColors.border, width: 1),
        columnSpacing: 16,
        columns: [
          accCol('ລ/ດ'),
          accCol('ວ/ດ/ປ'),
          accCol('ໝວດໝູ່'),
          accCol('ເນື້ອໃນ'),
          accCol('ຮັບ (₭)',       numeric: true),
          accCol('ຈ່າຍ (₭)',      numeric: true),
          accCol('ຍອດເຫຼືອ (₭)', numeric: true),
          accCol('ໝາຍເຫດ'),
          accCol('ຈັດການ'),
        ],
        rows: [
          ...rowsWithBal.asMap().entries.map((entry) {
            final idx      = entry.key;
            final tx       = entry.value.tx;
            final bal      = entry.value.bal;
            final isIncome = tx.income > 0;
            return DataRow(cells: [
              DataCell(Text('${idx + 1}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12))),
              DataCell(Text(_formatDate(tx.date),
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace'))),
              DataCell(_catBadge(tx.category)),
              DataCell(Text(tx.desc,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500))),
              DataCell(Text(
                  isIncome ? '${fmtKip(tx.income)} ₭' : '-',
                  style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace'))),
              DataCell(Text(
                  !isIncome ? '${fmtKip(tx.expense)} ₭' : '-',
                  style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace'))),
              DataCell(Text(
                '${bal < 0 ? '−' : ''}${fmtKip(bal.abs())} ₭',
                style: TextStyle(
                    color: bal >= 0
                        ? const Color(0xFF42A5F5)
                        : const Color(0xFFEF5350),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace'),
              )),
              DataCell(Text(
                  tx.note.isEmpty ? '-' : tx.note,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11))),
              DataCell(
                _isLocked
                    ? Tooltip(
                        message: 'ບັນຊີນີ້ຖືກລັອກແລ້ວ',
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.lock_rounded,
                              size: 14, color: Color(0xFF4CAF50)),
                        ),
                      )
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        InkWell(
                          onTap: () =>
                              _showFormDialog(existing: tx),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.3))),
                            child: const Icon(Icons.edit_outlined,
                                size: 14, color: AppColors.accent),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _confirmDelete(tx),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEF5350)
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xFFEF5350)
                                        .withValues(alpha: 0.3))),
                            child: const Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: Color(0xFFEF5350)),
                          ),
                        ),
                      ]),
              ),
            ]);
          }),
          // ── Total row ──
          DataRow(cells: [
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('ລວມ',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600))),
            DataCell(Text('${fmtKip(_totalIncome)} ₭',
                style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace'))),
            DataCell(Text('${fmtKip(_totalExpense)} ₭',
                style: const TextStyle(
                    color: Color(0xFFEF5350),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace'))),
            DataCell(Text(
              '${_totalNet < 0 ? '−' : ''}${fmtKip(_totalNet.abs())} ₭',
              style: TextStyle(
                  color: _totalNet >= 0
                      ? const Color(0xFF42A5F5)
                      : const Color(0xFFEF5350),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace'),
            )),
            const DataCell(Text('')),
            const DataCell(Text('')),
          ]),
        ],
      ),
    );
  }

  // ─── Signature Section ────────────────────────────────────────
  Widget _buildSignatureSection() {
    final locked = _isLocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: locked
            ? const Color(0xFF4CAF50).withValues(alpha: 0.04)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: locked
                ? const Color(0xFF4CAF50).withValues(alpha: 0.45)
                : AppColors.border,
            width: locked ? 1.5 : 1),
      ),
      child: Column(children: [
        if (locked) ...[
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
            ),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Icon(Icons.lock_rounded,
                  size: 14, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text(
                '🔒 ບັນຊີນີ້ຖືກລັອກແລ້ວ — ບໍ່ສາມາດແກ້ໄຂ ຫຼື ລຶບໄດ້',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50)),
              ),
            ]),
          ),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _sigTitles.asMap().entries.map((e) {
            final idx   = e.key;
            final title = e.value;
            return Expanded(
              child: Row(children: [
                if (idx > 0) const SizedBox(width: 12),
                Expanded(
                  child: _signatureBox(
                    title,
                    _sigControllers[title]!,
                    locked: locked,
                  ),
                ),
              ]),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Text(
          'ບໍລິຄຳໄຊ, ວັນທີ ${_now.day}/${_now.month}/${_now.year}',
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),

        if (!locked) ...[
          const SizedBox(height: 20),
          _LockButtonWidget(
            sigControllers: _sigControllers,
            onNotReady: () =>
                _showSnack(context, '⚠️ ກະລຸນາ sign ໃຫ້ຄົບ 4 ຄົນກ່ອນ'),
            onLock: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.bgSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  title: const Row(children: [
                    Icon(Icons.lock_rounded,
                        color: Color(0xFF4CAF50), size: 18),
                    SizedBox(width: 8),
                    Text('ຢືນຢັນການລັອກ',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                  ]),
                  content: const Text(
                    'ເມື່ອລັອກແລ້ວ ຈະບໍ່ສາມາດລຶບ ຫຼື ແກ້ໄຂລາຍການໃດໄດ້ອີກ.\n\nຢືນຢັນຈະລັອກບັນຊີເດືອນນີ້?',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text('ຍົກເລີກ',
                          style: TextStyle(
                              color: AppColors.textMuted)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.lock_rounded,
                          size: 14),
                      label: const Text('ລັອກ'),
                      onPressed: () =>
                          Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _lockCurrentMonth();
                if (mounted) {
                  _showSnack(context,
                      '🔒 ລັອກບັນຊີສຳເລັດ — ຂໍ້ມູນບໍ່ສາມາດແກ້ໄຂ/ລຶບໄດ້ອີກ');
                }
              }
            },
          ),
        ],
      ]),
    );
  }

  Widget _signatureBox(
      String title, SignatureController controller,
      {bool locked = false}) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        if (controller.isNotEmpty && locked) ...[
          const SizedBox(width: 4),
          const Icon(Icons.check_circle,
              size: 11, color: Color(0xFF4CAF50)),
        ],
      ]),
      const SizedBox(height: 12),
      Container(
        height: 70,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: (controller.isNotEmpty && locked)
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: locked
              ? _buildLockedSigDisplay(title, controller)
              : Signature(
                  controller: controller,
                  height: 70,
                  backgroundColor: Colors.white),
        ),
      ),
      const SizedBox(height: 8),
      if (!locked) ...[
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFF4CAF50), width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
                backgroundColor: const Color(0xFF4CAF50)
                    .withValues(alpha: 0.05),
              ),
              onPressed: () {
                if (controller.isEmpty) {
                  _showSnack(
                      context, '❌ ກະລຸນາເຊັນໃນຊ່ອງ "$title" ກ່ອນ');
                  return;
                }
                _showSnack(
                    context, '✅ ບັນທຶກລາຍເຊັນ "$title" ສຳເລັດແລ້ວ');
              },
              child: const Text('ເຊັນ',
                  style: TextStyle(
                      color: Color(0xFF4CAF50), fontSize: 10)),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, size: 14, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => controller.clear(),
            tooltip: 'ລຶບຂຽນໃໝ່',
          ),
        ]),
      ] else ...[
        const SizedBox(height: 4),
        const Icon(Icons.lock_rounded,
            size: 13, color: Color(0xFF4CAF50)),
        const SizedBox(height: 2),
      ],
      const SizedBox(height: 4),
      const Divider(color: AppColors.border, height: 1),
      const SizedBox(height: 6),
      const Text('ຊື່ ແລະ ນາມສະກຸນ...',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
    ]);
  }

  Widget _buildLockedSigDisplay(
      String title, SignatureController controller) {
    final bytes = _savedSigBytes[title];
    if (bytes != null) {
      return Image.memory(bytes as dynamic,
          fit: BoxFit.contain,
          width: double.infinity,
          height: 70);
    }
    return AbsorbPointer(
      absorbing: true,
      child: Signature(
          controller: controller,
          height: 70,
          backgroundColor: Colors.white),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2,'0')}/'
        '${d.month.toString().padLeft(2,'0')}/'
        '${d.year}';
  }

  Widget _catBadge(String cat) {
    const catColors = <String, Color>{
      'ລາຍຮັບພາກສະໜາມ': Color(0xFF4CAF50),
      'ນ້ຳມັນ':           Color(0xFFFF7043),
      'ວັດສະດຸ':          Color(0xFF42A5F5),
      'ອຸປະກອນ':         Color(0xFFAB47BC),
      'ແຮງງານ':           Color(0xFFFFCA28),
      'ຄ່າຂົນສົ່ງ':      Color(0xFF26A69A),
      'ອາຫານ/ນ້ຳ':       Color(0xFF78909C),
    };
    final color = catColors[cat] ?? const Color(0xFF8b949e);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(cat,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));

  Widget _typeChip(String label, String value, Color color,
      String current, ValueChanged<String> onTap) {
    final selected = current == value;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textMuted)),
      ),
    );
  }

  Widget _fieldDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: AppColors.bgSecondary,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.bgPrimary,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.accent)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      );

  Widget _fieldInput(
    TextEditingController ctrl, {
    String hint              = '',
    TextInputType keyboardType = TextInputType.text,
    String? suffix,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          suffixText: suffix,
          suffixStyle: const TextStyle(
              color: AppColors.textMuted, fontSize: 11),
          isDense: true,
          filled: true,
          fillColor: AppColors.bgPrimary,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.accent)),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  _LockButtonWidget — ແຍກ StatefulWidget ສຳລັບ lifecycle
// ═══════════════════════════════════════════════════════════════
class _LockButtonWidget extends StatefulWidget {
  final Map<String, SignatureController> sigControllers;
  final VoidCallback onNotReady;
  final Future<void> Function() onLock;

  const _LockButtonWidget({
    required this.sigControllers,
    required this.onNotReady,
    required this.onLock,
  });

  @override
  State<_LockButtonWidget> createState() => _LockButtonWidgetState();
}

class _LockButtonWidgetState extends State<_LockButtonWidget> {
  final List<VoidCallback> _listeners = [];

  bool get _allSigned =>
      widget.sigControllers.values.every((c) => c.isNotEmpty);

  @override
  void initState() {
    super.initState();
    for (final ctrl in widget.sigControllers.values) {
      void fn() { if (mounted) setState(() {}); }
      _listeners.add(fn);
      ctrl.addListener(fn);
    }
  }

  @override
  void dispose() {
    final ctrls = widget.sigControllers.values.toList();
    for (int i = 0; i < ctrls.length && i < _listeners.length; i++) {
      ctrls[i].removeListener(_listeners[i]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canLock = _allSigned;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: canLock
              ? const Color(0xFF4CAF50)
              : AppColors.bgPrimary,
          foregroundColor:
              canLock ? Colors.white : AppColors.textMuted,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          side: BorderSide(
              color: canLock
                  ? const Color(0xFF4CAF50)
                  : AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: canLock
            ? () => widget.onLock()
            : () => widget.onNotReady(),
        icon: Icon(canLock
            ? Icons.lock_rounded
            : Icons.lock_open_rounded,
            size: 16),
        label: Text(
          canLock
              ? '🔒 ລັອກບັນຊີ (Sign ຄົບແລ້ວ)'
              : '🔓 ລັອກໄດ້ເມື່ອ Sign ຄົບ 4 ຄົນ',
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}