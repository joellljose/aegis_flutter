import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/system_state.dart';
import '../../providers/aegis_provider.dart';
import '../../theme/aegis_theme.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();
    final lat = provider.currentLat ?? 12.9716;
    final lng = provider.currentLng ?? 77.5946;
    final userPos = LatLng(lat, lng);
    final isAlertActive = provider.state == SystemState.activeDispatch || provider.state == SystemState.mistouchWindow;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live GPS Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AegisColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AegisColors.medicalGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GPS Engine: ${provider.locationStatusText}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AegisColors.textPrimary),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await provider.refreshLocation();
                    _mapController.move(LatLng(provider.currentLat ?? lat, provider.currentLng ?? lng), 15);
                  },
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Locate Me', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: AegisColors.primaryBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Map Container
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isAlertActive ? AegisColors.policeRed : AegisColors.cardBorder,
                width: isAlertActive ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userPos,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.knightmaster.aegis',
                  ),
                  CircleLayer(
                    circles: [
                      // Accuracy radius circle
                      CircleMarker(
                        point: userPos,
                        radius: (provider.currentAccuracy ?? 25.0).clamp(15.0, 80.0),
                        useRadiusInMeter: false,
                        color: (isAlertActive ? AegisColors.policeRed : AegisColors.primaryBlue).withValues(alpha: 0.15),
                        borderColor: isAlertActive ? AegisColors.policeRed : AegisColors.primaryBlue,
                        borderStrokeWidth: 1.5,
                      ),
                      // Safe Zones Circles
                      ...provider.safeZones.map(
                        (zone) => CircleMarker(
                          point: LatLng(zone['lat'] as double, zone['lng'] as double),
                          radius: 40.0,
                          useRadiusInMeter: false,
                          color: AegisColors.medicalGreen.withValues(alpha: 0.15),
                          borderColor: AegisColors.medicalGreen,
                          borderStrokeWidth: 1.5,
                        ),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // User GPS Beacon Marker
                      Marker(
                        point: userPos,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAlertActive ? AegisColors.policeRed : AegisColors.primaryBlue,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: (isAlertActive ? AegisColors.policeRed : AegisColors.primaryBlue).withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isAlertActive ? Icons.crisis_alert : Icons.person_pin,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Telemetry Stats Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('LATITUDE', lat.toStringAsFixed(5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile('LONGITUDE', lng.toStringAsFixed(5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile('ACCURACY', '±${provider.currentAccuracy?.round() ?? 5}m'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile('SPEED', '${provider.currentSpeed.toStringAsFixed(1)} km/h'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reverse Geocoded Address Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AegisColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AegisColors.policeRed, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'AUTHORITATIVE STREET ADDRESS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AegisColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  provider.currentAddress,
                  style: const TextStyle(fontSize: 13, color: AegisColors.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: const Text('Open in Google Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(foregroundColor: AegisColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Safe Zones (Geofences) Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE SAFE ZONES (GEOFENCES)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AegisColors.textSecondary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddSafeZoneDialog(context, provider),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Safe Zone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: AegisColors.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.safeZones.map(
            (z) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AegisColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AegisColors.medicalGreenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, color: AegisColors.medicalGreen, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          z['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AegisColors.textPrimary),
                        ),
                        Text(
                          '${z['radius']}m radius protection',
                          style: const TextStyle(fontSize: 11, color: AegisColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => provider.removeSafeZone(z['id'] as String),
                    icon: const Icon(Icons.delete_outline, color: AegisColors.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AegisColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AegisColors.textMuted)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AegisColors.textPrimary)),
        ],
      ),
    );
  }

  void _showAddSafeZoneDialog(BuildContext context, AegisProvider provider) {
    final nameCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '300');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Safe Zone Geofence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Zone Name (e.g. Office, Gym)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: radiusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Radius in meters (e.g. 300)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final radius = int.tryParse(radiusCtrl.text.trim()) ?? 300;
              if (name.isNotEmpty) {
                provider.addSafeZone(name, provider.currentLat ?? 12.9716, provider.currentLng ?? 77.5946, radius);
                Navigator.pop(context);
              }
            },
            child: const Text('Add Zone'),
          ),
        ],
      ),
    );
  }
}
