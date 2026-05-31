import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../theme/app_theme.dart';
import '../widgets/sos_button.dart';
import '../models/location_log.dart';
import '../services/location_tracker_service.dart';
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
  late PageController _pageController;
  
  // State for POI Filtering
  final Map<String, bool> _activeFilters = {
    'Hospital': true,
    'Police': true,
    'Mechanic': true,
    'Pharmacy': true,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Retain tab tap controls but animate page transitions
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: isDark ? AppTheme.charcoalNight : Colors.white,
          selectedItemColor: AppTheme.tacticalRed,
          unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[500],
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.assistant), label: 'AI Assistant'),
            BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: 'Report'),
            BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Facilities'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
          onTap: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
            );
          },
        ),
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
  StreamSubscription<LocationLog>? _trackerSubscription;
  final LocationTrackerService _locationTrackerService = LocationTrackerService();
  double? _mapHeight; // Dynamic resizable height of map

  // Live Telemetry Variables
  double _speedKmh = 0.0;
  double _headingDegrees = 0.0;
  double _altitudeMeters = 0.0;
  double _accuracyMeters = 0.0;

  // New Navigation States
  MarkerData? _selectedPOI;
  bool _isNavigating = false;
  List<LatLng>? _navigationPoints;
  bool _isDragging = false; // gestural tracking duration controller

  // Mock POI Data
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
    try {
      await _locationTrackerService.startTracking();
      _trackerSubscription = _locationTrackerService.locationStream.listen((LocationLog log) {
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(log.latitude, log.longitude);
          _locationText = "${log.latitude.toStringAsFixed(4)}, ${log.longitude.toStringAsFixed(4)}";
          _speedKmh = log.speed * 3.6; // Convert m/s to km/h
          _headingDegrees = log.heading;
          _altitudeMeters = log.altitude;
          _accuracyMeters = log.accuracy;
          _mapController.move(_currentLocation, 15.0);
        });
      });
    } catch (e) {
      debugPrint("Error initializing location tracker: $e");
    }
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isNotEmpty) _updateConnectionStatus(results.first);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (!mounted) return;
    setState(() {
      _networkStatus = (result == ConnectivityResult.none) ? "OFFLINE" : "ONLINE";
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _trackerSubscription?.cancel();
    _locationTrackerService.dispose();
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
        child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
      ),
    );

    // Filtered POI Markers with Tap Gesture Action
    for (var poi in _allPOIs) {
      if (widget.activeFilters[poi.type] == true) {
        markers.add(
          Marker(
            point: poi.point,
            width: 46,
            height: 46,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPOI = poi;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _getColorForType(poi.type).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _getColorForType(poi.type), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _getColorForType(poi.type).withOpacity(0.2),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Center(
                  child: Icon(_getIconForType(poi.type), color: _getColorForType(poi.type), size: 20),
                ),
              ),
            ),
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

  // Winding City Routing simulated polyline generator
  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    final latDelta = end.latitude - start.latitude;
    final lngDelta = end.longitude - start.longitude;

    return [
      start,
      LatLng(start.latitude + latDelta * 0.4, start.longitude),
      LatLng(start.latitude + latDelta * 0.4, start.longitude + lngDelta * 0.6),
      LatLng(end.latitude, start.longitude + lngDelta * 0.6),
      end,
    ];
  }

  // Live Nearest POI Calculator based on actual GPS distance formulas
  void _findAndNavigateToNearest(String type, double defaultMapHeight, double totalHeight) {
    double minDistance = double.infinity;
    MarkerData? nearestPOI;

    for (var poi in _allPOIs) {
      if (poi.type == type) {
        double dist = Geolocator.distanceBetween(
          _currentLocation.latitude,
          _currentLocation.longitude,
          poi.point.latitude,
          poi.point.longitude,
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearestPOI = poi;
        }
      }
    }

    if (nearestPOI != null) {
      setState(() {
        _selectedPOI = nearestPOI;
        // Automatically slide bottom panel fully down to maximize map view
        _mapHeight = totalHeight - 24;
      });
      _mapController.move(nearestPOI.point, 15.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No nearby $type found."),
          backgroundColor: AppTheme.tacticalRed,
        ),
      );
    }
  }

  // Search Bottom Sheet Options Selector
  void _showQuickSearchBottomSheet(double defaultMapHeight, double totalHeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quick Destination Search",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Find and navigate to the nearest critical service point.",
                style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              _buildSearchOption(Icons.local_hospital, "Nearest Medical Center", Colors.red, () {
                Navigator.pop(context);
                _findAndNavigateToNearest('Hospital', defaultMapHeight, totalHeight);
              }, isDark),
              const SizedBox(height: 12),
              _buildSearchOption(Icons.security, "Nearest Police Station", Colors.blue, () {
                Navigator.pop(context);
                _findAndNavigateToNearest('Police', defaultMapHeight, totalHeight);
              }, isDark),
              const SizedBox(height: 12),
              _buildSearchOption(Icons.build, "Nearest Mechanical Shop", Colors.orange, () {
                Navigator.pop(context);
                _findAndNavigateToNearest('Mechanic', defaultMapHeight, totalHeight);
              }, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchOption(IconData icon, String label, Color color, VoidCallback onTap, bool isDark) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header with Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CURRENT LOCATION", 
                        style: TextStyle(
                          color: isDark ? Colors.grey : Colors.grey[600], 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.tacticalRed, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _locationText, 
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87, 
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _networkStatus == "ONLINE" 
                          ? Colors.green.withOpacity(0.15) 
                          : AppTheme.amberWarning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _networkStatus == "ONLINE" ? Colors.green : AppTheme.amberWarning,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      _networkStatus,
                      style: TextStyle(
                        color: _networkStatus == "ONLINE" ? Colors.green : AppTheme.amberWarning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalHeight = constraints.maxHeight;
                  final defaultMapHeight = totalHeight * 0.52;
                  final currentMapHeight = _mapHeight ?? defaultMapHeight;

                  return Column(
                    children: [
                      // Resizable Map Area with Gestural Duration Interpolation
                      AnimatedContainer(
                        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        height: currentMapHeight,
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
                                // Glowing polyline navigation layer
                                if (_navigationPoints != null)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: _navigationPoints!,
                                        color: Colors.blueAccent,
                                        strokeWidth: 6.0,
                                      ),
                                    ],
                                  ),
                                MarkerLayer(markers: _buildMarkers()),
                              ],
                            ),
                            
                            // Filter Chips Overlay (Only show when not in active HUD navigation mode)
                            if (!_isNavigating)
                              Positioned(
                                top: 12,
                                left: 0,
                                right: 0,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: widget.activeFilters.keys.map((filter) {
                                      final isSelected = widget.activeFilters[filter]!;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: FilterChip(
                                          label: Text(
                                            filter, 
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          selected: isSelected,
                                          onSelected: (val) {
                                            widget.onFilterChanged(filter, val);
                                          },
                                          selectedColor: AppTheme.tacticalRed,
                                          checkmarkColor: Colors.white,
                                          labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700])),
                                          backgroundColor: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9),
                                          elevation: 2,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                            // Floating Car Navigation Quick-Search button (overlayed in the right corner)
                            if (!_isNavigating)
                              Positioned(
                                bottom: 36,
                                right: 16,
                                child: FloatingActionButton(
                                  onPressed: () => _showQuickSearchBottomSheet(defaultMapHeight, totalHeight),
                                  backgroundColor: AppTheme.tacticalRed,
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 6,
                                  child: const Icon(Icons.directions_car_filled, size: 28),
                                ),
                              ),

                            // Floating touch-POI Details Card
                            if (_selectedPOI != null && !_isNavigating)
                              _buildPoiDetailsCard(_selectedPOI!, isDark, totalHeight),

                            // Active Navigation Top HUD Banner
                            if (_isNavigating && _selectedPOI != null)
                              _buildNavigationHUD(_selectedPOI!, isDark),
                          ],
                        ),
                      ),

                      // Draggable Horizontal divider boundary
                      GestureDetector(
                        onVerticalDragStart: (_) {
                          setState(() {
                            _isDragging = true;
                          });
                        },
                        onVerticalDragEnd: (_) {
                          setState(() {
                            _isDragging = false;
                          });
                        },
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            double newHeight = currentMapHeight + details.primaryDelta!;
                            // Lower limit: Cannot drag upwards than the default position
                            if (newHeight < defaultMapHeight) {
                              newHeight = defaultMapHeight;
                            }
                            // Upper limit: Can collapse completely down to totalHeight - 24
                            final maxMapHeight = totalHeight - 24;
                            if (newHeight > maxMapHeight) {
                              newHeight = maxMapHeight;
                            }
                            _mapHeight = newHeight;
                          });
                        },
                        child: _buildDivider(isDark, currentMapHeight, defaultMapHeight, totalHeight),
                      ),

                      // Resizable Bottom SOS Panel
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.charcoalNight : const Color(0xFFF5F5F7),
                          ),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Live Telemetry Grid
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                        width: 1,
                                      ),
                                      boxShadow: isDark ? null : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildTelemetryMetric(Icons.speed, _speedKmh.toStringAsFixed(1), "km/h", "SPEED", isDark),
                                        _buildTelemetryMetric(Icons.explore, "${_headingDegrees.toStringAsFixed(0)}°", "DIR", "HEADING", isDark),
                                        _buildTelemetryMetric(Icons.filter_hdr, _altitudeMeters.toStringAsFixed(0), "m", "ALTITUDE", isDark),
                                        _buildTelemetryMetric(Icons.gps_fixed, "±${_accuracyMeters.toStringAsFixed(1)}", "m", "ACCURACY", isDark),
                                      ],
                                    ),
                                  ),
                                  const SOSButton(),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildQuickAction(Icons.local_hospital, "Hospitals", isDark, () {}),
                                      _buildQuickAction(Icons.security, "Police", isDark, () {}),
                                      _buildQuickAction(Icons.build, "Mechanics", isDark, () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const RoadsideAssistanceScreen()),
                                        );
                                      }),
                                      _buildQuickAction(Icons.history, "History", isDark, () {}),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.tacticalRed.withOpacity(0.1),
                                      child: const Icon(Icons.person, color: AppTheme.tacticalRed),
                                    ),
                                    title: Text(
                                      "Emergency Contact: Mom", 
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87, 
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "+91 98765 43210", 
                                      style: TextStyle(
                                        color: isDark ? Colors.grey : Colors.grey[600], 
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.call, color: Colors.green, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark, double currentMapHeight, double defaultMapHeight, double totalHeight) {
    final isFullyCollapsed = currentMapHeight >= totalHeight - 24;
    return Container(
      width: double.infinity,
      height: 24,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), width: 1),
          bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), width: 1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isFullyCollapsed) {
                  _mapHeight = defaultMapHeight;
                } else {
                  _mapHeight = totalHeight - 24;
                  _selectedPOI = null; // Dismiss details overlay on collapse
                }
              });
            },
            child: Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.tacticalRed,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.tacticalRed.withOpacity(0.35),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                isFullyCollapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              shape: BoxShape.circle,
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: isDark ? Colors.white : AppTheme.tacticalRed, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700], 
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetric(IconData icon, String value, String unit, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.tacticalRed),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey : Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPoiDetailsCard(MarkerData poi, bool isDark, double totalHeight) {
    double dist = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      poi.point.latitude,
      poi.point.longitude,
    );
    String distanceText = dist >= 1000 
        ? "${(dist / 1000).toStringAsFixed(1)} km" 
        : "${dist.toStringAsFixed(0)} m";

    return Positioned(
      bottom: 12,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    poi.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorForType(poi.type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    poi.type.toUpperCase(),
                    style: TextStyle(
                      color: _getColorForType(poi.type),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: isDark ? Colors.grey : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "$distanceText away",
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                const Text(
                  "Open 24/7",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedPOI = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      "CLOSE",
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isNavigating = true;
                        _navigationPoints = _generateRoutePoints(_currentLocation, poi.point);
                        // Hide bottom panel completely to show full street view
                        _mapHeight = totalHeight - 24;
                      });
                    },
                    icon: const Icon(Icons.navigation, size: 16, color: Colors.white),
                    label: const Text(
                      "NAVIGATE",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tacticalRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationHUD(MarkerData poi, bool isDark) {
    double dist = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      poi.point.latitude,
      poi.point.longitude,
    );
    String distanceText = dist >= 1000 
        ? "${(dist / 1000).toStringAsFixed(1)} km" 
        : "${dist.toStringAsFixed(0)} m";

    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.tacticalRed,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tacticalRed.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.navigation, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Navigating to ${poi.name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Remaining: $distanceText • 2 min",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isNavigating = false;
                  _navigationPoints = null;
                  _selectedPOI = null;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "CANCEL",
                style: TextStyle(
                  color: AppTheme.tacticalRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
