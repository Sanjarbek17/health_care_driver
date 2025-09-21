import 'package:flutter/material.dart';
import 'package:health_care_driver/screens/map_screen.dart';
import 'package:health_care_driver/screens/driver_registration_screen.dart';
import 'package:health_care_driver/screens/driver_dashboard_screen.dart';
import 'package:health_care_driver/style/main_style.dart';
import 'package:provider/provider.dart';

import 'providers/main_provider.dart';
import 'providers/driver_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserLocationProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: SafeArea(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          initialRoute: '/',
          routes: {
            '/': (context) => const DriverRegistrationScreen(),
            '/dashboard': (context) => const DriverDashboardScreen(),
            '/map': (context) => HomeScreen(),
          },
        ),
      ),
    );
  }
}
