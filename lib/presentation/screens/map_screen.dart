import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pmv_tracker/core/constants.dart';
import 'package:pmv_tracker/data/models/pmv_report.dart';
import 'package:pmv_tracker/data/repository/supabase_client.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MaplibreMapController mapController;
  final SupabaseClient _dbClient = SupabaseClient();
  String _selectedRoute = AppConstants.commonRoutes.first;
  String _selectedStatus = 'waiting'; // Default status
  List<PmvReport> _reports = [];
  bool _isLoading = true;
  final Map<String, Symbol> _markers = {};

  // Called when the map is fully loaded
  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
    // Start listening to live reports and center map on user
    _setupLiveReports();
    _centerMapOnUser();
  }

  // Set up real-time stream of PMV reports from Supabase
  void _setupLiveReports() {
    _dbClient.getLiveReports().listen((List<PmvReport> reports) {
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
        _updateMapMarkers();
      }
    });
  }

  // Add/update markers on the map based on current reports
  void _updateMapMarkers() {
    // Create a set of current report IDs for easy lookup
    final currentReportIds = _reports.map((r) => r.id.toString()).toSet();
    
    // Remove markers that are no longer in the reports
    final keysToRemove = _markers.keys.where((key) => !currentReportIds.contains(key)).toList();
    for (final key in keysToRemove) {
      mapController.removeSymbol(_markers[key]!);
      _markers.remove(key);
    }
    
    // Add new markers for reports that don't have a marker yet
    for (final report in _reports) {
      final reportId = report.id.toString();
      if (!_markers.containsKey(reportId)) {
        final symbolOptions = SymbolOptions(
          geometry: LatLng(report.latitude, report.longitude),
          iconImage: _getIconForStatus(report.status),
          textField: report.routeName,
          textSize: 12.0,
          textOffset: const Offset(0, 2),
        );
        
        // Store the symbol with its ID for later removal
        mapController.addSymbol(symbolOptions).then((symbol) {
          if (mounted) {
            setState(() {
              _markers[reportId] = symbol;
            });
          }
        });
      }
    }
  }

  // Get appropriate icon based on PMV status
  String _getIconForStatus(String status) {
    switch (status) {
      case 'onboard':
        return 'marker-green';
      case 'full':
        return 'marker-red';
      case 'waiting':
      default:
        return 'marker-blue';
    }
  }

  // Get user's location and center the map (UPDATED for geolocator ^14.0.2)
  Future<void> _centerMapOnUser() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled. Please enable them in your device settings.');
        return;
      }

      // Check and request location permissions (UPDATED API for v14)
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are required to center the map on your location.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
          'Location permissions are permanently denied. Please enable them in your device settings.'
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Animate camera to user's location
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    } catch (e) {
      // Fallback to Port Moresby center
      _showLocationError('Could not get your location: ${e.toString()}');
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          const LatLng(
            AppConstants.initialLatitude,
            AppConstants.initialLongitude,
          ),
          AppConstants.initialZoom,
        ),
      );
    }
  }

  // Submit a new PMV report
  Future<void> _submitReport() async {
    try {
      // Get current position with updated geolocator API
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final newReport = PmvReport(
        latitude: position.latitude,
        longitude: position.longitude,
        routeName: _selectedRoute,
        status: _selectedStatus,
      );

      await _dbClient.insertReport(newReport);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PMV reported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Show location error message
  void _showLocationError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PMV Tracker - Wei Bai?'),
        backgroundColor: Colors.blue[800],
        elevation: 4,
      ),
      body: Stack(
        children: [
          // The Interactive Map
          MaplibreMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(
                AppConstants.initialLatitude,
                AppConstants.initialLongitude,
              ),
              zoom: AppConstants.initialZoom,
            ),
            styleString: AppConstants.mapStyleUrl,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.TrackingGPS,
          ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Reporting Controls (positioned at the bottom)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report a PMV',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Route Selection
                    const Text('Select Route:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRoute,
                      items: AppConstants.commonRoutes
                          .map((route) => DropdownMenuItem(
                                value: route,
                                child: Text(route),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRoute = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status Selection
                    const Text('Status:'),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusChip('waiting', '🚐 Waiting', Colors.blue),
                          const SizedBox(width: 8),
                          _buildStatusChip('onboard', '✅ Got On', Colors.green),
                          const SizedBox(width: 8),
                          _buildStatusChip('full', '🟥 Full', Colors.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.location_on),
                        label: const Text(
                          'REPORT PMV HERE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Active reports counter
          Positioned(
            top: 80,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_reports.length} active',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Button to re-center map on user
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMapOnUser,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  // Helper to build a status selection chip
  Widget _buildStatusChip(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: color,
      backgroundColor: Colors.grey[200],
      elevation: isSelected ? 4 : 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );
  }
}
