import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

_rad(double x) {
  return x * pi / 180;
}

calculateDistance(LatLng p1, LatLng p2) {
  var R = 6371e3; // metres
  var r1 = _rad(p1.latitude);
  var r2 = _rad(p2.latitude);
  var d1 = _rad((p1.latitude - p2.latitude));
  var d2 = _rad((p1.longitude - p2.longitude));

  var a = sin(d1/2) * sin(d1/2) + cos(r1) * cos(r2) * sin(d2/2) * sin(d2/2);
  var c = 2 * atan2(sqrt(a), sqrt(1-a));

  var d = R * c;

  return d;
}