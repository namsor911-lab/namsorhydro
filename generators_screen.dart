import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

class GeneratorsScreen extends StatefulWidget {
  const GeneratorsScreen({super.key});
  @override
  State<GeneratorsScreen> createState() => _GeneratorsScreenState();
}

class _GeneratorsScreenState extends State<GeneratorsScreen> {
  final _stations = sampleGenerators();
  String _filter = 'all';
  final Set<int> _expanded = {0, 1};

  Color _statusColor(String s) {
    switch (s) {
      case 'online':      return AppColors.success;
      case 'standby':     return AppColors.warning;
      case 'maintenance': return AppColors.info;
      default:            return AppColors.danger;
    }
  }

  Color _mwColor(double mw) {
    if (mw == 0)   return AppColors.textMuted;
    if (mw > 2.75)   return AppColors.success;
    if (mw > 2.75)   return AppColors.warning;
    return AppColors.danger;
  }

  void _showUnitDetail(GeneratorUnit u) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(u.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              ...[
                ['ສະຖານະ',  u.status],
                ['ກຳລັງ',    '${u.mw} MW'],
                ['ຄວາມຖີ່',  '${u.hz} Hz'],
                ['ອຸນຫະພູມ', '${u.temp}°C'],
                ['ແຮງດັນ',   u.voltage],
              ].map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r[0],
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        Text(r[1],
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              AppButton(
                label: 'ປິດ',
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['all', 'online', 'standby', 'maintenance'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AppCard(
        title: 'ໜ່ວຍໄຟຟ້າທັງໝົດ',
        trailing: Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active
                              ? AppColors.accent
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f == 'all' ? 'ທັງໝົດ' : f,
                        style: TextStyle(
                            fontSize: 12,
                            color: active
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        child: Column(
          children: _stations.asMap().entries.map((entry) {
            final si = entry.key;
            final stn = entry.value;
            final shown = _filter == 'all'
                ? stn.units
                : stn.units
                    .where((u) => u.status == _filter)
                    .toList();
            if (shown.isEmpty) return const SizedBox.shrink();

            final isExpanded = _expanded.contains(si);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => isExpanded
                        ? _expanded.remove(si)
                        : _expanded.add(si)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          Text(stn.station,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(width: 10),
                          Text(
                            '${shown.where((u) => u.status == 'online').length}/${stn.units.length} online',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.expand_more,
                                color: AppColors.textSecondary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Column(
                        children: shown.map((u) {
                          final online = u.status == 'online';
                          final sc = _statusColor(u.status);
                          final mc = _mwColor(u.mw);
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showUnitDetail(u),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: online
                                    ? AppColors.accent.withValues(alpha: 0.07)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: online
                                            ? AppColors.accent
                                            : AppColors.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: online
                                        ? Center(
                                            child: Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                  color: AppColors.accent,
                                                  shape: BoxShape.circle),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(u.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary)),
                                  ),
                                  StatusBadge(
                                      label: u.status.toUpperCase(),
                                      color: sc),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: mc.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      u.mw > 0
                                          ? '${u.mw} MW'
                                          : '—',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: mc,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}