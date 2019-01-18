import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'utils/distance.dart';
import 'models/reminder.dart';
import 'services/storage.dart';
import 'widgets/save_dialog.dart';

var flutterLocalNotificationsPlugin;

var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
  '1', 'reminder', 'your personal reminders',
  importance: Importance.Max,
  priority: Priority.High,
  groupKey: 'reminder',
);
var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
var platformChannelSpecifics = new NotificationDetails(
    androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

void main() async {
  final storage = Storage();
  flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  var initializationSettingsAndroid =
  new AndroidInitializationSettings('app_icon');
  var initializationSettingsIOS = new IOSInitializationSettings();
  var initializationSettings = new InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  flutterLocalNotificationsPlugin.initialize(initializationSettings);


  runApp(MaterialApp(
    home: Scaffold(
      body: Map(
        storage: storage,
      ),
    ),
  ));
}

const radius = 500;

enum Modes {
  idle,
  setMarker,
  confirmMarker,
}

class Map extends StatefulWidget {
  final Storage storage;

  Map({
    Key, key,
    @required this.storage,
  }): super(key: key);

  State createState() => MapState();
}

class MapState extends State<Map> with WidgetsBindingObserver {
  static const platform = const MethodChannel('reminder.flutter.io/location');
  GoogleMapController _mapController;
  final _location = Location();
  Modes _mode = Modes.idle;

  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.storage.ready.then((_) async {
      platform.invokeMethod('LocationService.markers', [widget.storage.items.toString()]);
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _mapController.clearMarkers();
      _renderMarkers();
    }
  }

  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    final center = await _getUserLocation();

    if (center != null) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: center == null ? LatLng(0, 0) : center, zoom: 15.0)));
      platform.invokeMethod('LocationService.start');
    }

    widget.storage.ready.then((_) {
      _renderMarkers();
    });
  }

  void _renderMarkers() {
    List<Reminder> items = widget.storage.items;

    items.forEach((item) {
      _mapController.addMarker(
          MarkerOptions(
            position: item.position,
          )
      ).then((Marker marker) {
        item.removeMarker = () {
          _mapController.removeMarker(marker);
        };
      });
    });
  }

  Future<LatLng> _getUserLocation() async {
    try {
      final currentLocation = await _location.getLocation();

      final lat = currentLocation['latitude'];
      final lng = currentLocation['longitude'];
      final center = LatLng(lat, lng);

      return center;
    } catch(e) {
      return null;
    }
  }

  Widget _renderActionButton() {
    if (_mode == Modes.setMarker) {
      return FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: _showDialog,
      );
    }

    return FloatingActionButton(
      child: Icon(Icons.add_location),
      onPressed: () async {
        setState(() {
          _mode = Modes.setMarker;
        });
      },
    );
  }

  Widget _renderCross(BuildContext context) {
    var top = -9999.0;
    var left = -9999.0;

    if (_mode == Modes.setMarker) {
      final iconOffset = IconTheme.of(context).size / 2;
      top = MediaQuery.of(context).size.height / 2 - iconOffset;
      left = MediaQuery.of(context).size.width / 2 - iconOffset;
    }

    return Positioned(
      left: left,
      top: top,
      child: Icon(Icons.fullscreen_exit),
    );
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SaveDialog(
          onCancel: () {
            setState(() {
              _mode = Modes.idle;
            });
          },
          onSave: (String text, bool notifyOnce) {
            final position = _mapController.cameraPosition.target;

            _mapController.addMarker(MarkerOptions(
              position: position,
            ));

            setState(() {
              _mode = Modes.idle;
              final currentReminder = Reminder(
                notifyOnce: notifyOnce,
                position: position,
                text: text,
              );

              widget.storage.add(currentReminder);
            });
          },
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              options: GoogleMapOptions(
                myLocationEnabled: true,
                trackCameraPosition: true,
              ),
              onMapCreated: _onMapCreated,
            ),
          ),
          _renderCross(context),
        ],
      ),
      floatingActionButton: _renderActionButton(),
    );
  }
}