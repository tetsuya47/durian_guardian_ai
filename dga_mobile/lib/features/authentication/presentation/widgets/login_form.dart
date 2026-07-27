import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/loading/loading_dialog.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isFormValid = false;
  bool _loadedRememberedEmail = false;

  final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    if (_loadedRememberedEmail) return;
    _loadedRememberedEmail = true;

    try {
      final localDataSource = ref.read(authLocalDataSourceProvider);
      final email = await localDataSource.getUserEmail();
      if (email != null && email.isNotEmpty && mounted) {
        _emailController.text = email;
        ref.read(rememberMeProvider.notifier).state = true;
      }
    } catch (_) {
      // Ignore errors loading remembered email
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final email = _emailController.text;
    final password = _passwordController.text;
    final isEmailValid = _emailRegExp.hasMatch(email);
    final isPasswordValid = password.isNotEmpty && password.length >= 6;

    if (mounted) {
      setState(() {
        _isFormValid = isEmailValid && isPasswordValid;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authLoadingProvider.notifier).state = true;
    LoadingDialog.show(context, message: 'Đang đăng nhập...');

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.login(_emailController.text, _passwordController.text);

    if (mounted) {
      LoadingDialog.hide(context);
      ref.read(authLoadingProvider.notifier).state = false;

      if (result.isSuccess) {
        // Clear guest mode on real login
        ref.read(guestModeProvider.notifier).state = false;

        // Handle Remember Me
        final rememberMe = ref.read(rememberMeProvider);
        final localDataSource = ref.read(authLocalDataSourceProvider);
        if (rememberMe) {
          await localDataSource.saveUserEmail(_emailController.text);
        } else {
          await localDataSource.saveUserEmail('');
        }

        if (!mounted) return;
        AppSnackbars.showSuccess(context, AppStrings.loginSuccess);
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
    final rememberMe = ref.watch(rememberMeProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          PasswordField(
            label: AppStrings.password,
            hintText: 'Nhập mật khẩu',
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
          AppSpacing.v12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (val) {
                      ref.read(rememberMeProvider.notifier).state = val ?? false;
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                  Text(
                    AppStrings.rememberMe,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(
                  AppStrings.forgotPassword,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.v24,
          PrimaryButton(
            text: AppStrings.login,
            onPressed: _isFormValid ? _handleLogin : null,
          ),
        ],
      ),
    );
  }
}
