package com.example.reminder;

import android.os.Bundle;
import android.content.Intent;
import android.util.Log;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "reminder.flutter.io/location";
  private MethodChannel channel;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    channel = new MethodChannel(getFlutterView(), CHANNEL);
    final Intent intent = new Intent(this, LocationService.class);
    channel.setMethodCallHandler(
      new MethodCallHandler() {
        @Override
        public void onMethodCall(MethodCall call, Result result) {
          if(call.method.equals("LocationService.start")) {
            startService(intent);
          }

          if (call.method.equals("LocationService.markers")) {
            final Intent intent = new Intent(LocationService.ACTION_REMINDERS);
            intent.putExtra("data", call.arguments().toString());
          }
        }
      }
    );
  }

  @Override
  protected void onResume() {
    super.onResume();
  }

  @Override
  protected void onPause() {
    super.onPause();
  }
}
