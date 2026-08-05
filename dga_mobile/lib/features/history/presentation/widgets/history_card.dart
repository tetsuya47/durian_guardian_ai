import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/url_resolver.dart';
import '../../domain/entities/history_entities.dart';

class HistoryCard extends StatelessWidget {
  final HistoryLogEntity log;
  final VoidCallback onTap;

  const HistoryCard({
    super.key,
    required this.log,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = log.diseaseName.contains('Không phát hiện') || log.diseaseName.toLowerCase().contains('khỏe mạnh');
    final isNeedMonitor = log.severity == 'Trung bình' || log.diseaseName.toLowerCase().contains('theo dõi');

    String statusText = isHealthy ? 'Khỏe mạnh' : (isNeedMonitor ? 'Cần theo dõi' : 'Có bệnh');
    Color badgeBg = isHealthy ? const Color(0xFFE8F5ED) : (isNeedMonitor ? const Color(0xFFE0F2FE) : const Color(0xFFFEF3C7));
    Color badgeTextColor = isHealthy ? const Color(0xFF1E8E4A) : (isNeedMonitor ? const Color(0xFF0284C7) : const Color(0xFFD97706));

    final confidencePercent = (log.confidence * 100).toStringAsFixed(0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 95,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Leaf Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _buildSmartImage(log.imageUrl),
                ),
              ),
              const SizedBox(width: 14),

              // Middle Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.treeName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${log.date} • ${log.time}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 13,
                          color: badgeTextColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Độ tin cậy: $confidencePercent%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron Right Button
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F9F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF1E8E4A),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartImage(String url) {
    final resolvedUrl = UrlResolver.resolve(url);
    if (resolvedUrl.isEmpty) {
      return _buildFallbackImage();
    }

    if (resolvedUrl.startsWith('assets/')) {
      return Image.asset(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }

    if (resolvedUrl.startsWith('/') || resolvedUrl.startsWith('file:')) {
      final cleanPath = resolvedUrl.replaceFirst('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.withOpacity(0.1),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _buildFallbackImage(),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Icon(
        Icons.energy_savings_leaf_rounded,
        size: 32,
        color: Color(0xFF1E8E4A),
      ),
    );
  }
}
