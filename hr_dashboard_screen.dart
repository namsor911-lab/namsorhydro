// hr_dashboard_screen.dart
// Dashboard ບໍລິຫານບຸກຄະລາກອນ — ສະຖິຕິ + ລາຍຊື່ພະນັກງານ

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'add_employee_screen.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────
class EmployeeModel {
  final String id;
  final String name;
  final String position;
  final String department;
  final String phone;
  final String email;
  final String startDate;
  final String status; // 'active' | 'leave' | 'inactive'
  final String shift;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    required this.phone,
    required this.email,
    required this.startDate,
    required this.status,
    required this.shift,
  });
}

// ─────────────────────────────────────────────────────────────
// HrDashboardScreen
// ─────────────────────────────────────────────────────────────
class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  String _searchQuery = '';
  String _filterDept = 'ທັງໝົດ';
  String _filterStatus = 'ທັງໝົດ';

  // ຂໍ້ມູນຕົວຢ່າງ
  final List<EmployeeModel> _employees = const [
    EmployeeModel(id: 'NS-001', name: 'ພູວຽງ ຈັນສະໄໝ',    position: 'OPERATOR',   department: 'ຜະລິດໄຟຟ້າ',  phone: '020-5511-1001', email: 'phouvieng@namsor.la',  startDate: '01/03/2018', status: 'active',   shift: 'Shift 1'),
    EmployeeModel(id: 'NS-002', name: 'ວິໄລລັກ ຄຳປະສົງ',  position: 'OPERATOR',      department: 'ຜະລິດໄຟຟ້າ',  phone: '020-5511-1002', email: 'vilaylak@namsor.la',   startDate: '15/06/2019', status: 'active',   shift: 'Shift 1'),
    EmployeeModel(id: 'NS-003', name: 'ສົມຄິດ ວິໄລວັນ',   position: 'OPERATOR',  department: 'ຜະລິດໄຟຟ້າ',         phone: '020-5511-1003', email: 'somkid@namsor.la',     startDate: '10/01/2020', status: 'active',   shift: 'Shift 2'),
    EmployeeModel(id: 'NS-004', name: 'ພິທັກ ໄຊສົມຊາງ',   position: 'OPERATOR', department: 'ຜະລິດໄຟຟ້າ',         phone: '020-5511-1004', email: 'phithak@namsor.la',    startDate: '22/09/2020', status: 'active',   shift: 'Shift 2'),
    EmployeeModel(id: 'NS-005', name: 'ມັງກອນ ຍອດວົງສາ',  position: 'OPERATOR',    department: 'ຜະລິດໄຟຟ້າ',  phone: '020-5511-1005', email: 'mangkon@namsor.la',    startDate: '05/04/2017', status: 'active',   shift: 'Shift 3'),
    EmployeeModel(id: 'NS-006', name: 'ບົວສອນ ໄຊຈະເລີນ',  position: 'OPERATOR',           department: 'ຜະລິດໄຟຟ້າ',  phone: '020-5511-1006', email: 'bouason@namsor.la',    startDate: '18/11/2021', status: 'leave',    shift: 'Shift 3'),
    EmployeeModel(id: 'NS-007', name: 'ຕ໋ອກ ເພຍໄຊ',       position: 'OPERATOR',          department: 'ຜະລິດໄຟຟ້າ',      phone: '020-5511-1007', email: 'tok@namsor.la',        startDate: '03/07/2019', status: 'active',   shift: '-'),
    EmployeeModel(id: 'NS-008', name: 'ອາເຈ່ຍ ໄຊຈະເລີນ',  position: 'OPERATOR',      department: 'ຜະລິດໄຟຟ້າ',      phone: '020-5511-1008', email: 'ajey@namsor.la',       startDate: '12/02/2022', status: 'active',   shift: '-'),
  ];

  List<EmployeeModel> get _filtered {
    return _employees.where((e) {
      final matchSearch = e.name.contains(_searchQuery) ||
          e.id.contains(_searchQuery) ||
          e.position.contains(_searchQuery);
      final matchDept = _filterDept == 'ທັງໝົດ' || e.department == _filterDept;
      final matchStatus = _filterStatus == 'ທັງໝົດ' || e.status == _filterStatus;
      return matchSearch && matchDept && matchStatus;
    }).toList();
  }

  List<String> get _departments {
    final depts = _employees.map((e) => e.department).toSet().toList();
    depts.sort();
    return ['ທັງໝົດ', ...depts];
  }

  int get _activeCount    => _employees.where((e) => e.status == 'active').length;
  int get _leaveCount     => _employees.where((e) => e.status == 'leave').length;
  int get _inactiveCount  => _employees.where((e) => e.status == 'inactive').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _buildHeader(),
          _buildStatCards(),
          _buildFilters(),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.people_alt_outlined,
                color: Color(0xFF4FC3F7), size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ບໍລິຫານບຸກຄະລາກອນ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('HR Management Dashboard',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          // ປຸ່ມເພີ່ມພະນັກງານ
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddEmployeeScreen()));
              setState(() {}); // refresh
            },
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('ເພີ່ມພະນັກງານໃໝ່', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Cards ──
  Widget _buildStatCards() {
    final stats = [
      {'label': 'ພະນັກງານທັງໝົດ', 'value': '${_employees.length}', 'icon': Icons.groups_outlined,          'color': const Color(0xFF4FC3F7)},
      {'label': 'ກຳລັງເຮັດວຽກ',   'value': '$_activeCount',         'icon': Icons.check_circle_outline,     'color': const Color(0xFF81C784)},
      {'label': 'ລາພັກ / ສາຍ',    'value': '$_leaveCount',          'icon': Icons.event_busy_outlined,      'color': const Color(0xFFFFB74D)},
      {'label': 'ໝົດສັນຍາ',       'value': '$_inactiveCount',       'icon': Icons.person_off_outlined,      'color': const Color(0xFFEF9A9A)},
    ];
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: stats.map((s) {
          final color = s['color'] as Color;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(s['icon'] as IconData, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['value'] as String,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                      Text(s['label'] as String,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Filters ──
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.bgPrimary,
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'ຄົ້ນຫາຊື່, ລະຫັດ, ຕຳແໜ່ງ…',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                filled: true,
                fillColor: AppColors.bgSecondary,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
            ),
          ),
          const SizedBox(width: 10),
          // Dept filter
          Expanded(
            flex: 2,
            child: _buildDropdown(_filterDept, _departments, (v) => setState(() => _filterDept = v!)),
          ),
          const SizedBox(width: 10),
          // Status filter
          Expanded(
            flex: 2,
            child: _buildDropdown(_filterStatus, ['ທັງໝົດ', 'active', 'leave', 'inactive'],
                (v) => setState(() => _filterStatus = v!),
                labelMap: {'active': 'ເຮັດວຽກ', 'leave': 'ລາພັກ', 'inactive': 'ໝົດສັນຍາ'}),
          ),
          const SizedBox(width: 10),
          Text('${_filtered.length} ຄົນ',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged,
      {Map<String, String>? labelMap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.bgSecondary,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(labelMap?[e] ?? e, style: const TextStyle(fontSize: 12)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Table ──
  Widget _buildTable() {
    final list = _filtered;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 100, child: Text('ລະຫັດ',     style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text('ຊື່-ນາມສະກຸນ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text('ຕຳແໜ່ງ',       style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('ພະແນກ',        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('ເບີໂທ',         style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                SizedBox(width: 80,  child: Text('ຍາມ',        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                SizedBox(width: 90,  child: Text('ສະຖານະ',     style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                SizedBox(width: 60,  child: Text('ຈັດການ',     style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('ບໍ່ພົບຂໍ້ມູນ', style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) => _buildRow(list[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(EmployeeModel e, int i) {
    Color statusColor;
    String statusLabel;
    switch (e.status) {
      case 'active':   statusColor = const Color(0xFF81C784); statusLabel = 'ເຮັດວຽກ';   break;
      case 'leave':    statusColor = const Color(0xFFFFB74D); statusLabel = 'ລາພັກ';     break;
      default:         statusColor = const Color(0xFFEF9A9A); statusLabel = 'ໝົດສັນຍາ'; break;
    }
    return InkWell(
      onTap: () => _showEmployeeDetail(e),
      child: Container(
        color: i.isOdd ? const Color(0xFF1E1E1E) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 100,
              child: Text(e.id, style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600))),
            Expanded(flex: 3,
              child: Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                  child: Text(e.name[0], style: const TextStyle(fontSize: 12, color: Color(0xFF4FC3F7), fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.name, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              ])),
            Expanded(flex: 3,
              child: Text(e.position, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2,
              child: Text(e.department, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2,
              child: Text(e.phone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
            SizedBox(width: 80,
              child: Text(e.shift, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            SizedBox(width: 90,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(statusLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
              )),
            SizedBox(width: 60,
              child: Row(children: [
                InkWell(
                  onTap: () => _showEmployeeDetail(e),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.visibility_outlined, size: 16, color: AppColors.accent),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ])),
          ],
        ),
      ),
    );
  }

  void _showEmployeeDetail(EmployeeModel e) {
    Color statusColor;
    String statusLabel;
    switch (e.status) {
      case 'active':   statusColor = const Color(0xFF81C784); statusLabel = 'ເຮັດວຽກ';   break;
      case 'leave':    statusColor = const Color(0xFFFFB74D); statusLabel = 'ລາພັກ';     break;
      default:         statusColor = const Color(0xFFEF9A9A); statusLabel = 'ໝົດສັນຍາ'; break;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border)),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                child: Text(e.name[0], style: const TextStyle(fontSize: 24, color: Color(0xFF4FC3F7), fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              Text(e.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(e.position, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              _detailRow(Icons.badge_outlined,           'ລະຫັດ',    e.id),
              _detailRow(Icons.business_outlined,        'ພະແນກ',    e.department),
              _detailRow(Icons.schedule_outlined,        'ຍາມ',      e.shift),
              _detailRow(Icons.phone_outlined,           'ເບີໂທ',    e.phone),
              _detailRow(Icons.email_outlined,           'ອີເມລ',     e.email),
              _detailRow(Icons.calendar_today_outlined,  'ເລີ່ມວຽກ', e.startDate),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('ປິດ', style: TextStyle(color: AppColors.accent))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('ແກ້ໄຂ', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}