import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import 'hr_screen.dart';
import 'field_accounting_screen.dart';
import 'purchase_screen.dart'; // ← ລາຍການຊື້ເຄື່ອງ (ຮ້ານຄາ)

// ═══════════════════════════════════════════════════════════════
//  AccountingScreen — ບັນຊີ/ການເງິນ Namsor HydroPower
// ═══════════════════════════════════════════════════════════════
class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});
  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  int _selectedCategory = -1; // -1 = show main grid

  // ══════════════════════════════════════════
  // ໝວດໝູ່ທັງໝົດ 10 ໝວດ
  // ══════════════════════════════════════════
  static const List<_AccCategory> _categories = [
    // 1 ─ ລາຍຮັບ
    _AccCategory(
      icon: Icons.trending_up_outlined,
      label: 'ລາຍຮັບ',
      sublabel: 'Revenue',
      color: Color(0xFF4CAF50),
      items: [
        _AccItem(icon: Icons.bolt_outlined,              title: 'ລາຍຮັບຈາກການຂາຍໄຟ',       sub: 'Power Sales Revenue'),
        _AccItem(icon: Icons.receipt_outlined,           title: 'ອອກໃບເກັບເງິນ',            sub: 'Issue Invoice'),
        _AccItem(icon: Icons.calendar_today_outlined,    title: 'ລາຍຮັບປະຈຳເດືອນ',          sub: 'Monthly Revenue'),
        _AccItem(icon: Icons.bar_chart_outlined,         title: 'ລາຍຮັບປະຈຳປີ',             sub: 'Annual Revenue'),
        _AccItem(icon: Icons.attach_money_outlined,      title: 'ລາຍຮັບອື່ນໆ',              sub: 'Other Income'),
        _AccItem(icon: Icons.compare_arrows_outlined,    title: 'ທຽບລາຍຮັບ',               sub: 'Revenue Comparison'),
      ],
    ),

    // 2 ─ ຄ່າໃຊ້ຈ່າຍ
    _AccCategory(
      icon: Icons.money_off_outlined,
      label: 'ຄ່າໃຊ້ຈ່າຍ',
      sublabel: 'Expenses',
      color: Color(0xFFEF5350),
      items: [
        _AccItem(icon: Icons.engineering_outlined,       title: 'ຄ່າແຮງງານ',                sub: 'Labour Cost'),
        _AccItem(icon: Icons.build_outlined,             title: 'ຄ່າບຳລຸງຮັກສາ',            sub: 'Maintenance Cost'),
        _AccItem(icon: Icons.local_gas_station_outlined, title: 'ຄ່ານ້ຳມັນ & ພະລັງງານ',     sub: 'Fuel & Energy Cost'),
        _AccItem(icon: Icons.inventory_outlined,         title: 'ຄ່າວັດສະດຸສິ່ງຂອງ',        sub: 'Material Cost'),
        _AccItem(icon: Icons.business_center_outlined,   title: 'ຄ່າບໍລິຫານທົ່ວໄປ',         sub: 'G&A Expenses'),
        _AccItem(icon: Icons.file_copy_outlined,         title: 'ບັນທຶກຄ່າໃຊ້ຈ່າຍ',         sub: 'Expense Entry'),
      ],
    ),

    // 3 ─ ງົບປະມານ
    _AccCategory(
      icon: Icons.account_balance_outlined,
      label: 'ງົບປະມານ',
      sublabel: 'Budget',
      color: Color(0xFF42A5F5),
      items: [
        _AccItem(icon: Icons.add_chart_outlined,         title: 'ສ້າງງົບປະມານ',             sub: 'Create Budget'),
        _AccItem(icon: Icons.approval_outlined,          title: 'ອະນຸມັດງົບປະມານ',           sub: 'Budget Approval'),
        _AccItem(icon: Icons.track_changes_outlined,     title: 'ຕິດຕາມການໃຊ້ງົບ',           sub: 'Budget Tracking'),
        _AccItem(icon: Icons.difference_outlined,        title: 'ວິເຄາະສ່ວນຕ່າງ',            sub: 'Variance Analysis'),
        _AccItem(icon: Icons.update_outlined,            title: 'ປັບປຸງງົບປະມານ',            sub: 'Budget Revision'),
        _AccItem(icon: Icons.summarize_outlined,         title: 'ສະຫຼຸບງົບປະມານ',            sub: 'Budget Summary'),
      ],
    ),

    // 4 ─ ເງິນເດືອນ & HR
    _AccCategory(
      icon: Icons.payments_outlined,
      label: 'ເງິນເດືອນ & HR',
      sublabel: 'Payroll & HR',
      color: Color(0xFFAB47BC),
      items: [
        _AccItem(icon: Icons.calculate_outlined,         title: 'ຄຳນວນເງິນເດືອນ',           sub: 'Calculate Payroll'),
        _AccItem(icon: Icons.send_outlined,              title: 'ຈ່າຍເງິນເດືອນ',             sub: 'Process Payroll'),
        _AccItem(icon: Icons.receipt_long_outlined,      title: 'ໃບແຈ້ງເງິນເດືອນ',           sub: 'Payslip'),
        _AccItem(icon: Icons.percent_outlined,           title: 'ພາສີ & ປະກັນສັງຄົມ',        sub: 'Tax & Social Security'),
        _AccItem(icon: Icons.workspace_premium_outlined, title: 'ໂບນັດ & ລາງວັນ',           sub: 'Bonus & Incentive'),
        _AccItem(icon: Icons.history_outlined,           title: 'ປະຫວັດການຈ່າຍ',             sub: 'Payment History'),
      ],
    ),

    // 5 ─ ບັນຊີຈ່າຍ-ຮັບ
    _AccCategory(
      icon: Icons.swap_horiz_outlined,
      label: 'ບັນຊີຈ່າຍ-ຮັບ',
      sublabel: 'AP / AR',
      color: Color(0xFF26A69A),
      items: [
        _AccItem(icon: Icons.terrain_outlined,            title: 'ລາຍຮັບລາຍຈ່າຍ ພາກສະໜາມ',       sub: 'Field Accounting'),
        _AccItem(icon: Icons.arrow_circle_up_outlined,   title: 'ລາຍຮັບຄ້າງຈ່າຍ (AR)',       sub: 'Accounts Receivable'),
        _AccItem(icon: Icons.arrow_circle_down_outlined, title: 'ລາຍການຊື້ເຄື່ອງ (ຮ້ານຄາ)',          sub: 'Accounts Payable'),
        _AccItem(icon: Icons.price_check_outlined,       title: 'ຊຳລະໃບແຈ້ງໜີ້',            sub: 'Invoice Payment'),
        _AccItem(icon: Icons.watch_later_outlined,       title: 'ຕິດຕາມໜີ້ຄ້າງ',             sub: 'Overdue Tracking'),
        _AccItem(icon: Icons.assignment_turned_in_outlined, title: 'ປຶກສາໃບກຳກັບ',         sub: 'Reconciliation'),
        _AccItem(icon: Icons.people_outlined,            title: 'ທະບຽນຜູ້ສະໜອງ',            sub: 'Vendor Registry'),
      ],
    ),

    // 6 ─ ສິນຄ້າ & ຊັບສິນ
    _AccCategory(
      icon: Icons.warehouse_outlined,
      label: 'ສິນຄ້າ & ຊັບສິນ',
      sublabel: 'Inventory & Assets',
      color: Color(0xFFFF7043),
      items: [
        _AccItem(icon: Icons.category_outlined,          title: 'ທະບຽນຊັບສິນຖາວອນ',         sub: 'Fixed Assets'),
        _AccItem(icon: Icons.show_chart_outlined,        title: 'ຄ່າເສື່ອມລາຄາ',             sub: 'Depreciation'),
        _AccItem(icon: Icons.inventory_2_outlined,       title: 'ສິນຄ້າຄົງຄັງ',              sub: 'Inventory Valuation'),
        _AccItem(icon: Icons.move_down_outlined,         title: 'ການໂອນຊັບສິນ',              sub: 'Asset Transfer'),
        _AccItem(icon: Icons.delete_forever_outlined,    title: 'ຈຳໜ່າຍຊັບສິນ',              sub: 'Asset Disposal'),
        _AccItem(icon: Icons.qr_code_2_outlined,         title: 'ສຳຫຼວດຊັບສິນ',              sub: 'Asset Audit'),
      ],
    ),

    // 7 ─ ລາຍງານການເງິນ
    _AccCategory(
      icon: Icons.analytics_outlined,
      label: 'ລາຍງານການເງິນ',
      sublabel: 'Financial Reports',
      color: Color(0xFFFFCA28),
      items: [
        _AccItem(icon: Icons.table_chart_outlined,       title: 'ງົບດຸ່ລ (Balance Sheet)',    sub: 'Balance Sheet'),
        _AccItem(icon: Icons.trending_up_outlined,       title: 'ກຳໄລ-ຂາດທຶນ (P&L)',        sub: 'Profit & Loss'),
        _AccItem(icon: Icons.water_drop_outlined,        title: 'ກະແສເງິນສົດ',               sub: 'Cash Flow Statement'),
        _AccItem(icon: Icons.account_tree_outlined,      title: 'ຜັງບັນຊີ (COA)',             sub: 'Chart of Accounts'),
        _AccItem(icon: Icons.download_outlined,          title: 'ສົ່ງອອກລາຍງານ',             sub: 'Export Reports'),
        _AccItem(icon: Icons.picture_as_pdf_outlined,    title: 'ລາຍງານ PDF',                sub: 'PDF Report'),
      ],
    ),

    // 8 ─ ພາສີ & ກົດໝາຍ
    _AccCategory(
      icon: Icons.gavel_outlined,
      label: 'ພາສີ & ກົດໝາຍ',
      sublabel: 'Tax & Compliance',
      color: Color(0xFF78909C),
      items: [
        _AccItem(icon: Icons.percent_outlined,           title: 'ຄຳນວນພາສີມູນຄ່າເພີ່ມ',     sub: 'VAT Calculation'),
        _AccItem(icon: Icons.assignment_outlined,        title: 'ລາຍງານພາສີ',               sub: 'Tax Report'),
        _AccItem(icon: Icons.send_time_extension_outlined, title: 'ຍື່ນພາສີ',               sub: 'Tax Filing'),
        _AccItem(icon: Icons.verified_user_outlined,     title: 'ກວດສອບການປະຕິບັດ',        sub: 'Compliance Check'),
        _AccItem(icon: Icons.policy_outlined,            title: 'ເອກະສານກົດໝາຍ',            sub: 'Legal Documents'),
        _AccItem(icon: Icons.history_edu_outlined,       title: 'ປະຫວັດພາສີ',               sub: 'Tax History'),
      ],
    ),

    // 9 ─ ທະນາຄານ & ເງິນສົດ
    _AccCategory(
      icon: Icons.account_balance_wallet_outlined,
      label: 'ທະນາຄານ & ເງິນສົດ',
      sublabel: 'Banking & Cash',
      color: Color(0xFF29B6F6),
      items: [
        _AccItem(icon: Icons.account_balance_outlined,   title: 'ຈັດການບັນຊີທະນາຄານ',      sub: 'Bank Account Management'),
        _AccItem(icon: Icons.sync_alt_outlined,          title: 'ການໂອນເງິນ',               sub: 'Fund Transfer'),
        _AccItem(icon: Icons.price_check_outlined,       title: 'ກວດສອບໃບ Statement',       sub: 'Bank Reconciliation'),
        _AccItem(icon: Icons.point_of_sale_outlined,     title: 'ຈັດການເງິນສົດ',             sub: 'Petty Cash'),
        _AccItem(icon: Icons.savings_outlined,           title: 'ການລົງທຶນ',                sub: 'Investments'),
        _AccItem(icon: Icons.currency_exchange_outlined, title: 'ອັດຕາແລກປ່ຽນ',             sub: 'Exchange Rate'),
      ],
    ),

    // 10 ─ ກວດສອບ & ຄວບຄຸມ
    _AccCategory(
      icon: Icons.fact_check_outlined,
      label: 'ກວດສອບ & ຄວບຄຸມ',
      sublabel: 'Audit & Control',
      color: Color(0xFFEC407A),
      items: [
        _AccItem(icon: Icons.manage_search_outlined,     title: 'ກວດສອບພາຍໃນ',             sub: 'Internal Audit'),
        _AccItem(icon: Icons.verified_outlined,          title: 'ກວດສອບພາຍນອກ',             sub: 'External Audit'),
        _AccItem(icon: Icons.lock_clock_outlined,        title: 'ປິດປີບັນຊີ',               sub: 'Year-End Closing'),
        _AccItem(icon: Icons.find_in_page_outlined,      title: 'ຕິດຕາມລາຍການ',             sub: 'Transaction Audit Trail'),
        _AccItem(icon: Icons.admin_panel_settings_outlined, title: 'ຄວບຄຸມການເຂົ້າເຖິງ',   sub: 'Access Control'),
        _AccItem(icon: Icons.error_outline,              title: 'ລາຍງານຄວາມຜິດພາດ',        sub: 'Error Report'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _selectedCategory == -1
        ? _buildMainGrid()
        : _buildSubMenu(_categories[_selectedCategory]);
  }

  // ══════════════════════════════════════════
  //  ໜ້າ Grid ຫຼັກ
  // ══════════════════════════════════════════
  Widget _buildMainGrid() {
    return Column(
      children: [
        // ── Header ──────────────────────────
        const _AccHeader(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: Color(0xFF4CAF50),
          title: 'ລະບົບບັນຊີ/ການເງິນ',
          subtitle: 'Namsor HydroPower — Accounting & Finance',
          badge: 'Finance Active',
          badgeColor: Color(0xFF4CAF50),
        ),

        // ── KPI Strip ───────────────────────
        _buildKpiStrip(),

        // ── ແຖວນອນ scroll ─────────────────────
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _CategoryRow(
              cat: _categories[i],
              index: i,
              onTap: () => setState(() => _selectedCategory = i),
            ),
          ),
        ),
      ],
    );
  }

  // ── KPI ຈຳນວນ 4 ກ່ອງ ──────────────────────
  Widget _buildKpiStrip() {
    const kpis = [
      _KpiData(label: 'ລາຍຮັບເດືອນນີ້',  value: '₭ 2.84B',  icon: Icons.trending_up,   color: Color(0xFF4CAF50)),
      _KpiData(label: 'ຄ່າໃຊ້ຈ່າຍ',       value: '₭ 0.96B',  icon: Icons.money_off,     color: Color(0xFFEF5350)),
      _KpiData(label: 'ກຳໄລສຸດທິ',        value: '₭ 1.88B',  icon: Icons.savings,       color: Color(0xFF42A5F5)),
      _KpiData(label: 'ໃບເກັບເງິນ (ຄ້າງ)', value: '12 ໃບ',   icon: Icons.receipt_long,  color: Color(0xFFFFCA28)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: kpis
            .map((k) => Expanded(child: _KpiBox(data: k)))
            .toList(),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  ໜ້າ Sub-menu
  // ══════════════════════════════════════════
  Widget _buildSubMenu(_AccCategory cat) {
    return Column(
      children: [
        // Back header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _BackButton(onTap: () => setState(() => _selectedCategory = -1)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(cat.icon, color: cat.color, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(cat.sublabel,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ]),
              const Spacer(),
              Text('${cat.items.length} ລາຍການ',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),

        // Action grid
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (ctx, bc) {
              final cols = bc.maxWidth > 900 ? 6 : bc.maxWidth > 600 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemCount: cat.items.length,
                itemBuilder: (_, i) => _ActionCard(
                  item: cat.items[i],
                  color: cat.color,
                  onTap: () => _handleItemTap(cat.items[i].title),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  //  ນຳທາງໄປໜ້າທີ່ກ່ຽວຂ້ອງ — ປຸ່ມ "ຄຳນວນເງິນເດືອນ" ແລະ "ຈ່າຍເງິນເດືອນ"
  //  ໃຫ້ໄປເປີດໜ້າດຽວກັນກັບໃນ hr_screen.dart (ໜ້າຕາຕະລາງເງິນເດືອນ HR)
  // ══════════════════════════════════════════
  void _handleItemTap(String title) {
    const payrollTitles = <String>['ຄຳນວນເງິນເດືອນ', 'ຈ່າຍເງິນເດືອນ'];
    if (payrollTitles.contains(title)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HrScreen()),
      );
      return;
    }
    switch (title) {
      case 'ລາຍຮັບລາຍຈ່າຍ ພາກສະໜາມ':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FieldAccountingScreen()));
        return;
      case 'ລາຍການຊື້ເຄື່ອງ (ຮ້ານຄາ)':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PurchaseScreen())); // ແກ້ໄຂແລ້ວ
        return;
      case 'ໃບແຈ້ງເງິນເດືອນ':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PayslipScreen()));
        return;
      case 'ພາສີ & ປະກັນສັງຄົມ':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaxSocialScreen()));
        return;
      case 'ໂບນັດ & ລາງວັນ':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BonusScreen()));
        return;
      case 'ປະຫວັດການຈ່າຍ':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
        return;
    }
    _showDialog(title);
  }

  void _showDialog(String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(children: [
          const Icon(Icons.info_outline, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary))),
        ]),
        content: const Text(
          'ຟັງຊັ່ນນີ້ກຳລັງພັດທະນາ\nThis feature is under development.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຕົກລົງ / OK',
                  style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Re-usable Widgets
// ═══════════════════════════════════════════════════════════════

class _AccHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;

  const _AccHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(Icons.circle, size: 7, color: badgeColor),
            const SizedBox(width: 5),
            Text(badge,
                style: TextStyle(
                    fontSize: 11,
                    color: badgeColor,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

// ── KPI Box ─────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiData(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}

// ================= ປັບປຸງ _KpiBox (ໄອຄອນ ແລະ ຕົວອັກສອນ ຢູ່ກາງ) =================
class _KpiBox extends StatelessWidget {
  final _KpiData data;
  const _KpiBox({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // ໃຫ້ຢູ່ກາງ
        children: [
          Icon(data.icon, color: data.color, size: 22), // ປັບຈາກ 18 ເປັນ 22
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  style: TextStyle(
                      fontSize: 14, // ປັບຈາກ 13 ເປັນ 14
                      fontWeight: FontWeight.w700,
                      color: data.color)),
              Text(data.label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category Row (horizontal card) ─────────────────────────────
// ================= ປັບປຸງ _CategoryRow (ໄອຄອນໃຫຍ່, ຈັດກາງ) =================
class _CategoryRow extends StatelessWidget {
  final _AccCategory cat;
  final int index;
  final VoidCallback onTap;
  const _CategoryRow({required this.cat, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        height: 86,
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ໄອຄອນ ແລະ ຕົວເລກ (ວາງຢູ່ເທິງ)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32, // ປັບຈາກ 26 ເປັນ 32
                  height: 32,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 18), // ປັບຈາກ 13 ເປັນ 18
                ),
                const SizedBox(width: 4),
                Text('${index + 1}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cat.color)),
              ],
            ),
            const SizedBox(height: 6),
            // ຕົວອັກສອນຢູ່ກາງ
            Text(
              cat.label,
              style: const TextStyle(
                fontSize: 11, // ປັບຈາກ 10 ເປັນ 11
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Card ──────────────────────────────────────────────────
// ================= ປັບປຸງ _ActionCard (ໄອຄອນໃຫຍ່, ຈັດກາງ) =================
class _ActionCard extends StatelessWidget {
  final _AccItem item;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.item, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ໄອຄອນໃຫຍ່ຂຶ້ນ
            Container(
              padding: const EdgeInsets.all(8), // ປັບຈາກ 6 ເປັນ 8
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: color, size: 20), // ປັບຈາກ 14 ເປັນ 20
            ),
            const SizedBox(height: 6),
            // ຕົວອັກສອນຢູ່ກາງ
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 10, // ປັບຈາກ 9 ເປັນ 10
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item.sub,
              style: const TextStyle(
                fontSize: 8, // ຄົງເດີມ
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
}

// ── Back Button ──────────────────────────────────────────────────
// ================= ປັບປຸງ _BackButton (ໃຫ້ເດັ່ນຂຶ້ນ) =================
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 20, // ປັບຈາກ 15 ເປັນ 20
          color: AppColors.accent,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Data Models
// ═══════════════════════════════════════════════════════════════
class _AccCategory {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final List<_AccItem> items;
  const _AccCategory({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.items,
  });
}

class _AccItem {
  final IconData icon;
  final String title;
  final String sub;
  const _AccItem({required this.icon, required this.title, required this.sub});
}

// ═══════════════════════════════════════════════════════════════
//  ໜ້າຍ່ອຍ Payroll (ໃບແຈ້ງເງິນເດືອນ / ພາສີ&ປະກັນສັງຄົມ / ໂບນັດ&ລາງວັນ / ປະຫວັດການຈ່າຍ)
//  ໃຊ້ຂໍ້ມູນພະນັກງານ "ຮ່ວມກັນ" ກັບ hr_screen.dart (SharedPreferences key 'nhr_v2')
//  ເພື່ອໃຫ້ຕົວເລກຕໍ່ເນື່ອງກັນທັງລະບົບ — ບໍ່ຕ້ອງປ້ອນຂໍ້ມູນຊ້ຳ
// ═══════════════════════════════════════════════════════════════

const List<String> kAccMonthNames = <String>[
  'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ', 'ພຶດສະພາ', 'ມິຖຸນາ',
  'ກໍລະກົດ', 'ສິງຫາ', 'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
];

// ອັດຕາປະກັນສັງຄົມ (ປະມານການ — ສາມາດປັບໄດ້ຕາມລະບຽບ ສປສ ປະຈຸບັນ)
const double kSsoEmployeeRate = 0.055; // 5.5% ຫັກຈາກພະນັກງານ
const double kSsoEmployerRate = 0.06;  // 6.0% ນາຍຈ້າງສົມທົບ

// ─── ໂຫຼດຖານຂໍ້ມູນເງິນເດືອນຮ່ວມກັນກັບ HR (key: 'YYYY_MM' → List<Employee>) ───
Future<Map<String, List<Employee>>> loadPayrollDb() async {
  final prefs = await SharedPreferences.getInstance();
  final dbStr = prefs.getString('nhr_v2');
  if (dbStr == null) return <String, List<Employee>>{};
  try {
    final Map<String, dynamic> raw = jsonDecode(dbStr);
    return raw.map((key, value) {
      final list = (value as List).map((e) => Employee.fromJson(e)).toList();
      return MapEntry(key, list);
    });
  } catch (_) {
    return <String, List<Employee>>{};
  }
}

String fmtKip(double v) {
  final String s = v.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

DataColumn accCol(String label, {bool numeric = false}) => DataColumn(
      label: Text(label,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      numeric: numeric,
    );

// ─── ຫໍ່ DataTable ໃຫ້ scroll ໄດ້ທັງ 2 ທິດທາງ ແລະ ເຕັມຄວາມກວ້າງຈໍສະເໝີ ───
Widget accTableWrap(Widget table) {
  return LayoutBuilder(builder: (ctx, bc) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: bc.maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: table,
        ),
      ),
    );
  });
}

// ─── ສ່ວນຫົວທີ່ໃຊ້ຮ່ວມກັນ ສຳລັບໜ້າຍ່ອຍທັງໝົດ ───
class SubScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  const SubScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.arrow_back, size: 18, color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 10),
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ]),
          ]),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── ຕົວເລືອກ ເດືອນ/ປີ ໃຊ້ຮ່ວມກັນທຸກໜ້າຍ່ອຍ ───
class MonthYearPicker extends StatelessWidget {
  final String month; // '01'..'12'
  final String year; // '2026'
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<String> onYearChanged;
  const MonthYearPicker({
    super.key,
    required this.month,
    required this.year,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final int curYear = DateTime.now().year;
    final List<String> years = List<String>.generate(5, (i) => '${curYear - 2 + i}');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: month,
            dropdownColor: AppColors.bgSecondary,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            items: List<DropdownMenuItem<String>>.generate(12, (i) {
              final String mm = '${i + 1}'.padLeft(2, '0');
              return DropdownMenuItem<String>(value: mm, child: Text(kAccMonthNames[i]));
            }),
            onChanged: (v) {
              if (v != null) onMonthChanged(v);
            },
          ),
        ),
        const SizedBox(width: 10),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: year,
            dropdownColor: AppColors.bgSecondary,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            items: years.map((y) => DropdownMenuItem<String>(value: y, child: Text(y))).toList(),
            onChanged: (v) {
              if (v != null) onYearChanged(v);
            },
          ),
        ),
      ]),
    );
  }
}

