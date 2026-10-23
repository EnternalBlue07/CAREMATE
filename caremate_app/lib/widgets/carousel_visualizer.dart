import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/medication.dart';

class CarouselVisualizer extends StatelessWidget {
  final int activeSlot; // 1 to 6
  final bool isGateOpen;
  final bool isJamDetected;
  final bool isDispensing;
  final List<Medication> medications;
  final Function(int slot)? onSlotTap;

  const CarouselVisualizer({
    super.key,
    required this.activeSlot,
    required this.isGateOpen,
    required this.isJamDetected,
    required this.isDispensing,
    this.medications = const [],
    this.onSlotTap,
  });

  String _getSlotMedicationName(int slotNum) {
    final med = medications.where((m) => m.compartmentSlot == slotNum).firstOrNull;
    if (med != null) {
      // Short friendly display name
      if (med.name.toLowerCase().contains('metformin')) return 'Metformin';
      if (med.name.toLowerCase().contains('amlodipine')) return 'Amlodipine';
      if (med.name.toLowerCase().contains('atorvastatin')) return 'Atorvastatin';
      if (med.name.toLowerCase().contains('aspirin')) return 'Aspirin';
      if (med.name.toLowerCase().contains('paracetamol')) return 'Paracetamol';
      if (med.name.toLowerCase().contains('vitamin')) return 'Vitamin D3';
      return med.name.split(' ').first;
    }
    // Hardcoded fallback for default 6-slot demo if unassigned
    if (slotNum == 1) return 'Paracetamol';
    if (slotNum == 2) return 'Amlodipine';
    if (slotNum == 3) return 'Vitamin D3';
    if (slotNum == 4) return 'BP Medicine';
    return 'Empty';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const carouselDiameter = 200.0;
    const totalOuterWidth = 320.0;
    const totalOuterHeight = 310.0;

    // Smooth servo rotation angle
    // Slot 1 at top: angle 0. When activeSlot changes, rotate so activeSlot is at top.
    final targetAngle = ((activeSlot - 1) * (2 * math.pi / 6));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Radial Carousel with External Labels
        SizedBox(
          width: totalOuterWidth,
          height: totalOuterHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Circular Metallic Bezel / Track
              Container(
                width: carouselDiameter + 30,
                height: carouselDiameter + 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFFFFFFF), const Color(0xFFE2E8F0)],
                    stops: const [0.75, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isJamDetected
                          ? AppTheme.statusFailed.withOpacity(0.3)
                          : Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),

              // Rotating Turntable Disc with 6 Recessed Wells
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: -targetAngle),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeInOutCubic,
                builder: (context, rotation, child) {
                  return Transform.rotate(
                    angle: rotation,
                    child: SizedBox(
                      width: carouselDiameter,
                      height: carouselDiameter,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base turntable surface with groove partitions
                          Container(
                            width: carouselDiameter,
                            height: carouselDiameter,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF152238) : const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                          ),

                          // 6 Compartment Wells
                          for (int i = 1; i <= 6; i++)
                            _buildRecessedWell(context, i, carouselDiameter, isDark),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Center Spindle Hub with CAREMATE Monogram
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border.all(
                    color: isJamDetected
                        ? AppTheme.statusFailed
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'CAREMATE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: AppTheme.primaryTealDark,
                      ),
                    ),
                  ],
                ),
              ),

              // 6 External Static Slot Labels Positioned Around Bezel
              for (int i = 1; i <= 6; i++)
                _buildExternalSlotLabel(i, totalOuterWidth, totalOuterHeight, isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Alignment Status Pill Banner
        _buildAlignmentStatusPill(isDark),
      ],
    );
  }

  // --- External Static Labels Around the Bezel ---
  Widget _buildExternalSlotLabel(int slotNum, double w, double h, bool isDark) {
    // Top (slot 1) is at angle -pi/2 (0° top)
    final angle = (slotNum - 1) * (2 * math.pi / 6) - (math.pi / 2);
    const labelDistance = 126.0; // Radius from center to external text
    final cx = (w / 2) + labelDistance * math.cos(angle);
    final cy = (h / 2) + labelDistance * math.sin(angle);

    final isSelected = slotNum == activeSlot;
    final medName = _getSlotMedicationName(slotNum);
    final isEmpty = medName.toLowerCase() == 'empty';

    return Positioned(
      left: cx - 44,
      top: cy - 14,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSlotTap?.call(slotNum),
        child: Container(
          width: 88,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'S$slotNum',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? AppTheme.primaryTeal
                      : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                ),
              ),
              Text(
                medName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryTealDark
                      : (isEmpty
                          ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                          : (isDark ? Colors.white60 : const Color(0xFF475569))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Recessed Circular Well with Pill Graphic Inside ---
  Widget _buildRecessedWell(BuildContext context, int slotNum, double diameter, bool isDark) {
    final angle = (slotNum - 1) * (2 * math.pi / 6) - (math.pi / 2);
    final radius = (diameter / 2) - 34;
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    final isSelected = slotNum == activeSlot;
    final med = medications.where((m) => m.compartmentSlot == slotNum).firstOrNull;
    final medName = _getSlotMedicationName(slotNum);
    final isEmpty = medName.toLowerCase() == 'empty';

    return Transform.translate(
      offset: Offset(x, y),
      child: Semantics(
        label: 'Compartment Slot $slotNum: ${med != null ? "${med.name} ${med.dosage}" : "Empty compartment"}',
        value: isSelected ? 'Currently aligned with bottom dispense chute' : 'Rotated ${(slotNum - 1) * 60} degrees',
        hint: 'Double tap to rotate carousel and select slot $slotNum',
        button: true,
        selected: isSelected,
        onTap: onSlotTap != null ? () => onSlotTap!(slotNum) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSlotTap?.call(slotNum),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 50,
              minHeight: 50,
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFCCFBF1) // Glowing Mint Active
                    : (isDark ? const Color(0xFF0B1320) : const Color(0xFFF1F5F9)),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF22D3EE) // Illuminated Cyan Halo
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                  width: isSelected ? 2.5 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF22D3EE).withOpacity(0.45),
                          blurRadius: 10,
                          spreadRadius: 1.5,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _buildPillShapeInsideWell(slotNum, medName, isEmpty, isSelected),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Realistic 3D-styled Pill Graphic Inside the Well ---
  Widget _buildPillShapeInsideWell(int slotNum, String medName, bool isEmpty, bool isSelected) {
    if (isEmpty) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.12),
        ),
      );
    }

    if (slotNum == 1) {
      // White Capsule (Paracetamol)
      return Container(
        width: 22,
        height: 11,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
    } else if (slotNum == 2 || slotNum == 4) {
      // Pink Tablet (Amlodipine / BP Medicine)
      return Container(
        width: 20,
        height: 11,
        decoration: BoxDecoration(
          color: const Color(0xFFFDA4AF),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
    } else {
      // White / Yellow Round Tablet (Vitamin D3)
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFEF08A),
          border: Border.all(color: const Color(0xFFFDE047), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
    }
  }

  // --- 2. Alignment Status Pill Banner ---
  Widget _buildAlignmentStatusPill(bool isDark) {
    if (isJamDetected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.statusFailed.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.statusFailed, size: 16),
            SizedBox(width: 6),
            Text(
              'CAROUSEL JAMMED (CLEAR JAM REQUIRED)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.statusFailed,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    if (isDispensing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
            ),
            SizedBox(width: 8),
            Text(
              'DISPENSING IN PROGRESS (OPTICAL DROP CHECK)...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6D28D9),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.statusDispensed.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.statusDispensed, size: 16),
          const SizedBox(width: 6),
          Text(
            'Slot $activeSlot aligned with dispense chute',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }
}
