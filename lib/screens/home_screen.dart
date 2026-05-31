import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../theme/app_theme.dart';
import '../widgets/sos_button.dart';
import 'asset_hub_panel.dart';
import 'emergency_report_screen.dart';
import 'facilities_screen.dart';
import 'settings_screen.dart';
import 'emergency_assistant_screen.dart';
import 'roadside_assistance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // State for POI Filtering
  final Map<String, bool> _activeFilters = {
    'Hospital': true,
    'Police': true,
    'Mechanic': true,
    'Pharmacy': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardStack(
            activeFilters: _activeFilters,
            onFilterChanged: (filter, isSelected) {
              setState(() {
                _activeFilters[filter] = isSelected;
              });
            },
          ),
          const EmergencyAssistantScreen(),
          const EmergencyReportScreen(),
          const FacilitiesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppTheme.charcoalNight,
        selectedItemColor: AppTheme.tacticalRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assistant), label: 'AI Assistant'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Facilities'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class MarkerData {
  final LatLng point;
  final String type;
  final String name;

  MarkerData(this.point, this.type, this.name);
}

class DashboardStack extends StatefulWidget {
  final Map<String, bool> activeFilters;
  final Function(String, bool) onFilterChanged;
  const DashboardStack({super.key, required this.activeFilters, required this.onFilterChanged});

  @override
  State<DashboardStack> createState() => _DashboardStackState();
}

class _DashboardStackState extends State<DashboardStack> {
  String _locationText = "Fetching location...";
  String _networkStatus = "Checking...";
  LatLng _currentLocation = const LatLng(12.9716, 77.5946);
  final MapController _mapController = MapController();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  StreamSubscription<Position>? _positionSubscription;

  // Mock POI Data (In production this would come from the offline DB)
  final List<MarkerData> _allPOIs = [
    MarkerData(LatLng(12.9750, 77.5960), 'Hospital', 'St. Johns Hospital'),
    MarkerData(LatLng(12.9700, 77.5900), 'Police', 'City Police Station'),
    MarkerData(LatLng(12.9800, 77.5850), 'Mechanic', 'Expert Garage'),
    MarkerData(LatLng(12.9650, 77.6000), 'Pharmacy', 'Apollo Pharmacy'),
    MarkerData(LatLng(12.9780, 77.5990), 'Hospital', 'Narayana Health'),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initLocationTracking();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) _updateConnectionStatus(results.first);
    });
  }

  void _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _locationText = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
          _mapController.move(_currentLocation, 15.0);
        });
      });
    }
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isNotEmpty) _updateConnectionStatus(results.first);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _networkStatus = (result == ConnectivityResult.none) ? "OFFLINE" : "ONLINE";
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    
    // User Marker
    markers.add(
      Marker(
        point: _currentLocation,
        width: 60,
        height: 60,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
      ),
    );

    // Filtered POI Markers
    for (var poi in _allPOIs) {
      if (widget.activeFilters[poi.type] == true) {
        markers.add(
          Marker(
            point: poi.point,
            child: Icon(_getIconForType(poi.type), color: _getColorForType(poi.type), size: 30),
          ),
        );
      }
    }
    return markers;
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Hospital': return Icons.local_hospital;
      case 'Police': return Icons.security;
      case 'Mechanic': return Icons.build;
      case 'Pharmacy': return Icons.local_pharmacy;
      default: return Icons.location_on;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Hospital': return Colors.red;
      case 'Police': return Colors.blue;
      case 'Mechanic': return Colors.orange;
      case 'Pharmacy': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.charcoalNight,
      child: SafeArea(
        child: Column(
          children: [
            // Header with Status
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CURRENT LOCATION", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.tacticalRed, size: 14),
                          const SizedBox(width: 4),
                          Text(_locationText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _networkStatus == "ONLINE" ? Colors.green.withOpacity(0.2) : AppTheme.amberWarning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _networkStatus == "ONLINE" ? Colors.green : AppTheme.amberWarning),
                    ),
                    child: Text(
                      _networkStatus,
                      style: TextStyle(
                        color: _networkStatus == "ONLINE" ? Colors.green : AppTheme.amberWarning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.road_safety_sos',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                  // Filter Chips Overlay
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: widget.activeFilters.keys.map((filter) {
                          final isSelected = widget.activeFilters[filter]!;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter, style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              onSelected: (val) {
                                 widget.onFilterChanged(filter, val);
                               },
                              selectedColor: AppTheme.tacticalRed.withOpacity(0.7),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                              backgroundColor: Colors.black.withOpacity(0.7),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dashboard Actions...

            // Dashboard Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.charcoalNight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Column(
                children: [
                  const SOSButton(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(Icons.local_hospital, "Hospitals", () {}),
                      _buildQuickAction(Icons.security, "Police", () {}),
                      _buildQuickAction(Icons.build, "Mechanics", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoadsideAssistanceScreen()),
                        );
                      }),
                      _buildQuickAction(Icons.history, "History", () {}),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.grey),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: AppTheme.tacticalRed, child: Icon(Icons.person, color: Colors.white)),
                    title: Text("Emergency Contact: Mom", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("+91 98765 43210", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Icon(Icons.call, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

class MapStack extends StatelessWidget {
  const MapStack({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(12.9716, 77.5946),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.road_safety_sos',
        ),
        const MarkerLayer(
          markers: [
            Marker(
              point: LatLng(12.9716, 77.5946),
              child: Icon(Icons.location_on, color: AppTheme.tacticalRed, size: 40),
            ),
          ],
        ),
      ],
    );
  }
}
