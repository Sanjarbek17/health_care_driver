// ignore_for_file: avoid_print, unrelated_type_equality_checks

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/animation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

Future statusPermission() async {
  // Test if location services are enabled.
  var status = await Permission.storage.status;

  if (status == Permission.storage.isDenied) {
    // Permissions are denied, next time you could try
    // requesting permissions again (this is also where
    // Android's shouldShowRequestPermissionRationale
    // returned true. According to Android guidelines
    // your App should show an explanatory UI now.
    return Future.error('Location permissions are denied');
  }
  Permission.storage.request();
  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return status;
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(begin!.latitude, begin!.longitude);
  }
}

Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
  final String apiUrl = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=5b3ce3597851110001cf6248bbbb913eeda14ab1b42f177bd4cb4e2d&start=${start.longitude},${start.latitude},&end=${end.longitude},${end.latitude}';
  print(apiUrl);

  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode == 200) {
    final decodedData = jsonDecode(response.body);
    // print(decodedData);
    final geometry = decodedData['features'][0]['geometry']['coordinates'];
    print(geometry);
    final routePoints = <LatLng>[];
    for (final point in geometry) {
      routePoints.add(LatLng(point[1], point[0]));
    }
    return routePoints;
  } else {
    throw Exception('Failed to load route data');
  }
}
