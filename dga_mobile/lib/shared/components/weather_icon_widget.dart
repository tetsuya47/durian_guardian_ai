import 'package:flutter/material.dart';

/// A smart dynamic weather icon widget that matches description keywords and OpenWeather icon codes.
/// Renders rain icons for rain ("mưa nhẹ", "mưa rào", "rain"), sun for sunny ("nắng", "clear"), etc.
class WeatherIconWidget extends StatelessWidget {
  final String? description;
  final String? iconCode;
  final String? iconUrl;
  final double size;
  final Color? color;

  const WeatherIconWidget({
    super.key,
    this.description,
    this.iconCode,
    this.iconUrl,
    this.size = 56,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Try loading network image from OpenWeather icon_url if provided
    if (iconUrl != null && iconUrl!.startsWith('http')) {
      return Image.network(
        iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildIconFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildIconFallback();
        },
      );
    }

    return _buildIconFallback();
  }

  Widget _buildIconFallback() {
    final desc = (description ?? '').toLowerCase();
    final code = (iconCode ?? '').toLowerCase();

    IconData iconData = Icons.cloud_outlined;
    Color iconColor = color ?? Colors.white70;

    // Check Rain / Drizzle / Shower / Thunderstorm
    if (desc.contains('mưa') ||
        desc.contains('rain') ||
        desc.contains('drizzle') ||
        desc.contains('nước') ||
        code.startsWith('09') ||
        code.startsWith('10')) {
      iconData = Icons.water_drop_rounded;
      iconColor = color ?? Colors.lightBlueAccent;
    } else if (desc.contains('dông') ||
        desc.contains('sấm') ||
        desc.contains('bão') ||
        desc.contains('thunderstorm') ||
        code.startsWith('11')) {
      iconData = Icons.thunderstorm_rounded;
      iconColor = color ?? Colors.amberAccent;
    } else if (desc.contains('sương') || desc.contains('mist') || code.startsWith('50')) {
      iconData = Icons.cloud_queue_rounded;
      iconColor = color ?? Colors.grey.shade300;
    } else if (desc.contains('nắng') ||
        desc.contains('quang') ||
        desc.contains('clear') ||
        desc.contains('sun') ||
        code == '01d') {
      iconData = Icons.wb_sunny_rounded;
      iconColor = color ?? Colors.amberAccent;
    } else if (desc.contains('mây') || desc.contains('cloud') || code.startsWith('02') || code.startsWith('03') || code.startsWith('04')) {
      iconData = Icons.cloud_rounded;
      iconColor = color ?? Colors.white70;
    }

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }
}
