// create_invoice_screen.dart
// ໃບແຈ້ງໜີ້ ສຳລັບທີ່ຢູ່ເຂື່ອນໄຟຟ້າພະລິດໄຟຂາຍ

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// CreateInvoiceScreen — ສ້າງໃບແຈ້ງໜີ້ເຂື່ອນໄຟຟ້າ
// ─────────────────────────────────────────────────────────────
class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Controllers ──
  final _invoiceNoCtrl   = TextEditingController();
  final _issueDateCtrl   = TextEditingController();
  final _dueDateCtrl     = TextEditingController();
  final _periodFromCtrl  = TextEditingController();
  final _periodToCtrl    = TextEditingController();

  // Buyer
  final _buyerNameCtrl   = TextEditingController();
  final _buyerAddrCtrl   = TextEditingController();
  final _buyerTaxCtrl    = TextEditingController();
  final _buyerContactCtrl= TextEditingController();
  final _buyerEmailCtrl  = TextEditingController();

  // Power Data
  final _contractMWCtrl  = TextEditingController();
  final _actualMWhCtrl   = TextEditingController();
  final _peakMWhCtrl     = TextEditingController();
  final _offPeakMWhCtrl  = TextEditingController();
  final _unitPriceCtrl   = TextEditingController();
  final _peakPriceCtrl   = TextEditingController();
  final _offPeakPriceCtrl= TextEditingController();

  // Bank
  final _bankNameCtrl    = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNoCtrl   = TextEditingController();
  final _swiftCtrl       = TextEditingController();
  final _remarkCtrl      = TextEditingController();

  // Dropdown
  String _currency       = 'USD';
  String _buyerType      = 'EDL'; // EDL / EGAT / Private
  String _invoiceType    = 'Monthly Energy'; // Monthly Energy / Capacity / Penalty
  String _taxRate        = '10%';
  bool   _usePeakOffPeak = false;
  bool   _includeTax     = true;
  bool   _includeCapacity= false;

  // Capacity
  final _capacityMWCtrl  = TextEditingController();
  final _capacityPriceCtrl = TextEditingController();

  // Penalty
  final _penaltyCtrl     = TextEditingController();
  final _penaltyReasonCtrl = TextEditingController();

  // Seller (ເຂື່ອນ)
  final _damNameCtrl     = TextEditingController(text: 'ບໍລິສັດ ເຂື່ອນໄຟຟ້າ XXX ຈຳກັດ');
  final _damAddrCtrl     = TextEditingController(text: 'ສ.ປ.ປ. ລາວ');
  final _damTaxCtrl      = TextEditingController();
  final _damContactCtrl  = TextEditingController();

  final List<String> _currencies   = ['USD', 'LAK', 'THB', 'CNY'];
  final List<String> _buyerTypes   = ['EDL', 'EGAT', 'PEA', 'Private'];
  final List<String> _invoiceTypes = ['Monthly Energy', 'Capacity Charge', 'Penalty / Adjustment', 'Mixed'];
  final List<String> _taxRates     = ['0%', '7%', '10%'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateInvoiceNo();
    _issueDateCtrl.text = _formatDate(DateTime.now());
    _dueDateCtrl.text   = _formatDate(DateTime.now().add(const Duration(days: 30)));
  }

  void _generateInvoiceNo() {
    final now = DateTime.now();
    _invoiceNoCtrl.text =
        'INV-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.millisecond.toString().padLeft(4, '0')}';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  // ── Calculation ──
  double get _energyAmount {
    if (_usePeakOffPeak) {
      final peak    = double.tryParse(_peakMWhCtrl.text)    ?? 0;
      final offPeak = double.tryParse(_offPeakMWhCtrl.text) ?? 0;
      final pPrice  = double.tryParse(_peakPriceCtrl.text)  ?? 0;
      final oPrice  = double.tryParse(_offPeakPriceCtrl.text) ?? 0;
      return (peak * pPrice) + (offPeak * oPrice);
    }
    final mwh   = double.tryParse(_actualMWhCtrl.text)  ?? 0;
    final price = double.tryParse(_unitPriceCtrl.text)  ?? 0;
    return mwh * price;
  }

  double get _capacityAmount {
    if (!_includeCapacity) return 0;
    final mw    = double.tryParse(_capacityMWCtrl.text)    ?? 0;
    final price = double.tryParse(_capacityPriceCtrl.text) ?? 0;
    return mw * price;
  }

  double get _penaltyAmount => double.tryParse(_penaltyCtrl.text) ?? 0;

  double get _subtotal => _energyAmount + _capacityAmount - _penaltyAmount;

  double get _taxAmount {
    if (!_includeTax) return 0;
    final rate = double.tryParse(_taxRate.replaceAll('%', '')) ?? 0;
    return _subtotal * rate / 100;
  }

  double get _total => _subtotal + _taxAmount;

  String _fmt(double v) {
    if (_currency == 'LAK') {
      return v.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
    }
    return v.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTab1_GeneralInfo(),
                _buildTab2_PowerData(),
                _buildTab3_Charges(),
                _buildTab4_Preview(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgSecondary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.accent),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF81C784).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_long, color: Color(0xFF81C784), size: 20),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ສ້າງໃບແຈ້ງໜີ້',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text('Create Invoice — Hydropower Plant',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currency,
              isDense: true,
              style: const TextStyle(fontSize: 12, color: AppColors.success,
                  fontWeight: FontWeight.w700),
              dropdownColor: AppColors.bgSecondary,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.success, size: 16),
              items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.bgSecondary,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.accent,
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline, size: 16), text: 'ຂໍ້ມູນທົ່ວໄປ'),
          Tab(icon: Icon(Icons.bolt_outlined, size: 16), text: 'ຂໍ້ມູນໄຟຟ້າ'),
          Tab(icon: Icon(Icons.attach_money, size: 16), text: 'ຄ່າທຳນຽມ'),
          Tab(icon: Icon(Icons.preview_outlined, size: 16), text: 'ສະຫລຸບ'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1 — ຂໍ້ມູນທົ່ວໄປ
  // ═══════════════════════════════════════════
  Widget _buildTab1_GeneralInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Invoice Meta
        _sectionCard(
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF81C784),
          title: 'ຂໍ້ມູນໃບແຈ້ງໜີ້',
          subtitle: 'Invoice Information',
          children: [
            Row(children: [
              Expanded(child: _field('ເລກທີ່ໃບແຈ້ງໜີ້', 'Invoice No.', _invoiceNoCtrl,
                  suffix: IconButton(
                    icon: const Icon(Icons.refresh, size: 16, color: AppColors.accent),
                    onPressed: () { setState(_generateInvoiceNo); },
                  ))),
              const SizedBox(width: 12),
              Expanded(child: _dropdown('ປະເພດໃບແຈ້ງໜີ້', 'Type', _invoiceType,
                  _invoiceTypes, (v) => setState(() => _invoiceType = v!))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dateField('ວັນທີ່ອອກ', 'Issue Date', _issueDateCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _dateField('ວັນຄົບກຳນົດ', 'Due Date', _dueDateCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dateField('ໄລຍະ: ຈາກ', 'Period From', _periodFromCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _dateField('ໄລຍະ: ຫາ', 'Period To', _periodToCtrl)),
            ]),
          ],
        ),

        const SizedBox(height: 14),

        // Seller (Dam)
        _sectionCard(
          icon: Icons.factory_outlined,
          color: const Color(0xFF4FC3F7),
          title: 'ຜູ້ຂາຍ (ເຂື່ອນໄຟຟ້າ)',
          subtitle: 'Seller — Power Plant',
          children: [
            _field('ຊື່ບໍລິສັດ', 'Company Name', _damNameCtrl),
            const SizedBox(height: 12),
            _field('ທີ່ຢູ່ / ທີ່ຕັ້ງເຂື່ອນ', 'Address / Dam Location', _damAddrCtrl, maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('ເລກທະບຽນພາສີ', 'Tax ID', _damTaxCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _field('ຕິດຕໍ່', 'Contact', _damContactCtrl)),
            ]),
          ],
        ),

        const SizedBox(height: 14),

        // Buyer
        _sectionCard(
          icon: Icons.business_outlined,
          color: const Color(0xFFFFB74D),
          title: 'ຜູ້ຊື້ໄຟຟ້າ',
          subtitle: 'Power Buyer',
          children: [
            Row(children: [
              Expanded(child: _dropdown('ປະເພດຜູ້ຊື້', 'Buyer Type', _buyerType,
                  _buyerTypes, (v) => setState(() => _buyerType = v!))),
              const SizedBox(width: 12),
              Expanded(child: _field('ຊື່ບໍລິສັດ/ອົງກອນ', 'Buyer Name', _buyerNameCtrl)),
            ]),
            const SizedBox(height: 12),
            _field('ທີ່ຢູ່', 'Address', _buyerAddrCtrl, maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('ເລກທະບຽນພາສີ', 'Tax ID', _buyerTaxCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _field('ອີເມວ', 'Email', _buyerEmailCtrl,
                  keyboardType: TextInputType.emailAddress)),
            ]),
            const SizedBox(height: 12),
            _field('ຜູ້ຕິດຕໍ່', 'Contact Person', _buyerContactCtrl),
          ],
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 2 — ຂໍ້ມູນໄຟຟ້າ
  // ═══════════════════════════════════════════
  Widget _buildTab2_PowerData() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Contract Info
        _sectionCard(
          icon: Icons.bolt_outlined,
          color: const Color(0xFF4FC3F7),
          title: 'ຂໍ້ມູນສັນຍາ & ການຜະລິດ',
          subtitle: 'Contract & Generation Data',
          children: [
            Row(children: [
              Expanded(child: _numberField('ກຳລັງສັນຍາ (MW)', 'Contract Capacity MW', _contractMWCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _numberField('ພະລັງງານຕົວຈິງ (MWh)', 'Actual Energy MWh', _actualMWhCtrl,
                  onChanged: (_) => setState((){}),)),
            ]),
            const SizedBox(height: 14),
            // Peak / Off-Peak Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('ແຍກ Peak / Off-Peak',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ),
                Switch(
                  value: _usePeakOffPeak,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setState(() => _usePeakOffPeak = v),
                ),
              ]),
            ),

            if (_usePeakOffPeak) ...[
              const SizedBox(height: 12),
              // Peak Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.25)),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.wb_sunny_outlined, size: 15, color: Color(0xFFFF7043)),
                    const SizedBox(width: 6),
                    const Text('ຊ່ວງ Peak (On-Peak)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: Color(0xFFFF7043))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _numberField('MWh Peak', 'Peak MWh', _peakMWhCtrl,
                        onChanged: (_) => setState((){}))),
                    const SizedBox(width: 10),
                    Expanded(child: _numberField('ລາຄາ/MWh', 'Price/MWh', _peakPriceCtrl,
                        onChanged: (_) => setState((){}))),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),
              // Off-Peak Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.25)),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.nights_stay_outlined, size: 15, color: Color(0xFF42A5F5)),
                    const SizedBox(width: 6),
                    const Text('ຊ່ວງ Off-Peak',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: Color(0xFF42A5F5))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _numberField('MWh Off-Peak', 'Off-Peak MWh', _offPeakMWhCtrl,
                        onChanged: (_) => setState((){}))),
                    const SizedBox(width: 10),
                    Expanded(child: _numberField('ລາຄາ/MWh', 'Price/MWh', _offPeakPriceCtrl,
                        onChanged: (_) => setState((){}))),
                  ]),
                ]),
              ),
            ] else ...[
              const SizedBox(height: 12),
              _numberField('ລາຄາຂາຍ/MWh ($_currency)', 'Unit Price per MWh', _unitPriceCtrl,
                  onChanged: (_) => setState((){})),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // Live Summary Card
        _sectionCard(
          icon: Icons.calculate_outlined,
          color: const Color(0xFF81C784),
          title: 'ສະຫລຸບຄ່າໄຟ',
          subtitle: 'Energy Charge Summary',
          children: [
            _summaryRow('ຈຳນວນ MWh', _usePeakOffPeak
                ? '${(double.tryParse(_peakMWhCtrl.text) ?? 0) + (double.tryParse(_offPeakMWhCtrl.text) ?? 0)} MWh'
                : '${_actualMWhCtrl.text.isEmpty ? "0" : _actualMWhCtrl.text} MWh'),
            _summaryRow('ມູນຄ່າພະລັງງານ', '$_currency ${_fmt(_energyAmount)}',
                highlight: true),
          ],
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 3 — ຄ່າທຳນຽມ & ພາສີ
  // ═══════════════════════════════════════════
  Widget _buildTab3_Charges() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Capacity Charge
        _sectionCard(
          icon: Icons.electric_bolt_outlined,
          color: const Color(0xFFBA68C8),
          title: 'ຄ່າກຳລັງການຜະລິດ',
          subtitle: 'Capacity Charge',
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.power_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Expanded(child: Text('ລວມຄ່າກຳລັງ (Capacity)',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                Switch(
                  value: _includeCapacity,
                  activeColor: const Color(0xFFBA68C8),
                  onChanged: (v) => setState(() => _includeCapacity = v),
                ),
              ]),
            ),
            if (_includeCapacity) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _numberField('ກຳລັງ (MW)', 'Capacity MW', _capacityMWCtrl,
                    onChanged: (_) => setState((){}))),
                const SizedBox(width: 12),
                Expanded(child: _numberField('ລາຄາ/MW/ເດືອນ', 'Price/MW/Month', _capacityPriceCtrl,
                    onChanged: (_) => setState((){}))),
              ]),
              const SizedBox(height: 8),
              _summaryRow('ຄ່າກຳລັງ', '$_currency ${_fmt(_capacityAmount)}', highlight: true),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // Penalty / Adjustment
        _sectionCard(
          icon: Icons.remove_circle_outline,
          color: const Color(0xFFF06292),
          title: 'ຫັກ / ປັບ (Penalty & Deductions)',
          subtitle: 'Penalty & Adjustments',
          children: [
            _numberField('ຈຳນວນທີ່ຫັກ ($_currency)', 'Deduction Amount', _penaltyCtrl,
                onChanged: (_) => setState((){})),
            const SizedBox(height: 12),
            _field('ເຫດຜົນ', 'Reason for Deduction', _penaltyReasonCtrl, maxLines: 2),
          ],
        ),

        const SizedBox(height: 14),

        // Tax
        _sectionCard(
          icon: Icons.account_balance_outlined,
          color: const Color(0xFFFFD54F),
          title: 'ພາສີ & ອາກອນ',
          subtitle: 'Tax & VAT',
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.percent_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Expanded(child: Text('ລວມ VAT / ອາກອນ',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                Switch(
                  value: _includeTax,
                  activeColor: const Color(0xFFFFD54F),
                  onChanged: (v) => setState(() => _includeTax = v),
                ),
              ]),
            ),
            if (_includeTax) ...[
              const SizedBox(height: 12),
              _dropdown('ອັດຕາພາສີ', 'Tax Rate', _taxRate, _taxRates,
                  (v) => setState(() => _taxRate = v!)),
              const SizedBox(height: 8),
              _summaryRow('ພາສີ', '$_currency ${_fmt(_taxAmount)}'),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // Bank Account
        _sectionCard(
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF4DB6AC),
          title: 'ບັນຊີຮັບເງິນ',
          subtitle: 'Payment Bank Account',
          children: [
            _field('ຊື່ທະນາຄານ', 'Bank Name', _bankNameCtrl),
            const SizedBox(height: 12),
            _field('ຊື່ບັນຊີ', 'Account Name', _accountNameCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('ເລກບັນຊີ', 'Account No.', _accountNoCtrl,
                  keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field('SWIFT / BIC', 'SWIFT Code', _swiftCtrl)),
            ]),
            const SizedBox(height: 12),
            _field('ໝາຍເຫດ / ເລກອ້າງອີງ', 'Remark / Reference', _remarkCtrl, maxLines: 3),
          ],
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 4 — ສະຫລຸບ & ພິມ
  // ═══════════════════════════════════════════
  Widget _buildTab4_Preview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Invoice Header Preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_damNameCtrl.text.isEmpty ? 'ຊື່ບໍລິສັດ...' : _damNameCtrl.text,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text(_damAddrCtrl.text.isEmpty ? 'ທີ່ຢູ່...' : _damAddrCtrl.text,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('INVOICE', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w900, color: Color(0xFF81C784))),
                Text(_invoiceNoCtrl.text,
                    style: const TextStyle(fontSize: 12, color: AppColors.accent)),
              ]),
            ]),

            Divider(height: 24, color: AppColors.border),

            // Buyer / Date Info
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _previewLabel('ຜູ້ຊື້ (Bill To)'),
                _previewValue(_buyerNameCtrl.text.isEmpty ? '-' : _buyerNameCtrl.text),
                _previewValue(_buyerAddrCtrl.text.isEmpty ? '' : _buyerAddrCtrl.text),
                _previewValue(_buyerTaxCtrl.text.isEmpty ? '' : 'Tax: ${_buyerTaxCtrl.text}'),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _previewRowKV('ວັນທີ່ອອກ:', _issueDateCtrl.text),
                _previewRowKV('ຄົບກຳນົດ:', _dueDateCtrl.text),
                _previewRowKV('ໄລຍະ:', '${_periodFromCtrl.text} - ${_periodToCtrl.text}'),
                _previewRowKV('ສະກຸນເງິນ:', _currency),
              ]),
            ]),

            Divider(height: 20, color: AppColors.border),

            // Line Items
            _previewTableHeader(),
            if (_usePeakOffPeak) ...[
              _previewLine('Peak Energy',
                  '${_peakMWhCtrl.text} MWh',
                  _peakPriceCtrl.text,
                  (double.tryParse(_peakMWhCtrl.text) ?? 0) * (double.tryParse(_peakPriceCtrl.text) ?? 0)),
              _previewLine('Off-Peak Energy',
                  '${_offPeakMWhCtrl.text} MWh',
                  _offPeakPriceCtrl.text,
                  (double.tryParse(_offPeakMWhCtrl.text) ?? 0) * (double.tryParse(_offPeakPriceCtrl.text) ?? 0)),
            ] else
              _previewLine('ພະລັງງານ (Energy)',
                  '${_actualMWhCtrl.text} MWh',
                  _unitPriceCtrl.text,
                  _energyAmount),

            if (_includeCapacity)
              _previewLine('Capacity Charge',
                  '${_capacityMWCtrl.text} MW',
                  _capacityPriceCtrl.text,
                  _capacityAmount),

            if (_penaltyAmount != 0)
              _previewLine('ຫັກ (Deduction)',
                  _penaltyReasonCtrl.text,
                  '',
                  -_penaltyAmount,
                  isDeduct: true),

            Divider(height: 16, color: AppColors.border),

            // Totals
            _totalRow('Subtotal', _subtotal),
            if (_includeTax) _totalRow('VAT ($_taxRate)', _taxAmount),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL AMOUNT DUE',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text('$_currency ${_fmt(_total)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                        color: Color(0xFF81C784))),
              ]),
            ),

            if (_bankNameCtrl.text.isNotEmpty || _accountNoCtrl.text.isNotEmpty) ...[
              Divider(height: 20, color: AppColors.border),
              _previewLabel('ຂໍ້ມູນການຊຳລະ (Payment Details)'),
              if (_bankNameCtrl.text.isNotEmpty)
                _previewValue('ທະນາຄານ: ${_bankNameCtrl.text}'),
              if (_accountNameCtrl.text.isNotEmpty)
                _previewValue('ຊື່ບັນຊີ: ${_accountNameCtrl.text}'),
              if (_accountNoCtrl.text.isNotEmpty)
                _previewValue('ເລກບັນຊີ: ${_accountNoCtrl.text}'),
              if (_swiftCtrl.text.isNotEmpty)
                _previewValue('SWIFT: ${_swiftCtrl.text}'),
            ],

            if (_remarkCtrl.text.isNotEmpty) ...[
              Divider(height: 20, color: AppColors.border),
              _previewLabel('ໝາຍເຫດ (Remark)'),
              _previewValue(_remarkCtrl.text),
            ],
          ]),
        ),

        const SizedBox(height: 12),

        // Signature Boxes
        Row(children: [
          Expanded(child: _signatureBox('ຜູ້ອອກໃບແຈ້ງໜີ້\nIssued By')),
          const SizedBox(width: 12),
          Expanded(child: _signatureBox('ຜູ້ອະນຸມັດ\nApproved By')),
          const SizedBox(width: 12),
          Expanded(child: _signatureBox('ຜູ້ຮັບ\nReceived By')),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Amount display
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('ຍອດລວມທັງໝົດ:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('$_currency ${_fmt(_total)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: Color(0xFF81C784))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('ບັນທຶກ Draft', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _printPreview,
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('ພິມ / PDF', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _submitInvoice,
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('ສົ່ງໃບແຈ້ງໜີ້', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81C784),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────
  // HELPERS — UI Widgets
  // ─────────────────────────────────────────
  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ]),
        ]),
        Divider(height: 16, color: AppColors.border),
        ...children,
      ]),
    );
  }

  Widget _field(String label, String hint, TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: AppColors.bgPrimary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
        onChanged: (_) => setState((){}),
      ),
    ]);
  }

  Widget _numberField(String label, String hint, TextEditingController ctrl, {
    void Function(String)? onChanged,
  }) {
    return _field(label, hint, ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true));
  }

  Widget _dateField(String label, String hint, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        readOnly: true,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.accent),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: AppColors.bgPrimary,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.accent)),
        ),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
            builder: (ctx, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(primary: AppColors.accent),
              ),
              child: child!,
            ),
          );
          if (d != null) setState(() => ctrl.text = _formatDate(d));
        },
      ),
    ]);
  }

  Widget _dropdown(String label, String hint, String value, List<String> items,
      void Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            dropdownColor: AppColors.bgSecondary,
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 11,
            color: highlight ? AppColors.textPrimary : AppColors.textSecondary)),
        Text(value, style: TextStyle(
            fontSize: 12,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? const Color(0xFF81C784) : AppColors.textSecondary)),
      ]),
    );
  }

  // Preview Helpers
  Widget _previewLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary)),
  );

  Widget _previewValue(String t) => t.isEmpty ? const SizedBox() : Text(t,
      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary));

  Widget _previewRowKV(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(children: [
      Text(k, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      const SizedBox(width: 6),
      Text(v, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary)),
    ]),
  );

  Widget _previewTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(children: [
        Expanded(flex: 3, child: Text('ລາຍການ', style: TextStyle(fontSize: 10,
            fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('ປະລິມານ', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('ລາຄາ/ໜ່ວຍ', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('ຈຳນວນ', textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
      ]),
    );
  }

  Widget _previewLine(String name, String qty, String price, double amount,
      {bool isDeduct = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(children: [
        Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 11,
            color: AppColors.textPrimary))),
        Expanded(flex: 2, child: Text(qty, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text(price.isEmpty ? '-' : price,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('${isDeduct ? "-" : ""}${_fmt(amount.abs())}',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: isDeduct ? const Color(0xFFF06292) : AppColors.textPrimary))),
      ]),
    );
  }

  Widget _totalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text('$_currency ${_fmt(amount)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _signatureBox(String label) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────
  void _saveDraft() {
    _showSnack('ບັນທຶກ Draft ສຳເລັດ ✓', AppColors.accent);
  }

  void _printPreview() {
    _showSnack('ກຳລັງສ້າງ PDF... (ຟັງຊັ່ນນີ້ຕ້ອງເຊື່ອມ print plugin)', AppColors.textSecondary);
  }

  void _submitInvoice() {
    if (_buyerNameCtrl.text.isEmpty) {
      _showSnack('⚠ ກະລຸນາໃສ່ຊື່ຜູ້ຊື້', const Color(0xFFFF7043));
      return;
    }
    if (_invoiceNoCtrl.text.isEmpty) {
      _showSnack('⚠ ກະລຸນາໃສ່ເລກທີ່ໃບແຈ້ງໜີ້', const Color(0xFFFF7043));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border)),
        title: const Row(children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF81C784), size: 22),
          SizedBox(width: 8),
          Text('ຢືນຢັນສົ່ງໃບແຈ້ງໜີ້', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dialogRow('ເລກທີ່:', _invoiceNoCtrl.text),
          _dialogRow('ຜູ້ຊື້:', _buyerNameCtrl.text),
          _dialogRow('ຍອດລວມ:', '$_currency ${_fmt(_total)}'),
          _dialogRow('ວັນຄົບກຳນົດ:', _dueDateCtrl.text),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _showSnack('ສົ່ງໃບແຈ້ງໜີ້ ${_invoiceNoCtrl.text} ສຳເລັດ ✓',
                  const Color(0xFF81C784));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
            child: const Text('ຢືນຢັນ / Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text(k, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(width: 8),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
    ]),
  );

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _invoiceNoCtrl, _issueDateCtrl, _dueDateCtrl, _periodFromCtrl, _periodToCtrl,
      _buyerNameCtrl, _buyerAddrCtrl, _buyerTaxCtrl, _buyerContactCtrl, _buyerEmailCtrl,
      _contractMWCtrl, _actualMWhCtrl, _peakMWhCtrl, _offPeakMWhCtrl,
      _unitPriceCtrl, _peakPriceCtrl, _offPeakPriceCtrl,
      _bankNameCtrl, _accountNameCtrl, _accountNoCtrl, _swiftCtrl, _remarkCtrl,
      _capacityMWCtrl, _capacityPriceCtrl, _penaltyCtrl, _penaltyReasonCtrl,
      _damNameCtrl, _damAddrCtrl, _damTaxCtrl, _damContactCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }
}