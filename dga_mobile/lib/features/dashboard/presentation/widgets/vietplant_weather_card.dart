import 'package:flutter/material.dart';
import '../../../../shared/components/weather_icon_widget.dart';

class VietplantWeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final VoidCallback? onViewDetails;

  const VietplantWeatherCard({
    super.key,
    this.weatherData,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final location = weatherData?['location_name'] ?? weatherData?['location'] ?? 'Krông Pắc, Đắk Lắk';
    final tempVal = weatherData?['temp_celsius'] ?? weatherData?['temperature_c'] ?? weatherData?['temp'];
    final temp = tempVal != null ? (tempVal is num ? tempVal.round().toString() : (double.tryParse(tempVal.toString())?.round().toString() ?? tempVal.toString())) : '24';
    final highTemp = weatherData?['temp_max'] != null ? (weatherData!['temp_max'] is num ? (weatherData!['temp_max'] as num).round().toString() : (double.tryParse(weatherData!['temp_max'].toString())?.round().toString() ?? '31')) : '31';
    final lowTemp = weatherData?['temp_min'] != null ? (weatherData!['temp_min'] is num ? (weatherData!['temp_min'] as num).round().toString() : (double.tryParse(weatherData!['temp_min'].toString())?.round().toString() ?? '22')) : '22';
    final condition = weatherData?['description'] ?? weatherData?['condition'] ?? 'Nắng nhẹ, mây rải rác';
    final iconUrl = weatherData?['icon_url']?.toString();
    final iconCode = weatherData?['icon_code']?.toString();
    final recommendation = weatherData?['agricultural_advice'] ?? weatherData?['agri_recommendation'] ??
        'Tây Nguyên: Duy trì hệ thống thoát nước thông suốt, theo dõi độ ẩm vườn và kiểm soát nấm nứt thân xì mủ Phytophthora.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tin thời tiết',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              InkWell(
                onTap: onViewDetails,
                child: const Row(
                  children: [
                    Text(
                      'Chi tiết',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: Color(0xFFE65100)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Main Weather Card Container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location & Main Weather Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.navigation, color: Colors.white70, size: 15),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '$temp°',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.arrow_upward, color: Colors.amberAccent, size: 12),
                                          Text(
                                            ' $highTemp°',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.arrow_downward, color: Colors.cyanAccent, size: 12),
                                          Text(
                                            ' $lowTemp°',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            condition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Dynamic Weather Icon matching description (Mưa, Nắng, Mây...)
                    WeatherIconWidget(
                      description: condition,
                      iconUrl: iconUrl,
                      iconCode: iconCode,
                      size: 64,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Agri-Recommendation Box (Khuyến cáo nông vụ)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Color(0xFFE65100), size: 18),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Khuyến cáo nông vụ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recommendation,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF444444),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
