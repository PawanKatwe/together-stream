import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/livekit_service.dart';

class QualitySelectorSheet extends StatelessWidget {
  final ScreenQualityPreset currentPreset;
  final ValueChanged<ScreenQualityPreset> onSelectPreset;

  const QualitySelectorSheet({
    super.key,
    required this.currentPreset,
    required this.onSelectPreset,
  });

  static void show(
    BuildContext context, {
    required ScreenQualityPreset currentPreset,
    required ValueChanged<ScreenQualityPreset> onSelectPreset,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => QualitySelectorSheet(
        currentPreset: currentPreset,
        onSelectPreset: onSelectPreset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stream Quality Preset',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Adjust resolution to balance battery, heat, and data usage.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 18),

          ...ScreenQualityPreset.values.map((preset) {
            final isSelected = preset == currentPreset;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryRose.withOpacity(0.12) : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryRose : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  preset.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryRoseLight : AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${preset.width}x${preset.height} • ${preset.frameRate} fps • ~${(preset.bitrate / 1000000).toStringAsFixed(1)} Mbps',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppTheme.primaryRose)
                    : null,
                onTap: () {
                  onSelectPreset(preset);
                  Navigator.pop(context);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
