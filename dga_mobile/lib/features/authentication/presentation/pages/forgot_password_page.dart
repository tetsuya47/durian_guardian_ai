import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isFormValid = false;

  final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text;
    final isValid = _emailRegExp.hasMatch(email);
    if (mounted) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authLoadingProvider.notifier).state = true;

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.forgotPassword(_emailController.text);

    if (mounted) {
      ref.read(authLoadingProvider.notifier).state = false;

      if (result.isSuccess) {
        AppDialogs.showSuccess(
          context,
          title: AppStrings.forgotPasswordSuccessTitle,
          message: AppStrings.forgotPasswordSuccessDesc,
          closeText: 'Đóng',
          onClose: () {
            context.pop();
          },
        );
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
      appBar: AppBar(
        title: const Text(AppStrings.forgotPasswordTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.v20,
                Text(
                  AppStrings.forgotPasswordTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.v12,
                Text(
                  AppStrings.forgotPasswordDesc,
                  style: theme.textTheme.bodyMedium,
                ),
                AppSpacing.v32,
                CustomInputField(
                  label: AppStrings.email,
                  hintText: 'Nhập địa chỉ email của bạn',
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
                AppSpacing.v40,
                PrimaryButton(
                  text: AppStrings.sendRequest,
                  onPressed: _isFormValid ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

