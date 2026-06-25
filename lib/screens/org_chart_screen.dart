import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Employee {
  final String name;
  final String position;
  final String department;
  final String bio;
  final String imageUrl;
  final String phone;
  final String email;

  const Employee({
    required this.name,
    required this.position,
    required this.department,
    required this.bio,
    required this.imageUrl,
    required this.phone,
    required this.email,
  });
}

class OrgChartScreen extends StatefulWidget {
  const OrgChartScreen({super.key});

  @override
  State<OrgChartScreen> createState() => _OrgChartScreenState();
}

class _OrgChartScreenState extends State<OrgChartScreen> {
  final List<Employee> _allEmployees = const [
    Employee(
      name: 'ທ່ານ ສົມພອນ ພົມມະຈັນ',
      position: 'ຜູ້ອຳນວຍການໃຫຍ່ (CEO)',
      department: 'ຄະນະບໍລິຫານ',
      bio: 'ປະສົບການບໍລິຫານໂຮງໄຟຟ້າ 20+ ປີ, ປະລິນຍາໂທ ວິສະວະກຳພະລັງງານ',
      imageUrl: 'https://i.pravatar.cc/300?img=11',
      phone: '020 5555 1111',
      email: 'somphone@namsor.com',
    ),
    Employee(
      name: 'ທ່ານນາງ ມະນີວັນ ສີປະເສີດ',
      position: 'ຫົວໜ້າຝ່າຍປະຕິບັດການ (COO)',
      department: 'ຝ່າຍປະຕິບັດການ',
      bio: 'ຊ່ຽວຊານ SCADA ແລະ ການຄຸ້ມຄອງທີມວິສະວະກອນ',
      imageUrl: 'https://i.pravatar.cc/300?img=5',
      phone: '020 5555 2222',
      email: 'manivanh@namsor.com',
    ),
    Employee(
      name: 'ທ່ານ ບຸນມີ ໄຊຍະວົງ',
      position: 'ຫົວໜ້າວິສະວະກອນ',
      department: 'ຝ່າຍວິສະວະກຳ',
      bio: 'ຮັບຜິດຊອບກວດກາ ແລະ ບຳລຸງຮັກສາເຄື່ອງຈັກທຸກໜ່ວຍ',
      imageUrl: 'https://i.pravatar.cc/300?img=12',
      phone: '020 5555 3333',
      email: 'bounmy@namsor.com',
    ),
    Employee(
      name: 'ທ່ານນາງ ອານຸສອນ ວົງພະຈັນ',
      position: 'ນັກວິເຄາະຂໍ້ມູນພະລັງງານ',
      department: 'ຝ່າຍວິເຄາະຂໍ້ມູນ',
      bio: 'ວິເຄາະປະລິມານນໍ້າ ແລະ ປະເມີນກຳລັງຜະລິດລາຍວັນ',
      imageUrl: 'https://i.pravatar.cc/300?img=9',
      phone: '020 5555 4444',
      email: 'anousone@namsor.com',
    ),
    Employee(
      name: 'ທ່ານ ຄຳພອນ ສີສຸວັນ',
      position: 'ວິສະວະກອນຄວບຄຸມ',
      department: 'ຝ່າຍວິສະວະກຳ',
      bio: 'ຮັບຜິດຊອບລະບົບຄວບຄຸມອັດຕະໂນມັດ ແລະ ເຊັນເຊີ',
      imageUrl: 'https://i.pravatar.cc/300?img=3',
      phone: '020 5555 5555',
      email: 'khamphone@namsor.com',
    ),
    Employee(
      name: 'ທ່ານນາງ ຈັນທະວີ ພົມມະວົງ',
      position: 'ເຈົ້າໜ້າທີ່ການເງິນ',
      department: 'ຝ່າຍບັນຊີ/ການເງິນ',
      bio: 'ຄຸ້ມຄອງງົບປະມານ ແລະ ລາຍງານການເງິນ',
      imageUrl: 'https://i.pravatar.cc/300?img=10',
      phone: '020 5555 6666',
      email: 'chanthavy@namsor.com',
    ),
  ];

  String _searchQuery = '';
  String _selectedDepartment = 'ທັງໝົດ';
  late List<String> _departments;

  @override
  void initState() {
    super.initState();
    final deps = _allEmployees.map((e) => e.department).toSet().toList();
    _departments = ['ທັງໝົດ', ...deps];
  }

  List<Employee> get _filteredEmployees {
    return _allEmployees.where((emp) {
      final matchName = emp.name.contains(_searchQuery) ||
          emp.position.contains(_searchQuery) ||
          emp.department.contains(_searchQuery);
      final matchDept = _selectedDepartment == 'ທັງໝົດ' ||
          emp.department == _selectedDepartment;
      return matchName && matchDept;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            border: const Border(bottom: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppColors.textPrimary),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'ຄົ້ນຫາຊື່, ຕຳແໜ່ງ, ພະແນກ...',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontFamily: 'PhetsarathOT'),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.bgPrimary,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppColors.textMuted, size: 20),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDepartment,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: AppColors.textMuted),
                        dropdownColor: AppColors.bgSecondary,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'PhetsarathOT'),
                        items: _departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedDepartment = value!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ພົບ ${_filteredEmployees.length} ທ່ານ',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontFamily: 'PhetsarathOT'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 900) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 2;
              }
              if (_filteredEmployees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search_off,
                          size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text(
                        'ບໍ່ພົບພະນັກງານ',
                        style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontFamily: 'PhetsarathOT'),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final emp = _filteredEmployees[index];
                    return _buildEmployeeCard(emp);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee emp) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSecondary,
            AppColors.bgPrimary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _getDepartmentColor(emp.department),
                        _getDepartmentColor(emp.department)
                            .withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getDepartmentColor(emp.department)
                            .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(emp.imageUrl),
                    backgroundColor: AppColors.border,
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'PhetsarathOT',
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getDepartmentColor(emp.department)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          emp.position,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getDepartmentColor(emp.department),
                            fontFamily: 'PhetsarathOT',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.business_center,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  emp.department,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'PhetsarathOT'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              emp.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
                fontFamily: 'PhetsarathOT',
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_android_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          emp.phone,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFeatures: [
                                FontFeature.tabularFigures()
                              ]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.call,
                          color: AppColors.success,
                          onTap: () {},
                        ),
                        const SizedBox(width: 6),
                        _buildActionButton(
                          icon: Icons.email_outlined,
                          color: AppColors.info,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Color _getDepartmentColor(String dept) {
    switch (dept) {
      case 'ຄະນະບໍລິຫານ':
        return Colors.amber.shade600;
      case 'ຝ່າຍປະຕິບັດການ':
        return Colors.cyan.shade500;
      case 'ຝ່າຍວິສະວະກຳ':
        return Colors.green.shade400;
      case 'ຝ່າຍວິເຄາະຂໍ້ມູນ':
        return Colors.purple.shade400;
      case 'ຝ່າຍບັນຊີ/ການເງິນ':
        return Colors.pink.shade400;
      default:
        return AppColors.accent;
    }
  }
}