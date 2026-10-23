import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/robot_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/caregiver_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/robot_state.dart';
import '../core/theme/app_theme.dart';
import '../widgets/carousel_visualizer.dart';
import '../widgets/emergency_call_sheet.dart';
import '../core/constants/ble_protocol_constants.dart';

class RobotControlScreen extends StatefulWidget {
  const RobotControlScreen({super.key});

  @override
  State<RobotControlScreen> createState() => _RobotControlScreenState();
}

class _RobotControlScreenState extends State<RobotControlScreen> {
  final ScrollController _terminalScrollController = ScrollController();
  bool _showDiagnostics = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(
          _terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final robotProvider = context.watch<RobotProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final caregiverProvider = context.watch<CaregiverProvider>();
    final appState = context.watch<AppStateProvider>();
    final state = robotProvider.state;
    final isConnected = state.connectionStatus == RobotConnectionStatus.connected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bpReading = caregiverProvider.latestBloodPressure;
    final hrReading = caregiverProvider.latestHeartRate;
    final spo2Reading = caregiverProvider.latestSpO2;

    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Return to Home',
          onPressed: () {
            // If in caregiver mode, pop or switch role
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              appState.switchRole(UserRole.caregiver);
            }
          },
        ),
        title: const Text(
          'Robot Status',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          // Connection Status Pill matching mockup
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(
              label: isConnected ? 'Robot Connected via Bluetooth' : 'Robot Disconnected',
              button: true,
              child: InkWell(
                onTap: () {
                  if (isConnected) {
                    robotProvider.disconnect();
                  } else {
                    robotProvider.connect(simulate: true);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFFD1FAE5)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isConnected
                          ? AppTheme.statusDispensed.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? AppTheme.statusDispensed : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isConnected ? 'Connected' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isConnected ? const Color(0xFF047857) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // More Options Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Hardware Options',
            onSelected: (val) {
              if (val == 'calibrate') {
                robotProvider.calibrate();
              } else if (val == 'toggle_jam') {
                robotProvider.toggleSimulatedJam();
              } else if (val == 'estop') {
                robotProvider.emergencyStop();
              } else if (val == 'toggle_diagnostics') {
                setState(() {
                  _showDiagnostics = !_showDiagnostics;
                });
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'calibrate',
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryTeal),
                    SizedBox(width: 8),
                    Text('Calibrate Carousel Servo (Slot 1)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_diagnostics',
                child: Row(
                  children: [
                    Icon(
                      _showDiagnostics ? Icons.visibility_off_rounded : Icons.terminal_rounded,
                      size: 18,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(_showDiagnostics ? 'Hide Diagnostics Panel' : 'Show BLE Protocol Console'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_jam',
                child: Row(
                  children: [
                    Icon(
                      state.isJamDetected ? Icons.check_circle_rounded : Icons.warning_rounded,
                      size: 18,
                      color: state.isJamDetected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(state.isJamDetected ? 'Clear Simulated Jam' : 'Simulate Mechanical Jam'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'estop',
                child: Row(
                  children: [
                    Icon(Icons.pan_tool_rounded, size: 18, color: AppTheme.statusFailed),
                    SizedBox(width: 8),
                    Text('Emergency Stop'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Carousel Hardware Visualizer Card matching reference mockup
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF152238) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: CarouselVisualizer(
              activeSlot: state.activeSlot,
              isGateOpen: state.isGateOpen,
              isJamDetected: state.isJamDetected,
              isDispensing: state.isDispensing,
              medications: medProvider.medications,
              onSlotTap: (slot) {
                if (isConnected && !state.isDispensing) {
                  robotProvider.sendCustomCommand(BleProtocolConstants.cmdDispenseSlot(slot));
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. Direct Hardware Action Buttons Row: Rotate Left + Dispense Slot 1
          _buildHardwareActionRow(context, robotProvider, medProvider, state, isConnected, isDark),
          const SizedBox(height: 24),

          // 3. Live Health Vitals Section with Simulated Provenance
          _buildLiveHealthVitalsSection(bpReading, hrReading, spo2Reading, isDark),
          const SizedBox(height: 20),

          // 4. Emergency Assist Banner
          _buildEmergencyAssistCard(context, isDark),
          const SizedBox(height: 20),

          // 5. Expandable Hardware Diagnostics & Raw BLE Console
          _buildDiagnosticsExpansionTile(context, robotProvider, state, isConnected, isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- 2. Action Row: Rotate Left + Dispense Slot N ---
  Widget _buildHardwareActionRow(
    BuildContext context,
    RobotProvider robotProvider,
    MedicationProvider medProvider,
    RobotState state,
    bool isConnected,
    bool isDark,
  ) {
    return Row(
      children: [
        // Button 1: Rotate Left (or Align Next Slot)
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6FDF5),
                foregroundColor: AppTheme.primaryTeal,
                elevation: 0,
                side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.35), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isConnected && !state.isDispensing
                  ? () {
                      // Rotate to previous slot (1 to 6 cyclic)
                      final prevSlot = state.activeSlot == 1 ? 6 : state.activeSlot - 1;
                      robotProvider.sendCustomCommand(BleProtocolConstants.cmdDispenseSlot(prevSlot));
                    }
                  : null,
              icon: const Icon(Icons.rotate_left_rounded, size: 20),
              label: const Text(
                'Rotate Left',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Button 2: Dispense Slot N (Prominent Solid Teal)
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isConnected && !state.isDispensing && !state.isJamDetected
                  ? () async {
                      final currentMed = medProvider.medications
                          .where((m) => m.compartmentSlot == state.activeSlot)
                          .firstOrNull;

                      if (currentMed != null) {
                        final ok = await medProvider.dispenseMedication(currentMed);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(medProvider.lastDispenseMessage ?? 'Dispense completed.'),
                              backgroundColor: ok ? AppTheme.statusDispensed : AppTheme.statusFailed,
                            ),
                          );
                        }
                      } else {
                        // Direct hardware test trigger
                        robotProvider.sendCustomCommand(BleProtocolConstants.cmdDispenseSlot(state.activeSlot));
                      }
                    }
                  : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                'Dispense Slot ${state.activeSlot}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. Live Health Vitals Section ---
  Widget _buildLiveHealthVitalsSection(dynamic bp, dynamic hr, dynamic spo2, bool isDark) {
    // Values extracted safely or fallback to clinical defaults
    final bpText = bp != null ? '${bp.primaryValue.toInt()}/${bp.secondaryValue?.toInt()}' : '120/80';
    final hrText = hr != null ? '${hr.primaryValue.toInt()}' : '72';
    final spo2Text = spo2 != null ? '${spo2.primaryValue.toInt()}' : '98';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row with Amber Simulated Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Live Health Vitals',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors_rounded, size: 12, color: Color(0xFFB45309)),
                  SizedBox(width: 4),
                  Text(
                    'Simulated Data',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3 Cards in a row: Blood Pressure, Heart Rate, SpO2
        Row(
          children: [
            // Card 1: Blood Pressure
            Expanded(
              child: _buildVitalMetricCard(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Blood Pressure',
                value: bpText,
                unit: 'mmHg',
                provenance: 'Simulated • Omron',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),

            // Card 2: Heart Rate
            Expanded(
              child: _buildVitalMetricCard(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Heart Rate',
                value: hrText,
                unit: 'bpm',
                provenance: 'Simulated • Masimo',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),

            // Card 3: SpO2
            Expanded(
              child: _buildVitalMetricCard(
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'SpO₂',
                value: spo2Text,
                unit: '%',
                provenance: 'Simulated • Masimo',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required String provenance,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152238) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Big Metric Number
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          // Amber Provenance Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              provenance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Emergency Assist Banner ---
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
              minimumSize: const Size(42, 42),
            ),
            icon: const Icon(Icons.call_rounded, size: 20),
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

  // --- 5. Diagnostics Expansion Tile ---
  Widget _buildDiagnosticsExpansionTile(
    BuildContext context,
    RobotProvider robotProvider,
    RobotState state,
    bool isConnected,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152238) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _showDiagnostics,
          leading: const Icon(Icons.memory_rounded, color: AppTheme.primaryTeal),
          title: const Text(
            'Hardware Diagnostics & Protocol Console',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          subtitle: Text(
            'Servo angles • IR optical drop sensor • BLE UART',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16),

                  // Diagnostics Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDiagItem(
                        icon: Icons.explore_rounded,
                        label: 'Servo Angle',
                        value: '${(state.activeSlot - 1) * 60}°',
                        color: Colors.blue,
                      ),
                      _buildDiagItem(
                        icon: Icons.sensors_rounded,
                        label: 'Optical IR Drop',
                        value: state.isDispensing ? 'Monitoring' : 'Armed (LOW)',
                        color: Colors.teal,
                      ),
                      _buildDiagItem(
                        icon: Icons.battery_charging_full_rounded,
                        label: 'Battery',
                        value: '${state.batteryLevel}%',
                        color: Colors.green,
                      ),
                      _buildDiagItem(
                        icon: Icons.wifi_tethering_rounded,
                        label: 'BLE RSSI',
                        value: '${state.rssi} dBm',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Emergency Stop Mechanism Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusFailed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isConnected ? () => robotProvider.emergencyStop() : null,
                      icon: const Icon(Icons.pan_tool_rounded, size: 18),
                      label: const Text(
                        'EMERGENCY STOP MECHANISM',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fault Injection Testbed for Judges & Developers
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science_rounded, size: 16, color: Colors.amber),
                            SizedBox(width: 6),
                            Text('Simulation & Fault Injection Controls', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Test fail-safe error handling without false delivery confirmation.',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ActionChip(
                                avatar: Icon(
                                  state.isJamDetected ? Icons.check_circle_rounded : Icons.warning_rounded,
                                  size: 14,
                                  color: state.isJamDetected ? Colors.green : AppTheme.statusFailed,
                                ),
                                label: Text(
                                  state.isJamDetected ? 'Clear Jam' : 'Simulate Jam',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: isConnected ? () => robotProvider.toggleSimulatedJam() : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ActionChip(
                                avatar: const Icon(Icons.sensors_off_rounded, size: 14, color: Colors.orange),
                                label: const Text('Fail Next Drop', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  robotProvider.triggerNextDispenseFailure();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Simulated empty slot: Next drop will report ERR:NO_DROP_DETECTED.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live BLE Protocol Console
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Live BLE RX/TX Console', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => robotProvider.clearLogs(),
                        icon: const Icon(Icons.clear_all_rounded, size: 14),
                        label: const Text('Clear', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 140,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F1D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: ListView.builder(
                      controller: _terminalScrollController,
                      itemCount: robotProvider.terminalLogs.length,
                      itemBuilder: (context, index) {
                        final log = robotProvider.terminalLogs[index];
                        Color color = const Color(0xFF38BDF8);
                        if (log.contains('ERR')) color = const Color(0xFFF87171);
                        if (log.contains('CONFIRMED') || log.contains('ACK')) color = const Color(0xFF4ADE80);
                        if (log.contains('TX')) color = const Color(0xFFA78BFA);

                        return Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            color: color,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
      ],
    );
  }
}
