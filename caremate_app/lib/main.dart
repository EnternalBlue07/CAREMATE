import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/ble_robot_service.dart';
import 'services/ai_companion_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/robot_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/caregiver_provider.dart';
import 'providers/ai_chat_provider.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/medication_schedule_screen.dart';
import 'screens/robot_control_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/patient_companion_screen.dart';
import 'screens/medical_reference_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline persistence
  final storageService = await StorageService.init();
  final bleRobotService = BleRobotService();
  final aiCompanionService = AiCompanionService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => RobotProvider(bleRobotService)),
        ChangeNotifierProvider(
          create: (_) => MedicationProvider(storageService, bleRobotService),
        ),
        ChangeNotifierProvider(create: (_) => CaregiverProvider(storageService)),
        ChangeNotifierProvider(create: (_) => AiChatProvider(aiCompanionService)),
      ],
      child: const CaremateApp(),
    ),
  );
}

class CaremateApp extends StatelessWidget {
  const CaremateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    ThemeData activeTheme;
    if (appState.isHighContrast) {
      activeTheme = AppTheme.highContrastTheme;
    } else {
      activeTheme = AppTheme.lightTheme;
    }

    return MaterialApp(
      title: 'CAREMATE Healthcare Companion',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: appState.isHighContrast ? AppTheme.highContrastTheme : AppTheme.darkTheme,
      themeMode: appState.themeMode,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final caregiver = context.watch<CaregiverProvider>();

    // If patient mode is selected, render the high-accessibility PatientCompanionScreen directly
    if (appState.currentRole == UserRole.patient) {
      return Scaffold(
        body: const PatientCompanionScreen(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: AppTheme.primaryTeal,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: 'Patient Mode',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.switch_account_rounded),
              label: 'Switch to Caregiver',
            ),
          ],
          onTap: (index) {
            if (index == 1) {
              appState.switchRole(UserRole.caregiver);
            }
          },
        ),
      );
    }

    final screens = [
      HomeDashboardScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const MedicationScheduleScreen(),
      const RobotControlScreen(),
      const CaregiverDashboardScreen(),
      const MedicalReferenceScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppTheme.tealLight,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryTealDark),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.primaryTealDark),
            label: 'Schedule',
          ),
          const NavigationDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            selectedIcon: Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryTealDark),
            label: 'Robot',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: caregiver.unacknowledgedAlertsCount > 0,
              label: Text('${caregiver.unacknowledgedAlertsCount}'),
              child: const Icon(Icons.admin_panel_settings_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: caregiver.unacknowledgedAlertsCount > 0,
              label: Text('${caregiver.unacknowledgedAlertsCount}'),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryTealDark),
            ),
            label: 'Caregiver',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital_rounded, color: AppTheme.primaryTealDark),
            label: 'Med Ref',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.primaryTealDark),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
