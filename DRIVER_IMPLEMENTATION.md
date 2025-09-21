# Health Care Driver App - Driver Side Implementation

This Flutter application implements the driver side functionality for an ambulance dispatch system, based on the API documentation provided.

## Features Implemented

### ✅ Driver Registration & Authentication
- Driver registration with location permissions
- Custom driver ID support
- Real-time location tracking
- WebSocket connection establishment

### ✅ Emergency Request Management
- Real-time emergency alerts via WebSocket
- Accept/decline emergency requests
- View pending emergency requests
- Request details display (patient location, emergency type, distance)

### ✅ Real-time Communication
- WebSocket connection to backend server (`ws://localhost:8080`)
- Live location updates to server
- Patient location tracking during emergencies
- Driver status synchronization

### ✅ Map Integration
- Interactive map with OpenStreetMap tiles
- Driver location marker with navigation
- Patient location markers during active emergencies
- Route calculation and display to patient location
- Navigation mode with GPS tracking

### ✅ Driver Dashboard
- Multi-tab interface (Emergency Requests, Map)
- Real-time status display
- Pending request notifications
- Driver status management (Available, Responding, Busy, etc.)

## Project Structure

```
lib/
├── main.dart                           # App entry point with provider setup
├── providers/
│   ├── main_provider.dart             # Location tracking provider
│   └── driver_provider.dart           # Driver state management
├── services/
│   └── driver_service.dart            # WebSocket & API communication
├── screens/
│   ├── driver_registration_screen.dart # Driver registration UI
│   ├── driver_dashboard_screen.dart   # Main driver interface
│   ├── emergency_requests_screen.dart # Emergency request management
│   └── map_screen.dart               # Enhanced map with driver features
└── widgets/
    ├── widgets.dart                   # Location utilities
    └── functions.dart                 # FCM notifications
```

## API Endpoints Used

### Driver Registration
```
POST /api/driver/register
```
- Registers driver with location
- Returns driver ID for further communication

### Get Pending Requests
```
GET /api/driver/requests
```
- Retrieves list of pending emergency requests

### Driver Status
```
GET /api/driver/status/{driver_id}
```
- Gets current driver status from server

## WebSocket Events

### Client to Server
- `register_driver`: Register driver with location
- `accept_request`: Accept emergency request
- `decline_request`: Decline emergency request
- `update_location`: Send location updates
- `complete_request`: Mark request as completed

### Server to Client
- `emergency_alert`: New emergency request notification
- `patient_location_update`: Patient location updates
- `driver_assigned`: Confirmation of request acceptance

## Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Backend URL**
   Update the base URL in `lib/services/driver_service.dart`:
   ```dart
   static const String baseUrl = 'http://your-server-url:8080';
   ```

3. **Permissions**
   The app requires location permissions. These are handled automatically on first launch.

4. **Run the App**
   ```bash
   flutter run
   ```

## Usage Flow

1. **Driver Registration**
   - Launch app → Driver Registration Screen
   - Enable location permissions
   - Optionally set custom driver ID
   - Register as driver

2. **Waiting for Requests**
   - Dashboard shows "Available" status
   - Emergency Requests tab shows pending requests
   - Real-time notifications for new emergencies

3. **Responding to Emergency**
   - Accept emergency request
   - Status changes to "Responding"
   - Map shows route to patient location
   - Navigate to patient using GPS

4. **Complete Emergency**
   - Mark request as completed
   - Status returns to "Available"
   - Ready for next emergency

## Driver Status States

- **Offline**: Not connected to server
- **Connecting**: Establishing connection
- **Available**: Ready to receive requests
- **Responding**: En route to patient
- **Busy**: Handling emergency
- **Error**: Connection or system error

## Real-time Features

- ✅ Live GPS tracking and location updates
- ✅ Real-time emergency notifications
- ✅ Patient location tracking during emergencies
- ✅ Route calculation and navigation
- ✅ Status synchronization with server
- ✅ Connection state management

## Backend Integration

This app integrates with the ambulance dispatch system API as documented. Ensure the backend server is running on `localhost:8080` or update the URL configuration accordingly.

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **socket_io_client**: Real-time WebSocket communication
- **flutter_map**: Interactive map display
- **geolocator**: GPS location services
- **provider**: State management
- **http**: HTTP API calls

## Next Steps

To complete the system:
1. Start the backend server from the API documentation
2. Test the driver registration flow
3. Use the patient app to create emergency requests
4. Test real-time communication between patient and driver apps