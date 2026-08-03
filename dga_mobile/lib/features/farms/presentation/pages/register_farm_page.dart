import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_providers.dart';

class RegisterFarmPage extends ConsumerStatefulWidget {
  const RegisterFarmPage({super.key});

  @override
  ConsumerState<RegisterFarmPage> createState() => _RegisterFarmPageState();
}

class _RegisterFarmPageState extends ConsumerState<RegisterFarmPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController(text: '1.5');
  final _treeCountController = TextEditingController(text: '120');
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _treeCountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(dioApiClientProvider);
      final payload = {
        'farm_name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'area_hectare': double.tryParse(_areaController.text.trim()) ?? 1.0,
        'tree_count': int.tryParse(_treeCountController.text.trim()) ?? 0,
        'description': _descController.text.trim(),
        'onboarding_status': 'ACTIVE',
      };

      await apiClient.request<dynamic>(
        path: ApiEndpoints.farms,
        method: 'POST',
        data: payload,
        decoder: (json) => json,
      );

      if (mounted) {
        ref.invalidate(dashboardDataProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký trang trại mới thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đăng ký trang trại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Vườn Sầu Riêng Mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.eco_outlined, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kích hoạt vườn cây của bạn để sử dụng AI tự động cảnh báo & khuyến nghị kỹ thuật.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.v20,

              Text('Tên Trang Trại / Vườn', style: theme.textTheme.labelLarge),
              AppSpacing.v8,
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Vườn Sầu Riêng Phong Điền 01',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên trang trại' : null,
              ),
              AppSpacing.v16,

              Text('Vị Trí / Địa Chỉ Vườn', style: theme.textTheme.labelLarge),
              AppSpacing.v8,
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Huyện Phong Điền, Cần Thơ',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              AppSpacing.v16,

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Diện Tích (ha)', style: theme.textTheme.labelLarge),
                        AppSpacing.v8,
                        TextFormField(
                          controller: _areaController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: '1.5',
                            prefixIcon: Icon(Icons.square_foot),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Nhập diện tích' : null,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Số Lượng Cây', style: theme.textTheme.labelLarge),
                        AppSpacing.v8,
                        TextFormField(
                          controller: _treeCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '120',
                            prefixIcon: Icon(Icons.park_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Nhập số cây' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.v16,

              Text('Ghi Chú / Mô Tả Vườn', style: theme.textTheme.labelLarge),
              AppSpacing.v8,
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Nhập thông tin giống sầu riêng (Ri6, Monthong), độ tuổi cây...',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.v24,

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isLoading ? 'Đang Xử Lý...' : 'Hoàn Tất Đăng Ký Trang Trại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
