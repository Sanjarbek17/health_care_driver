import 'package:flutter/material.dart';

class UserLocationProvider with ChangeNotifier {
  double _latitude = 39.6548;
  double _longitude = 66.9597;

  bool _isLocationEnabled = false;

  double get latitude => _latitude;
  double get longitude => _longitude;

  bool get isLocationEnabled => _isLocationEnabled;

  void setLocationEnabled(bool enabled) {
    _isLocationEnabled = enabled;
    notifyListeners();
  }

  void setLatitude(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }
}