// ─── ສະຖານະວ່າງ (ບໍ່ມີຂໍ້ມູນ) ───
class EmptyMonthState extends StatelessWidget {
  final String message;
  const EmptyMonthState({super.key, this.message = 'ບໍ່ມີຂໍ້ມູນເດືອນນີ້ — ກະລຸນາເພີ່ມພະນັກງານຢູ່ໜ້າ HR ກ່ອນ'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textMuted),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  1. ໃບແຈ້ງເງິນເດືອນ — Payslip
// ═══════════════════════════════════════════════════════════════
class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});
  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final DateTime _now = DateTime.now();
  late String _month;
  late String _year;
  Map<String, List<Employee>> _db = <String, List<Employee>>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _month = '${_now.month}'.padLeft(2, '0');
    _year = '${_now.year}';
    _load();
  }

  Future<void> _load() async {
    final db = await loadPayrollDb();
    if (!mounted) return;
    setState(() {
      _db = db;
      _loading = false;
    });
  }

  List<Employee> get _employees => _db['${_year}_$_month'] ?? <Employee>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          SubScreenHeader(
            title: 'ໃບແຈ້ງເງິນເດືອນ',
            subtitle: 'Payslip — ${kAccMonthNames[int.parse(_month) - 1]} $_year',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFFAB47BC),
            trailing: MonthYearPicker(
              month: _month,
              year: _year,
              onMonthChanged: (v) => setState(() => _month = v),
              onYearChanged: (v) => setState(() => _year = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _employees.isEmpty
                    ? const EmptyMonthState()
                    : accTableWrap(DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
                        dataRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
                        border: TableBorder.all(color: AppColors.border, width: 1),
                        columns: [
                          accCol('No'),
                          accCol('ຊື່ພະນັກງານ'),
                          accCol('ຕຳແໜ່ງ'),
                          accCol('ເງິນເດືອນພື້ນ', numeric: true),
                          accCol('ລວມລາຍຮັບ', numeric: true),
                          accCol('ອາກອນ', numeric: true),
                          accCol('ສຸດທິ', numeric: true),
                          accCol('ໃບແຈ້ງ'),
                        ],
                        rows: _employees.asMap().entries.map((entry) {
                          final int i = entry.key;
                          final Employee e = entry.value;
                          final TaxResult r = calcTax(e.basic, e.ot, e.living, e.other, e.deduct);
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                            DataCell(Text(e.name,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text(e.role,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                            DataCell(Text(fmtKip(e.basic),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
                            DataCell(Text(fmtKip(r.gross),
                                style: const TextStyle(
                                    color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600))),
                            DataCell(Text(fmtKip(r.tax),
                                style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12))),
                            DataCell(Text(fmtKip(r.net),
                                style: const TextStyle(
                                    color: Color(0xFF42A5F5), fontSize: 12, fontWeight: FontWeight.w700))),
                            DataCell(InkWell(
                              onTap: () => _showPayslipDetail(e, r),
                              child: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.accent),
                            )),
                          ]);
                        }).toList(),
                      )),
          ),
        ]),
      ),
    );
  }

  void _showPayslipDetail(Employee e, TaxResult r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
        title: Row(children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('ໃບແຈ້ງເງິນເດືອນ — ${e.name}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
        ]),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _payslipRow('ເງິນເດືອນພື້ນ', e.basic),
            _payslipRow('ໂອທີ', e.ot),
            _payslipRow('ອັດຕາກິນ/ເດີນທາງ', e.living),
            _payslipRow('ລາຍຮັບອື່ນໆ', e.other),
            const Divider(color: AppColors.border),
            _payslipRow('ລວມລາຍຮັບ (Gross)', r.gross, bold: true, color: const Color(0xFF4CAF50)),
            _payslipRow('ຫັກ (ມຕ.35)', e.deduct, color: const Color(0xFFEF5350)),
            _payslipRow('ອາກອນເງິນເດືອນ', r.tax, color: const Color(0xFFEF5350)),
            const Divider(color: AppColors.border),
            _payslipRow('ເງິນເດືອນສຸດທິ', r.net, bold: true, color: const Color(0xFF42A5F5)),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ປິດ', style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
  }

  Widget _payslipRow(String label, double value, {bool bold = false, Color color = AppColors.textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Text('${fmtKip(value)} ₭',
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  2. ພາສີ & ປະກັນສັງຄົມ — Tax & Social Security
// ═══════════════════════════════════════════════════════════════
class TaxSocialScreen extends StatefulWidget {
  const TaxSocialScreen({super.key});
  @override
  State<TaxSocialScreen> createState() => _TaxSocialScreenState();
}

class _TaxSocialScreenState extends State<TaxSocialScreen> {
  final DateTime _now = DateTime.now();
  late String _month;
  late String _year;
  Map<String, List<Employee>> _db = <String, List<Employee>>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _month = '${_now.month}'.padLeft(2, '0');
    _year = '${_now.year}';
    _load();
  }

  Future<void> _load() async {
    final db = await loadPayrollDb();
    if (!mounted) return;
    setState(() {
      _db = db;
      _loading = false;
    });
  }

  List<Employee> get _employees => _db['${_year}_$_month'] ?? <Employee>[];

  @override
  Widget build(BuildContext context) {
    double totalTax = 0, totalSsoEmp = 0, totalSsoEmployer = 0, totalNet = 0;
    for (final e in _employees) {
      final r = calcTax(e.basic, e.ot, e.living, e.other, e.deduct);
      final ssoEmp = e.basic * kSsoEmployeeRate;
      totalTax += r.tax;
      totalSsoEmp += ssoEmp;
      totalSsoEmployer += e.basic * kSsoEmployerRate;
      totalNet += r.net - ssoEmp;
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          SubScreenHeader(
            title: 'ພາສີ & ປະກັນສັງຄົມ',
            subtitle: 'Tax & Social Security — ${kAccMonthNames[int.parse(_month) - 1]} $_year',
            icon: Icons.percent_outlined,
            color: const Color(0xFF78909C),
            trailing: MonthYearPicker(
              month: _month,
              year: _year,
              onMonthChanged: (v) => setState(() => _month = v),
              onYearChanged: (v) => setState(() => _year = v),
            ),
          ),
          if (!_loading && _employees.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.bgSecondary,
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                _miniStat('ລວມອາກອນ', totalTax, const Color(0xFFEF5350)),
                _miniStat('ປະກັນສັງຄົມ (ພະນັກງານ)', totalSsoEmp, const Color(0xFFFFCA28)),
                _miniStat('ປະກັນສັງຄົມ (ນາຍຈ້າງ)', totalSsoEmployer, const Color(0xFF42A5F5)),
                _miniStat('ສຸດທິລວມ', totalNet, const Color(0xFF4CAF50)),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _employees.isEmpty
                    ? const EmptyMonthState()
                    : accTableWrap(DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
                        dataRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
                        border: TableBorder.all(color: AppColors.border, width: 1),
                        columns: [
                          accCol('No'),
                          accCol('ຊື່ພະນັກງານ'),
                          accCol('ເງິນເດືອນລວມ', numeric: true),
                          accCol('ຍົກເວັ້ນ', numeric: true),
                          accCol('5%', numeric: true),
                          accCol('10%', numeric: true),
                          accCol('15%+', numeric: true),
                          accCol('ອາກອນລວມ', numeric: true),
                          accCol('ປະກັນສັງຄົມ (ພນ.)', numeric: true),
                          accCol('ປະກັນສັງຄົມ (ນຈ.)', numeric: true),
                          accCol('ສຸດທິ', numeric: true),
                        ],
                        rows: _employees.asMap().entries.map((entry) {
                          final int i = entry.key;
                          final Employee e = entry.value;
                          final TaxResult r = calcTax(e.basic, e.ot, e.living, e.other, e.deduct);
                          final double ssoEmp = e.basic * kSsoEmployeeRate;
                          final double ssoEmployer = e.basic * kSsoEmployerRate;
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                            DataCell(Text(e.name,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text(fmtKip(r.gross),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
                            DataCell(Text(fmtKip(r.exempt),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                            DataCell(Text(r.b5 > 0 ? fmtKip(r.b5) : '0',
                                style: const TextStyle(color: Color(0xFFFFCA28), fontSize: 12))),
                            DataCell(Text(r.b10 > 0 ? fmtKip(r.b10) : '0',
                                style: const TextStyle(color: Color(0xFFFFCA28), fontSize: 12))),
                            DataCell(Text(r.b15Up > 0 ? fmtKip(r.b15Up) : '0',
                                style: const TextStyle(color: Color(0xFFFFCA28), fontSize: 12))),
                            DataCell(Text(fmtKip(r.tax),
                                style: const TextStyle(
                                    color: Color(0xFFEF5350), fontSize: 12, fontWeight: FontWeight.w600))),
                            DataCell(Text(fmtKip(ssoEmp),
                                style: const TextStyle(color: Color(0xFFFFCA28), fontSize: 12))),
                            DataCell(Text(fmtKip(ssoEmployer),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                            DataCell(Text(fmtKip(r.net - ssoEmp),
                                style: const TextStyle(
                                    color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w700))),
                          ]);
                        }).toList(),
                      )),
          ),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        Text('${fmtKip(value)} ₭',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  3. ໂບນັດ & ລາງວັນ — Bonus & Incentive
// ═══════════════════════════════════════════════════════════════
class BonusRecord {
  final String employeeId;
  String employeeName;
  String role;
  double performance;
  double holiday;
  double other;
  BonusRecord({
    required this.employeeId,
    required this.employeeName,
    this.role = '',
    this.performance = 0,
    this.holiday = 0,
    this.other = 0,
  });

  double get total => performance + holiday + other;

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'role': role,
        'performance': performance,
        'holiday': holiday,
        'other': other,
      };

  factory BonusRecord.fromJson(Map<String, dynamic> j) => BonusRecord(
        employeeId: j['employeeId'] ?? '',
        employeeName: j['employeeName'] ?? '',
        role: j['role'] ?? '',
        performance: (j['performance'] ?? 0).toDouble(),
        holiday: (j['holiday'] ?? 0).toDouble(),
        other: (j['other'] ?? 0).toDouble(),
      );
}

class BonusScreen extends StatefulWidget {
  const BonusScreen({super.key});
  @override
  State<BonusScreen> createState() => _BonusScreenState();
}

class _BonusScreenState extends State<BonusScreen> {
  static const String _kBonusKey = 'nacc_bonus_v1';
  final DateTime _now = DateTime.now();
  late String _month;
  late String _year;
  Map<String, List<BonusRecord>> _bonusDb = <String, List<BonusRecord>>{};
  List<Employee> _employees = <Employee>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _month = '${_now.month}'.padLeft(2, '0');
    _year = '${_now.year}';
    _load();
  }

  String get _key => '${_year}_$_month';

  Future<void> _load() async {
    setState(() => _loading = true);
    final payrollDb = await loadPayrollDb();
    final prefs = await SharedPreferences.getInstance();
    final bonusStr = prefs.getString(_kBonusKey);
    Map<String, List<BonusRecord>> bonusDb = <String, List<BonusRecord>>{};
    if (bonusStr != null) {
      try {
        final Map<String, dynamic> raw = jsonDecode(bonusStr);
        bonusDb = raw.map((key, value) {
          final list = (value as List).map((e) => BonusRecord.fromJson(e)).toList();
          return MapEntry(key, list);
        });
      } catch (_) {}
    }
    final emps = payrollDb[_key] ?? <Employee>[];
    final List<BonusRecord> existing = bonusDb[_key] ?? <BonusRecord>[];
    // ສ້າງແຖວໂບນັດໃຫ້ພະນັກງານທີ່ຍັງບໍ່ມີຂໍ້ມູນ ໂດຍອີງຕາມລາຍຊື່ HR ເດືອນນັ້ນ
    final List<BonusRecord> merged = emps.map((e) {
      final found = existing.where((b) => b.employeeId == e.id);
      if (found.isNotEmpty) {
        final b = found.first;
        b.employeeName = e.name;
        b.role = e.role;
        return b;
      }
      return BonusRecord(employeeId: e.id, employeeName: e.name, role: e.role);
    }).toList();
    bonusDb[_key] = merged;

    if (!mounted) return;
    setState(() {
      _bonusDb = bonusDb;
      _employees = emps;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = _bonusDb.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()));
    await prefs.setString(_kBonusKey, jsonEncode(jsonMap));
  }

  List<BonusRecord> get _records => _bonusDb[_key] ?? <BonusRecord>[];

  void _editBonus(int index) {
    final b = _records[index];
    final perfCtrl = TextEditingController(text: b.performance == 0 ? '' : b.performance.toStringAsFixed(0));
    final holCtrl = TextEditingController(text: b.holiday == 0 ? '' : b.holiday.toStringAsFixed(0));
    final otherCtrl = TextEditingController(text: b.other == 0 ? '' : b.other.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
        title: Row(children: [
          const Icon(Icons.workspace_premium_outlined, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('ໂບນັດ & ລາງວັນ — ${b.employeeName}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
        ]),
        content: SizedBox(
          width: 320,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _bonusField('ໂບນັດຜົນງານ', perfCtrl),
            const SizedBox(height: 10),
            _bonusField('ໂບນັດບຸນປີ/ກິດຈະການ', holCtrl),
            const SizedBox(height: 10),
            _bonusField('ລາງວັນ/ອື່ນໆ', otherCtrl),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
              onPressed: () {
                setState(() {
                  b.performance = double.tryParse(perfCtrl.text) ?? 0;
                  b.holiday = double.tryParse(holCtrl.text) ?? 0;
                  b.other = double.tryParse(otherCtrl.text) ?? 0;
                });
                _persist();
                Navigator.pop(context);
              },
              child: const Text('ບັນທຶກ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _bonusField(String label, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.bgPrimary,
          suffixText: '₭',
          suffixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.accent)),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final double totalBonus = _records.fold(0.0, (s, b) => s + b.total);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          SubScreenHeader(
            title: 'ໂບນັດ & ລາງວັນ',
            subtitle: 'Bonus & Incentive — ${kAccMonthNames[int.parse(_month) - 1]} $_year',
            icon: Icons.workspace_premium_outlined,
            color: const Color(0xFFAB47BC),
            trailing: MonthYearPicker(
              month: _month,
              year: _year,
              onMonthChanged: (v) {
                setState(() => _month = v);
                _load();
              },
              onYearChanged: (v) {
                setState(() => _year = v);
                _load();
              },
            ),
          ),
          if (!_loading && _records.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.bgSecondary,
              child: Row(children: [
                const Icon(Icons.savings_outlined, size: 14, color: Color(0xFFAB47BC)),
                const SizedBox(width: 6),
                Text('ລວມໂບນັດທັງໝົດ: ${fmtKip(totalBonus)} ₭',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFAB47BC))),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _employees.isEmpty
                    ? const EmptyMonthState()
                    : accTableWrap(DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
                        dataRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
                        border: TableBorder.all(color: AppColors.border, width: 1),
                        columns: [
                          accCol('No'),
                          accCol('ຊື່ພະນັກງານ'),
                          accCol('ຕຳແໜ່ງ'),
                          accCol('ໂບນັດຜົນງານ', numeric: true),
                          accCol('ໂບນັດບຸນປີ', numeric: true),
                          accCol('ອື່ນໆ', numeric: true),
                          accCol('ລວມໂບນັດ', numeric: true),
                          accCol('ຈັດການ'),
                        ],
                        rows: _records.asMap().entries.map((entry) {
                          final int i = entry.key;
                          final BonusRecord b = entry.value;
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                            DataCell(Text(b.employeeName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text(b.role,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                            DataCell(Text(fmtKip(b.performance),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
                            DataCell(Text(fmtKip(b.holiday),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
                            DataCell(Text(fmtKip(b.other),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
                            DataCell(Text(fmtKip(b.total),
                                style: const TextStyle(
                                    color: Color(0xFFAB47BC), fontSize: 12, fontWeight: FontWeight.w700))),
                            DataCell(InkWell(
                              onTap: () => _editBonus(i),
                              child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                            )),
                          ]);
                        }).toList(),
                      )),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  4. ປະຫວັດການຈ່າຍ — Payment History
// ═══════════════════════════════════════════════════════════════
class _MonthSummary {
  final String key;
  final String label;
  final int count;
  final double gross;
  final double tax;
  final double net;
  final List<Employee> employees;
  _MonthSummary({
    required this.key,
    required this.label,
    required this.count,
    required this.gross,
    required this.tax,
    required this.net,
    required this.employees,
  });
}

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});
  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<_MonthSummary> _summaries = <_MonthSummary>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await loadPayrollDb();
    final List<_MonthSummary> list = [];
    for (final entry in db.entries) {
      final parts = entry.key.split('_');
      if (parts.length != 2) continue;
      final String year = parts[0];
      final String month = parts[1];
      final int? mIdx = int.tryParse(month);
      if (mIdx == null || mIdx < 1 || mIdx > 12) continue;
      final List<Employee> emps = entry.value;
      if (emps.isEmpty) continue;
      double gross = 0, tax = 0, net = 0;
      for (final e in emps) {
        final r = calcTax(e.basic, e.ot, e.living, e.other, e.deduct);
        gross += r.gross;
        tax += r.tax;
        net += r.net;
      }
      list.add(_MonthSummary(
        key: entry.key,
        label: '${kAccMonthNames[mIdx - 1]} $year',
        count: emps.length,
        gross: gross,
        tax: tax,
        net: net,
        employees: emps,
      ));
    }
    list.sort((a, b) => b.key.compareTo(a.key));
    if (!mounted) return;
    setState(() {
      _summaries = list;
      _loading = false;
    });
  }

  void _showDetail(_MonthSummary m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
        title: Row(children: [
          const Icon(Icons.history_outlined, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('ລາຍລະອຽດການຈ່າຍ — ${m.label}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
        ]),
        content: SizedBox(
          width: 380,
          height: 320,
          child: ListView.separated(
            itemCount: m.employees.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
            itemBuilder: (_, i) {
              final e = m.employees[i];
              final r = calcTax(e.basic, e.ot, e.living, e.other, e.deduct);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.name,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      Text(e.role, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ]),
                  ),
                  Text('${fmtKip(r.net)} ₭',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF42A5F5), fontWeight: FontWeight.w700)),
                ]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ປິດ', style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          const SubScreenHeader(
            title: 'ປະຫວັດການຈ່າຍ',
            subtitle: 'Payment History — ທຸກເດືອນທີ່ມີການຈ່າຍເງິນເດືອນ',
            icon: Icons.history_outlined,
            color: Color(0xFF26A69A),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _summaries.isEmpty
                    ? const EmptyMonthState(message: 'ຍັງບໍ່ມີປະຫວັດການຈ່າຍເງິນເດືອນ')
                    : accTableWrap(DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
                        dataRowColor: WidgetStateProperty.all(AppColors.bgSecondary),
                        border: TableBorder.all(color: AppColors.border, width: 1),
                        columns: [
                          accCol('No'),
                          accCol('ເດືອນ/ປີ'),
                          accCol('ຈຳນວນພະນັກງານ', numeric: true),
                          accCol('ລວມລາຍຮັບ', numeric: true),
                          accCol('ລວມອາກອນ', numeric: true),
                          accCol('ລວມສຸດທິ', numeric: true),
                          accCol('ສະຖານະ'),
                          accCol('ລາຍລະອຽດ'),
                        ],
                        rows: _summaries.asMap().entries.map((entry) {
                          final int i = entry.key;
                          final _MonthSummary m = entry.value;
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                            DataCell(Text(m.label,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text('${m.count}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                            DataCell(Text(fmtKip(m.gross),
                                style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12))),
                            DataCell(Text(fmtKip(m.tax),
                                style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12))),
                            DataCell(Text(fmtKip(m.net),
                                style: const TextStyle(
                                    color: Color(0xFF42A5F5), fontSize: 12, fontWeight: FontWeight.w700))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                              ),
                              child: const Text('ຈ່າຍແລ້ວ',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                            )),
                            DataCell(InkWell(
                              onTap: () => _showDetail(m),
                              child: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.accent),
                            )),
                          ]);
                        }).toList(),
                      )),
          ),
        ]),
      ),
    );
  }
}