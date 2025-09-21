import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocationProvider with ChangeNotifier {
  double _latitude = 39.6548;
  double _longitude = 66.9597;
  double _accuracy = 0.0;

  bool _isLocationEnabled = false;
  bool _isLocationTracking = false;

  // Location stream subscription
  late StreamSubscription<Position>? _locationSubscription;

  double get latitude => _latitude;
  double get longitude => _longitude;
  double get accuracy => _accuracy;
  LatLng get currentLatLng => LatLng(_latitude, _longitude);

  bool get isLocationEnabled => _isLocationEnabled;
  bool get isLocationTracking => _isLocationTracking;

  void setLocationEnabled(bool enabled) {
    _isLocationEnabled = enabled;
    notifyListeners();
  }

  void setLocation(double latitude, double longitude, {double accuracy = 0.0}) {
    _latitude = latitude;
    _longitude = longitude;
    _accuracy = accuracy;
    notifyListeners();
  }

  void updateFromPosition(Position position) {
    _latitude = position.latitude;
    _longitude = position.longitude;
    _accuracy = position.accuracy;
    _isLocationEnabled = true;
    notifyListeners();
  }

  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async {
    if (_isLocationTracking) return;

    try {
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      ).listen((Position position) {
        updateFromPosition(position);
      });

      _isLocationTracking = true;
      notifyListeners();
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isLocationTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
