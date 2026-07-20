import 'package:flutter/material.dart';
import 'input_field.dart';

class PasswordField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const PasswordField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomInputField(
      label: widget.label,
      hintText: widget.hintText ?? 'Nhập mật khẩu',
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      maxLines: 1,
      keyboardType: TextInputType.visiblePassword,
      onChanged: widget.onChanged,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onPressed: _toggleObscureText,
      ),
    );
  }
}
