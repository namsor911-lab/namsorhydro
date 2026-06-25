// administration_screen.dart (ສະບັບແກ້ໄຂ BOTTOM OVERFLOW)
// ແກ້ໄຂໃຫ້ປຸ່ມ "ການຈ່າຍເງິນເດືອນ" ເປີດໄປ hr_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'hr_screen.dart';
import 'shift_schedule_screen.dart';
import 'hr_dashboard_screen.dart';
import 'add_employee_screen.dart';
import 'create_invoice_screen.dart';
import 'budget_approval_screen.dart';
import 'yearly_report_screen.dart';

// ─────────────────────────────────────────────────────────────
// AdministrationScreen — ໜ້າຈໍການບໍລິຫານບໍລິສັດ
// ─────────────────────────────────────────────────────────────
class AdministrationScreen extends StatefulWidget {
  const AdministrationScreen({super.key});

  @override
  State<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends State<AdministrationScreen> {
  int _selectedCategory = -1;

  final List<_AdminCategory> _categories = const [
    _AdminCategory(
      icon: Icons.people_alt_outlined,
      label: 'ບໍລິຫານບຸກຄະລາກອນ',
      sublabel: 'HR Management',
      color: Color(0xFF4FC3F7),
      items: [
        _AdminItem(icon: Icons.person_add_outlined,       title: 'ເພີ່ມພະນັກງານໃໝ່',          sub: 'Add New Employee'),
        _AdminItem(icon: Icons.badge_outlined,            title: 'ທະບຽນພະນັກງານ',             sub: 'Employee Registry'),
        _AdminItem(icon: Icons.schedule_outlined,         title: 'ຈັດຕາຕະລາງເຮັດວຽກ',         sub: 'Work Schedule'),
        _AdminItem(icon: Icons.card_travel_outlined,      title: 'ການລາພັກ/ສາຍ',              sub: 'Leave & Absence'),
        _AdminItem(icon: Icons.school_outlined,           title: 'ຝຶກອົບຮົມ & ພັດທະນາ',        sub: 'Training & Development'),
      ],
    ),
    _AdminCategory(
      icon: Icons.account_balance_outlined,
      label: 'ການເງິນ & ບັນຊີ',
      sublabel: 'Finance & Accounting',
      color: Color(0xFF81C784),
      items: [
        _AdminItem(icon: Icons.receipt_long_outlined,     title: 'ສ້າງໃບແຈ້ງໜີ້',             sub: 'Create Invoice'),
        _AdminItem(icon: Icons.payments_outlined,         title: 'ອະນຸມັດງົບປະມານ',           sub: 'Budget Approval'),
        _AdminItem(icon: Icons.trending_up_outlined,      title: 'ລາຍງານລາຍຮັບ',             sub: 'Revenue Report'),
        _AdminItem(icon: Icons.money_off_outlined,        title: 'ຄ່າໃຊ້ຈ່າຍ & ຕົ້ນທຶນ',       sub: 'Expenses & Cost'),
        _AdminItem(icon: Icons.account_balance_wallet_outlined, title: 'ການຈ່າຍເງິນເດືອນ',    sub: 'Payroll'),
        _AdminItem(icon: Icons.bar_chart_outlined,        title: 'ງົບດູ່ລ & P&L',             sub: 'Balance Sheet & P&L'),
      ],
    ),
    _AdminCategory(
      icon: Icons.gavel_outlined,
      label: 'ນິຕິກຳ & ສັນຍາ',
      sublabel: 'Legal & Contracts',
      color: Color(0xFFFFB74D),
      items: [
        _AdminItem(icon: Icons.description_outlined,      title: 'ສ້າງ/ແກ້ໄຂສັນຍາ',           sub: 'Create/Edit Contracts'),
        _AdminItem(icon: Icons.folder_special_outlined,   title: 'ທະບຽນສັນຍາ',               sub: 'Contract Registry'),
        _AdminItem(icon: Icons.verified_outlined,         title: 'ໃບອະນຸຍາດ & ໃບຮັບຮອງ',     sub: 'Licenses & Permits'),
        _AdminItem(icon: Icons.policy_outlined,           title: 'ນະໂຍບາຍ & ລະບຽບ',          sub: 'Policies & Regulations'),
        _AdminItem(icon: Icons.handshake_outlined,        title: 'ຜູ້ສະໜອງ & ຄູ່ຮ່ວມ',         sub: 'Suppliers & Partners'),
        _AdminItem(icon: Icons.history_edu_outlined,      title: 'ບັນທຶກດ້ານກົດໝາຍ',          sub: 'Legal Records'),
      ],
    ),
    _AdminCategory(
      icon: Icons.inventory_2_outlined,
      label: 'ຄຸ້ມຄອງຊັບສິນ',
      sublabel: 'Asset Management',
      color: Color(0xFFBA68C8),
      items: [
        _AdminItem(icon: Icons.precision_manufacturing_outlined, title: 'ທະບຽນອຸປະກອນ',      sub: 'Equipment Registry'),
        _AdminItem(icon: Icons.build_circle_outlined,    title: 'ສ້ອມແປງ & ບຳລຸງຮັກສາ',       sub: 'Maintenance Schedule'),
        _AdminItem(icon: Icons.storefront_outlined,      title: 'ຄັງວັດສະດຸ',                sub: 'Inventory/Warehouse'),
        _AdminItem(icon: Icons.qr_code_outlined,         title: 'ຕິດຕາມຊັບສິນ',              sub: 'Asset Tracking'),
        _AdminItem(icon: Icons.recycling_outlined,       title: 'ການຈຳໜ່າຍຊັບສິນ',           sub: 'Asset Disposal'),
        _AdminItem(icon: Icons.attach_money_outlined,    title: 'ຄ່າເສື່ອມລາຄາ',             sub: 'Depreciation'),
      ],
    ),
    _AdminCategory(
      icon: Icons.assignment_outlined,
      label: 'ໂຄງການ & ແຜນງານ',
      sublabel: 'Projects & Planning',
      color: Color(0xFFF06292),
      items: [
        _AdminItem(icon: Icons.add_task_outlined,         title: 'ສ້າງໂຄງການໃໝ່',            sub: 'New Project'),
        _AdminItem(icon: Icons.task_alt_outlined,         title: 'ຕິດຕາມຄວາມຄືບໜ້າ',         sub: 'Progress Tracking'),
        _AdminItem(icon: Icons.calendar_month_outlined,   title: 'ແຜນຜັງ Gantt',              sub: 'Gantt Chart'),
        _AdminItem(icon: Icons.group_work_outlined,       title: 'ມອບໝາຍວຽກງານ',            sub: 'Task Assignment'),
        _AdminItem(icon: Icons.analytics_outlined,        title: 'ລາຍງານໂຄງການ',            sub: 'Project Reports'),
        _AdminItem(icon: Icons.flag_outlined,             title: 'ຈຸດໝາຍ & KPI',             sub: 'Milestones & KPI'),
      ],
    ),
    _AdminCategory(
      icon: Icons.health_and_safety_outlined,
      label: 'ຄວາມປອດໄພ & HSE',
      sublabel: 'Safety & HSE',
      color: Color(0xFF4DB6AC),
      items: [
        _AdminItem(icon: Icons.report_problem_outlined,   title: 'ລາຍງານອຸບັດຕິເຫດ',         sub: 'Incident Report'),
        _AdminItem(icon: Icons.checklist_outlined,        title: 'ການກວດກາຄວາມປອດໄພ',       sub: 'Safety Inspection'),
        _AdminItem(icon: Icons.fire_extinguisher_outlined,title: 'ອຸປະກອນສຸກເສີນ',           sub: 'Emergency Equipment'),
        _AdminItem(icon: Icons.masks_outlined,            title: 'PPE & ອຸປະກອນປ້ອງກັນ',     sub: 'PPE Management'),
        _AdminItem(icon: Icons.local_hospital_outlined,   title: 'ສຸຂະພາບພະນັກງານ',          sub: 'Employee Health'),
        _AdminItem(icon: Icons.crisis_alert_outlined,     title: 'ແຜນສຸກເສີນ',               sub: 'Emergency Plan'),
      ],
    ),
    _AdminCategory(
      icon: Icons.bar_chart_outlined,
      label: 'ລາຍງານ & ວິເຄາະ',
      sublabel: 'Reports & Analytics',
      color: Color(0xFFFFD54F),
      items: [
        _AdminItem(icon: Icons.summarize_outlined,        title: 'ລາຍງານປະຈຳວັນ',           sub: 'Daily Report'),
        _AdminItem(icon: Icons.calendar_view_month_outlined, title: 'ລາຍງານປະຈຳເດືອນ',     sub: 'Monthly Report'),
        _AdminItem(icon: Icons.donut_large_outlined,       title: 'ລາຍງານການຜະລິດ',          sub: 'Production Report'),
        _AdminItem(icon: Icons.download_outlined,         title: 'ສົ່ງອອກຂໍ້ມູນ',            sub: 'Export Data'),
        _AdminItem(icon: Icons.compare_arrows_outlined,   title: 'ການວິເຄາະທຽບ',            sub: 'Comparative Analysis'),
        _AdminItem(icon: Icons.table_chart_outlined,      title: 'ລາຍງານ Custom',            sub: 'Custom Reports'),
      ],
    ),
    _AdminCategory(
      icon: Icons.settings_outlined,
      label: 'ຕັ້ງຄ່າລະບົບ',
      sublabel: 'System Configuration',
      color: Color(0xFF90A4AE),
      items: [
        _AdminItem(icon: Icons.manage_accounts_outlined,  title: 'ຈັດການຜູ້ໃຊ້ & ສິດ',       sub: 'Users & Permissions'),
        _AdminItem(icon: Icons.lock_outline,              title: 'ຄວາມປອດໄພ & ການເຂົ້າສູ່ລະບົບ', sub: 'Security & Login'),
        _AdminItem(icon: Icons.backup_outlined,           title: 'ສຳຮອງ & ກູ້ຂໍ້ມູນ',        sub: 'Backup & Recovery'),
        _AdminItem(icon: Icons.notifications_active_outlined, title: 'ຕັ້ງຄ່າການແຈ້ງເຕືອນ',  sub: 'Notification Settings'),
        _AdminItem(icon: Icons.lan_outlined,              title: 'ຕັ້ງຄ່າເຄືອຂ່າຍ',          sub: 'Network Configuration'),
        _AdminItem(icon: Icons.integration_instructions_outlined, title: 'ການເຊື່ອມຕໍ່ API', sub: 'API Integration'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _selectedCategory == -1
        ? _buildGrid()
        : _buildSubMenu(_categories[_selectedCategory]);
  }

  // ──────────────────────────────────────────
  // Grid ໝວດຫມູ່ຫຼັກ (ແກ້ໄຂ Overflow)
  // ──────────────────────────────────────────
  Widget _buildGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings,
                    color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ລະບົບການບໍລິຫານ',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('Administration Management System',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: AppColors.success),
                    SizedBox(width: 5),
                    Text('Admin Active',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ===== Grid ຫຼັກ (ໃຊ້ Expanded ຫໍ່ GridView ໂດຍກົງ) =====
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 900
                  ? 8
                  : constraints.maxWidth > 600
                      ? 6
                      : 4;
              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 1.3,
                ),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) => _buildCategoryCard(_categories[i], i),
                physics: const ClampingScrollPhysics(), // ເພີ່ມ physics ເພື່ອເລື່ອນ
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(_AdminCategory cat, int index) {
    return InkWell(
      onTap: () {
        if (cat.label == 'ບໍລິຫານບຸກຄະລາກອນ') {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HrDashboardScreen()));
        } else {
          setState(() => _selectedCategory = index);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cat.icon, color: cat.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              cat.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              cat.sublabel,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${cat.items.length} ລາຍການ',
                style: TextStyle(
                  fontSize: 8,
                  color: cat.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // SubMenu — ເມນູຍ່ອຍ (ແກ້ໄຂ Overflow)
  // ──────────────────────────────────────────
  Widget _buildSubMenu(_AdminCategory cat) {
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header ຍ່ອຍ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: AppColors.bgSecondary,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // Back Button (ປັບປຸງໃຫ້ເດັ່ນ)
                InkWell(
                  onTap: () => setState(() => _selectedCategory = -1),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 22,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.label,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(cat.sublabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // ===== Grid ຍ່ອຍ (ໃຊ້ Expanded ຫໍ່ GridView ໂດຍກົງ) =====
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 900
                    ? 8
                    : constraints.maxWidth > 600
                        ? 6
                        : 4;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    // === ແກ້ໄຂ: ເພີ່ມຄ່າ childAspectRatio ຈາກ 2.2 ເປັນ 1.7 ເພື່ອເພີ່ມຄວາມສູງຂອງບັດ ແລະ ແກ້ໄຂ Overflow ===
                    childAspectRatio: 1.7, 
                  ),
                  itemCount: cat.items.length,
                  itemBuilder: (ctx, i) =>
                      _buildActionCard(cat.items[i], cat.color),
                  physics: const ClampingScrollPhysics(), // ເພີ່ມ physics ເພື່ອເລື່ອນ
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(_AdminItem item, Color color) {
    return InkWell(
      onTap: () {
        if (item.title == 'ການຈ່າຍເງິນເດືອນ') {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HrScreen()));
        } else if (item.title == 'ຈັດຕາຕະລາງເຮັດວຽກ') {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ShiftScheduleScreen()));
        } else if (item.title == 'ສ້າງໃບແຈ້ງໜີ້') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
        } else if (item.title == 'ອະນຸມັດງົບປະມານ') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetApprovalScreen()));
        } else if (item.title == 'ລາຍງານລາຍຮັບ') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const YearlyReportScreen()));
        } else if (item.title == 'ເພີ່ມພະນັກງານໃໝ່') {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddEmployeeScreen()));
        } else {
          _showComingSoon(item.title);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              item.sub,
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textPrimary)),
            ),
          ],
        ),
        content: const Text(
          'ຟັງຊັ່ນນີ້ກຳລັງພັດທະນາ\nThis feature is under development.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຕົກລົງ / OK',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────
class _AdminCategory {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final List<_AdminItem> items;

  const _AdminCategory({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.items,
  });
}

class _AdminItem {
  final IconData icon;
  final String title;
  final String sub;

  const _AdminItem({
    required this.icon,
    required this.title,
    required this.sub,
  });
}