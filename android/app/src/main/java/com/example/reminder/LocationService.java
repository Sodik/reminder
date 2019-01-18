package com.example.reminder;

import android.annotation.SuppressLint;
import android.app.IntentService;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.IBinder;
import android.os.Handler;
import android.support.v4.app.NotificationCompat;
import android.location.LocationListener;
import android.os.Bundle;
import android.location.Location;
import android.location.LocationManager;
import android.util.Log;

public class LocationService extends IntentService implements LocationListener {
    static final String ACTION_REMINDERS = "com.example.reminder.LocationService.REMINDERS";
    private LocationManager locationManager;
    private String NOTIFICATION_CHANNEL_ID = "reminders";
    private NotificationManager notificationManager;
    private NotificationCompat.Builder notificationBuilder;

    public LocationService() {
        super("LocationService");
    }

    Handler handler = new Handler();

    private Runnable updateData = new Runnable(){
        public void run(){
            notificationBuilder.setContentText("Update");

            notificationManager.notify(1, notificationBuilder.build());
            //call the service here
            ////// set the interval time here
            handler.postDelayed(updateData,10000);
        }
    };

    @Override
    protected void onHandleIntent(Intent intent) {

    }

    public IBinder onBind(Intent intent) {
        // We don't provide binding, so return null
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            @SuppressLint("WrongConstant") NotificationChannel notificationChannel = new NotificationChannel(NOTIFICATION_CHANNEL_ID, "My Notifications", NotificationManager.IMPORTANCE_MAX);
            // Configure the notification channel.
            notificationManager.createNotificationChannel(notificationChannel);
        }

        notificationBuilder = new NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID);

        notificationBuilder.setAutoCancel(false)
                .setDefaults(Notification.DEFAULT_ALL)
                .setWhen(System.currentTimeMillis())
                .setSmallIcon(R.drawable.app_icon)
                .setContentTitle("Reminder notification");
    }

    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent.getAction();

        switch(action) {
            case ACTION_REMINDERS:
                Log.v("3", "!!!!!!!!!!!!!!!!!!!!!");
                Log.v("2", intent.getData().toString());
                break;
            default:
                locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);

                if (checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    Location location = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
                    if (location != null) {
                        onLocationChanged(location);
                    }
                    locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000, 1, this);
                }
        }

        return super.onStartCommand(intent, flags, startId);
    }

    public void onLocationChanged(Location location) {
        notificationBuilder.setContentText(location.toString());

        notificationManager.notify(1, notificationBuilder.build());
    }

    public void onStatusChanged(String provider, int code, Bundle t) {

    }

    public void onProviderEnabled(String result) {

    }

    public void onProviderDisabled(String result) {

    }
}
