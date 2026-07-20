import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../styles/app_styles.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Tìm kiếm...',
    this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late final TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClearButton = _controller.text.isNotEmpty;
    });
  }

  void _clearText() {
    _controller.clear();
    if (widget.onChanged != null) widget.onChanged!('');
    if (widget.onClear != null) widget.onClear!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        boxShadow: AppShadow.low,
        borderRadius: AppRadius.borderMedium,
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          suffixIcon: _showClearButton
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearText,
                )
              : null,
          filled: true,
          fillColor: theme.brightness == Brightness.light ? AppColors.white : AppColors.darkCard,
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderMedium,
            borderSide: BorderSide(
              color: theme.brightness == Brightness.light ? AppColors.lightBorder : AppColors.darkBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderMedium,
            borderSide: BorderSide(
              color: theme.brightness == Brightness.light ? AppColors.lightBorder : AppColors.darkBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderMedium,
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
