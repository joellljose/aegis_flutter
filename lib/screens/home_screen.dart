import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/system_state.dart';
import '../providers/aegis_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/aegis_theme.dart';
import 'tabs/safety_hub_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/contacts_tab.dart';
import 'tabs/medical_id_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<AegisProvider>().syncWithUserProfile(auth.currentUser!);
      }
    });
  }

  final List<Widget> _tabs = const [
    SafetyHubTab(),
    MapTab(),
    ContactsTab(),
    MedicalIdTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield Logo
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AegisColors.primaryBlueLight,
                shape: BoxShape.circle,
                border: Border.all(color: AegisColors.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.shield, color: AegisColors.primaryBlue, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AEGIS One',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AegisColors.textPrimary, height: 1.1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AegisColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'COMPANION',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AegisColors.primaryBlue, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Dynamic System Status Pill
          _buildStatusPill(provider.state),
          const SizedBox(width: 8),

          // BLE Hardware status button
          IconButton(
            onPressed: () {
              if (!provider.telemetry.isPaired) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AegisColors.primaryBlue,
                    content: Text('No AEGIS One wearable paired. Use "Pair AEGIS One Wearable" on the dashboard to connect.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                provider.toggleBleConnection();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: provider.telemetry.bleConnected ? AegisColors.primaryBlue : AegisColors.warningAmber,
                    content: Text(provider.telemetry.bleConnected
                        ? 'Hardware BLE 5.0 Link Active: ${provider.telemetry.bleDeviceName}'
                        : 'Hardware BLE 5.0 Disconnected.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: Icon(
              provider.telemetry.bleConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: provider.telemetry.bleConnected ? AegisColors.primaryBlue : AegisColors.textMuted,
              size: 22,
            ),
            tooltip: provider.telemetry.isPaired
                ? (provider.telemetry.bleConnected ? 'BLE Connected (Tap to Disconnect)' : 'BLE Disconnected (Tap to Reconnect)')
                : 'No Device Paired',
          ),

          // User Profile & Sign Out Menu
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser;
              return PopupMenuButton<String>(
                tooltip: 'Account & Profile',
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: AegisColors.primaryBlueLight,
                  child: Text(
                    user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AegisColors.primaryBlue),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await auth.logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'AEGIS User',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AegisColors.textPrimary),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(fontSize: 12, color: AegisColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AegisColors.primaryBlueLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user?.role.toUpperCase() ?? 'USER',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AegisColors.primaryBlue),
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: AegisColors.dangerRed),
                        SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(color: AegisColors.dangerRed)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AegisColors.cardBorder, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AegisColors.primaryBlue,
          unselectedItemColor: AegisColors.textMuted,
          backgroundColor: Colors.white,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'Companion'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Live GPS'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), activeIcon: Icon(Icons.people_alt), label: 'Network'),
            BottomNavigationBarItem(icon: Icon(Icons.health_and_safety_outlined), activeIcon: Icon(Icons.health_and_safety), label: 'Medical ID'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(SystemState state) {
    Color color;
    Color bg;
    String text;
    switch (state) {
      case SystemState.allSafe:
        color = AegisColors.medicalGreen;
        bg = AegisColors.medicalGreenLight;
        text = 'ALL SAFE';
        break;
      case SystemState.mistouchWindow:
        color = AegisColors.warningAmber;
        bg = AegisColors.warningAmberLight;
        text = 'COUNTDOWN';
        break;
      case SystemState.activeDispatch:
        color = AegisColors.policeRed;
        bg = AegisColors.policeRedLight;
        text = 'DISPATCH LIVE';
        break;
      case SystemState.resolved:
        color = AegisColors.primaryBlue;
        bg = AegisColors.primaryBlueLight;
        text = 'RESOLVED';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
