import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'models/reminder.dart';

var flutterLocalNotificationsPlugin;

var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
    'your channel id', 'your channel name', 'your channel description',
    importance: Importance.Max, priority: Priority.High);

void main() {
  flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  runApp(MaterialApp(
    home: Scaffold(
      body: MapsDemo(),
    ),
  ));
}

const radius = 500;

enum Modes {
  idle,
  setMarker,
  confirmMarker,
}

rad(double x) {
  return x * pi / 180;
}

calculateDistance(LatLng p1, LatLng p2) {
  var R = 6371e3; // metres
  var r1 = rad(p1.latitude);
  var r2 = rad(p2.latitude);
  var d1 = rad((p1.latitude - p2.latitude));
  var d2 = rad((p1.longitude - p2.longitude));

  var a = sin(d1/2) * sin(d1/2) + cos(r1) * cos(r2) * sin(d2/2) * sin(d2/2);
  var c = 2 * atan2(sqrt(a), sqrt(1-a));

  var d = R * c;

  return d;
}

class _SaveDialogState extends State<_SaveDialog> {
  String _text = '';
  final inputController = TextEditingController();

  void initState() {
    super.initState();

    inputController.addListener(() {
      setState(() {
        _text = inputController.text;
      });
    });
  }

  void dispose() {
    super.dispose();

    inputController.dispose();
  }

  Widget build(BuildContext context) {
    return SimpleDialog(
      children: <Widget>[
        Form(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 180,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        maxLines: 3,
                        autofocus: true,
                        controller: inputController,
                        decoration: InputDecoration(
                            labelText: 'Enter text'
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: <Widget>[
                              FlatButton(
                                onPressed: () {
                                  widget.onCancel();
                                  Navigator.pop(context);
                                },
                                child: Text('Cancel'),
                              ),
                              RaisedButton(
                                onPressed: _text.length > 0 ? () {
                                  widget.onSave(_text);
                                  Navigator.pop(context);
                                } : null,
                                child: Text('Save'),
                              ),
                            ],
                          )
                      ),
                    ],
                  ),
                )
            )
        ),
      ],
    );
  }
}

class _SaveDialog extends StatefulWidget {
  final Function onSave;
  final Function onCancel;

  _SaveDialog({
    Key key,
    @required this.onSave,
    @required this.onCancel,
  }): super(key: key);

  _SaveDialogState createState() => _SaveDialogState();
}

class MapsDemo extends StatefulWidget {
  State createState() => MapsDemoState();
}

class MapsDemoState extends State<MapsDemo> {
  GoogleMapController _mapController;
  Map<String, double> _currentLocation;
  final _location = Location();
  final LocalStorage storage = new LocalStorage('reminders');
  List<Reminder> _reminders = [];
  Modes _mode = Modes.idle;

  initState() {
    super.initState();
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);
  }

  Future _onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  }

  _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    final center = await _getUserLocation();

    if (center != null) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: center == null ? LatLng(0, 0) : center, zoom: 15.0)));
    }

    _location.onLocationChanged().listen((Map<String, double> newLocation) {
      if (_currentLocation != null || _currentLocation != null && (_currentLocation['latitude'] != newLocation['latitude'] || _currentLocation['longitude'] != newLocation['longitude'])) {
        _currentLocation = newLocation;
        final currentLatLng = LatLng(_currentLocation['latitude'], _currentLocation['longitude']);
        List<Reminder> items = [];
        _reminders.forEach((item) {
          final matched = calculateDistance(item.position, currentLatLng).abs() <= radius;

          if (matched) {
            items.add(item);
            flutterLocalNotificationsPlugin.show(1, '', item.text, androidPlatformChannelSpecifics);
          }
        });

        print(items);
      }
    });

    storage.ready.then((bool val) {
      List<dynamic> items = storage.getItem('items') ?? [];

      _reminders = items.map((item) {
        final position = (item['position'] ?? '').split(',');
        final reminder = Reminder(
          id: item['id'],
          text: item['text'],
          position: LatLng(double.parse(position[0]), double.parse(position[1])),
        );

        _mapController.addMarker(
            MarkerOptions(
              position: reminder.position,
            )
        );

        return reminder;
      }).toList();
    });
  }

  Future<LatLng> _getUserLocation() async {
    try {
      _currentLocation = await _location.getLocation();

      final lat = _currentLocation['latitude'];
      final lng = _currentLocation['longitude'];
      final center = LatLng(lat, lng);

      return center;
    } catch(e) {
      _currentLocation = null;

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
        return _SaveDialog(
          onCancel: () {
            setState(() {
              _mode = Modes.idle;
            });
          },
          onSave: (String text) {
            final position = _mapController.cameraPosition.target;

            _mapController.addMarker(MarkerOptions(
              position: position,
            ));

            setState(() {
              _mode = Modes.idle;
              final currentReminder = Reminder(
                position: position,
                text: text,
              );

              final items = storage.getItem('items') ?? [];
              items.add(currentReminder);
              storage.setItem('items', items);
              _reminders.add(currentReminder);
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