import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/driver_service.dart';

enum DriverStatus {
  offline,
  connecting,
  available,
  responding,
  busy,
  error,
}

class DriverProvider with ChangeNotifier {
  final DriverService _driverService = DriverService();

  // Driver state
  DriverStatus _status = DriverStatus.offline;
  String? _driverId;
  LatLng? _currentLocation;
  String? _errorMessage;

  // Emergency requests
  List<EmergencyRequest> _pendingRequests = [];
  EmergencyRequest? _activeRequest;
  LatLng? _patientLocation;

  // Connection state
  bool _isConnected = false;
  bool _isRegistered = false;

  // Getters
  DriverStatus get status => _status;
  String? get driverId => _driverId;
  LatLng? get currentLocation => _currentLocation;
  String? get errorMessage => _errorMessage;
  List<EmergencyRequest> get pendingRequests => _pendingRequests;
  EmergencyRequest? get activeRequest => _activeRequest;
  LatLng? get patientLocation => _patientLocation;
  bool get isConnected => _isConnected;
  bool get isRegistered => _isRegistered;
  bool get isAvailable => _status == DriverStatus.available;
  bool get isBusy => _status == DriverStatus.busy || _status == DriverStatus.responding;

  DriverProvider() {
    _setupDriverServiceCallbacks();
  }

  void _setupDriverServiceCallbacks() {
    _driverService.onConnected = () {
      _isConnected = true;
      if (_status == DriverStatus.connecting) {
        _setStatus(DriverStatus.available);
      }
      notifyListeners();
    };

    _driverService.onDisconnected = () {
      _isConnected = false;
      if (_status != DriverStatus.offline) {
        _setStatus(DriverStatus.error);
        _errorMessage = 'Connection lost';
      }
      notifyListeners();
    };

    _driverService.onDriverRegistered = (driverId) {
      _driverId = driverId;
      _isRegistered = true;
      _setStatus(DriverStatus.available);
      _clearError();
      notifyListeners();
    };

    _driverService.onEmergencyAlert = (request) {
      _pendingRequests.add(request);
      _clearError();
      notifyListeners();
    };

    _driverService.onPatientLocationUpdate = (location) {
      _patientLocation = location;
      notifyListeners();
    };

    _driverService.onDriverAssigned = (message) {
      // When driver accepts a request, move it to active and clear pending
      if (_pendingRequests.isNotEmpty) {
        _activeRequest = _pendingRequests.first;
        _pendingRequests.clear();
        _setStatus(DriverStatus.responding);
      }
      _clearError();
      notifyListeners();
    };

    _driverService.onError = (error) {
      _errorMessage = error;
      if (_status == DriverStatus.connecting) {
        _setStatus(DriverStatus.error);
      }
      notifyListeners();
    };
  }

  void _setStatus(DriverStatus newStatus) {
    _status = newStatus;
    print('Driver status changed to: $newStatus');
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<bool> initializeDriver() async {
    try {
      _setStatus(DriverStatus.connecting);
      notifyListeners();

      await _driverService.connect();
      return true;
    } catch (e) {
      _setStatus(DriverStatus.error);
      _errorMessage = 'Failed to initialize driver service';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDriver(LatLng location, {String? customDriverId}) async {
    if (_status == DriverStatus.connecting || _status == DriverStatus.offline) {
      await initializeDriver();
    }

    try {
      _currentLocation = location;
      final result = await _driverService.registerDriver(location, customDriverId: customDriverId);

      if (result != null) {
        _driverId = result['driver_id'];
        _isRegistered = true;
        _setStatus(DriverStatus.available);
        _clearError();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setStatus(DriverStatus.error);
      _errorMessage = 'Registration failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshPendingRequests() async {
    try {
      final requests = await _driverService.getPendingRequests();
      if (requests != null) {
        _pendingRequests = requests;
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to refresh requests: $e';
      notifyListeners();
    }
  }

  Future<void> refreshDriverStatus() async {
    try {
      final status = await _driverService.getDriverStatus();
      if (status != null) {
        // Update status based on server response
        if (status['status'] == 'available') {
          _setStatus(DriverStatus.available);
        } else if (status['status'] == 'busy') {
          _setStatus(DriverStatus.busy);
        }
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to refresh status: $e';
      notifyListeners();
    }
  }

  void acceptRequest(EmergencyRequest request) {
    if (!isAvailable) {
      _errorMessage = 'Driver not available to accept requests';
      notifyListeners();
      return;
    }

    try {
      _driverService.acceptRequest(request.requestId);
      _activeRequest = request;
      _pendingRequests.remove(request);
      _setStatus(DriverStatus.responding);
      _clearError();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to accept request: $e';
      notifyListeners();
    }
  }

  void declineRequest(EmergencyRequest request) {
    try {
      _driverService.declineRequest(request.requestId);
      _pendingRequests.remove(request);
      _clearError();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to decline request: $e';
      notifyListeners();
    }
  }

  void updateLocation(LatLng location) {
    _currentLocation = location;

    if (_isConnected && _isRegistered) {
      _driverService.updateLocation(location);
    }

    notifyListeners();
  }

  void completeActiveRequest() {
    if (_activeRequest != null) {
      try {
        _driverService.completeRequest(_activeRequest!.requestId);
        _activeRequest = null;
        _patientLocation = null;
        _setStatus(DriverStatus.available);
        _clearError();
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Failed to complete request: $e';
        notifyListeners();
      }
    }
  }

  void goOffline() {
    _driverService.disconnect();
    _setStatus(DriverStatus.offline);
    _isConnected = false;
    _isRegistered = false;
    _driverId = null;
    _activeRequest = null;
    _patientLocation = null;
    _pendingRequests.clear();
    _clearError();
    notifyListeners();
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  String getStatusText() {
    switch (_status) {
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.connecting:
        return 'Connecting...';
      case DriverStatus.available:
        return 'Available';
      case DriverStatus.responding:
        return 'Responding to Emergency';
      case DriverStatus.busy:
        return 'Busy';
      case DriverStatus.error:
        return 'Error';
    }
  }

  Color getStatusColor() {
    switch (_status) {
      case DriverStatus.offline:
        return Colors.grey;
      case DriverStatus.connecting:
        return Colors.orange;
      case DriverStatus.available:
        return Colors.green;
      case DriverStatus.responding:
        return Colors.blue;
      case DriverStatus.busy:
        return Colors.red;
      case DriverStatus.error:
        return Colors.red;
    }
  }

  @override
  void dispose() {
    _driverService.dispose();
    super.dispose();
  }
}
