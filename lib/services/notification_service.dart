import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:ciputra_patroli/services/firebase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<String> allTokens = [];

  NotificationService() {
    _initializeLocalNotifications();
    _initializeFirebaseMessaging();
  }

  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'kejadian_channel', // id
      'Kejadian Notifications', // title
      description: 'Notifications for kejadian events', // description
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Create the notification channel
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _initializeFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    _showNotification(message.notification?.title, message.notification?.body);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print(
        "Message received in foreground: ${message.notification?.title} - ${message.notification?.body}");
    _showNotification(message.notification?.title, message.notification?.body);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print(
        "Message opened from background: ${message.notification?.title} - ${message.notification?.body}");
    _showNotification(message.notification?.title, message.notification?.body);
  }

  Future<void> _showNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'kejadian_channel', // channel id
      'Kejadian Notifications', // channel name
      channelDescription: 'Notifications for kejadian events',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // unique id
      title ?? 'New Notification',
      body ?? '',
      platformChannelSpecifics,
      payload: 'kejadian_notification',
    );
  }

  Future<void> initNotification() async {
    try {
      // Request permission for notifications
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      log('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get the token
        String? token = await _firebaseMessaging.getToken();
        log('FCM Token obtained: $token');

        if (token != null) {
          // Subscribe to topic for all kejadian notifications
          await _firebaseMessaging.subscribeToTopic('kejadian');
          log('Subscribed to kejadian topic');

          // Handle token refresh
          _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
            log('FCM Token refreshed: $newToken');
            // Update token in Firebase
            await _firebaseService.updateSatpamFcmToken(token);
          });
        }
      } else {
        log('User declined or has not accepted permission');
      }
    } catch (e) {
      log('Error initializing notifications: $e');
    }
  }

  Future<void> sendNotificationToAll(String title, String message) async {
    try {
      allTokens = await _firebaseService.getAllFCMTokens();
      log('Retrieved ${allTokens.length} FCM tokens');

      if (allTokens.isEmpty) {
        log('No FCM tokens available for sending notifications');
        return;
      }

      for (String token in allTokens) {
        try {
          await _firebaseService.sendNotification(
            satpamId:
                token, // Using token as satpamId since we're sending to all
            title: title,
            body: message,
            data: {
              'type': 'kejadian',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          log('Notification sent successfully to token: ${token.substring(0, 10)}...');
        } catch (e) {
          log('Failed to send notification to token ${token.substring(0, 10)}...: $e');
          // Continue with next token even if one fails
          continue;
        }
      }
    } catch (e) {
      log('Error in sendNotificationToAll: $e');
    }
  }

  Future<void> sendNotification(
      String token, String title, String message) async {
    try {
      final credentials = json.decode(
          await rootBundle.loadString('assets/firebase-credentials.json'));

      final authClient = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(credentials),
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/ciputrapatroli/messages:send');

      final response = await authClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "message": {
            "token": token,
            "notification": {
              "title": title,
              "body": message,
            },
            "android": {
              "priority": "high",
              "notification": {
                "channel_id": "kejadian_channel",
                "sound": "default",
                "default_sound": true,
                "default_vibrate_timings": true,
                "default_light_settings": true,
                "icon": "@mipmap/ic_launcher",
                "click_action": "FLUTTER_NOTIFICATION_CLICK"
              }
            },
            "data": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "type": "kejadian",
              "title": title,
              "body": message
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully: ${response.body}');
      } else {
        print(
            'Failed to send notification: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
