import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_providers.dart';

class HistorySearchBar extends ConsumerWidget {
  const HistorySearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(historyQueryProvider);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (val) {
                ref.read(historyQueryProvider.notifier).state = val;
              },
              controller: TextEditingController(text: query)..selection = TextSelection.fromPosition(TextPosition(offset: query.length)),
              decoration: const InputDecoration(
                hintText: 'Tìm cây / mã cây / bệnh...',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          if (query.isNotEmpty)
            GestureDetector(
              onTap: () => ref.read(historyQueryProvider.notifier).state = '',
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.cancel_rounded, color: Color(0xFF9CA3AF), size: 18),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(
            Icons.qr_code_scanner_rounded,
            color: Color(0xFF374151),
            size: 22,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
