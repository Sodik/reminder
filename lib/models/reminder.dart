import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final uuid = Uuid();

class Reminder {
  String id;
  LatLng position;
  String text;
  Marker marker;
  bool notifyOnce;

  Reminder({position, text, id, notifyOnce}) {
    this.position = position;
    this.text = text;
    this.id = id ?? uuid.v1();
    this.notifyOnce = notifyOnce ?? true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'position': "${position.latitude},${position.longitude}",
    'text': text,
    'notifyOnce': notifyOnce,
  };
}