import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:latlong2/latlong.dart';

class EmergencyRequest {
  final String requestId;
  final String patientId;
  final LatLng patientLocation;
  final String emergencyType;
  final double distance;
  final DateTime timestamp;

  EmergencyRequest({
    required this.requestId,
    required this.patientId,
    required this.patientLocation,
    required this.emergencyType,
    required this.distance,
    required this.timestamp,
  });

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      requestId: json['request_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientLocation: LatLng(
        json['patient_location']['lat']?.toDouble() ?? 0.0,
        json['patient_location']['lng']?.toDouble() ?? 0.0,
      ),
      emergencyType: json['emergency_type'] ?? '',
      distance: json['distance']?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
  }
}

class DriverService {
  static const String baseUrl = 'http://192.168.88.234:5656';
  static const String socketUrl = 'ws://192.168.88.234:5656';

  late IO.Socket socket;
  String? driverId;
  bool isConnected = false;

  // Callbacks for different events
  Function(String driverId)? onDriverRegistered;
  Function(EmergencyRequest request)? onEmergencyAlert;
  Function(LatLng location)? onPatientLocationUpdate;
  Function(String message)? onDriverAssigned;
  Function(String message)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  DriverService() {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Connection events
    socket.on('connect', (_) {
      print('Driver WebSocket connected');
      isConnected = true;
      onConnected?.call();
    });

    socket.on('disconnect', (_) {
      print('Driver WebSocket disconnected');
      isConnected = false;
      onDisconnected?.call();
    });

    socket.on('connect_error', (error) {
      print('Driver WebSocket connection error: $error');
      onError?.call('Connection error: $error');
    });

    // Driver-specific events
    socket.on('emergency_alert', (data) {
      print('Emergency alert received: $data');
      try {
        final request = EmergencyRequest.fromJson(data);
        onEmergencyAlert?.call(request);
      } catch (e) {
        print('Error parsing emergency alert: $e');
        onError?.call('Error parsing emergency request');
      }
    });

    socket.on('patient_location_update', (data) {
      print('Patient location update: $data');
      try {
        final location = LatLng(
          data['patient_location']['lat']?.toDouble() ?? 0.0,
          data['patient_location']['lng']?.toDouble() ?? 0.0,
        );
        onPatientLocationUpdate?.call(location);
      } catch (e) {
        print('Error parsing patient location: $e');
      }
    });

    socket.on('driver_assigned', (data) {
      print('Driver assigned: $data');
      onDriverAssigned?.call('Request assigned successfully');
    });

    socket.on('request_completed', (data) {
      print('Request completed: $data');
      // Handle request completion
    });

    socket.on('error', (error) {
      print('Socket error: $error');
      onError?.call(error.toString());
    });
  }

  Future<void> connect() async {
    try {
      socket.connect();
    } catch (e) {
      print('Error connecting to socket: $e');
      onError?.call('Failed to connect to server');
    }
  }

  void disconnect() {
    socket.disconnect();
    isConnected = false;
  }

  // HTTP API calls
  Future<Map<String, dynamic>?> registerDriver(LatLng location, {String? customDriverId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/driver/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (customDriverId != null) 'driver_id': customDriverId,
          'location': {
            'lat': location.latitude,
            'lng': location.longitude,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        driverId = data['driver_id'];

        // Register with WebSocket after HTTP registration
        if (isConnected) {
          _registerWithSocket(location);
        }

        onDriverRegistered?.call(driverId!);
        return data;
      } else {
        final error = jsonDecode(response.body);
        onError?.call(error['error'] ?? 'Registration failed');
        return null;
      }
    } catch (e) {
      print('Error registering driver: $e');
      onError?.call('Network error during registration');
      return null;
    }
  }

  void _registerWithSocket(LatLng location) {
    if (driverId != null && isConnected) {
      socket.emit('register_driver', {
        'driver_id': driverId,
        'location': {
          'lat': location.latitude,
          'lng': location.longitude,
        },
      });
    }
  }

  Future<List<EmergencyRequest>?> getPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/driver/requests'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final requests = <EmergencyRequest>[];

        if (data['requests'] != null) {
          for (var requestData in data['requests']) {
            try {
              requests.add(EmergencyRequest.fromJson(requestData));
            } catch (e) {
              print('Error parsing request: $e');
            }
          }
        }

        return requests;
      } else {
        final error = jsonDecode(response.body);
        onError?.call(error['error'] ?? 'Failed to get requests');
        return null;
      }
    } catch (e) {
      print('Error getting pending requests: $e');
      onError?.call('Network error getting requests');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDriverStatus() async {
    if (driverId == null) {
      onError?.call('Driver not registered');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/driver/status/$driverId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        onError?.call(error['error'] ?? 'Failed to get status');
        return null;
      }
    } catch (e) {
      print('Error getting driver status: $e');
      onError?.call('Network error getting status');
      return null;
    }
  }

  void acceptRequest(String requestId) {
    if (driverId != null && isConnected) {
      socket.emit('accept_request', {
        'driver_id': driverId,
        'request_id': requestId,
      });
    } else {
      onError?.call('Not connected or not registered');
    }
  }

  void declineRequest(String requestId) {
    if (driverId != null && isConnected) {
      socket.emit('decline_request', {
        'driver_id': driverId,
        'request_id': requestId,
      });
    } else {
      onError?.call('Not connected or not registered');
    }
  }

  void updateLocation(LatLng location) {
    if (driverId != null && isConnected) {
      socket.emit('update_location', {
        'user_id': driverId,
        'location': {
          'lat': location.latitude,
          'lng': location.longitude,
        },
        'user_type': 'driver',
      });
    }
  }

  void completeRequest(String requestId) {
    if (driverId != null && isConnected) {
      socket.emit('complete_request', {
        'driver_id': driverId,
        'request_id': requestId,
      });
    } else {
      onError?.call('Not connected or not registered');
    }
  }

  void dispose() {
    disconnect();
  }
}
