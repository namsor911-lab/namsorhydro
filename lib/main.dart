import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/generators_screen.dart';
import 'screens/operator_screen.dart';
import 'screens/transmission_screen.dart';
import 'screens/administration_screen.dart';
import 'screens/accounting_screen.dart';
import 'screens/org_chart_screen.dart' as org;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('lo', null);
  } catch (e) {
    debugPrint('Warning: Could not initialize Lao locale: $e');
  }
  runApp(const NamsorApp());
}

class NamsorApp extends StatelessWidget {
  const NamsorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namsor Hydropower ComPaNy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String lao;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.lao,
  });
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.people_alt_outlined,   label: 'Org Chart',      lao: 'ໂຄງສ້າງອົງກອນ'),
    _NavItem(icon: Icons.dashboard_outlined,    label: 'Dashboard',      lao: 'ພາບລວມ'),
    _NavItem(icon: Icons.electric_bolt_outlined, label: 'Generators',     lao: 'ໜ່ວຍຜະລິດ'),
    _NavItem(icon: Icons.cable_outlined,         label: 'Transmission',   lao: 'ສາຍສົ່ງ'),
    _NavItem(icon: Icons.notifications_outlined, label: 'Alerts',         lao: 'ການແຈ້ງເຕືອນ'),
    _NavItem(icon: Icons.admin_panel_settings_outlined, label: 'Administration', lao: 'ການບໍລິຫານ'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Accounting',   lao: 'ບັນຊີ/ການເງິນ'),
    _NavItem(icon: Icons.security_outlined,     label: 'Security',       lao: 'ຍາມ'),
    _NavItem(icon: Icons.person_outline,        label: 'Operator',       lao: 'ຜູ້ປະຈຳການ'),
    _NavItem(icon: Icons.settings_outlined,      label: 'Settings',       lao: 'ການຕັ້ງຄ່າ'),
  ];

  // ໃຊ້ org.OrgChartScreen() ແທນ
  final List<Widget> _screens = [
    const org.OrgChartScreen(),
    const DashboardScreen(),
    const GeneratorsScreen(),
    const TransmissionScreen(),
    const _PlaceholderScreen(title: 'Alerts', icon: Icons.notifications_outlined),
    const AdministrationScreen(),
    const AccountingScreen(),
    const _PlaceholderScreen(title: 'Security', icon: Icons.security_outlined),
    const OperatorScreen(),
    const _PlaceholderScreen(title: 'Settings', icon: Icons.settings_outlined),
  ];

  final List<String> _pageTitles = const [
    'Organization Chart',
    'Dashboard',
    'Generators',
    'Transmission',
    'Alerts',
    'Administration',
    'Accounting',
    'Security',
    'Operator',
    'Settings',
  ];

  final List<String> _pageTitlesLao = const [
    'ໂຄງສ້າງອົງກອນ',
    'ພາບລວມລະບົບ',
    'ໜ່ວຍຜະລິດໄຟຟ້າ',
    'ສາຍສົ່ງໄຟຟ້າ',
    'ການແຈ້ງເຕືອນ',
    'ການບໍລິຫານ',
    'ບັນຊີ/ການເງິນ',
    'ຍາມ',
    'ຜູ້ປະຈຳການ',
    'ການຕັ້ງຄ່າ',
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    if (!isWide) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: _buildTopBar(mobile: true),
        body: _screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppColors.bgSecondary,
          indicatorColor: AppColors.accent.withValues(alpha: 0.2),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: _navItems.map((n) => NavigationDestination(
            icon: Icon(n.icon, color: AppColors.textSecondary, size: 20),
            selectedIcon: Icon(n.icon, color: AppColors.accent, size: 20),
            label: n.label,
          )).toList(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Scaffold(
              backgroundColor: AppColors.bgPrimary,
              appBar: _buildTopBar(mobile: false),
              body: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopBar({required bool mobile}) {
    return AppBar(
      backgroundColor: AppColors.bgSecondary,
      elevation: 0,
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (!mobile)
              IconButton(
                icon: Icon(
                  _sidebarCollapsed ? Icons.menu_open : Icons.menu,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                tooltip: 'Toggle Sidebar',
              ),
            if (!mobile) const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _pageTitles[_selectedIndex],
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                Text(
                  _pageTitlesLao[_selectedIndex],
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 7, color: AppColors.success),
                  SizedBox(width: 5),
                  Text('SCADA Online',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const _LiveClock(),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildSidebar() {
    final w = _sidebarCollapsed ? 60.0 : 220.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      color: AppColors.bgSecondary,
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.info],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.water_drop,
                      color: Colors.white, size: 16),
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Nam Sor HyDroPoWer',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _navItems.asMap().entries.map((e) {
                final i = e.key;
                final n = e.value;
                final selected = _selectedIndex == i;
                return Tooltip(
                  message: _sidebarCollapsed ? n.label : '',
                  preferBelow: false,
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(n.icon,
                              size: 18,
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.textSecondary),
                          if (!_sidebarCollapsed) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: selected
                                              ? AppColors.accent
                                              : AppColors.textPrimary)),
                                  Text(n.lao,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: _sidebarCollapsed
                ? const Icon(Icons.account_circle_outlined,
                    color: AppColors.textMuted, size: 22)
                : const Row(
                    children: [
                      Icon(Icons.account_circle_outlined,
                          color: AppColors.textMuted, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Operator',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                            Text('Control Room',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late String _time;

  @override
  void initState() {
    super.initState();
    _time = _fmt();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _time = _fmt());
      return true;
    });
  }

  String _fmt() {
    final n = DateTime.now();
    final h = n.hour.toString().padLeft(2, '0');
    final m = n.minute.toString().padLeft(2, '0');
    final s = n.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) => Text(
        _time,
        style: const TextStyle(
            fontSize: 13,
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()]),
      );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('ໜ້າ $title',
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          const Text('ກຳລັງພັດທະນາ…',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}