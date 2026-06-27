// budget_approval_screen.dart
// ອະນຸມັດງົບປະມານ — ນ້ຳຊໍ້ ໄຮໂດຼ ພາວເວີ ຈຳກັດ

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────
enum BudgetStatus { pending, approved, rejected, revision }

class BudgetRequest {
  final String id;
  final String title;
  final String department;
  final String requester;
  final double amount;
  final String currency;
  final String category;
  final String reason;
  final String submitDate;
  final String deadline;
  BudgetStatus status;
  String? approverNote;
  String? approvedBy;
  String? actionDate;

  BudgetRequest({
    required this.id,
    required this.title,
    required this.department,
    required this.requester,
    required this.amount,
    required this.currency,
    required this.category,
    required this.reason,
    required this.submitDate,
    required this.deadline,
    this.status = BudgetStatus.pending,
    this.approverNote,
    this.approvedBy,
    this.actionDate,
  });
}

// ─────────────────────────────────────────────────────────────
// BudgetApprovalScreen
// ─────────────────────────────────────────────────────────────
class BudgetApprovalScreen extends StatefulWidget {
  const BudgetApprovalScreen({super.key});

  @override
  State<BudgetApprovalScreen> createState() => _BudgetApprovalScreenState();
}

class _BudgetApprovalScreenState extends State<BudgetApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';

  // ລຶບຂໍ້ມູນຕົວຢ່າງ 6 ລາຍການອອກ ໃຫ້ເປັນ List ວ່າງເປົ່າ
  final List<BudgetRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<BudgetRequest> _getByStatus(BudgetStatus? status) {
    var list = _requests.where((r) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return r.id.toLowerCase().contains(q) ||
            r.title.toLowerCase().contains(q) ||
            r.department.toLowerCase().contains(q) ||
            r.requester.toLowerCase().contains(q);
      }
      return true;
    }).toList();
    if (status != null) list = list.where((r) => r.status == status).toList();
    return list;
  }

  Color _statusColor(BudgetStatus s) {
    switch (s) {
      case BudgetStatus.pending:  return const Color(0xFFFFB74D);
      case BudgetStatus.approved: return AppColors.success;
      case BudgetStatus.rejected: return const Color(0xFFE53935);
      case BudgetStatus.revision: return const Color(0xFF4FC3F7);
    }
  }

  String _statusLabel(BudgetStatus s) {
    switch (s) {
      case BudgetStatus.pending:  return 'ລໍຖ້າ';
      case BudgetStatus.approved: return 'ອະນຸມັດ';
      case BudgetStatus.rejected: return 'ປະຕິເສດ';
      case BudgetStatus.revision: return 'ແກ້ໄຂ';
    }
  }

  IconData _statusIcon(BudgetStatus s) {
    switch (s) {
      case BudgetStatus.pending:  return Icons.hourglass_empty_rounded;
      case BudgetStatus.approved: return Icons.check_circle_outline;
      case BudgetStatus.rejected: return Icons.cancel_outlined;
      case BudgetStatus.revision: return Icons.edit_note_outlined;
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final pending  = _requests.where((r) => r.status == BudgetStatus.pending).length;
    final totalPending = _requests
        .where((r) => r.status == BudgetStatus.pending)
        .fold(0.0, (s, r) => s + r.amount);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(pending),
      body: Column(
        children: [
          // ── KPI Strip ──
          _buildKpiStrip(pending, totalPending),

          // ── Search ──
          _buildSearch(),

          // ── Tabs ──
          Container(
            color: AppColors.bgSecondary,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFF81C784),
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: const Color(0xFF81C784),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              tabs: [
                Tab(text: 'ທັງໝົດ (${_requests.length})'),
                Tab(text: 'ລໍຖ້າ ($pending)'),
                Tab(text: 'ອະນຸມັດ (${_requests.where((r) => r.status == BudgetStatus.approved).length})'),
                const Tab(text: 'ອື່ນໆ'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── List ──
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(null),
                _buildList(BudgetStatus.pending),
                _buildList(BudgetStatus.approved),
                _buildOtherList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewRequestDialog,
        backgroundColor: const Color(0xFF81C784),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ສ້າງຄຳຂໍ',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── AppBar ──
  PreferredSizeWidget _buildAppBar(int pending) {
    return AppBar(
      backgroundColor: AppColors.bgSecondary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.accent),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF81C784).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.payments_outlined, color: Color(0xFF81C784), size: 20),
        ),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ອະນຸມັດງົບປະມານ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text('ນ້ຳຊໍ້ ໄຮໂດຼ ພາວເວີ ຈຳກັດ',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ]),
      actions: [
        if (pending > 0)
          Container(
            margin: const EdgeInsets.only(right: 6, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.pending_actions, size: 14, color: Color(0xFFFFB74D)),
              const SizedBox(width: 4),
              Text('$pending ລໍຖ້າ',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFFFFB74D))),
            ]),
          ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: AppColors.accent),
          onPressed: () {},
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }

  // ── KPI Strip ──
  Widget _buildKpiStrip(int pending, double totalPending) {
    final approved = _requests.where((r) => r.status == BudgetStatus.approved).length;
    final totalApproved = _requests
        .where((r) => r.status == BudgetStatus.approved)
        .fold(0.0, (s, r) => s + r.amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppColors.bgSecondary,
      child: Row(children: [
        _kpiBox('ລໍຖ້າອະນຸມັດ', '$pending ລາຍການ',
            _fmt(totalPending), const Color(0xFFFFB74D), Icons.hourglass_top_rounded),
        const SizedBox(width: 8),
        _kpiBox('ອະນຸມັດແລ້ວ', '$approved ລາຍການ',
            _fmt(totalApproved), AppColors.success, Icons.check_circle_outline),
        const SizedBox(width: 8),
        _kpiBox('ທັງໝົດ Y2025', '${_requests.length} ລາຍການ',
            _fmt(_requests.fold(0.0, (s, r) => s + r.amount)),
            AppColors.accent, Icons.account_balance_wallet_outlined),
      ]),
    );
  }

  Widget _kpiBox(String title, String sub, String amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(child: Text(title,
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Text(amount,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          Text(sub,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  // ── Search ──
  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      color: AppColors.bgSecondary,
      child: TextField(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'ຄົ້ນຫາ ID, ຫົວຂໍ້, ພະແນກ...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
          filled: true,
          fillColor: AppColors.bgPrimary,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
      ),
    );
  }

  // ── List Builder ──
  Widget _buildList(BudgetStatus? filter) {
    final list = _getByStatus(filter);
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('ບໍ່ມີລາຍການ', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildCard(list[i]),
    );
  }

  Widget _buildOtherList() {
    final list = _requests.where((r) =>
        r.status == BudgetStatus.rejected || r.status == BudgetStatus.revision).toList();
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline, size: 48, color: AppColors.success.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('ບໍ່ມີລາຍການ', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildCard(list[i]),
    );
  }

  // ── Budget Card ──
  Widget _buildCard(BudgetRequest r) {
    final sc = _statusColor(r.status);
    return InkWell(
      onTap: () => _showDetail(r),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_statusIcon(r.status), size: 16, color: sc),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.id, style: const TextStyle(fontSize: 10,
                    color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                Text(r.title, style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${r.currency} ${_fmt(r.amount)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                        color: Color(0xFF81C784))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_statusLabel(r.status),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sc)),
                ),
              ]),
            ]),
          ),
          // Info strip
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              _infoChip(Icons.person_outline, r.requester),
              const SizedBox(width: 10),
              _infoChip(Icons.business_outlined, r.department),
              const Spacer(),
              if (r.status == BudgetStatus.pending)
                Row(children: [
                  _actionBtn('ອະນຸມັດ', Icons.check, AppColors.success,
                      () => _doAction(r, BudgetStatus.approved)),
                  const SizedBox(width: 6),
                  _actionBtn('ປະຕິເສດ', Icons.close, const Color(0xFFE53935),
                      () => _doAction(r, BudgetStatus.rejected)),
                ]),
              if (r.status != BudgetStatus.pending)
                _infoChip(Icons.calendar_today_outlined, r.actionDate ?? ''),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 12, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis),
    ]);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  // ── Action: approve / reject ──
  void _doAction(BudgetRequest r, BudgetStatus newStatus) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(children: [
          Icon(
            newStatus == BudgetStatus.approved ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: newStatus == BudgetStatus.approved ? AppColors.success : const Color(0xFFE53935),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            newStatus == BudgetStatus.approved ? 'ຢືນຢັນອະນຸມັດ' : 'ຢືນຢັນປະຕິເສດ',
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('${r.currency} ${_fmt(r.amount)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: Color(0xFF81C784))),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'ໝາຍເຫດ / ເຫດຜົນ (ທາງເລືອກ)...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == BudgetStatus.approved
                  ? AppColors.success : const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                r.status = newStatus;
                r.approverNote = noteCtrl.text.isNotEmpty ? noteCtrl.text : null;
                r.approvedBy = 'ທ່ານ ສີສຸວັນ';
                r.actionDate = '${DateTime.now().day.toString().padLeft(2,'0')}/'
                    '${DateTime.now().month.toString().padLeft(2,'0')}/'
                    '${DateTime.now().year}';
              });
              Navigator.pop(context);
              _showSnack(
                newStatus == BudgetStatus.approved ? '✓ ອະນຸມັດ ${r.id} ສຳເລັດ' : '✗ ປະຕິເສດ ${r.id} ແລ້ວ',
                newStatus == BudgetStatus.approved ? AppColors.success : const Color(0xFFE53935),
              );
            },
            child: Text(
              newStatus == BudgetStatus.approved ? 'ອະນຸມັດ' : 'ປະຕິເສດ',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Detail Dialog ──
  void _showDetail(BudgetRequest r) {
    final sc = _statusColor(r.status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_statusIcon(r.status), color: sc, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.id, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text(r.title, style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sc.withValues(alpha: 0.3)),
                  ),
                  child: Text(_statusLabel(r.status),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
                ),
              ]),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Body
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Amount
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF81C784).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.monetization_on_outlined,
                          color: Color(0xFF81C784), size: 28),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('ຈຳນວນງົບທີ່ຂໍ',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text('${r.currency} ${_fmt(r.amount)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                                color: Color(0xFF81C784))),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('ໝວດໝູ່', r.category, Icons.category_outlined),
                  _detailRow('ພະແນກ', r.department, Icons.business_outlined),
                  _detailRow('ຜູ້ຍື່ນຄຳຂໍ', r.requester, Icons.person_outline),
                  _detailRow('ວັນທີ່ຍື່ນ', r.submitDate, Icons.calendar_today_outlined),
                  _detailRow('ກຳນົດຕອບ', r.deadline, Icons.timer_outlined,
                      valueColor: const Color(0xFFFFB74D)),
                  const SizedBox(height: 12),
                  const Text('ເຫດຜົນ / ລາຍລະອຽດ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(r.reason,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary,
                            height: 1.5)),
                  ),
                  if (r.approverNote != null) ...[
                    const SizedBox(height: 12),
                    const Text('ໝາຍເຫດຈາກຜູ້ອະນຸມັດ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sc.withValues(alpha: 0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.approverNote!,
                            style: TextStyle(fontSize: 12, color: sc, height: 1.5)),
                        if (r.approvedBy != null) ...[
                          const SizedBox(height: 6),
                          Text('— ${r.approvedBy!} · ${r.actionDate ?? ''}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (r.status == BudgetStatus.pending)
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _doAction(r, BudgetStatus.rejected);
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('ປະຕິເສດ', style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE53935),
                            side: BorderSide(color: const Color(0xFFE53935).withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _doAction(r, BudgetStatus.approved);
                          },
                          icon: const Icon(Icons.check, size: 16, color: Colors.white),
                          label: const Text('ອະນຸມັດ',
                              style: TextStyle(fontSize: 13, color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(width: 120,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ),
      ]),
    );
  }

  // ── New Request Dialog ──
  void _showNewRequestDialog() {
    final titleCtrl   = TextEditingController();
    final amountCtrl  = TextEditingController();
    final reasonCtrl  = TextEditingController();
    String dept = 'ຝ່າຍວິສະວະກຳ';
    String cat  = 'ຊ່ອມແປງ & ບຳລຸງຮັກສາ';
    String currency = 'LAK'; // ເພີ່ມຕົວແປສະກຸນເງິນ, ຕັ້ງຄ່າເລີ່ມຕົ້ນເປັນ LAK

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              const Text('ສ້າງຄຳຂໍງົບໃໝ່',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _inputField('ຫົວຂໍ້', titleCtrl, 'ເຊັ່ນ: ຊື້ Bearing Turbine ໜ່ວຍ 3'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _dropdownField('ພະແນກ', dept,
                    ['ຝ່າຍວິສະວະກຳ', 'ຝ່າຍ HSE', 'ຝ່າຍການເງິນ', 'ຝ່າຍ IT', 'ຝ່າຍຊັບສິນ'],
                    (v) => setSt(() => dept = v!))),
                const SizedBox(width: 10),
                Expanded(child: _dropdownField('ໝວດໝູ່', cat,
                    ['ຊ່ອມແປງ & ບຳລຸງຮັກສາ', 'ພັດທະນາບຸກຄະລາກອນ',
                     'ຄວາມປອດໄພ & HSE', 'ລະບົບ IT & ເທັກໂນໂລຢີ',
                     'ໂຄງສ້າງພື້ນຖານ', 'ທີ່ປຶກສາ & ກົດໝາຍ'],
                    (v) => setSt(() => cat = v!))),
              ]),
              const SizedBox(height: 10),
              // ແກ້ໄຂແຖວປ້ອນຈຳນວນເງິນໃຫ້ມີຊ່ອງເລືອກສະກຸນເງິນ
              Row(children: [
                Expanded(flex: 3, child: _inputField('ຈຳນວນ', amountCtrl, '0.00',
                    keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _dropdownField('ສະກຸນເງິນ', currency,
                    ['USD', 'THB', 'LAK'],
                    (v) => setSt(() => currency = v!))),
              ]),
              const SizedBox(height: 10),
              _inputField('ເຫດຜົນ / ລາຍລະອຽດ', reasonCtrl, 'ອະທິບາຍຄວາມຈຳເປັນ...', maxLines: 3),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81C784),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                    final now = DateTime.now();
                    final id = 'BDG-${now.year}-${(_requests.length + 1).toString().padLeft(4, '0')}';
                    setState(() {
                      _requests.insert(0, BudgetRequest(
                        id: id,
                        title: titleCtrl.text,
                        department: dept,
                        requester: 'ທ່ານ ສົມພອນ ພົມມະຈັນ',
                        amount: double.tryParse(amountCtrl.text) ?? 0,
                        currency: currency, // ຮັບຄ່າສະກຸນເງິນທີ່ເລືອກມາກຳນົດໃສ່
                        category: cat,
                        reason: reasonCtrl.text,
                        submitDate: '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}',
                        deadline: '${(now.day + 14).toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}',
                      ));
                    });
                    Navigator.pop(context);
                    _showSnack('✓ ຍື່ນຄຳຂໍ $id ສຳເລັດ', AppColors.success);
                  },
                  child: const Text('ຍື່ນຄຳຂໍ Submit',
                      style: TextStyle(color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: AppColors.bgPrimary,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF81C784))),
        ),
      ),
    ]);
  }

  Widget _dropdownField(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            dropdownColor: AppColors.bgSecondary,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}