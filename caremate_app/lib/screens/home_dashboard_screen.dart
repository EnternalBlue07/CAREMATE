import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../providers/robot_provider.dart';
import '../providers/caregiver_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/dose_event.dart';
import '../models/robot_state.dart';
import '../core/theme/app_theme.dart';
import '../widgets/caremate_robot_avatar.dart';
import '../widgets/ai_companion_sheet.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/emergency_call_sheet.dart';

class HomeDashboardScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeDashboardScreen({super.key, this.onNavigateTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  String _formatDueCountdown(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      final pastMinutes = difference.inMinutes.abs();
      if (pastMinutes < 60) {
        return 'Due now ($pastMinutes min ago)';
      } else {
        return 'Due earlier today';
      }
    } else {
      final inMinutes = difference.inMinutes;
      if (inMinutes == 0) {
        return 'Due right now';
      } else if (inMinutes < 60) {
        return 'In $inMinutes minutes';
      } else {
        final hours = difference.inHours;
        final mins = inMinutes % 60;
        return mins > 0 ? 'In ${hours}h ${mins}m' : 'In ${hours}h';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final robotProvider = context.watch<RobotProvider>();
    final caregiverProvider = context.watch<CaregiverProvider>();
    final appState = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nextDose = medProvider.nextScheduledDose;
    final todayDoses = medProvider.todayDoses;
    final robotState = robotProvider.state;
    final unreadAlerts = caregiverProvider.unacknowledgedAlertsCount;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            // CAREMATE Monogram Logo Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CAREMATE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  'Your Home Health Companion',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notification Bell with Badge
          Semantics(
            label: 'Notifications and Alerts ($unreadAlerts unread)',
            button: true,
            child: IconButton(
              icon: Badge(
                isLabelVisible: unreadAlerts > 0,
                backgroundColor: AppTheme.statusFailed,
                smallSize: 8,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              tooltip: 'Notifications & Alerts',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const NotificationsSheet(),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryTeal,
        onRefresh: () async {
          await medProvider.loadData();
          await caregiverProvider.loadData();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Warm Greeting & Supportive Subtitle with User Profile Avatar
            _buildGreetingSection(context, appState, isDark),
            const SizedBox(height: 16),

            // 2. Hardware Status Ribbon (Live Telemetry / Diagnostics)
            _buildRobotStatusRibbon(context, robotState, onNavigateTab, isDark),
            const SizedBox(height: 16),

            // 3. Dark Teal Next Medicine Hero Card
            _buildNextMedicineHeroCard(context, nextDose, medProvider, robotState, isDark),
            const SizedBox(height: 20),

            // 4. Four Quick-Action Tiles
            _buildQuickActionGrid(context, onNavigateTab, isDark),
            const SizedBox(height: 24),

            // 5. Today's Progress Card (Circular Progress + Dose Timeline)
            _buildTodayProgressSection(context, todayDoses, medProvider, isDark),
            const SizedBox(height: 24),

            // 6. Emergency SOS Floating Quick Assist Banner
            _buildEmergencyAssistCard(context, isDark),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // --- 1. Warm Greeting Section ---
  Widget _buildGreetingSection(BuildContext context, AppStateProvider appState, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Zumaan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Stay on track. We\'re here with you.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Accessible Profile Avatar Button
        Semantics(
          label: 'User profile: Zumaan. Current mode: ${appState.currentRole.name}. Tap to switch mode.',
          button: true,
          child: InkWell(
            onTap: () => _showProfileDialog(context, appState),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. Hardware Status Ribbon ---
  Widget _buildRobotStatusRibbon(
      BuildContext context, RobotState robot, Function(int)? onNavigateTab, bool isDark) {
    final isConnected = robot.connectionStatus == RobotConnectionStatus.connected;

    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (robot.isJamDetected) {
      badgeColor = AppTheme.statusFailed;
      statusText = 'Carousel Jammed — Inspect Dispenser';
      statusIcon = Icons.warning_rounded;
    } else if (isConnected) {
      badgeColor = AppTheme.statusDispensed;
      statusText = 'CAREMATE Robot Connected (Slot ${robot.activeSlot} • ${robot.batteryLevel}%)';
      statusIcon = Icons.check_circle_rounded;
    } else {
      badgeColor = AppTheme.statusWarning;
      statusText = 'Robot Offline (BLE Simulator Ready • Tap to Inspect)';
      statusIcon = Icons.bluetooth_searching_rounded;
    }

    return InkWell(
      onTap: () => onNavigateTab?.call(2), // Switch to Robot Control tab
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withOpacity(0.30), width: 1),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: badgeColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: badgeColor.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  // --- 3. Dark Teal Next Medicine Hero Card ---
  Widget _buildNextMedicineHeroCard(
      BuildContext context,
      DoseEvent? nextDose,
      MedicationProvider medProvider,
      RobotState robot,
      bool isDark) {
    // If no dose scheduled for today or upcoming
    if (nextDose == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF132E35), Color(0xFF1A3B43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.2), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ALL CAUGHT UP',
                      style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No Pending Doses',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Great job! All scheduled medications for today are taken.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () => onNavigateTab?.call(1),
                    child: const Text('View Full Schedule ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const CaremateRobotAvatar(width: 100, height: 95),
          ],
        ),
      );
    }

    final timeStr = DateFormat('hh:mm a').format(nextDose.scheduledTime);
    final dueCountdown = _formatDueCountdown(nextDose.scheduledTime);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF132E35), Color(0xFF1B3D44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF132E35).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill & Header Kicker
                const Row(
                  children: [
                    Icon(Icons.medication_rounded, size: 15, color: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    Text(
                      'Next Medicine',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Medicine Name
                Text(
                  nextDose.medicationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),

                // Due Countdown Badge
                Text(
                  dueCountdown,
                  style: const TextStyle(
                    color: Color(0xFF2DD4BF), // Mint Accent
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                // Schedule Timing with Clock Icon
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(
                      '$timeStr • ${nextDose.dosage}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // View Schedule Action Pill Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: const Size(130, 40),
                  ),
                  onPressed: () => onNavigateTab?.call(1), // Switch to Schedule Tab
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Schedule',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right Friendly Robot Companion
          const SizedBox(width: 6),
          const CaremateRobotAvatar(width: 106, height: 100),
        ],
      ),
    );
  }

  // --- 4. Four Quick-Action Grid ---
  Widget _buildQuickActionGrid(BuildContext context, Function(int)? onNavigateTab, bool isDark) {
    return Row(
      children: [
        // Tile 1: Medication Schedule
        Expanded(
          child: _buildActionTile(
            context: context,
            label: 'Medication\nSchedule',
            icon: Icons.calendar_month_rounded,
            iconColor: AppTheme.primaryTeal,
            bgColor: const Color(0xFFE6F4F1),
            isDark: isDark,
            onTap: () => onNavigateTab?.call(1),
          ),
        ),
        const SizedBox(width: 10),

        // Tile 2: Robot Control
        Expanded(
          child: _buildActionTile(
            context: context,
            label: 'Robot\nControl',
            icon: Icons.smart_toy_rounded,
            iconColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFE0F2FE),
            isDark: isDark,
            onTap: () => onNavigateTab?.call(2),
          ),
        ),
        const SizedBox(width: 10),

        // Tile 3: Health Vitals
        Expanded(
          child: _buildActionTile(
            context: context,
            label: 'Health\nVitals',
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFE11D48),
            bgColor: const Color(0xFFFFE4E6),
            isDark: isDark,
            onTap: () => onNavigateTab?.call(3), // Caregiver/Health Vitals tab
          ),
        ),
        const SizedBox(width: 10),

        // Tile 4: AI Companion
        Expanded(
          child: _buildActionTile(
            context: context,
            label: 'AI\nCompanion',
            icon: Icons.chat_bubble_rounded,
            iconColor: const Color(0xFF9333EA),
            bgColor: const Color(0xFFF3E8FF),
            isDark: isDark,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AiCompanionSheet(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: label.replaceAll('\n', ' '),
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152238) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? bgColor.withOpacity(0.18) : bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. Today's Progress Section ---
  Widget _buildTodayProgressSection(
      BuildContext context, List<DoseEvent> todayDoses, MedicationProvider medProvider, bool isDark) {
    final totalCount = todayDoses.length;
    final takenCount = todayDoses.where((d) => d.status == DoseStatus.acknowledged).length;
    final progress = totalCount > 0 ? (takenCount / totalCount) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Progress",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () => onNavigateTab?.call(1),
              child: const Text(
                'View All',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress Card Container
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152238) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Circular Progress Ring Indicator
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 86,
                      height: 86,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$takenCount/$totalCount',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Doses Taken',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),

              // Today's Dose Timeline List Preview
              Expanded(
                child: todayDoses.isEmpty
                    ? Center(
                        child: Text(
                          'No medications scheduled for today.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      )
                    : Column(
                        children: todayDoses.take(4).map((dose) {
                          return _buildTimelineDoseRow(context, dose, isDark);
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDoseRow(BuildContext context, DoseEvent dose, bool isDark) {
    final timeStr = DateFormat('hh:mm a').format(dose.scheduledTime);

    Widget statusIcon;
    Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    switch (dose.status) {
      case DoseStatus.acknowledged:
        statusIcon = const Icon(Icons.check_circle_rounded, color: AppTheme.statusDispensed, size: 18);
        break;
      case DoseStatus.dispenseConfirmed:
        statusIcon = const Icon(Icons.inventory_2_rounded, color: AppTheme.tealAccent, size: 18);
        break;
      case DoseStatus.commandSent:
        statusIcon = const Icon(Icons.sync_rounded, color: AppTheme.statusCommandSent, size: 18);
        break;
      case DoseStatus.failed:
        statusIcon = const Icon(Icons.error_outline_rounded, color: AppTheme.statusFailed, size: 18);
        break;
      case DoseStatus.scheduled:
      default:
        // Next due or upcoming
        final isNext = DateTime.now().difference(dose.scheduledTime).inHours.abs() < 2;
        if (isNext) {
          statusIcon = const Icon(Icons.circle, color: AppTheme.statusWarning, size: 14);
        } else {
          statusIcon = Icon(Icons.radio_button_unchecked_rounded,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8), size: 16);
        }
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          statusIcon,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dose.medicationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Emergency Assist Floating Action Banner ---
  Widget _buildEmergencyAssistCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2), // Soft emergency rose
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.statusFailed.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded, color: AppTheme.statusFailed, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Assist',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF991B1B),
                  ),
                ),
                Text(
                  'Tap for immediate caregiver alert & SOS',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.statusFailed,
              foregroundColor: Colors.white,
              minimumSize: const Size(40, 40),
            ),
            icon: const Icon(Icons.call_rounded, size: 18),
            tooltip: 'Call Emergency Contact',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const EmergencyCallSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Profile / Persona Dialog ---
  void _showProfileDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_pin_rounded, color: AppTheme.primaryTeal),
            SizedBox(width: 8),
            Text('User Profile & Mode', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Patient Name: Zumaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('Account: Primary Household Patient', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            const Text('Current Role:', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SegmentedButton<UserRole>(
              segments: const [
                ButtonSegment(value: UserRole.caregiver, label: Text('Caregiver')),
                ButtonSegment(value: UserRole.patient, label: Text('Patient Mode')),
              ],
              selected: {appState.currentRole},
              onSelectionChanged: (newSelection) {
                appState.switchRole(newSelection.first);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
