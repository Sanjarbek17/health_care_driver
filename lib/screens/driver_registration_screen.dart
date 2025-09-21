import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/driver_provider.dart';
import '../providers/main_provider.dart';
import '../widgets/widgets.dart';
import 'driver_dashboard_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _driverIdController = TextEditingController();
  bool _isLoading = false;
  bool _useCustomId = false;

  @override
  void dispose() {
    _driverIdController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider = Provider.of<UserLocationProvider>(context, listen: false);

    try {
      final position = await determinePosition();
      locationProvider.updateFromPosition(position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final locationProvider = Provider.of<UserLocationProvider>(context, listen: false);

    try {
      // Get current location first
      await _getCurrentLocation();

      if (!locationProvider.isLocationEnabled) {
        throw Exception('Location not available');
      }

      // Register driver
      final success = await driverProvider.registerDriver(
        locationProvider.currentLatLng,
        customDriverId: _useCustomId ? _driverIdController.text.trim() : null,
      );

      if (success && mounted) {
        // Start location tracking for the driver
        await locationProvider.startLocationTracking(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        );

        // Navigate to driver dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DriverDashboardScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(driverProvider.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.local_hospital,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ambulance Driver Registration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Custom ID option
                Row(
                  children: [
                    Switch(
                      value: _useCustomId,
                      onChanged: (value) {
                        setState(() {
                          _useCustomId = value;
                          if (!value) {
                            _driverIdController.clear();
                          }
                        });
                      },
                      activeColor: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    const Text('Use custom driver ID'),
                  ],
                ),
                const SizedBox(height: 20),

                // Custom ID input (conditional)
                if (_useCustomId) ...[
                  TextFormField(
                    controller: _driverIdController,
                    decoration: const InputDecoration(
                      labelText: 'Driver ID',
                      hintText: 'Enter your driver ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (_useCustomId && (value == null || value.trim().isEmpty)) {
                        return 'Please enter a driver ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Location status
                Consumer<UserLocationProvider>(
                  builder: (context, locationProvider, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: locationProvider.isLocationEnabled ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        border: Border.all(
                          color: locationProvider.isLocationEnabled ? Colors.green : Colors.orange,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            locationProvider.isLocationEnabled ? Icons.location_on : Icons.location_off,
                            color: locationProvider.isLocationEnabled ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              locationProvider.isLocationEnabled ? 'Location: ${locationProvider.latitude.toStringAsFixed(4)}, ${locationProvider.longitude.toStringAsFixed(4)}' : 'Location not available',
                              style: TextStyle(
                                color: locationProvider.isLocationEnabled ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Get location button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Get Current Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Register button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _registerDriver,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.app_registration),
                  label: Text(_isLoading ? 'Registering...' : 'Register as Driver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Error display
                Consumer<DriverProvider>(
                  builder: (context, driverProvider, child) {
                    if (driverProvider.errorMessage != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                driverProvider.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              onPressed: () => driverProvider.clearError(),
                              icon: const Icon(Icons.close, color: Colors.red),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
