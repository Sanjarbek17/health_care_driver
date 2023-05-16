// ignore_for_file: must_be_immutable, avoid_print

import 'dart:async';
// import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:health_care_driver/widgets/functions.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart';
// import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/widgets.dart';
import 'constants.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../providers/main_provider.dart';
// import '../providers/translation_provider.dart';
// import '/screens/catalog/catalog_screen.dart';
// import 'info/info_screen.dart';
// import '../style/my_flutter_app_icons.dart';
// import '../widgets/widgets.dart';
// import 'constants.dart';
// import 'profile/profil_screen.dart';

class HomeScreen extends StatefulWidget with ChangeNotifier {
  HomeScreen({super.key});
  static const routeName = 'home-screen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, ChangeNotifier {
  List<LatLng> polylinePoints = [];

  // ambulance car
  // late final StreamController<LocationMarkerPosition> positionStreamController;
  // late final StreamController<LocationMarkerHeading> headingStreamController;

  late bool navigationMode;
  late int pointerCount;

  late FollowOnLocationUpdate _followOnLocationUpdate;
  late TurnOnHeadingUpdate _turnOnHeadingUpdate;
  late StreamController<double?> _followCurrentLocationStreamController;
  late StreamController<void> _turnHeadingUpStreamController;

  double _currentLat = 39.6548;
  double _currentLng = 66.9597;

  late FirebaseMessaging messaging;
  @override
  void initState() {
    super.initState();
    print('initstate');
    messaging = FirebaseMessaging.instance;
    messaging.getToken().then((value) {
      //  fBg22SJITjWIxwTdvkruzW:APA91bE1cAqAT1u6jBHIZY-YntoEX0K6plOTdAXT6yT5z_5hf-O7E3LuK4IJeMPlk-5LwYpynotpnKqHQ5x1lInyfu0xYpsfYOieTw20c8My3EbifxkjCd-FoK0AjM48RCs0bgF70yAu
      print('fiebase token');
      print(value);
    });

    messaging.subscribeToTopic('messaging');

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message recieved");
      print(event.notification!.body);
      print(event.data['position']);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(event.notification!.title!),
              content: Text(event.notification!.body!),
              actions: [
                TextButton(
                  child: Text("Ok"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
    });
    // positionStreamController = StreamController()
    //   ..add(
    //     LocationMarkerPosition(
    //       latitude: _currentLat,
    //       longitude: _currentLng,
    //       accuracy: 0,
    //     ),
    //   );
    // headingStreamController = StreamController()
    //   ..add(
    //     LocationMarkerHeading(
    //       heading: 0,
    //       accuracy: pi * 0.2,
    //     ),
    //   );

    navigationMode = false;
    pointerCount = 0;

    _followOnLocationUpdate = FollowOnLocationUpdate.never;
    _turnOnHeadingUpdate = TurnOnHeadingUpdate.never;
    _followCurrentLocationStreamController = StreamController<double?>();
    _turnHeadingUpStreamController = StreamController<void>();
    determinePosition();
    statusPermission();
  }

  @override
  void dispose() {
    _followCurrentLocationStreamController.close();

    // positionStreamController.close();
    // headingStreamController.close();
    super.dispose();
  }

  void nearestAmbulance(Function func) {
    determinePosition().then((value) {
      getRoutePoints(LatLng(_currentLat, _currentLng), LatLng(value.latitude, value.longitude)).then((value) {
        setState(() {
          polylinePoints = value;
        });
        moveCar(value, func);
      });
    });
  }

  void takeAmbulance() {
    setState(
      () {
        navigationMode = !navigationMode;
        _followOnLocationUpdate = navigationMode ? FollowOnLocationUpdate.always : FollowOnLocationUpdate.never;
        _turnOnHeadingUpdate = navigationMode ? TurnOnHeadingUpdate.always : TurnOnHeadingUpdate.never;
      },
    );
    if (navigationMode) {
      _followCurrentLocationStreamController.add(18);
      _turnHeadingUpStreamController.add(null);
    }
  }

  void moveCar(List<LatLng> polylinePoints, Function func) async {
    await Future.forEach(polylinePoints, (element) async {
      await Future.delayed(const Duration(seconds: 1)).then((value) {
        // headingStreamController.add(
        //   LocationMarkerHeading(
        //     heading: (atan2(element.longitude - _currentLng, element.latitude - _currentLat)) % (pi * 2),
        //     accuracy: pi * 0.2,
        //   ),
        // );
        _currentLat = element.latitude;
        _currentLat = _currentLat.clamp(-85, 85);
        _currentLng = element.longitude;
        _currentLng = _currentLng.clamp(-180, 180);

        // positionStreamController.add(
        //   LocationMarkerPosition(
        //     latitude: _currentLat,
        //     longitude: _currentLng,
        //     accuracy: 0,
        //   ),
        // );
      });
    });
    func();
  }

  final phoneNumber = Uri.parse('tel:103');
  final smsNumber = Uri.parse('sms:103');

  @override
  Widget build(BuildContext context) {
    // Language Provider
    // final language = Provider.of<Translate>(context, listen: false);
    // get mapprovider
    // final mapProvider = Provider.of<MapProvider>(context);
    // if (mapProvider.isRun) {
    //   print('car is running');
    //   nearestAmbulance(mapProvider.makeItZero);
    //   mapProvider.addOne();
    // }

    // final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          sendMessage({'title': 'hello', 'body': 'world'});
          print('send message');
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.red,
            child: Row(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                      child: const Icon(
                        Icons.phone_rounded,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    Text(
                      appBarTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ]),
                  // small title text
                  Text(
                    appBarLeadingText,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ]),
          ),
          // change to map widget
          // map widget
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(39.6548, 66.9597),
                zoom: 13,
              ),
              nonRotatedChildren: [
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
                )
              ],
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                PolylineLayer(
                  polylineCulling: false,
                  polylines: [
                    Polyline(points: polylinePoints, color: Colors.blue, strokeWidth: 4),
                  ],
                ),
                // the ambulance car
                // CurrentLocationLayer(
                //   positionStream: positionStreamController.stream,
                //   headingStream: headingStreamController.stream,
                //   style: LocationMarkerStyle(
                //     marker: DefaultLocationMarker(
                //       // color: Colors.transparent,
                //       child: Image.asset('assets/gps_map_car.png'),
                //     ),
                //     markerDirection: MarkerDirection.heading,
                //     markerSize: const Size.square(40),
                //     // showAccuracyCircle: false,
                //     // showHeadingSector: false,
                //     accuracyCircleColor: Colors.black,
                //     headingSectorColor: Colors.red,
                //   ),
                // ),
                // the user marker
                CurrentLocationLayer(
                  style: const LocationMarkerStyle(
                    marker: DefaultLocationMarker(child: Icon(Icons.navigation, color: Colors.white)),
                    markerSize: Size(40, 40),
                    markerDirection: MarkerDirection.heading,
                  ),
                  followCurrentLocationStream: _followCurrentLocationStreamController.stream,
                  turnHeadingUpLocationStream: _turnHeadingUpStreamController.stream,
                  followOnLocationUpdate: _followOnLocationUpdate,
                  turnOnHeadingUpdate: _turnOnHeadingUpdate,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
