import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/loading/loading_dialog.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isFormValid = false;

  final RegExp _emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final name = _nameController.text.trim();
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final isNameValid = name.isNotEmpty;
    final isEmailValid = _emailRegExp.hasMatch(email);
    final isPasswordValid = password.length >= 6;
    final isConfirmValid = confirm == password && confirm.isNotEmpty;

    if (mounted) {
      setState(() {
        _isFormValid = isNameValid && isEmailValid && isPasswordValid && isConfirmValid;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authLoadingProvider.notifier).state = true;
    LoadingDialog.show(context, message: 'Đang tạo tài khoản...');

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.register(
      _nameController.text.trim(),
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      LoadingDialog.hide(context);
      ref.read(authLoadingProvider.notifier).state = false;

      if (result.isSuccess) {
        AppSnackbars.showSuccess(context, 'Đăng ký thành công!');
        context.go('/dashboard');
      } else {
        final failureMessage = (result as Failure).message;
        AppDialogs.showWarning(
          context,
          title: AppStrings.error,
          message: failureMessage,
          closeText: 'Đóng',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withAlpha(25),
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  AppSpacing.v20,
                  Text(
                    'Tạo tài khoản',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  AppSpacing.v8,
                  Text(
                    'Đăng ký để sử dụng Durian Guardian AI',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  AppSpacing.v32,

                  // Full Name
                  CustomInputField(
                    label: 'Họ và tên',
                    hintText: 'Nhập họ và tên',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.v16,

                  // Email
                  CustomInputField(
                    label: AppStrings.email,
                    hintText: 'Nhập email của bạn',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.emailRequired;
                      }
                      if (!_emailRegExp.hasMatch(value)) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  AppSpacing.v16,

                  // Password
                  PasswordField(
                    label: AppStrings.password,
                    hintText: 'Ít nhất 6 ký tự',
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.emptyPassword;
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải chứa ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.v16,

                  // Confirm Password
                  PasswordField(
                    label: 'Xác nhận mật khẩu',
                    hintText: 'Nhập lại mật khẩu',
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.v32,

                  // Register Button
                  PrimaryButton(
                    text: 'Đăng ký',
                    onPressed: _isFormValid ? _handleRegister : null,
                  ),
                  AppSpacing.v20,

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          AppStrings.login,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.v32,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
