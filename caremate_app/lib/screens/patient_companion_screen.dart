import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../providers/robot_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/dose_event.dart';
import '../models/medication.dart';
import '../models/robot_state.dart';
import '../core/theme/app_theme.dart';
import '../widgets/emergency_call_sheet.dart';
import '../widgets/ai_companion_sheet.dart';
import '../widgets/caremate_robot_avatar.dart';

class PatientCompanionScreen extends StatefulWidget {
  const PatientCompanionScreen({super.key});

  @override
  State<PatientCompanionScreen> createState() => _PatientCompanionScreenState();
}

class _PatientCompanionScreenState extends State<PatientCompanionScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  List<DateTime> _generateWeekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 3 days before today, today, and 3 days after today (total 7 days)
    return List.generate(7, (i) => today.subtract(Duration(days: 3 - i)));
  }

  String _formatDueCountdown(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      final pastMinutes = difference.inMinutes.abs();
      if (pastMinutes < 60) {
        return 'Due now ($pastMinutes min ago)';
      } else {
        return 'Scheduled earlier';
      }
    } else {
      final inMinutes = difference.inMinutes;
      if (inMinutes == 0) {
        return 'Due right now';
      } else if (inMinutes < 60) {
        return 'Due in $inMinutes min';
      } else {
        final hours = difference.inHours;
        final mins = inMinutes % 60;
        return mins > 0 ? 'Due in ${hours}h ${mins}m' : 'Due in ${hours}h';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final robotProvider = context.watch<RobotProvider>();
    final appState = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final robotState = robotProvider.state;

    // Filter doses for selected date
    final dosesForDate = medProvider.doseHistory.where((d) {
      return d.scheduledTime.year == _selectedDate.year &&
          d.scheduledTime.month == _selectedDate.month &&
          d.scheduledTime.day == _selectedDate.day;
    }).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final isSelectedDateToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    // Check if there is an active dose awaiting patient physical ingestion
    final pendingAckDose = isSelectedDateToday
        ? dosesForDate.where((d) => d.status == DoseStatus.dispenseConfirmed).firstOrNull
        : null;

    final formattedHeaderDate = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Return to Caregiver Mode',
          onPressed: () {
            appState.switchRole(UserRole.caregiver);
          },
        ),
        title: Column(
          children: [
            const Text(
              "Today's Medication",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              formattedHeaderDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Date Picker action
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryTeal, size: 20),
            ),
            tooltip: 'Choose Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = DateTime(picked.year, picked.month, picked.day);
                });
              }
            },
          ),
          // Emergency SOS Action
          IconButton(
            tooltip: 'Emergency Contacts & SOS',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emergency_rounded, color: AppTheme.statusFailed, size: 20),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const EmergencyCallSheet(),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryTeal,
        onRefresh: () async {
          await medProvider.loadData();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Horizontal Date Ribbon (7 days)
            _buildDateRibbon(isDark),
            const SizedBox(height: 16),

            // 2. Reassuring Robot & Hardware Status Banner
            _buildHardwareStatusBanner(context, robotState, isDark),
            const SizedBox(height: 16),

            // 3. Urgent In-Tray Ingestion Confirmation Alert (if dose is waiting in tray)
            if (pendingAckDose != null) ...[
              _buildTrayReadyAlertCard(context, pendingAckDose, medProvider, isDark),
              const SizedBox(height: 16),
            ],

            // 4. Medication Dose Cards List
            if (dosesForDate.isEmpty)
              _buildEmptyDayCard(isDark)
            else
              for (int i = 0; i < dosesForDate.length; i++)
                _buildMedicationScheduleCard(
                  context: context,
                  dose: dosesForDate[i],
                  medProvider: medProvider,
                  robotState: robotState,
                  index: i,
                  isDark: isDark,
                  isHighlighted: _isNextUpcomingDose(dosesForDate[i], dosesForDate),
                ),

            const SizedBox(height: 16),

            // 5. Hydration & Senior Wellness Reassurance Card
            _buildHydrationPromptCard(isDark),
            const SizedBox(height: 16),

            // 6. Caremate AI Voice & Healthcare Assistant Banner
            _buildAiAssistantBanner(context, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- 1. Horizontal Date Ribbon ---
  Widget _buildDateRibbon(bool isDark) {
    final weekDays = _generateWeekDays();

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: weekDays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = weekDays[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;

          return Semantics(
            button: true,
            selected: isSelected,
            label: '${DateFormat('EEEE, d MMMM').format(date)}${isToday ? ', Today' : ''}',
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryTeal
                      : (isDark ? const Color(0xFF152238) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryTeal
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('d').format(date),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEE').format(date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                    if (isToday && !isSelected) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 2. Hardware Status Banner ---
  Widget _buildHardwareStatusBanner(BuildContext context, RobotState robot, bool isDark) {
    final isConnected = robot.connectionStatus == RobotConnectionStatus.connected;

    Color badgeColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    if (robot.isJamDetected) {
      badgeColor = AppTheme.statusFailed;
      statusTitle = 'Robot Dispenser Jammed';
      statusSubtitle = 'Please ask a caregiver or family member to check the tray.';
      statusIcon = Icons.warning_rounded;
    } else if (isConnected) {
      badgeColor = AppTheme.statusDispensed;
      statusTitle = 'CAREMATE Robot Connected';
      statusSubtitle = 'Compartment slot ${robot.activeSlot} ready • Battery at ${robot.batteryLevel}%';
      statusIcon = Icons.bluetooth_connected_rounded;
    } else {
      badgeColor = AppTheme.statusWarning;
      statusTitle = 'Robot Offline (Simulator Mode)';
      statusSubtitle = 'Pills can be taken manually or verified in simulation.';
      statusIcon = Icons.bluetooth_searching_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Tray-Ready Acknowledgment Card ---
  Widget _buildTrayReadyAlertCard(
      BuildContext context, DoseEvent dose, MedicationProvider provider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5), // Soft reassuring mint/emerald
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.statusDispensed, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.statusDispensed.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.statusDispensed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEDICINE IS IN ROBOT TRAY',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Optical drop sensor confirmed physical drop.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${dose.medicationName} • ${dose.dosage}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF064E3B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please pick up the tablet from the tray and swallow with a full glass of water. Then tap below to record ingestion:',
            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF065F46)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusDispensed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await provider.acknowledgeDose(dose.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Ingestion confirmed and recorded in caregiver history.'),
                      backgroundColor: AppTheme.statusDispensed,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 22),
              label: const Text(
                'I HAVE TAKEN MY MEDICINE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Medication Schedule Card ---
  Widget _buildMedicationScheduleCard({
    required BuildContext context,
    required DoseEvent dose,
    required MedicationProvider medProvider,
    required RobotState robotState,
    required int index,
    required bool isDark,
    required bool isHighlighted,
  }) {
    final med = medProvider.medications.where((m) => m.id == dose.medicationId).firstOrNull;
    final timeStr = DateFormat('hh:mm a').format(dose.scheduledTime);
    final dueCountdown = _formatDueCountdown(dose.scheduledTime);

    // Border and background highlighting
    Color cardBg = isDark ? const Color(0xFF152238) : Colors.white;
    Border cardBorder;

    if (dose.status == DoseStatus.dispenseConfirmed) {
      cardBorder = Border.all(color: AppTheme.statusDispensed, width: 2);
    } else if (isHighlighted && dose.status == DoseStatus.scheduled) {
      // Golden/Amber accent border matching reference mockup
      cardBorder = Border.all(color: const Color(0xFFF59E0B), width: 2);
    } else {
      cardBorder = Border.all(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        width: 1,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: cardBorder,
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Time + Status Badge + Options
          Row(
            children: [
              // Scheduled Time
              _buildTimeHeader(dose, timeStr, isDark),
              const SizedBox(width: 8),

              // Status Pill Badge
              _buildStatusPill(dose, dueCountdown, isHighlighted),

              const Spacer(),

              // Medicine More Options
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, size: 20, color: Colors.grey),
                tooltip: 'Medication Details',
                onPressed: () => _showMedicationDetails(context, dose, med),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Medicine Content Row with Visual Pill Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visual Pill Thumbnail
              _buildPillThumbnail(dose.medicationName, index),
              const SizedBox(width: 14),

              // Medication Name & Food/Timing Instructions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.medicationName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${dose.dosage} • ${_formatFoodContext(med, dose)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Primary Action Button (If highlighted or awaiting action)
          if (dose.status == DoseStatus.scheduled) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (med == null) return;
                  final success = await medProvider.dispenseMedication(med, existingDose: dose);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(medProvider.lastDispenseMessage ?? 'Dispense command sent to robot.'),
                        backgroundColor: success ? AppTheme.statusDispensed : AppTheme.statusFailed,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.touch_app_rounded, size: 20),
                label: Text(
                  robotState.connectionStatus == RobotConnectionStatus.connected
                      ? 'DISPENSE FROM ROBOT'
                      : 'MARK AS TAKEN',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.4),
                ),
              ),
            ),
          ] else if (dose.status == DoseStatus.dispenseConfirmed) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusDispensed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await medProvider.acknowledgeDose(dose.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Ingestion confirmed and recorded in caregiver history.'),
                        backgroundColor: AppTheme.statusDispensed,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'CONFIRM MEDICINE TAKEN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeHeader(DoseEvent dose, String timeStr, bool isDark) {
    if (dose.status == DoseStatus.acknowledged) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.statusDispensed, size: 18),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.statusDispensed,
            ),
          ),
        ],
      );
    } else if (dose.status == DoseStatus.dispenseConfirmed) {
      return Row(
        children: [
          const Icon(Icons.inventory_2_rounded, color: AppTheme.tealAccent, size: 18),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.tealAccent,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatusPill(DoseEvent dose, String dueCountdown, bool isHighlighted) {
    switch (dose.status) {
      case DoseStatus.acknowledged:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.statusDispensed.withOpacity(0.35)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, color: Color(0xFF047857), size: 13),
              SizedBox(width: 4),
              Text(
                'Taken',
                style: TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      case DoseStatus.dispenseConfirmed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFCCFBF1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.35)),
          ),
          child: const Text(
            'In Tray',
            style: TextStyle(color: Color(0xFF0F766E), fontSize: 11, fontWeight: FontWeight.w800),
          ),
        );
      case DoseStatus.commandSent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Dispensing...',
            style: TextStyle(color: Color(0xFF6D28D9), fontSize: 11, fontWeight: FontWeight.w700),
          ),
        );
      case DoseStatus.failed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Check Robot',
            style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11, fontWeight: FontWeight.w700),
          ),
        );
      case DoseStatus.scheduled:
      default:
        if (isHighlighted) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFFB45309), size: 13),
                const SizedBox(width: 4),
                Text(
                  dueCountdown,
                  style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
    }
  }

  // Visual Pill Avatar Thumbnail matching reference image
  Widget _buildPillThumbnail(String medName, int index) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    final lower = medName.toLowerCase();
    if (lower.contains('metformin') || lower.contains('aspirin') || lower.contains('vitamin')) {
      // Yellow round tablet
      iconColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFEF3C7);
      icon = Icons.circle;
    } else if (lower.contains('paracetamol')) {
      // Light blue capsule
      iconColor = const Color(0xFF0284C7);
      bgColor = const Color(0xFFE0F2FE);
      icon = Icons.medication_rounded;
    } else {
      // Soft pink oval tablet
      iconColor = const Color(0xFFE11D48);
      bgColor = const Color(0xFFFFE4E6);
      icon = Icons.medication_liquid_rounded;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  String _formatFoodContext(Medication? med, DoseEvent dose) {
    if (med != null && med.instructions.isNotEmpty) {
      final lower = med.instructions.toLowerCase();
      if (lower.contains('breakfast')) return 'After breakfast';
      if (lower.contains('lunch')) return 'After lunch';
      if (lower.contains('dinner')) return 'After dinner';
      if (lower.contains('meal') || lower.contains('food')) return 'After food';
    }
    final hour = dose.scheduledTime.hour;
    if (hour < 11) return 'After breakfast';
    if (hour < 15) return 'After lunch';
    return 'After dinner';
  }

  bool _isNextUpcomingDose(DoseEvent dose, List<DoseEvent> doses) {
    final pending = doses.where((d) => d.status == DoseStatus.scheduled || d.status == DoseStatus.dispenseConfirmed).toList();
    if (pending.isEmpty) return false;
    return pending.first.id == dose.id;
  }

  Widget _buildEmptyDayCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152238) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 48, color: AppTheme.primaryTeal.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'No Prescriptions Scheduled',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'No doses were recorded for this date.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
          ),
        ],
      ),
    );
  }

  // --- 5. Hydration Prompt Card ---
  Widget _buildHydrationPromptCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152238) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.local_drink_rounded, color: Color(0xFF0284C7), size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carry a glass of water',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stay hydrated for better health & easy swallowing.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. AI Healthcare Companion Banner ---
  Widget _buildAiAssistantBanner(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AiCompanionSheet(),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A283F) : const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9333EA).withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            CaremateRobotAvatar(width: 52, height: 50),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help? Ask Caremate AI',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF6B21A8),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ask in English or Hindi about your medicine or food instructions.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF9333EA), size: 20),
          ],
        ),
      ),
    );
  }

  void _showMedicationDetails(BuildContext context, DoseEvent dose, Medication? med) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dose.medicationName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Dosage: ${dose.dosage}', style: const TextStyle(fontSize: 14)),
            if (med != null) ...[
              const SizedBox(height: 4),
              Text('Instructions: ${med.instructions}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Text('Purpose: ${med.purpose}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
