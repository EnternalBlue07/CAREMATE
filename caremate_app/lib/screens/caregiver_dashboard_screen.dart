import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/caregiver_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/robot_provider.dart';
import '../models/caregiver_alert.dart';
import '../models/dose_event.dart';
import '../models/robot_state.dart';
import '../core/theme/app_theme.dart';
import '../widgets/dose_status_badge.dart';
import '../widgets/vital_card.dart';
import '../widgets/emergency_call_sheet.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  String _alertFilter = 'all'; // 'all', 'unread', 'critical'

  @override
  Widget build(BuildContext context) {
    final caregiver = context.watch<CaregiverProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final robotProvider = context.watch<RobotProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unreadAlerts = caregiver.unacknowledgedAlerts;
    final doses = medProvider.doseHistory;
    final robotState = robotProvider.state;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caregiver Oversight',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Local Device Audit Mode (No Remote Cloud)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTeal,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Patient Profile Action Button
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'Patient Profile & Care Team',
              onPressed: () => _showPatientProfileModal(context, caregiver, isDark),
            ),
            // Emergency SOS Contact Action
            IconButton(
              icon: const Icon(Icons.emergency_outlined, color: AppTheme.statusFailed),
              tooltip: 'Emergency Contacts & SOS',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const EmergencyCallSheet(),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.primaryTeal,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: [
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Overview'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Alerts'),
                    if (unreadAlerts.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.statusFailed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${unreadAlerts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Audit Log'),
              const Tab(text: 'Vitals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Today's Overview & Adherence Analytics
            _buildOverviewTab(context, caregiver, medProvider, robotState, isDark),

            // Tab 2: Actionable Alerts Center
            _buildAlertsTab(context, caregiver, isDark),

            // Tab 3: Chronological Truthful Dose Audit Timeline
            _buildTimelineTab(context, doses, isDark),

            // Tab 4: Health Vitals History with Honest Provenance
            _buildVitalsTab(context, caregiver, isDark),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & ADHERENCE ANALYTICS
  // ==========================================
  Widget _buildOverviewTab(
    BuildContext context,
    CaregiverProvider caregiver,
    MedicationProvider medProvider,
    RobotState robotState,
    bool isDark,
  ) {
    final todayAdherence = medProvider.todayAdherenceRate;
    final adherencePercent = (todayAdherence * 100).toInt();
    final sevenDayAdherence = (medProvider.sevenDayAdherenceRate * 100).toInt();
    final todayDoses = medProvider.todayDoses;
    final takenCount = medProvider.todayTakenCount;
    final pendingCount = medProvider.todayPendingCount;
    final missedCount = medProvider.todayMissedOrFailedCount;
    final lowStock = medProvider.lowStockMedications;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Patient Quick Header Card
        _buildPatientSummaryCard(context, caregiver, isDark),
        const SizedBox(height: 16),

        // 2. Local vs Remote Synchronisation Warning Banner
        _buildSyncModeBanner(isDark),
        const SizedBox(height: 16),

        // 3. Today's Adherence Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F2B2E), const Color(0xFF134E48)]
                  : [AppTheme.primaryTealDark, AppTheme.primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryTeal.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TODAY'S ADHERENCE RATE",
                    style: TextStyle(
                      color: Color(0xFF99F6E4),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '7-Day: $sevenDayAdherence%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$adherencePercent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayDoses.isEmpty
                              ? 'No scheduled doses for today'
                              : '$takenCount of ${todayDoses.length} doses taken or dispensed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calculated strictly from local optical sensor confirmations & patient inputs.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: todayAdherence,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Metric Breakdown Grid (Taken, Pending, Missed/Jammed)
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Taken / Tray',
                count: takenCount.toString(),
                subtitle: 'Verified by sensor',
                color: AppTheme.statusDispensed,
                icon: Icons.check_circle_outline_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Pending',
                count: pendingCount.toString(),
                subtitle: 'Scheduled today',
                color: AppTheme.primaryTeal,
                icon: Icons.schedule_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Attention',
                count: missedCount.toString(),
                subtitle: 'Missed / Failed',
                color: missedCount > 0 ? AppTheme.statusFailed : AppTheme.statusAcknowledged,
                icon: Icons.warning_amber_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 5. Active Safety Warnings (Low stock, Robot status)
        if (lowStock.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B18) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Low Medication Stock Alert',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lowStock.map((m) => "${m.name} (${m.stockCount} left)").join(", ")}. Refill required soon.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 6. Robot Hardware Telemetry Card
        _buildRobotTelemetryCard(robotState, isDark),
      ],
    );
  }

  Widget _buildPatientSummaryCard(BuildContext context, CaregiverProvider caregiver, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.tealLight,
            child: Text(
              'RS',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.primaryTealDark,
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
                    const Text(
                      'Ramesh Sharma',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade700, width: 0.8),
                      ),
                      child: Text(
                        'Demo Patient Record',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Age 74 • Hypertension & Type 2 Diabetes',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(48, 36),
              side: const BorderSide(color: AppTheme.primaryTeal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.phone_outlined, size: 14, color: AppTheme.primaryTeal),
            label: const Text(
              'Call',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const EmergencyCallSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSyncModeBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132338) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF38BDF8).withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFF0284C7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing local device records. Remote cloud synchronization is offline (direct Bluetooth audit mode only).',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String count,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRobotTelemetryCard(RobotState state, bool isDark) {
    final isConnected = state.connectionStatus == RobotConnectionStatus.connected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Robot Hardware Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isConnected ? AppTheme.statusDispensed : AppTheme.statusFailed,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isConnected ? AppTheme.statusDispensed : AppTheme.statusFailed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'BLE Connected' : 'BLE Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isConnected ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryItem(
                  label: 'Current Slot',
                  val: 'Slot ${state.activeSlot}',
                  icon: Icons.rotate_right_rounded,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildTelemetryItem(
                  label: 'Battery (ESP32)',
                  val: '${state.batteryLevel}%',
                  icon: Icons.battery_charging_full_rounded,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildTelemetryItem(
                  label: 'Optical Drop Sensor',
                  val: state.isDispensing ? 'Triggered' : 'Clear',
                  icon: Icons.sensors_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (state.isJamDetected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppTheme.statusFailed, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mechanism Jam Detected: Carousel servo halted for patient safety.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.statusFailed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryItem({
    required String label,
    required String val,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: ACTIONABLE ALERTS CENTER
  // ==========================================
  Widget _buildAlertsTab(BuildContext context, CaregiverProvider caregiver, bool isDark) {
    List<CaregiverAlert> displayAlerts;
    if (_alertFilter == 'unread') {
      displayAlerts = caregiver.unacknowledgedAlerts;
    } else if (_alertFilter == 'critical') {
      displayAlerts = caregiver.criticalAlerts;
    } else {
      displayAlerts = caregiver.alerts;
    }

    return Column(
      children: [
        // Filter Pills Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            children: [
              _buildFilterChip('All (${caregiver.alerts.length})', 'all', _alertFilter, (v) {
                setState(() => _alertFilter = v);
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Unread (${caregiver.unacknowledgedAlerts.length})', 'unread', _alertFilter, (v) {
                setState(() => _alertFilter = v);
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Critical (${caregiver.criticalAlerts.length})', 'critical', _alertFilter, (v) {
                setState(() => _alertFilter = v);
              }),
            ],
          ),
        ),

        // Alert Items List
        Expanded(
          child: displayAlerts.isEmpty
              ? _buildEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No alerts matching this filter',
                  subtitle: 'All caregiver alerts have been acknowledged or none match this filter.',
                  isDark: isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = displayAlerts[index];
                    return _buildAlertCard(context, caregiver, alert, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String) onSelect) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    CaregiverProvider caregiver,
    CaregiverAlert alert,
    bool isDark,
  ) {
    final timeStr = DateFormat('hh:mm a • MMM d').format(alert.timestamp);

    Color borderClr;
    Color bgClr;
    IconData icon;

    switch (alert.severity) {
      case AlertSeverity.emergency:
      case AlertSeverity.hardwareError:
        borderClr = AppTheme.statusFailed;
        bgClr = isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2);
        icon = Icons.error_rounded;
        break;
      case AlertSeverity.missedDose:
      case AlertSeverity.warning:
        borderClr = AppTheme.statusWarning;
        bgClr = isDark ? const Color(0xFF292212) : const Color(0xFFFFFBEB);
        icon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.info:
        borderClr = AppTheme.primaryTeal;
        bgClr = isDark ? const Color(0xFF0F2426) : const Color(0xFFF0FDFA);
        icon = Icons.info_outline_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: alert.isAcknowledged ? (isDark ? const Color(0xFF1E293B) : Colors.white) : bgClr,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: alert.isAcknowledged
              ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
              : borderClr.withOpacity(0.7),
          width: alert.isAcknowledged ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: borderClr, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (alert.actionNeeded != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: borderClr.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_late_rounded, size: 16, color: borderClr),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Required Action: ${alert.actionNeeded}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: borderClr,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (alert.relatedMedication != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      alert.relatedMedication!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (!alert.isAcknowledged)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(48, 36),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text(
                      'Mark Resolved',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => caregiver.acknowledgeAlert(alert.id),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.done_all_rounded, size: 14, color: AppTheme.statusDispensed),
                      const SizedBox(width: 4),
                      Text(
                        'Resolved',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: TRUTHFUL AUDIT LOG & DOSE TIMELINE
  // ==========================================
  Widget _buildTimelineTab(BuildContext context, List<DoseEvent> doses, bool isDark) {
    if (doses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'No dose events recorded',
        subtitle: 'Dose history will appear here as soon as scheduled times arrive or robot commands fire.',
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doses.length,
      itemBuilder: (context, index) {
        final dose = doses[index];
        final schedStr = DateFormat('hh:mm a • MMM d').format(dose.scheduledTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      schedStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    DoseStatusBadge(status: dose.status, compact: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dose.medicationName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  '${dose.dosage} • Compartment Slot ${dose.compartmentSlot}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 6),

                // Chronological Truthful Event Audit Trail
                _buildAuditMilestone(
                  title: '1. Scheduled Dispense',
                  timestamp: DateFormat('hh:mm:ss a').format(dose.scheduledTime),
                  isComplete: true,
                  isDark: isDark,
                ),
                _buildAuditMilestone(
                  title: '2. BLE Command Sent to ESP32',
                  timestamp: dose.commandSentTime != null
                      ? DateFormat('hh:mm:ss a').format(dose.commandSentTime!)
                      : 'Pending',
                  isComplete: dose.commandSentTime != null,
                  isDark: isDark,
                ),
                _buildAuditMilestone(
                  title: '3. Physical Optical IR Drop Confirmed',
                  timestamp: dose.dispensedTime != null
                      ? DateFormat('hh:mm:ss a').format(dose.dispensedTime!)
                      : (dose.status == DoseStatus.failed ? 'Failed (Optical IR Timeout)' : 'Awaiting physical drop'),
                  isComplete: dose.dispensedTime != null,
                  isFailed: dose.status == DoseStatus.failed,
                  isDark: isDark,
                ),
                _buildAuditMilestone(
                  title: '4. Patient Taken Confirmation',
                  timestamp: dose.acknowledgedTime != null
                      ? DateFormat('hh:mm:ss a').format(dose.acknowledgedTime!)
                      : 'Pending consumption from tray',
                  isComplete: dose.acknowledgedTime != null,
                  isDark: isDark,
                ),

                if (dose.failureReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 14, color: AppTheme.statusFailed),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Audit Note: ${dose.failureReason!}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.statusFailed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditMilestone({
    required String title,
    required String timestamp,
    required bool isComplete,
    bool isFailed = false,
    required bool isDark,
  }) {
    Color dotColor = isFailed
        ? AppTheme.statusFailed
        : (isComplete ? AppTheme.statusDispensed : const Color(0xFF94A3B8));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isComplete ? FontWeight.w700 : FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isFailed ? AppTheme.statusFailed : (isComplete ? dotColor : const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: HEALTH VITALS & PROVENANCE
  // ==========================================
  Widget _buildVitalsTab(BuildContext context, CaregiverProvider caregiver, bool isDark) {
    final vitals = caregiver.vitals;

    if (vitals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.monitor_heart_outlined,
        title: 'No vitals data recorded',
        subtitle: 'Paired medical BLE GATT peripheral readings will appear here.',
        isDark: isDark,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Provenance Transparency Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF241C12) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD97706).withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clinical Provenance Notice',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All entries below are marked [Simulated Demo Profiles] pending physical validation with Omron/Masimo medical Bluetooth peripherals.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : const Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        for (final vital in vitals)
          VitalCard(vital: vital),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PATIENT PROFILE & CARE TEAM MODAL
  // ==========================================
  void _showPatientProfileModal(BuildContext context, CaregiverProvider caregiver, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.tealLight,
                  child: Text(
                    'RS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryTealDark,
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
                          const Text(
                            'Ramesh Sharma',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade700, width: 0.8),
                            ),
                            child: Text(
                              'Demo Profile',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Patient ID: CARE-IND-4820 (Demonstration Profile)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Clinical Profile Summary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _buildProfileRow('Age & Gender', '74 Years • Male', isDark),
            _buildProfileRow('Primary Diagnoses', 'Essential Hypertension, Type 2 Diabetes', isDark),
            _buildProfileRow('Allergies', 'Penicillin (Mild Rash) - NKDA otherwise', isDark),
            _buildProfileRow('Dispenser Unit', 'CAREMATE Six-Slot BLE Station (ID: ESP32-CAREMATE)', isDark),
            const SizedBox(height: 20),
            const Text(
              'Emergency Care Team',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final contact in caregiver.emergencyContacts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          Text(
                            contact.relationship,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        contact.phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
