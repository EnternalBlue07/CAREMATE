import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/caregiver_provider.dart';
import '../core/theme/app_theme.dart';

class EmergencyCallSheet extends StatelessWidget {
  const EmergencyCallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final caregiver = context.watch<CaregiverProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emergency_rounded, color: AppTheme.statusFailed, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Contacts & SOS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Immediate assistance & clinical contacts',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          for (final contact in caregiver.emergencyContacts)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: contact.isPrimary
                      ? AppTheme.primaryTeal
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  width: contact.isPrimary ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: contact.isPrimary ? AppTheme.tealLight : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  child: Icon(
                    contact.relationship.contains('Physician')
                        ? Icons.medical_services_rounded
                        : Icons.phone_rounded,
                    color: contact.isPrimary ? AppTheme.primaryTealDark : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                title: Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  '${contact.relationship} • ${contact.phone}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: contact.isPrimary ? AppTheme.primaryTeal : AppTheme.statusFailed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dialing ${contact.name} (${contact.phone})...'),
                        backgroundColor: AppTheme.primaryTeal,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
