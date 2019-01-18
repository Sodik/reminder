import 'package:flutter/material.dart';

class _SaveDialogState extends State<SaveDialog> {
  String _text = '';
  bool _notifyOnce = true;
  final _inputController = TextEditingController();

  void initState() {
    super.initState();

    _inputController.addListener(() {
      setState(() {
        _text = _inputController.text;
      });
    });
  }

  void dispose() {
    super.dispose();

    _inputController.dispose();
  }

  Widget build(BuildContext context) {
    return SimpleDialog(
      children: <Widget>[
        Form(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 240,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        maxLines: 3,
                        autofocus: true,
                        controller: _inputController,
                        decoration: InputDecoration(
                            labelText: 'Enter text'
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Text('Notify only once'),
                          Checkbox(
                            value: _notifyOnce,
                            onChanged: (bool value) {
                              setState(() {
                                _notifyOnce = value;
                              });
                            },
                          ),
                        ],
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
                                  widget.onSave(_text, _notifyOnce);
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

class SaveDialog extends StatefulWidget {
  final Function(String text, bool notifyOnce) onSave;
  final Function onCancel;

  SaveDialog({
    Key key,
    @required this.onSave,
    @required this.onCancel,
  }): super(key: key);

  _SaveDialogState createState() => _SaveDialogState();
}