import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_providers.dart';

class HistoryFilterBar extends ConsumerWidget {
  const HistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(historyFilterProvider);

    final filters = [
      'Tất cả',
      'Khỏe mạnh',
      'Có bệnh',
      'Cần theo dõi',
    ];

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((filter) {
                final isSelected = activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isSelected ? const Color(0xFFE8F5ED) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        ref.read(historyFilterProvider.notifier).state = filter;
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E8E4A) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF1E8E4A),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              filter,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF1E8E4A) : const Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Filter Icon Button
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.filter_list_rounded,
              color: Color(0xFF374151),
              size: 20,
            ),
            onPressed: () {
              _showFilterModal(context, ref);
            },
          ),
        ),
      ],
    );
  }

  void _showFilterModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final activeTime = ref.watch(historyTimeFilterProvider);
            final activeSort = ref.watch(historySortProvider);

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bộ lọc & Sắp xếp',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Tất cả', 'Hôm nay', '7 ngày', '30 ngày'].map((t) {
                      final sel = activeTime == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: sel,
                        selectedColor: const Color(0xFF1E8E4A),
                        labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
                        onSelected: (_) => ref.read(historyTimeFilterProvider.notifier).state = t,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sắp xếp theo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Mới nhất', 'Cũ nhất', 'Độ tin cậy', 'Tên cây'].map((s) {
                      final sel = activeSort == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: sel,
                        selectedColor: const Color(0xFF1E8E4A),
                        labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
                        onSelected: (_) => ref.read(historySortProvider.notifier).state = s,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
