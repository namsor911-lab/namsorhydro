import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// ═══════════════════════════════════════════════════════════════
//  PurchaseScreen — ບັນຊີລາຍການຊື້ເຄື່ອງ (ຮ້ານຄາ)
//  ຮອງຮັບທັງ Mobile ແລະ Web
//  ປັບປຸງ: ຕາຕະລາງກວ້າງເຕັມຈໍ, ເພີ່ມຮູບໃບບິນໄດ້ໃນ Web
// ═══════════════════════════════════════════════════════════════

// ── Colour tokens ──────────────────────────────────────────────
class _C {
  static const bg   = Color(0xFF0D1117);
  static const bg2  = Color(0xFF161B22);
  static const bg3  = Color(0xFF1C2128);
  static const bg4  = Color(0xFF21262D);
  static const bdr  = Color(0xFF30363D);
  static const bdr2 = Color(0xFF21262D);
  static const txt  = Color(0xFFE6EDF3);
  static const txt2 = Color(0xFF8B949E);
  static const txt3 = Color(0xFF484F58);
  static const green     = Color(0xFF3FB950);
  static const greenDim  = Color(0x1F3FB950);
  static const red       = Color(0xFFF85149);
  static const blue      = Color(0xFF58A6FF);
  static const blueDim   = Color(0x1658A6FF);
  static const accent    = Color(0xFF238636);
}

// ── ຄລາສສຳລັບເກັບຂໍ້ມູນຮູບພາບ (ຮອງຮັບທັງ Mobile ແລະ Web) ──
class ImageData {
  final String? path;          // ໃຊ້ກັບ Mobile (File path)
  final Uint8List? bytes;      // ໃຊ້ກັບ Web (ຂໍ້ມູນຮູບ)
  final bool isWeb;

  ImageData({this.path, this.bytes})
      : isWeb = kIsWeb;

  // ກວດສອບວ່າມີຮູບຫຼືບໍ່
  bool get hasImage => path != null || bytes != null;

  // ສ້າງ Widget ສະແດງຮູບຕາມແພລັດຟອມ
  Widget toImageWidget({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (isWeb) {
      if (bytes != null) {
        return Image.memory(
          bytes!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: _C.txt3),
        );
      }
    } else {
      if (path != null && File(path!).existsSync()) {
        return Image.file(
          File(path!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: _C.txt3),
        );
      }
    }
    return const Icon(Icons.broken_image, color: _C.txt3);
  }

  // ສຳເນົາຮູບ (ເພື່ອໃຊ້ໃນການຄັດລອກ)
  ImageData copy() => ImageData(path: path, bytes: bytes);
}

// ── Data model ──────────────────────────────────────────────────
class PurchaseItem {
  final String id;
  final String date;
  final String name;
  final double qty;
  final double price;
  final String unit;
  final String note;
  final ImageData receiptImage;   // ຮູບໃບບິນ
  final ImageData qrImage;        // ຮູບ QR Code

  const PurchaseItem({
    required this.id,
    required this.date,
    required this.name,
    required this.qty,
    required this.price,
    required this.unit,
    required this.note,
    required this.receiptImage,
    required this.qrImage,
  });

  double get total => qty * price;
}

