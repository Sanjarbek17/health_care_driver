import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../providers/main_provider.dart';
import 'emergency_requests_screen.dart';
import 'map_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize driver and start location tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDriver();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeDriver() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final locationProvider = Provider.of<UserLocationProvider>(context, listen: false);

    if (!driverProvider.isConnected) {
      await driverProvider.initializeDriver();
    }

    // Set up location updates for the driver
    locationProvider.addListener(() {
      if (locationProvider.isLocationEnabled) {
        driverProvider.updateLocation(locationProvider.currentLatLng);
      }
    });

    // Refresh pending requests
    await driverProvider.refreshPendingRequests();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Driver'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          Consumer<DriverProvider>(
            builder: (context, driverProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'refresh_requests':
                      driverProvider.refreshPendingRequests();
                      break;
                    case 'refresh_status':
                      driverProvider.refreshDriverStatus();
                      break;
                    case 'go_offline':
                      _showGoOfflineDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh_requests',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Refresh Requests'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh_status',
                    child: ListTile(
                      leading: Icon(Icons.sync),
                      title: Text('Refresh Status'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'go_offline',
                    child: ListTile(
                      leading: Icon(Icons.power_settings_new),
                      title: Text('Go Offline'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Driver status banner
          Consumer<DriverProvider>(
            builder: (context, driverProvider, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: driverProvider.getStatusColor(),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(driverProvider.status),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${driverProvider.getStatusText()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (driverProvider.driverId != null)
                      Text(
                        'ID: ${driverProvider.driverId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                const EmergencyRequestsScreen(),
                HomeScreen(), // Map screen
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<DriverProvider>(
        builder: (context, driverProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.red,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.emergency),
                    if (driverProvider.pendingRequests.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${driverProvider.pendingRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Requests',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(DriverStatus status) {
    switch (status) {
      case DriverStatus.offline:
        return Icons.power_settings_new;
      case DriverStatus.connecting:
        return Icons.sync;
      case DriverStatus.available:
        return Icons.check_circle;
      case DriverStatus.responding:
        return Icons.directions_car;
      case DriverStatus.busy:
        return Icons.block;
      case DriverStatus.error:
        return Icons.error;
    }
  }

  void _showGoOfflineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Offline'),
        content: const Text('Are you sure you want to go offline? You will stop receiving emergency requests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              final locationProvider = Provider.of<UserLocationProvider>(context, listen: false);

              driverProvider.goOffline();
              locationProvider.stopLocationTracking();

              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Go Offline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
