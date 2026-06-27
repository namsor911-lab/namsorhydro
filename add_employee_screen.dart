// add_employee_screen.dart
// ຟອມເພີ່ມພະນັກງານໃໝ່ — ຄົບສົມບຸນ

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // ── Controllers ──
  final _idCtrl         = TextEditingController();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _nickCtrl       = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _positionCtrl   = TextEditingController();
  final _salaryCtrl     = TextEditingController();
  final _bankCtrl       = TextEditingController();
  final _accountCtrl    = TextEditingController();
  final _emergNameCtrl  = TextEditingController();
  final _emergPhoneCtrl = TextEditingController();
  final _noteCtrl       = TextEditingController();

  // ── Dropdowns ──
  String _gender       = 'ຊາຍ';
  String _department   = 'ຜະລິດໄຟຟ້າ';
  String _employType   = 'ພະນັກງານປະຈຳ';
  String _shift        = 'Shift 1';
  String _status       = 'ເຮັດວຽກ';
  String _nationality  = 'ລາວ';
  String _education    = 'ປະລິນຍາຕີ';
  DateTime? _dob;
  DateTime? _startDate;
  DateTime? _contractEnd;

  final List<String> _departments = ['ຜະລິດໄຟຟ້າ', 'SCADA', 'ບຳລຸງຮັກສາ', 'ການເງິນ', 'HSE', 'ບໍລິຫານ', 'IT'];
  final List<String> _shifts      = ['Shift 1', 'Shift 2', 'Shift 3', 'Shift 4', '-'];
  final List<String> _empTypes    = ['ພະນັກງານປະຈຳ', 'ພະນັກງານສັນຍາ', 'ພະນັກງານທົດລອງ', 'ແຮງງານຊົ່ວຄາວ'];
  final List<String> _educations  = ['ມັດທະຍົມ', 'ອາຊີວະສຶກສາ', 'ອະນຸປະລິນຍາ', 'ປະລິນຍາຕີ', 'ປະລິນຍາໂທ', 'ປະລິນຍາເອກ'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _idCtrl.text = 'NS-0${(DateTime.now().millisecond % 900 + 100)}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [_idCtrl, _firstNameCtrl, _lastNameCtrl, _nickCtrl,
      _phoneCtrl, _emailCtrl, _addressCtrl, _positionCtrl, _salaryCtrl,
      _bankCtrl, _accountCtrl, _emergNameCtrl, _emergPhoneCtrl, _noteCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTab1Personal(),
                  _buildTab2Work(),
                  _buildTab3Finance(),
                  _buildTab4Extra(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add_outlined, color: Color(0xFF4FC3F7), size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ເພີ່ມພະນັກງານໃໝ່',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('Add New Employee', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(_idCtrl.text,
                style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── TabBar ──
  Widget _buildTabBar() {
    return Container(
      color: AppColors.bgSecondary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accent,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.person_outline, size: 16),       text: 'ຂໍ້ມູນສ່ວນຕົວ'),
          Tab(icon: Icon(Icons.work_outline, size: 16),          text: 'ຂໍ້ມູນວຽກ'),
          Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 16), text: 'ການເງິນ'),
          Tab(icon: Icon(Icons.more_horiz, size: 16),            text: 'ເພີ່ມເຕີມ'),
        ],
      ),
    );
  }

  // ────────────────────────────────
  // Tab 1 — ຂໍ້ມູນສ່ວນຕົວ
  // ────────────────────────────────
  Widget _buildTab1Personal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.person_outline, 'ຂໍ້ມູນພື້ນຖານ', 'Basic Information'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('ຊື່ (ພາສາລາວ)*', _firstNameCtrl, required: true)),
            const SizedBox(width: 12),
            Expanded(child: _field('ນາມສະກຸນ (ພາສາລາວ)*', _lastNameCtrl, required: true)),
            const SizedBox(width: 12),
            Expanded(child: _field('ຊື່ຫຼີ້ນ', _nickCtrl)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dropdown('ເພດ*', _gender, ['ຊາຍ', 'ຍິງ', 'ອື່ນໆ'], (v) => setState(() => _gender = v!))),
            const SizedBox(width: 12),
            Expanded(child: _datePicker('ວັນເດືອນປີເກີດ*', _dob, (d) => setState(() => _dob = d))),
            const SizedBox(width: 12),
            Expanded(child: _dropdown('ສັນຊາດ', _nationality, ['ລາວ', 'ໄທ', 'ຈີນ', 'ຫວຽດ', 'ອື່ນໆ'], (v) => setState(() => _nationality = v!))),
          ]),
          const SizedBox(height: 20),
          _sectionTitle(Icons.contact_phone_outlined, 'ຂໍ້ມູນຕິດຕໍ່', 'Contact Information'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('ເບີໂທລະສັບ*', _phoneCtrl, required: true, keyboardType: TextInputType.phone)),
            const SizedBox(width: 12),
            Expanded(child: _field('ອີເມລ', _emailCtrl, keyboardType: TextInputType.emailAddress)),
          ]),
          const SizedBox(height: 12),
          _field('ທີ່ຢູ່', _addressCtrl, maxLines: 2),
          const SizedBox(height: 20),
          _sectionTitle(Icons.school_outlined, 'ການສຶກສາ', 'Education'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _dropdown('ລະດັບການສຶກສາ', _education, _educations, (v) => setState(() => _education = v!))),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),
        ],
      ),
    );
  }

  // ────────────────────────────────
  // Tab 2 — ຂໍ້ມູນວຽກ
  // ────────────────────────────────
  Widget _buildTab2Work() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.work_outline, 'ຂໍ້ມູນຕຳແໜ່ງ', 'Position Information'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('ລະຫັດພະນັກງານ*', _idCtrl, required: true)),
            const SizedBox(width: 12),
            Expanded(child: _field('ຕຳແໜ່ງ*', _positionCtrl, required: true)),
            const SizedBox(width: 12),
            Expanded(child: _dropdown('ພະແນກ*', _department, _departments, (v) => setState(() => _department = v!))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dropdown('ປະເພດພະນັກງານ', _employType, _empTypes, (v) => setState(() => _employType = v!))),
            const SizedBox(width: 12),
            Expanded(child: _dropdown('ຍາມ (Shift)', _shift, _shifts, (v) => setState(() => _shift = v!))),
            const SizedBox(width: 12),
            Expanded(child: _dropdown('ສະຖານະ', _status, ['ເຮັດວຽກ', 'ທົດລອງ', 'ລາພັກ'], (v) => setState(() => _status = v!))),
          ]),
          const SizedBox(height: 20),
          _sectionTitle(Icons.calendar_month_outlined, 'ວັນທີ່ສັນຍາ', 'Contract Dates'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _datePicker('ວັນເລີ່ມງານ*', _startDate, (d) => setState(() => _startDate = d))),
            const SizedBox(width: 12),
            Expanded(child: _datePicker('ວັນໝົດສັນຍາ', _contractEnd, (d) => setState(() => _contractEnd = d))),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 20),
          // Progress indicator tab
          _sectionTitle(Icons.checklist_outlined, 'ເອກະສານທີ່ຕ້ອງການ', 'Required Documents'),
          const SizedBox(height: 12),
          _docCheckItem('ສຳເນົາ ທະບ. ຄົວເຮືອນ'),
          _docCheckItem('ສຳເນົາ ບັດປະຈຳຕົວ'),
          _docCheckItem('ໃບຢັ້ງຢືນວຸດທິ'),
          _docCheckItem('ຮູບ 3x4 (2 ໃບ)'),
          _docCheckItem('ໃບກວດສຸຂະພາບ'),
        ],
      ),
    );
  }

  bool _doc1 = false, _doc2 = false, _doc3 = false, _doc4 = false, _doc5 = false;

  Widget _docCheckItem(String label) {
    final map = {
      'ສຳເນົາ ທະບ. ຄົວເຮືອນ': [_doc1, (v) => setState(() => _doc1 = v)],
      'ສຳເນົາ ບັດປະຈຳຕົວ':    [_doc2, (v) => setState(() => _doc2 = v)],
      'ໃບຢັ້ງຢືນວຸດທິ':        [_doc3, (v) => setState(() => _doc3 = v)],
      'ຮູບ 3x4 (2 ໃບ)':        [_doc4, (v) => setState(() => _doc4 = v)],
      'ໃບກວດສຸຂະພາບ':         [_doc5, (v) => setState(() => _doc5 = v)],
    };
    final val      = map[label]![0] as bool;
    final onChange = map[label]![1] as Function(bool);
    return CheckboxListTile(
      dense: true,
      value: val,
      onChanged: (v) => onChange(v!),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      checkColor: Colors.white,
      activeColor: AppColors.accent,
      side: const BorderSide(color: AppColors.border),
      contentPadding: EdgeInsets.zero,
    );
  }

  // ────────────────────────────────
  // Tab 3 — ການເງິນ
  // ────────────────────────────────
  Widget _buildTab3Finance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.payments_outlined, 'ຂໍ້ມູນເງິນເດືອນ', 'Salary Information'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('ເງິນເດືອນພື້ນຖານ (ກີບ)*', _salaryCtrl,
                required: true, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 20),
          _sectionTitle(Icons.account_balance_outlined, 'ຂໍ້ມູນບັນຊີທະນາຄານ', 'Bank Account'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('ຊື່ທະນາຄານ', _bankCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _field('ເລກບັນຊີ', _accountCtrl)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 20),
          _sectionTitle(Icons.calculate_outlined, 'ສ່ວນປະກອບເງິນເດືອນ', 'Salary Components'),
          const SizedBox(height: 12),
          _salaryRow('ເງິນເດືອນພື້ນຖານ',     _salaryCtrl.text.isEmpty ? '0' : _salaryCtrl.text, const Color(0xFF81C784)),
          _salaryRow('ເງິນອຸດໜູນການຂົນສົ່ງ', '200,000',  const Color(0xFF4FC3F7)),
          _salaryRow('ເງິນອຸດໜູນທີ່ພັກ',      '300,000',  const Color(0xFF4FC3F7)),
          _salaryRow('ປະກັນສັງຄົມ (ຫັກ)',     '- 55,000', const Color(0xFFEF9A9A)),
          const Divider(color: AppColors.border, height: 24),
          _salaryRow('ລວມສຸດທິ', '~${_salaryCtrl.text.isEmpty ? "0" : _salaryCtrl.text} ກີບ', AppColors.accent, bold: true),
        ],
      ),
    );
  }

  Widget _salaryRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(
              fontSize: 13, color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal))),
          Text(value, style: TextStyle(fontSize: 13, color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  // ────────────────────────────────
  // Tab 4 — ເພີ່ມເຕີມ
  // ────────────────────────────────
  Widget _buildTab4Extra() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.emergency_outlined, 'ຜູ້ຕິດຕໍ່ສຸກເສີນ', 'Emergency Contact'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('ຊື່ຜູ້ຕິດຕໍ່', _emergNameCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _field('ເບີໂທ', _emergPhoneCtrl, keyboardType: TextInputType.phone)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 20),
          _sectionTitle(Icons.note_outlined, 'ໝາຍເຫດ', 'Notes'),
          const SizedBox(height: 14),
          _field('ໝາຍເຫດ / ຂໍ້ມູນເພີ່ມເຕີມ', _noteCtrl, maxLines: 4),
          const SizedBox(height: 20),
          // Summary preview
          _sectionTitle(Icons.preview_outlined, 'ສະຫຼຸບຂໍ້ມູນ', 'Summary Preview'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _previewRow('ຊື່-ນາມສະກຸນ', '${_firstNameCtrl.text} ${_lastNameCtrl.text}'),
                _previewRow('ຕຳແໜ່ງ',       _positionCtrl.text),
                _previewRow('ພະແນກ',         _department),
                _previewRow('ເພດ',            _gender),
                _previewRow('ຍາມ (Shift)',   _shift),
                _previewRow('ປະເພດ',         _employType),
                _previewRow('ສະຖານະ',        _status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          const Text(':', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Expanded(child: Text(value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ── Bottom Bar ──
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Step indicator
          Row(children: List.generate(4, (i) => Container(
            margin: const EdgeInsets.only(right: 6),
            width: 28, height: 4,
            decoration: BoxDecoration(
              color: _tabController.index >= i ? AppColors.accent : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ))),
          const Spacer(),
          if (_tabController.index > 0)
            TextButton.icon(
              onPressed: () => _tabController.animateTo(_tabController.index - 1),
              icon: const Icon(Icons.arrow_back_ios, size: 14),
              label: const Text('ກັບຄືນ', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          const SizedBox(width: 8),
          if (_tabController.index < 3)
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(_tabController.index + 1),
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: const Text('ຕໍ່ໄປ', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_isSaving ? 'ກຳລັງບັນທຶກ…' : 'ບັນທຶກພະນັກງານ', style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81C784), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Save ──
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSaving = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF81C784), size: 48),
          const SizedBox(height: 12),
          const Text('ບັນທຶກສຳເລັດ!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('ພະນັກງານ ${_firstNameCtrl.text} ${_lastNameCtrl.text}\nໄດ້ຖືກເພີ່ມໃສ່ລະບົບແລ້ວ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('ຕົກລົງ'),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──
  Widget _sectionTitle(IconData icon, String lao, String eng) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.accent),
      const SizedBox(width: 8),
      Text(lao, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(width: 6),
      Text('/ $eng', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(width: 12),
      Expanded(child: Container(height: 1, color: AppColors.border)),
    ]);
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          validator: required ? (v) => (v == null || v.isEmpty) ? 'ກະລຸນາປ້ອນ $label' : null : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgPrimary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEF9A9A))),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.bgSecondary,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker(String label, DateTime? value, ValueChanged<DateTime> onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime(1990),
              firstDate: DateTime(1950),
              lastDate: DateTime(2100),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.accent,
                    onPrimary: Colors.white,
                    surface: Color(0xFF2D2D2D),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (d != null) onPicked(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                value == null ? 'ເລືອກວັນທີ' : '${value.day.toString().padLeft(2,'0')}/${value.month.toString().padLeft(2,'0')}/${value.year}',
                style: TextStyle(fontSize: 13, color: value == null ? AppColors.textMuted : AppColors.textPrimary),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}