// ── Screen ──────────────────────────────────────────────────────
class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});
  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  // Local state (Mock Data)
  final List<PurchaseItem> _mockItems = [];

  // Form controllers
  final _nameCtrl  = TextEditingController();
  final _qtyCtrl   = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController(text: '0');
  final _unitCtrl  = TextEditingController();
  final _noteCtrl  = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Image data (ຈະຖືກບັນທຶກກ່ອນເພີ່ມ)
  ImageData? _receiptImageData;
  ImageData? _qrImageData;

  // Computed inline total
  double get _inlineTotal {
    final q = double.tryParse(_qtyCtrl.text)   ?? 0;
    final p = double.tryParse(_priceCtrl.text) ?? 0;
    return q * p;
  }

  // Number formatter
  final _fmt = NumberFormat('#,##0', 'en_US');
  String _fmtKip(double n) => '${_fmt.format(n.abs())} ₭';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Pick image (ຮອງຮັບທັງ Mobile ແລະ Web) ─────────────────
  Future<ImageData?> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return null;

      if (kIsWeb) {
        // Web: ອ່ານຂໍ້ມູນຮູບເປັນ Uint8List
        final bytes = await picked.readAsBytes();
        return ImageData(bytes: bytes);
      } else {
        // Mobile: ບັນທຶກໄວ້ໃນ App Directory ແລ້ວເກັບ path
        final dir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(picked.path);
        final fileName = 'img_$timestamp$extension';
        final savedPath = path.join(dir.path, fileName);

        final File savedFile = await File(picked.path).copy(savedPath);
        return ImageData(path: savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('❌ ເກີດຂໍ້ຜິດພາດ: $e', isErr: true);
      }
      return null;
    }
  }

  // ── Add purchase item ──────────────────────────────────────────
  Future<void> _addItem() async {
    final name  = _nameCtrl.text.trim();
    final qty   = double.tryParse(_qtyCtrl.text)   ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;

    if (name.isEmpty || qty <= 0 || price < 0) {
      _showSnack('⚠️ ກະລຸນາປ່ອນ ລາຍຊື່ເຄື່ອງ, ຈຳນວນ ແລະ ລາຄາ ໃຫ້ຄົບຖ້ວນ', isErr: true);
      return;
    }

    // ກວດສອບວ່າຮູບຍັງມີຢູ່ (ສຳລັບ Mobile ກວດ File, Web ກວດ bytes)
    bool receiptValid = false;
    if (_receiptImageData != null) {
      if (kIsWeb) {
        receiptValid = _receiptImageData!.bytes != null;
      } else {
        receiptValid = _receiptImageData!.path != null && File(_receiptImageData!.path!).existsSync();
      }
    }

    bool qrValid = false;
    if (_qrImageData != null) {
      if (kIsWeb) {
        qrValid = _qrImageData!.bytes != null;
      } else {
        qrValid = _qrImageData!.path != null && File(_qrImageData!.path!).existsSync();
      }
    }

    setState(() {
      _mockItems.add(
        PurchaseItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          name: name,
          qty: qty,
          price: price,
          unit: _unitCtrl.text.trim(),
          note: _noteCtrl.text.trim(),
          receiptImage: receiptValid ? _receiptImageData!.copy() : ImageData(),
          qrImage: qrValid ? _qrImageData!.copy() : ImageData(),
        ),
      );

      // Reset ຟອມ
      _nameCtrl.clear();
      _qtyCtrl.text   = '1';
      _priceCtrl.text = '0';
      _unitCtrl.clear();
      _noteCtrl.clear();
      _receiptImageData = null;
      _qrImageData = null;
    });

    _showSnack('✅ ເພີ່ມລາຍການຊື້ເຄື່ອງສຳເລັດ');
  }

  // ── Delete item (ພ້ອມລຶບຮູບສຳລັບ Mobile) ─────────────────
  Future<void> _deleteItem(PurchaseItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.bg2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _C.bdr)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: _C.red, size: 18),
          SizedBox(width: 8),
          Text('ຢືນຢັນລຶບ', style: TextStyle(fontSize: 14, color: _C.txt)),
        ]),
        content: Text('ລຶບ "${item.name}" ອອກຈາກລາຍການ?',
            style: const TextStyle(fontSize: 13, color: _C.txt2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: _C.txt2))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ລຶບ', style: TextStyle(color: _C.red))),
        ],
      ),
    );
    if (ok != true) return;

    // ລຶບຮູບທາງກາຍະພາບ (ສຳລັບ Mobile)
    if (!kIsWeb) {
      if (item.receiptImage.path != null) {
        try {
          final file = File(item.receiptImage.path!);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (item.qrImage.path != null) {
        try {
          final file = File(item.qrImage.path!);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }

    setState(() {
      _mockItems.remove(item);
    });
    _showSnack('🗑️ ລຶບລາຍການ ແລະ ຮູບພາບທີ່ກ່ຽວຂ້ອງແລ້ວ');
  }

  // ── View image fullscreen ──────────────────────────────────────
  void _viewImage(ImageData imageData) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(children: [
          InteractiveViewer(
            child: imageData.toImageWidget(fit: BoxFit.contain),
          ),
          Positioned(
            top: 8, right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Snackbar toast ─────────────────────────────────────────────
  void _showSnack(String msg, {bool isErr = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: isErr ? _C.red.withValues(alpha: 0.9) : _C.bg3,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isErr ? _C.red : _C.bdr)),
        duration: const Duration(seconds: 3),
      ));
  }

  // ── Pick date ──────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _C.green, surface: _C.bg2, onSurface: _C.txt),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildFormCard(),
          const SizedBox(height: 16),
          _buildTableCard(),
        ]),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
    backgroundColor: _C.bg2,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: _C.txt, size: 18),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Row(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF238636), Color(0xFF3FB950)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(Icons.bolt, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NAMSOR HYDRO',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: _C.txt, letterSpacing: 0.5)),
        Text('ບັນຊີລາຍການຊື້ເຄື່ອງ',
            style: TextStyle(fontSize: 10, color: _C.txt3,
                fontWeight: FontWeight.w400)),
      ]),
    ]),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _C.bg3,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.bdr),
        ),
        child: Text(
          DateFormat('d MMM yyyy', 'lo').format(DateTime.now()),
          style: const TextStyle(fontSize: 11, color: _C.txt3,
              fontFamily: 'monospace'),
        ),
      ),
    ],
    bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _C.bdr)),
  );

  // ── Form Card (ມີລຳດັບ 1-8) ──────────────────────────────────
  Widget _buildFormCard() => _Card(
    header: const Row(children: [
      Icon(Icons.add_circle_outline, color: _C.green, size: 16),
      SizedBox(width: 8),
      Text('ເພີ່ມຂໍ້ມູນລາຍການຊື້ເຄື່ອງໃໝ່ (Offline Mode)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.txt)),
    ]),
    child: Column(children: [
      // ── Row A: ວັນທີ + ລາຍຊື່ເຄື່ອງ ──────────────────────────
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 148,
          child: _FieldLabel(
            label: '1. ວັນເດືອນປີ',
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: _C.bg3,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _C.bdr),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: _C.txt2),
                  const SizedBox(width: 6),
                  Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 13, color: _C.txt,
                          fontFamily: 'monospace')),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FieldLabel(
            label: '2. ລາຍຊື່ເຄື່ອງ',
            child: _Input(controller: _nameCtrl, hint: 'ຊື່ເຄື່ອງ...'),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // ── Row B: ຈຳນວນ + ລາຄາ + ຫົວໜ່ວຍ + ໝາຍເຫດ ─────────────
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 1,
          child: _FieldLabel(
            label: '3. ຈຳນວນ',
            child: _Input(
              controller: _qtyCtrl,
              hint: '1',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _FieldLabel(
            label: '4. ລາຄາ (₭)',
            child: _Input(
              controller: _priceCtrl,
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: _FieldLabel(
            label: '5. ຫົວໜ່ວຍ',
            child: _Input(controller: _unitCtrl, hint: 'ອັນ, ຊຸດ...'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _FieldLabel(
            label: '6. ໝາຍເຫດ',
            child: _Input(controller: _noteCtrl, hint: '...'),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // ── Row C: ຮູບໃບບິນ + QR Code ───────────────────────────
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: _FieldLabel(
            label: '7. 📎 ຮູບໃບບິນ / ໃບເກັບເງິນ',
            child: _ImageUploadTile(
              imageData: _receiptImageData,
              icon: Icons.receipt_long_outlined,
              hint: 'ຄລິກເພື່ອເລືອກຮູບໃບບິນ (JPG, PNG)',
              onPick: () async {
                final data = await _pickImage();
                if (data != null) setState(() => _receiptImageData = data);
              },
              onClear: () => setState(() => _receiptImageData = null),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FieldLabel(
            label: '8. 📱 QR Code ຮ້ານ (ໂອນເງິນ)',
            child: _ImageUploadTile(
              imageData: _qrImageData,
              icon: Icons.qr_code_2_outlined,
              hint: 'ຄລິກເພື່ອເລືອກຮູບ QR Code ຂອງຮ້ານ (JPG, PNG)',
              onPick: () async {
                final data = await _pickImage();
                if (data != null) setState(() => _qrImageData = data);
              },
              onClear: () => setState(() => _qrImageData = null),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 16),

      // ── Bottom bar: total + submit ─────────────────────────────
      const Divider(color: _C.bdr, height: 1),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 15, color: _C.txt,
                fontWeight: FontWeight.w700),
            children: [
              const TextSpan(text: 'ຜົນລວມເງິນ: '),
              TextSpan(
                text: _fmtKip(_inlineTotal),
                style: const TextStyle(color: _C.green,
                    fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _C.accent,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: _addItem,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('ເພີ່ມລົງຕາຕະລາງ', style: TextStyle(fontSize: 13)),
        ),
      ]),
    ]),
  );

  // ── Table Card (ກວ້າງເຕັມຈໍ) ──────────────────────────────
  Widget _buildTableCard() {
    final items = _mockItems;
    final grand = items.fold<double>(0, (s, e) => s + e.total);

    return _Card(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(children: [
            Icon(Icons.table_chart_outlined, color: _C.green, size: 16),
            SizedBox(width: 8),
            Text('ຕາຕະລາງລາຍການຊື້ເຄື່ອງ',
                style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: _C.txt)),
          ]),
          Text(
            '${items.length} ລາຍການ',
            style: const TextStyle(fontSize: 12, color: _C.txt3),
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      child: Column(children: [
        // empty
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Text('ຍັງບໍ່ມີລາຍການຊື້ເຄື່ອງ',
                style: TextStyle(color: _C.txt3, fontSize: 13)),
          )
        // table (ກວ້າງເຕັມຈໍ)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // ກຳນົດຄວາມກວ້າງຕາຕະລາງໃຫ້ເຕັມທີ່
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth, // ເຕັມຄວາມກວ້າງຂອງພໍ່ແມ່
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        const Color(0xFF238636).withValues(alpha: 0.7)),
                    dataRowColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.hovered)
                            ? _C.greenDim
                            : Colors.transparent),
                    border: TableBorder.all(color: _C.bdr2, width: 1),
                    columnSpacing: 14,
                    headingTextStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.5),
                    dataTextStyle: const TextStyle(fontSize: 12, color: _C.txt),
                    columns: const [
                      DataColumn(label: Text('ລ/ດ')),
                      DataColumn(label: Text('ວ/ດ/ປ')),
                      DataColumn(label: Text('ລາຍຊື່ເຄື່ອງ')),
                      DataColumn(label: Text('ຈຳນວນ'), numeric: true),
                      DataColumn(label: Text('ລາຄາ (₭)'), numeric: true),
                      DataColumn(label: Text('ຜົນລວມ (₭)'), numeric: true),
                      DataColumn(label: Text('ຫົວໜ່ວຍ')),
                      DataColumn(label: Text('ໝາຍເຫດ')),
                      DataColumn(label: Text('ໃບບິນ')),
                      DataColumn(label: Text('QR Code ຮ້ານ')),
                      DataColumn(label: Text('ຈັດການ')),
                    ],
                    rows: items.asMap().entries.map((e) {
                      final i    = e.key;
                      final item = e.value;
                      return DataRow(cells: [
                        // ລ/ດ
                        DataCell(_NumBadge(n: i + 1)),
                        // ວັນທີ
                        DataCell(Text(item.date,
                            style: const TextStyle(
                                fontSize: 11, color: _C.txt2,
                                fontFamily: 'monospace'))),
                        // ຊື່
                        DataCell(Text(item.name,
                            style: const TextStyle(fontWeight: FontWeight.w500))),
                        // ຈຳນວນ
                        DataCell(Text(_fmt.format(item.qty),
                            style: const TextStyle(fontFamily: 'monospace'))),
                        // ລາຄາ
                        DataCell(Text(_fmtKip(item.price),
                            style: const TextStyle(
                                color: _C.txt2, fontFamily: 'monospace'))),
                        // ຜົນລວມ
                        DataCell(Text(_fmtKip(item.total),
                            style: const TextStyle(
                                color: _C.green, fontWeight: FontWeight.w700,
                                fontFamily: 'monospace'))),
                        // ຫົວໜ່ວຍ
                        DataCell(item.unit.isNotEmpty
                            ? _UnitBadge(label: item.unit)
                            : const Text('-',
                                style: TextStyle(color: _C.txt3))),
                        // ໝາຍເຫດ
                        DataCell(Text(item.note.isNotEmpty ? item.note : '-',
                            style: TextStyle(
                                color: item.note.isNotEmpty ? _C.txt3 : _C.txt3,
                                fontSize: 12))),
                        // ໃບບິນ (ຮອງຮັບທັງ Mobile ແລະ Web)
                        DataCell(
                          item.receiptImage.hasImage
                              ? GestureDetector(
                                  onTap: () => _viewImage(item.receiptImage),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: item.receiptImage.toImageWidget(
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : const Text('-',
                                  style: TextStyle(color: _C.txt3, fontSize: 11)),
                        ),
                        // QR Code (ຮອງຮັບທັງ Mobile ແລະ Web)
                        DataCell(
                          item.qrImage.hasImage
                              ? GestureDetector(
                                  onTap: () => _viewImage(item.qrImage),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: item.qrImage.toImageWidget(
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : const Text('-',
                                  style: TextStyle(color: _C.txt3, fontSize: 11)),
                        ),
                        // ຈັດການ
                        DataCell(IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: _C.red, size: 18),
                          tooltip: 'ລຶບ',
                          onPressed: () => _deleteItem(item),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),

        // Grand total footer
        if (items.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _C.green, width: 2)),
              gradient: LinearGradient(
                colors: [Color(0x303FB950), Color(0x1A3FB950)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('ລວມເງິນທັງໝົດ:  ',
                    style: TextStyle(fontSize: 12, color: _C.txt2,
                        letterSpacing: 0.5)),
                Text(_fmtKip(grand),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: _C.green, fontFamily: 'monospace')),
              ],
            ),
          ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Reusable sub-widgets
// ═══════════════════════════════════════════════════════════════

// ── Card shell ─────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget header;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Card({
    required this.header,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _C.bg2,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _C.bdr),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _C.bdr))),
        child: header,
      ),
      Padding(padding: padding, child: child),
    ]),
  );
}

// ── Field label wrapper ─────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldLabel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(fontSize: 12, color: _C.txt2,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      child,
    ],
  );
}

