import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ໝາຍເຫດ: ລຶບ import '../theme/app_theme.dart'; ອອກແລ້ວຕາມທີ່ Analyze ແນະນຳ

class Employee {
  final String name;
  final String position;
  final String department;
  final String bio;
  final String phone;
  final String email;
  Uint8List? imageBytes;

  Employee({
    required this.name,
    required this.position,
    required this.department,
    required this.bio,
    required this.phone,
    required this.email,
    this.imageBytes,
  });
}

// ── generate avatar color from name ──
Color _avatarColor(String name) {
  const colors = [
    Color(0xFF78909C),
    Color(0xFF8D6E63),
    Color(0xFF9E9E9E),
    Color(0xFF90A4AE),
    Color(0xFFB0A8A0),
    Color(0xFFA1887F),
    Color(0xFFBDBDBD),
    Color(0xFFBCAAA4),
  ];
  return colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
}

class OrgChartScreen extends StatefulWidget {
  // ແກ້ໄຂການໃຊ້ Key ຕາມທີ່ Analyze ແນະນຳ (ໃຊ້ super parameters)
  const OrgChartScreen({super.key});

  @override
  State<OrgChartScreen> createState() => _OrgChartScreenState();
}

class _OrgChartScreenState extends State<OrgChartScreen> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _profileStream;
  List<String> _departments = [];
  String _selectedDepartment = 'ທັງໝົດ';

  // 🔴 ຢ່າລືມເອົາຂໍ້ມູນພະນັກງານຕົວຈິງຂອງທ່ານມາໃສ່ໃນນີ້ 🔴
  final List<Employee> _allEmployees = [
    Employee(
      name: 'ຊື່ພະນັກງານ',
      position: 'ຕຳແໜ່ງ',
      department: 'ຄະນະບໍລິຫານ',
      bio: 'ປະຫວັດຫຍໍ້...',
      phone: '020 12345678',
      email: 'employee@example.com',
    ),
    // ... ເພີ່ມຂໍ້ມູນພະນັກງານອື່ນໆ
  ];

  @override
  void initState() {
    super.initState();
    final deps = _allEmployees.map((e) => e.department).toSet().toList();
    _departments = ['ທັງໝົດ', ...deps];

    _loadLocalProfiles();
    _startProfileStream();
  }

  @override
  void dispose() {
    _profileStream?.cancel();
    super.dispose();
  }

  // ── 1. ໂຫຼດຮູບຈາກ Cache (SharedPreferences) ──
  Future<void> _loadLocalProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    bool changed = false;
    for (var emp in _allEmployees) {
      final b64 = prefs.getString('profile_${emp.email}');
      if (b64 != null && b64.isNotEmpty) {
        emp.imageBytes = base64Decode(b64);
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  // ── 2. ຟັງການປ່ຽນແປງຈາກ Firestore ──
  void _startProfileStream() {
    _profileStream = _fs
        .collection('employee_profiles')
        .snapshots()
        .listen((snapshot) async {
      final prefs = await SharedPreferences.getInstance();
      bool changed = false;
      for (final doc in snapshot.docs) {
        try {
          final emp = _allEmployees.firstWhere((e) => e.email == doc.id);
          final b64 = doc.data()['imageBase64'] as String?;
          if (b64 != null && b64.isNotEmpty) {
            emp.imageBytes = base64Decode(b64);
            await prefs.setString('profile_${emp.email}', b64);
            changed = true;
          }
        } catch (_) {
          // ຂ້າມຖ້າບໍ່ພົບ Email ທີ່ກົງກັນ
        }
      }
      if (changed && mounted) {
        setState(() {});
      }
    }, onError: (e) {
      debugPrint('⚠️ _profileStream error: $e');
    });
  }

  // ── 3. ອັບໂຫຼດຮູບ ແລະ ບັນທຶກ ──
  Future<void> _saveProfileImage(Employee emp, Uint8List bytes) async {
    final b64String = base64Encode(bytes);

    setState(() {
      emp.imageBytes = bytes;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_${emp.email}', b64String);

    try {
      await _fs.collection('employee_profiles').doc(emp.email).set({
        'imageBase64': b64String,
        'name': emp.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('⚠️ _saveProfileImage error: ${e.message}');
    }
  }

  // ── ຟັງຊັນເລືອກຮູບພາບ ──
  Future<void> _pickImage(Employee emp) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 500,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      await _saveProfileImage(emp, bytes);
    }
  }

  Color _getDepartmentColor(String dept) {
    switch (dept) {
      case 'ຄະນະບໍລິຫານ':
        return const Color(0xFFB8860B);
      case 'ຝ່າຍປະຕິບັດການ':
        return const Color(0xFF00838F);
      case 'ຝ່າຍວິສະວະກຳ':
        return const Color(0xFF558B2F);
      case 'ຝ່າຍວິເຄາະຂໍ້ມູນ':
        return const Color(0xFF1565C0);
      default:
        return Colors.grey;
    }
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
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee emp) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _pickImage(emp),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: _avatarColor(emp.name),
                backgroundImage: emp.imageBytes != null
                    ? MemoryImage(emp.imageBytes!)
                    : null,
                child: emp.imageBytes == null
                    ? Text(
                        emp.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emp.position,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDepartmentColor(emp.department)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emp.department,
                          style: TextStyle(
                            color: _getDepartmentColor(emp.department),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.phone_outlined,
                            color: Colors.green,
                            onTap: () {},
                          ),
                          const SizedBox(width: 6),
                          _buildActionButton(
                            icon: Icons.email_outlined,
                            color: Colors.blue,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _selectedDepartment == 'ທັງໝົດ'
        ? _allEmployees
        : _allEmployees
            .where((e) => e.department == _selectedDepartment)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ໂຄງສ້າງອົງກອນ'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _departments.map((dept) {
                final isSelected = dept == _selectedDepartment;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(dept),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDepartment = dept;
                        });
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final emp = filteredEmployees[index];
                return _buildEmployeeCard(emp);
              },
            ),
          ),
        ],
      ),
    );
  }
}