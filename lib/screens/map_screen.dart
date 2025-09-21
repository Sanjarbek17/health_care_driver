// ignore_for_file: must_be_immutable, avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:health_care_driver/widgets/functions.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';
import '../style/main_style.dart';
import '../widgets/widgets.dart';
import 'constants.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget with ChangeNotifier {
  HomeScreen({super.key});
  static const routeName = 'home-screen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, ChangeNotifier {
  List<LatLng> polylinePoints = [LatLng(39.6548, 66.9597)];

  // ambulance car
  late final StreamController<LocationMarkerPosition> positionStreamController;
  late final StreamController<LocationMarkerHeading> headingStreamController;

  late bool navigationMode;
  late int pointerCount;

  late AlignOnUpdate _alignPositionOnUpdate;
  late AlignOnUpdate _alignDirectionOnUpdate;
  late StreamController<double?> _alignPositionStreamController;
  late StreamController<void> _alignDirectionStreamController;

  final double _currentLat = 39.6548;
  final double _currentLng = 66.9597;

  late FirebaseMessaging messaging;
  @override
  void initState() {
    super.initState();
    print('initstate');
    messaging = FirebaseMessaging.instance;
    messaging.getToken().then((value) {
      print('fiebase token');
      print(value);
    });
    messaging.unsubscribeFromTopic('user');
    messaging.subscribeToTopic('driver');

    // on background message
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) {
      print("message recieved");
      Map position = jsonDecode(event.data['position']);

      // change user locaiton
      Provider.of<UserLocationProvider>(context, listen: false).setLatitude(position['latitude'], position['longitude']);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(event.notification!.title!),
              content: Text(event.notification!.body!),
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    // draw route
                    nearestAmbulance();
                    // show user location
                    Provider.of<UserLocationProvider>(context, listen: false).setLocationEnabled(true);
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message recieved");
      Map position = jsonDecode(event.data['position']);

      // change user locaiton
      Provider.of<UserLocationProvider>(context, listen: false).setLatitude(position['latitude'], position['longitude']);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(event.notification!.title!),
              content: Text(event.notification!.body!),
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    // draw route
                    nearestAmbulance();
                    // show user location
                    Provider.of<UserLocationProvider>(context, listen: false).setLocationEnabled(true);
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    });
    positionStreamController = StreamController()
      ..add(
        LocationMarkerPosition(
          latitude: _currentLat,
          longitude: _currentLng,
          accuracy: 0,
        ),
      );
    headingStreamController = StreamController()
      ..add(
        LocationMarkerHeading(
          heading: 0,
          accuracy: pi * 0.2,
        ),
      );

    navigationMode = false;
    pointerCount = 0;

    _alignPositionOnUpdate = AlignOnUpdate.never;
    _alignDirectionOnUpdate = AlignOnUpdate.never;
    _alignPositionStreamController = StreamController<double?>();
    _alignDirectionStreamController = StreamController<void>();
    determinePosition();
    statusPermission();
  }

  @override
  void dispose() {
    _alignPositionStreamController.close();

    positionStreamController.close();
    headingStreamController.close();
    super.dispose();
  }

  void nearestAmbulance() {
    UserLocationProvider user = Provider.of<UserLocationProvider>(context, listen: false);
    determinePosition().then((value) {
      sendMessage({'position': value.toJson()});
      getRoutePoints(LatLng(user.latitude, user.longitude), LatLng(value.latitude, value.longitude)).then((value) {
        setState(() {
          polylinePoints = value;
        });
        // moveCar(value);
      });
    });
  }

  void takeAmbulance() {
    setState(
      () {
        navigationMode = !navigationMode;
        _alignPositionOnUpdate = navigationMode ? AlignOnUpdate.always : AlignOnUpdate.never;
        _alignDirectionOnUpdate = navigationMode ? AlignOnUpdate.always : AlignOnUpdate.never;
      },
    );
    if (navigationMode) {
      _alignPositionStreamController.add(18);
      _alignDirectionStreamController.add(null);
    }
  }
  // may be usefull!!!
  // void moveCar(List<LatLng> polylinePoints) async {
  //   await Future.forEach(polylinePoints, (element) async {
  //     await Future.delayed(const Duration(seconds: 1)).then((value) {
  //       headingStreamController.add(
  //         LocationMarkerHeading(
  //           heading: (atan2(element.longitude - _currentLng, element.latitude - _currentLat)) % (pi * 2),
  //           accuracy: pi * 0.2,
  //         ),
  //       );
  //       _currentLat = element.latitude;
  //       _currentLat = _currentLat.clamp(-85, 85);
  //       _currentLng = element.longitude;
  //       _currentLng = _currentLng.clamp(-180, 180);

  //       positionStreamController.add(
  //         LocationMarkerPosition(
  //           latitude: _currentLat,
  //           longitude: _currentLng,
  //           accuracy: 0,
  //         ),
  //       );
  //     });
  //   });
  // }

  final phoneNumber = Uri.parse('tel:103');
  final smsNumber = Uri.parse('sms:103');

  @override
  Widget build(BuildContext context) {
    // Language Provider
    // final language = Provider.of<Translate>(context, listen: false);

    // final double width = MediaQuery.of(context).size.width;
    // get user location provider
    final userLocationProvider = Provider.of<UserLocationProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: () async {
            showBottomSheet(
              context: context,
              builder: (context) => HistoryPage(),
            );
          },
          child: const Icon(Icons.history, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              appBarTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        // small title text
                        Text(
                          appBarLeadingText,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // change to map widget
              // map widget
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(39.6548, 66.9597),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.sanjarbek.health_care',
                          maxZoom: 17,
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(points: polylinePoints, color: Colors.blue, strokeWidth: 4),
                          ],
                        ),
                        // the user marker
                        if (userLocationProvider.isLocationEnabled)
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: LatLng(userLocationProvider.latitude, userLocationProvider.longitude),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        // the ambulance marker
                        CurrentLocationLayer(
                          style: const LocationMarkerStyle(
                            marker: DefaultLocationMarker(child: Icon(Icons.navigation, color: Colors.white)),
                            markerSize: Size(40, 40),
                            markerDirection: MarkerDirection.heading,
                          ),
                          alignPositionStream: _alignPositionStreamController.stream,
                          alignDirectionStream: _alignDirectionStreamController.stream,
                          alignPositionOnUpdate: _alignPositionOnUpdate,
                          alignDirectionOnUpdate: _alignDirectionOnUpdate,
                        ),
                      ],
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: FloatingActionButton(
                        backgroundColor: navigationMode ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          takeAmbulance();
                        },
                        child: const Icon(
                          Icons.navigation_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
