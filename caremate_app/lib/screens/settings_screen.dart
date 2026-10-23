import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/robot_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/ble_protocol_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final robotProvider = context.watch<RobotProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: User Profile & Role
          _buildSectionHeader('Ecosystem Persona & Role'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                RadioListTile<UserRole>(
                  title: const Text('Caregiver / Clinician Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Full schedule editing, audit timelines, robot fault injection, and alert resolution.'),
                  value: UserRole.caregiver,
                  groupValue: appState.currentRole,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (role) {
                    if (role != null) appState.switchRole(role);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<UserRole>(
                  title: const Text('Patient / Senior Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Simplified interface with large high-visibility buttons and companion voice/chat.'),
                  value: UserRole.patient,
                  groupValue: appState.currentRole,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (role) {
                    if (role != null) appState.switchRole(role);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Accessibility & Display
          _buildSectionHeader('Accessibility & Display'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('High-Contrast Accessible Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enhances border sharpness and font weight for low-vision users.'),
                  value: appState.isHighContrast,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (val) => appState.toggleHighContrast(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('OLED dark theme for night-time comfort.'),
                  value: isDark,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (val) {
                    appState.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Hardware Communication Profile
          _buildSectionHeader('Robot Hardware (ESP32 DevKit V1)'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GATT Service UUID:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        '${BleProtocolConstants.serviceUuid.substring(0, 18)}...',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Peripheral Device ID:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        robotProvider.state.deviceName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryTeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Firmware Protocol:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        robotProvider.state.firmwareVersion,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Hardware Safety Policy:\n• Dispense commands require optical IR drop sensor confirmation.\n• Unconfirmed cycles are never marked as completed.\n• Double-dose requests are blocked for 45 minutes.',
                    style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryTeal),
      ),
    );
  }
}