// ── Text input ─────────────────────────────────────────────────
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;

  const _Input({
    required this.controller,
    this.hint = '',
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13, color: _C.txt),
    cursorColor: _C.blue,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.txt3, fontSize: 13),
      filled: true,
      fillColor: _C.bg3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _C.bdr)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _C.bdr)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _C.blue, width: 1.5)),
    ),
  );
}

// ── Image upload tile (ຮອງຮັບ ImageData) ──────────────────────
class _ImageUploadTile extends StatelessWidget {
  final ImageData? imageData;
  final IconData icon;
  final String hint;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ImageUploadTile({
    required this.imageData,
    required this.icon,
    required this.hint,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // drop zone
      if (imageData == null || !imageData!.hasImage)
        GestureDetector(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.bg3,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _C.bdr, width: 2,
                  style: BorderStyle.solid),
            ),
            child: Column(children: [
              Icon(icon, color: _C.txt3, size: 24),
              const SizedBox(height: 6),
              Text(hint,
                  style: const TextStyle(fontSize: 12, color: _C.txt3),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),

      // preview
      if (imageData != null && imageData!.hasImage)
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageData!.toImageWidget(
              width: double.infinity,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ]),
    ],
  );
}

// ── Row number badge ───────────────────────────────────────────
class _NumBadge extends StatelessWidget {
  final int n;
  const _NumBadge({required this.n});

  @override
  Widget build(BuildContext context) => Container(
    width: 22, height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _C.bg4,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _C.bdr),
    ),
    child: Text('$n',
        style: const TextStyle(fontSize: 11, color: _C.txt3,
            fontWeight: FontWeight.w600, fontFamily: 'monospace')),
  );
}

// ── Unit badge ─────────────────────────────────────────────────
class _UnitBadge extends StatelessWidget {
  final String label;
  const _UnitBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: _C.blueDim,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: const TextStyle(fontSize: 11, color: _C.blue,
            fontWeight: FontWeight.w600)),
  );
}