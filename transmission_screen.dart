import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
//  TransmissionScreen — ສາຍສົ່ງໄຟຟ້າ Namsor HydroPower
// ═══════════════════════════════════════════════════════════════
class TransmissionScreen extends StatefulWidget {
  const TransmissionScreen({super.key});
  @override
  State<TransmissionScreen> createState() => _TransmissionScreenState();
}

class _TransmissionScreenState extends State<TransmissionScreen> {
  int _selectedCategory = -1;

  // ══════════════════════════════════════════
  // ໝວດໝູ່ທັງໝົດ 10 ໝວດ
  // ══════════════════════════════════════════
  static const List<_TxCategory> _categories = [

    // 1 ─ ຕິດຕາມສາຍສົ່ງ
    _TxCategory(
      icon: Icons.cable_outlined,
      label: 'ຕິດຕາມສາຍສົ່ງ',
      sublabel: 'Line Monitoring',
      color: Color(0xFF42A5F5),
      items: [
        _TxItem(icon: Icons.show_chart_outlined,          title: 'ສະຖານະສາຍສົ່ງ Real-time',  sub: 'Real-time Line Status'),
        _TxItem(icon: Icons.electric_bolt_outlined,       title: 'ກະແສໄຟຟ້າ (Current)',       sub: 'Current Monitoring'),
        _TxItem(icon: Icons.bolt_outlined,                title: 'ແຮງດັນໄຟຟ້າ (Voltage)',     sub: 'Voltage Monitoring'),
        _TxItem(icon: Icons.speed_outlined,               title: 'ຄວາມຖີ່ (Frequency)',        sub: 'Frequency Monitoring'),
        _TxItem(icon: Icons.power_outlined,               title: 'ພະລັງງານທີ່ສົ່ງ (MW)',       sub: 'Power Transmitted (MW)'),
        _TxItem(icon: Icons.timeline_outlined,            title: 'ກາຟສາຍສົ່ງ',               sub: 'Transmission Graph'),
      ],
    ),

    // 2 ─ ສະຖານີຍ່ອຍ
    _TxCategory(
      icon: Icons.account_balance_outlined,
      label: 'ສະຖານີຍ່ອຍ',
      sublabel: 'Substation',
      color: Color(0xFFFFB300),
      items: [
        _TxItem(icon: Icons.dashboard_outlined,           title: 'ພາບລວມສະຖານີຍ່ອຍ',         sub: 'Substation Overview'),
        _TxItem(icon: Icons.tune_outlined,                title: 'ຄວບຄຸມ Transformer',        sub: 'Transformer Control'),
        _TxItem(icon: Icons.device_hub_outlined,          title: 'ສະຖານະ Busbar',             sub: 'Busbar Status'),
        _TxItem(icon: Icons.toggle_on_outlined,           title: 'ສະຖານະ Breaker/Switch',     sub: 'Breaker & Switch Status'),
        _TxItem(icon: Icons.thermostat_outlined,          title: 'ອຸນຫະພູມ Transformer',       sub: 'Transformer Temperature'),
        _TxItem(icon: Icons.oil_barrel_outlined,          title: 'ລະດັບນ້ຳມັນ Transformer',   sub: 'Transformer Oil Level'),
      ],
    ),

    // 3 ─ ການປ້ອງກັນ (Protection)
    _TxCategory(
      icon: Icons.shield_outlined,
      label: 'ການປ້ອງກັນ',
      sublabel: 'Protection System',
      color: Color(0xFFEF5350),
      items: [
        _TxItem(icon: Icons.security_outlined,            title: 'ສະຖານະ Relay ປ້ອງກັນ',      sub: 'Protection Relay Status'),
        _TxItem(icon: Icons.flash_on_outlined,            title: 'ການຕັດໄຟ (Trip) ລ່າສຸດ',    sub: 'Latest Trip Events'),
        _TxItem(icon: Icons.gpp_bad_outlined,             title: 'ຄວາມຜິດພາດສາຍດິນ',         sub: 'Earth Fault'),
        _TxItem(icon: Icons.warning_amber_outlined,       title: 'ການລັດໄຟ (Short Circuit)',   sub: 'Short Circuit Protection'),
        _TxItem(icon: Icons.settings_input_component_outlined, title: 'ຕັ້ງຄ່າ Relay',       sub: 'Relay Settings'),
        _TxItem(icon: Icons.history_outlined,             title: 'ປະຫວັດການ Trip',            sub: 'Trip History'),
      ],
    ),

    // 4 ─ ສາຍສົ່ງ & ສາຍເຊື່ອມ
    _TxCategory(
      icon: Icons.electrical_services_outlined,
      label: 'ສາຍສົ່ງ & ເຊື່ອມ',
      sublabel: 'Lines & Interconnection',
      color: Color(0xFF26A69A),
      items: [
        _TxItem(icon: Icons.route_outlined,               title: 'ທະບຽນສາຍສົ່ງ',             sub: 'Transmission Line Registry'),
        _TxItem(icon: Icons.map_outlined,                 title: 'ແຜນທີ່ສາຍສົ່ງ GIS',         sub: 'GIS Line Map'),
        _TxItem(icon: Icons.link_outlined,                title: 'ຈຸດເຊື່ອມຕໍ່ Grid',          sub: 'Grid Interconnection Points'),
        _TxItem(icon: Icons.straighten_outlined,          title: 'ຄວາມຍາວ & ຂະໜາດສາຍ',      sub: 'Line Length & Size'),
        _TxItem(icon: Icons.cell_tower_outlined,          title: 'ເສົາໄຟຟ້າ (Tower)',          sub: 'Tower Management'),
        _TxItem(icon: Icons.hub_outlined,                 title: 'ສາຍສົ່ງ 115kV / 22kV',      sub: '115kV / 22kV Lines'),
      ],
    ),

    // 5 ─ ການໂຫຼດ & ດຸ່ນດ່ຽງ
    _TxCategory(
      icon: Icons.balance_outlined,
      label: 'ໂຫຼດ & ດຸ່ນດ່ຽງ',
      sublabel: 'Load & Balancing',
      color: Color(0xFFAB47BC),
      items: [
        _TxItem(icon: Icons.equalizer_outlined,           title: 'ການໂຫຼດ Real-time',         sub: 'Real-time Load'),
        _TxItem(icon: Icons.trending_flat_outlined,       title: 'ດຸ່ນດ່ຽງໂຫຼດ',              sub: 'Load Balancing'),
        _TxItem(icon: Icons.stacked_line_chart_outlined,  title: 'ກາຟໂຫຼດລາຍວັນ',            sub: 'Daily Load Curve'),
        _TxItem(icon: Icons.calendar_view_week_outlined,  title: 'ການພະຍາກອນໂຫຼດ',           sub: 'Load Forecasting'),
        _TxItem(icon: Icons.device_thermostat_outlined,   title: 'ການໂຫຼດສູງສຸດ (Peak)',      sub: 'Peak Load'),
        _TxItem(icon: Icons.low_priority_outlined,        title: 'ການໂຫຼດຕ່ຳສຸດ (Off-Peak)',  sub: 'Off-Peak Load'),
      ],
    ),

    // 6 ─ ຄຸນນະພາບໄຟຟ້າ
    _TxCategory(
      icon: Icons.high_quality_outlined,
      label: 'ຄຸນນະພາບໄຟຟ້າ',
      sublabel: 'Power Quality',
      color: Color(0xFF29B6F6),
      items: [
        _TxItem(icon: Icons.waves_outlined,               title: 'ການຜິດຮູບຄື້ນ (THD)',        sub: 'Total Harmonic Distortion'),
        _TxItem(icon: Icons.power_input_outlined,         title: 'ຄ່າ Power Factor',           sub: 'Power Factor'),
        _TxItem(icon: Icons.compress_outlined,            title: 'ແຮງດັນຕ່ຳ/ສູງ (Sag/Swell)', sub: 'Voltage Sag & Swell'),
        _TxItem(icon: Icons.filter_outlined,              title: 'ການກ່ຽວກວນ (Interference)',  sub: 'Electrical Interference'),
        _TxItem(icon: Icons.analytics_outlined,           title: 'ລາຍງານຄຸນນະພາບ',           sub: 'Power Quality Report'),
        _TxItem(icon: Icons.troubleshoot_outlined,        title: 'ກວດວິເຄາະ Harmonics',       sub: 'Harmonics Analysis'),
      ],
    ),

    // 7 ─ ບຳລຸງຮັກສາ
    _TxCategory(
      icon: Icons.build_circle_outlined,
      label: 'ບຳລຸງຮັກສາ',
      sublabel: 'Maintenance',
      color: Color(0xFFFF7043),
      items: [
        _TxItem(icon: Icons.event_available_outlined,     title: 'ແຜນບຳລຸງຮັກສາ',            sub: 'Maintenance Schedule'),
        _TxItem(icon: Icons.construction_outlined,        title: 'ແຈ້ງສ້ອມແປງສາຍ',           sub: 'Line Repair Request'),
        _TxItem(icon: Icons.engineering_outlined,         title: 'ທີມງານສ້ອມແປງ',             sub: 'Repair Team'),
        _TxItem(icon: Icons.checklist_rtl_outlined,       title: 'ກວດກາ Transformer',         sub: 'Transformer Inspection'),
        _TxItem(icon: Icons.electric_meter_outlined,      title: 'ກວດກາ Meter',               sub: 'Meter Inspection'),
        _TxItem(icon: Icons.assignment_turned_in_outlined,title: 'ບັນທຶກການບຳລຸງ',           sub: 'Maintenance Log'),
      ],
    ),

    // 8 ─ ການສູນເສຍ & ປະສິດທິຜົນ
    _TxCategory(
      icon: Icons.leak_add_outlined,
      label: 'ການສູນເສຍ & ປະສິດທິ',
      sublabel: 'Losses & Efficiency',
      color: Color(0xFF78909C),
      items: [
        _TxItem(icon: Icons.compare_outlined,             title: 'ການສູນເສຍສາຍສົ່ງ (%)',      sub: 'Transmission Losses %'),
        _TxItem(icon: Icons.speed_outlined,               title: 'ປະສິດທິຜົນລວມ',             sub: 'Overall Efficiency'),
        _TxItem(icon: Icons.thermostat_outlined,          title: 'ຄວາມຮ້ອນສາຍ (Line Heat)',   sub: 'Line Heat Loss'),
        _TxItem(icon: Icons.eco_outlined,                 title: 'ຫຼຸດການສູນເສຍ',              sub: 'Loss Reduction Plan'),
        _TxItem(icon: Icons.energy_savings_leaf_outlined, title: 'ການຊົດເຊີຍ Reactive',       sub: 'Reactive Compensation'),
        _TxItem(icon: Icons.bar_chart_outlined,           title: 'ລາຍງານການສູນເສຍ',          sub: 'Loss Report'),
      ],
    ),

    // 9 ─ ເຫດການ & ແຈ້ງເຕືອນ
    _TxCategory(
      icon: Icons.notifications_active_outlined,
      label: 'ເຫດການ & ແຈ້ງເຕືອນ',
      sublabel: 'Events & Alarms',
      color: Color(0xFFEC407A),
      items: [
        _TxItem(icon: Icons.crisis_alert_outlined,        title: 'ສຸກເສີນສາຍຂາດ',             sub: 'Line Fault Emergency'),
        _TxItem(icon: Icons.alarm_outlined,               title: 'ການແຈ້ງເຕືອນ Active',        sub: 'Active Alarms'),
        _TxItem(icon: Icons.history_outlined,             title: 'ປະຫວັດເຫດການ',              sub: 'Event History'),
        _TxItem(icon: Icons.report_problem_outlined,      title: 'ລາຍງານເຫດການ',             sub: 'Incident Report'),
        _TxItem(icon: Icons.notifications_paused_outlined,title: 'ລົບລ້າງ Alarm',             sub: 'Alarm Acknowledgement'),
        _TxItem(icon: Icons.send_outlined,                title: 'ແຈ້ງທີມງານ',                sub: 'Notify Team'),
      ],
    ),

    // 10 ─ ລາຍງານ & ເອກະສານ
    _TxCategory(
      icon: Icons.summarize_outlined,
      label: 'ລາຍງານ & ເອກະສານ',
      sublabel: 'Reports & Documents',
      color: Color(0xFF66BB6A),
      items: [
        _TxItem(icon: Icons.receipt_long_outlined,        title: 'ລາຍງານປະຈຳວັນ',             sub: 'Daily Report'),
        _TxItem(icon: Icons.calendar_month_outlined,      title: 'ລາຍງານປະຈຳເດືອນ',          sub: 'Monthly Report'),
        _TxItem(icon: Icons.insert_chart_outlined,        title: 'ລາຍງານ SCADA Export',        sub: 'SCADA Data Export'),
        _TxItem(icon: Icons.picture_as_pdf_outlined,      title: 'ສົ່ງອອກ PDF',               sub: 'Export PDF'),
        _TxItem(icon: Icons.folder_zip_outlined,          title: 'ທັງໝົດ / Archive',           sub: 'Archive & Download'),
        _TxItem(icon: Icons.description_outlined,         title: 'SLD Diagram',               sub: 'Single Line Diagram'),
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
        const _TxHeader(
          icon: Icons.cable_outlined,
          iconColor: Color(0xFF42A5F5),
          title: 'ລະບົບສາຍສົ່ງໄຟຟ້າ',
          subtitle: 'Namsor HydroPower — Transmission System',
          badge: 'Grid Online',
          badgeColor: Color(0xFF4CAF50),
        ),

        // ── Status Strip ─────────────────────
        _buildStatusStrip(),

        // ── Grid ────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (ctx, bc) {
              final cols =
                  bc.maxWidth > 900 ? 5 : bc.maxWidth > 600 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                itemCount: _categories.length,
                itemBuilder: (_, i) => _CategoryCard(
                  cat: _categories[i],
                  onTap: () => setState(() => _selectedCategory = i),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Status Strip (4 ຕົວຊີ້ວັດ) ─────────────
  Widget _buildStatusStrip() {
    const stats = [
      _StatData(label: 'ແຮງດັນ (kV)',     value: '115.2 kV', icon: Icons.bolt,              color: Color(0xFF42A5F5), status: 'Normal'),
      _StatData(label: 'ໂຫຼດ (MW)',        value: '48.6 MW',  icon: Icons.power,             color: Color(0xFF4CAF50), status: 'Normal'),
      _StatData(label: 'Power Factor',    value: '0.97',     icon: Icons.speed,             color: Color(0xFFFFB300), status: 'Good'),
      _StatData(label: 'ການສູນເສຍ (%)',   value: '2.1 %',    icon: Icons.leak_add,          color: Color(0xFFEF5350), status: 'Low'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: stats.map((s) => Expanded(child: _StatBox(data: s))).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  ໜ້າ Sub-menu
  // ══════════════════════════════════════════
  Widget _buildSubMenu(_TxCategory cat) {
    return Column(
      children: [
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
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (ctx, bc) {
              final cols =
                  bc.maxWidth > 900 ? 6 : bc.maxWidth > 600 ? 4 : 3;
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
                  onTap: () => _showDialog(cat.items[i].title),
                ),
              );
            }),
          ),
        ),
      ],
    );
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

// ── Header ──────────────────────────────────────────────────────
class _TxHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  const _TxHeader({
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

// ── Stat Strip Box ───────────────────────────────────────────────
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String status;
  const _StatData(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.status});
}

class _StatBox extends StatelessWidget {
  final _StatData data;
  const _StatBox({required this.data});

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
      child: Row(children: [
        Icon(data.icon, color: data.color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: data.color)),
            Text(data.label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
            Text(data.status,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }
}

// ── Category Card ────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final _TxCategory cat;
  final VoidCallback onTap;
  const _CategoryCard({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(cat.icon, color: cat.color, size: 16),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  size: 14, color: AppColors.textMuted),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat.label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Text(cat.sublabel,
                  style: const TextStyle(
                      fontSize: 8, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${cat.items.length} ລາຍການ',
                    style: TextStyle(
                        fontSize: 7,
                        color: cat.color,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Action Card ──────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final _TxItem item;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(item.icon, color: color, size: 14),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Text(item.sub,
                  style: const TextStyle(
                      fontSize: 8, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Back Button ──────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.arrow_back,
            size: 15, color: AppColors.textSecondary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Data Models
// ═══════════════════════════════════════════════════════════════
class _TxCategory {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final List<_TxItem> items;
  const _TxCategory({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.items,
  });
}

class _TxItem {
  final IconData icon;
  final String title;
  final String sub;
  const _TxItem(
      {required this.icon, required this.title, required this.sub});
}