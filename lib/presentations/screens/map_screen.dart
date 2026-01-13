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

  // Called when the map is fully loaded
  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
    // Center map on user's location
    _centerMapOnUser();
  }

  // Get user's location and move the map to it
  Future<void> _centerMapOnUser() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      // Fallback to Port Moresby center if location fails
      mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(AppConstants.initialLatitude, AppConstants.initialLongitude),
        ),
      );
    }
  }

  // Submit a new PMV report
  Future<void> _submitReport() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      final newReport = PmvReport(
        latitude: position.latitude,
        longitude: position.longitude,
        routeName: _selectedRoute,
        status: _selectedStatus,
      );

      await _dbClient.insertReport(newReport);

      // Show a confirmation message (Snackbar)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PMV reported successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PMV Tracker - Wei Bai?'),
      ),
      body: Stack(
        children: [
          // The Map
          MaplibreMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(
                  AppConstants.initialLatitude, AppConstants.initialLongitude),
              zoom: AppConstants.initialZoom,
            ),
            styleString: AppConstants.mapStyleUrl,
          ),
          // Reporting Controls (positioned at the bottom)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Route Selection Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedRoute,
                      items: AppConstants.commonRoutes
                          .map((route) => DropdownMenuItem(
                                value: route,
                                child: Text(route),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoute = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Route',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status Selection Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusChip('waiting', '🚐 Waiting'),
                        _buildStatusChip('onboard', '✅ Got On'),
                        _buildStatusChip('full', '🟥 Full'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.location_on),
                        label: const Text('Report PMV Here'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Button to re-center map on user
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMapOnUser,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  // Helper to build a status selection chip/button
  Widget _buildStatusChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedStatus == value,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }
}
