import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';

class SmartTaskItem {
  final String id;
  final String title;
  final String description;
  final String priority;
  bool isCompleted;

  SmartTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.isCompleted = false,
  });
}

class SmartTaskListCard extends StatefulWidget {
  const SmartTaskListCard({super.key});

  @override
  State<SmartTaskListCard> createState() => _SmartTaskListCardState();
}

class _SmartTaskListCardState extends State<SmartTaskListCard> {
  final List<SmartTaskItem> _tasks = [
    SmartTaskItem(
      id: '1',
      title: 'Kiểm tra rãnh thoát nước gốc cây',
      description: 'Phòng ngừa ngập úng gốc khi độ ẩm tăng cao (96%).',
      priority: 'Ưu tiên cao',
      isCompleted: false,
    ),
    SmartTaskItem(
      id: '2',
      title: 'Phun phòng nấm Phytophthora đợt 1',
      description: 'Phun phủ tán lá và quét gốc bằng Metalaxyl 25WP.',
      priority: 'Ưu tiên cao',
      isCompleted: false,
    ),
    SmartTaskItem(
      id: '3',
      title: 'Tưới gốc nấm vi sinh Trichoderma',
      description: 'Tăng cường vi sinh vật có lợi cho bộ rễ sầu riêng.',
      priority: 'Trung bình',
      isCompleted: true,
    ),
    SmartTaskItem(
      id: '4',
      title: 'Thu gom lá rụng và dọn sạch gốc',
      description: 'Hạn chế mầm bệnh lây lan giữa các khu vực vườn.',
      priority: 'Trung bình',
      isCompleted: false,
    ),
  ];

  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  void _addNewTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _tasks.add(SmartTaskItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        description: 'Nhiệm vụ nông trại do nông dân thêm mới.',
        priority: 'Thường',
        isCompleted: false,
      ));
    });
  }

  void _showAddTaskDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm nhiệm vụ chăm sóc mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên công việc (ví dụ: Bón phân hữu cơ...)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              _addNewTask(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final progress = _tasks.isNotEmpty ? completedCount / _tasks.length : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.task_alt_outlined, color: AppColors.secondary, size: 22),
                  ),
                  AppSpacing.h8,
                  Text(
                    'Nhiệm vụ Nông trại AI gợi ý',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                tooltip: 'Thêm nhiệm vụ',
                onPressed: _showAddTaskDialog,
              ),
            ],
          ),
          AppSpacing.v8,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ: $completedCount/${_tasks.length} nhiệm vụ',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          AppSpacing.v4,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.outline.withAlpha(30),
              color: AppColors.success,
              minHeight: 6,
            ),
          ),
          AppSpacing.v16,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return InkWell(
                onTap: () => _toggleTask(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? AppColors.success.withAlpha(12)
                        : theme.colorScheme.onSurface.withAlpha(8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: task.isCompleted
                          ? AppColors.success.withAlpha(40)
                          : theme.colorScheme.outline.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: task.isCompleted,
                        activeColor: AppColors.success,
                        onChanged: (_) => _toggleTask(index),
                      ),
                      AppSpacing.h4,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted
                                    ? theme.colorScheme.onSurface.withAlpha(120)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              task.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(140),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.priority.contains('cao')
                              ? AppColors.error.withAlpha(20)
                              : AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: task.priority.contains('cao') ? AppColors.error : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
