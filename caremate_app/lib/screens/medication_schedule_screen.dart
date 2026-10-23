import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../core/theme/app_theme.dart';

class MedicationScheduleScreen extends StatelessWidget {
  const MedicationScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meds = medProvider.medications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Schedule', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Add Medication',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryTeal),
            onPressed: () => _showAddEditMedicationDialog(context, null),
          ),
        ],
      ),
      body: meds.isEmpty
          ? const Center(child: Text('No active medications scheduled.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meds.length,
              itemBuilder: (context, index) {
                final med = meds[index];
                return _buildMedicationCard(context, med, medProvider, isDark);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditMedicationDialog(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMedicationCard(
      BuildContext context, Medication med, MedicationProvider provider, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'S${med.compartmentSlot}',
                      style: const TextStyle(
                        color: AppTheme.primaryTealDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              med.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ),
                          if (med.rxVerified)
                            const Tooltip(
                              message: 'Physician prescription verified',
                              child: Icon(Icons.verified_rounded, size: 16, color: AppTheme.primaryTeal),
                            ),
                        ],
                      ),
                      Text(
                        '${med.dosage} • ${med.purpose}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => _showMedOptions(context, med, provider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Schedule Times Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final time in med.scheduleTimes)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.tealLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 12, color: AppTheme.primaryTealDark),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryTealDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stock: ${med.stockCount} ${med.unit}s',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: med.stockCount < 10 ? AppTheme.statusFailed : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Instruction: ${med.instructions}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedOptions(BuildContext context, Medication med, MedicationProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.primaryTeal),
              title: const Text('Edit Schedule & Slot'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddEditMedicationDialog(context, med);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusFailed),
              title: const Text('Remove Medication'),
              onTap: () {
                Navigator.pop(ctx);
                provider.deleteMedication(med.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditMedicationDialog(BuildContext context, Medication? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '500 mg');
    final purposeCtrl = TextEditingController(text: existing?.purpose ?? 'Maintenance');
    final instructCtrl = TextEditingController(text: existing?.instructions ?? 'Take with water');
    final stockCtrl = TextEditingController(text: (existing?.stockCount ?? 30).toString());
    int selectedSlot = existing?.compartmentSlot ?? 1;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Prescription' : 'Edit Prescription'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Medication Name (e.g. Metformin HCl)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dosageCtrl,
                      decoration: const InputDecoration(labelText: 'Dosage (e.g. 500 mg)'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedSlot,
                      decoration: const InputDecoration(labelText: 'Robot Carousel Compartment Slot'),
                      items: List.generate(6, (i) => i + 1).map((slot) {
                        return DropdownMenuItem<int>(
                          value: slot,
                          child: Text('Slot $slot (Angle: ${(slot - 1) * 60}°)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedSlot = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: purposeCtrl,
                      decoration: const InputDecoration(labelText: 'Clinical Purpose'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: instructCtrl,
                      decoration: const InputDecoration(labelText: 'Instructions for Patient'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pill Stock Count in Compartment'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final provider = Provider.of<MedicationProvider>(context, listen: false);

                    if (existing != null) {
                      provider.updateMedication(existing.copyWith(
                        name: name,
                        dosage: dosageCtrl.text.trim(),
                        compartmentSlot: selectedSlot,
                        purpose: purposeCtrl.text.trim(),
                        instructions: instructCtrl.text.trim(),
                        stockCount: int.tryParse(stockCtrl.text.trim()) ?? 30,
                      ));
                    } else {
                      provider.addMedication(Medication(
                        id: 'med_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        dosage: dosageCtrl.text.trim(),
                        compartmentSlot: selectedSlot,
                        scheduleTimes: ['09:00'],
                        purpose: purposeCtrl.text.trim(),
                        instructions: instructCtrl.text.trim(),
                        stockCount: int.tryParse(stockCtrl.text.trim()) ?? 30,
                        rxVerified: true,
                      ));
                    }
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('Save Prescription'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
