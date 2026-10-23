import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vital_reading.dart';
import '../core/theme/app_theme.dart';

class VitalCard extends StatelessWidget {
  final VitalReading vital;

  const VitalCard({super.key, required this.vital});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    String label;

    switch (vital.type) {
      case VitalType.bloodPressure:
        icon = Icons.favorite_rounded;
        iconColor = const Color(0xFFEF4444);
        label = 'Blood Pressure';
        break;
      case VitalType.heartRate:
        icon = Icons.monitor_heart_rounded;
        iconColor = const Color(0xFFEC4899);
        label = 'Heart Rate';
        break;
      case VitalType.oxygenSaturation:
        icon = Icons.air_rounded;
        iconColor = const Color(0xFF3B82F6);
        label = 'SpO2 Oxygen';
        break;
      case VitalType.bloodGlucose:
        icon = Icons.bloodtype_rounded;
        iconColor = const Color(0xFF8B5CF6);
        label = 'Blood Glucose';
        break;
    }

    final timeStr = DateFormat('hh:mm a').format(vital.timestamp);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (vital.isValidated)
                        const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryTeal)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade700, width: 0.5),
                          ),
                          child: const Text(
                            'Simulated',
                            style: TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vital.formattedValue,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    vital.deviceModel,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (vital.clinicalNote != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      vital.clinicalNote!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vital.statusCategory,
                    style: const TextStyle(
                      color: AppTheme.primaryTealDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
