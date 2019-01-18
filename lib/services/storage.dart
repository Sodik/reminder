import 'package:localstorage/localstorage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/reminder.dart';

class Storage {
  List<Reminder> _items = [];
  final LocalStorage _storage = LocalStorage('reminders');

  List<Reminder> get items {
    return _items;
  }

  Storage() {
    _storage.ready.then((_){
      _items = _parseItems(_storage.getItem('items') ?? []);
    });
  }

  Future get ready {
    return _storage.ready;
  }

  List<Reminder> _parseItems(List<dynamic> items) {
    return items.map((item) {
      final position = (item['position'] ?? '').split(',');
      final reminder = Reminder(
        id: item['id'],
        text: item['text'],
        notifyOnce: item['notifyOnce'],
        position: LatLng(double.parse(position[0]), double.parse(position[1])),
      );

      return reminder;
    }).toList();
  }

  add(Reminder item) {
    _items.add(item);
    _save();
  }

  remove(Reminder item) {
    if (item.removeMarker != null) {
      item.removeMarker();
    }

    _items.remove(item);
    _save();
  }

  _save() {
    _storage.setItem('items', _items);
  }
}
