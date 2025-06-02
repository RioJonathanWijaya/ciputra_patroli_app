import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:ciputra_patroli/services/firebase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<String> allTokens = [];
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

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

      developer.log('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get the token
        String? token = await _firebaseMessaging.getToken();
        developer.log('FCM Token obtained: $token');

        if (token != null) {
          // Store the token first
          await _firebaseService.updateSatpamFcmToken(token);
          developer.log('FCM token stored successfully');

          // Try to subscribe to topic with retry logic
          try {
            await _subscribeToTopicWithRetry('kejadian');
            developer.log('Successfully subscribed to kejadian topic');
          } catch (e) {
            developer.log('Failed to subscribe to topic, will retry later: $e');
            // Store for later retry
            await _storeFailedSubscription('kejadian');
          }

          // Handle token refresh
          _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
            developer.log('FCM Token refreshed: $newToken');
            try {
              await _firebaseService.updateSatpamFcmToken(newToken);
              developer.log('Updated FCM token in Firebase');
            } catch (e) {
              developer.log('Failed to update FCM token in Firebase: $e');
            }
          });
        } else {
          developer.log('Failed to obtain FCM token');
        }
      } else {
        developer.log('User declined or has not accepted permission');
      }
    } catch (e) {
      developer.log('Error initializing notifications: $e');
      // Don't rethrow the error to allow the app to continue loading
    }
  }

  Future<void> _subscribeToTopicWithRetry(String topic) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        // Check if already subscribed
        final topics = await _firebaseMessaging.getAPNSToken();
        if (topics != null) {
          developer.log('Already subscribed to topic: $topic');
          return;
        }

        await _firebaseMessaging.subscribeToTopic(topic);
        developer.log('Successfully subscribed to topic: $topic');
        return;
      } catch (e) {
        retryCount++;
        developer.log('Failed to subscribe to topic (attempt $retryCount): $e');

        if (retryCount < maxRetries) {
          developer.log('Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        } else {
          developer
              .log('Max retries reached. Could not subscribe to topic: $topic');
          await _storeFailedSubscription(topic);
          // Don't throw the error to allow the app to continue loading
        }
      }
    }
  }

  Future<void> _storeFailedSubscription(String topic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedSubscriptions =
          prefs.getStringList('failed_fcm_subscriptions') ?? [];
      if (!failedSubscriptions.contains(topic)) {
        failedSubscriptions.add(topic);
        await prefs.setStringList(
            'failed_fcm_subscriptions', failedSubscriptions);
        developer.log('Stored failed subscription for topic: $topic');
      }
    } catch (e) {
      developer.log('Error storing failed subscription: $e');
    }
  }

  Future<void> retryFailedSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedSubscriptions =
          prefs.getStringList('failed_fcm_subscriptions') ?? [];

      if (failedSubscriptions.isNotEmpty) {
        developer
            .log('Retrying ${failedSubscriptions.length} failed subscriptions');
        for (final topic in failedSubscriptions) {
          await _subscribeToTopicWithRetry(topic);
        }
        // Clear the failed subscriptions list after retrying
        await prefs.remove('failed_fcm_subscriptions');
      }
    } catch (e) {
      developer.log('Error retrying failed subscriptions: $e');
    }
  }

  Future<void> sendNotificationToAll(String title, String message) async {
    try {
      allTokens = await _firebaseService.getAllFCMTokens();
      developer.log('Retrieved ${allTokens.length} FCM tokens');

      if (allTokens.isEmpty) {
        developer.log('No FCM tokens available for sending notifications');
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
          developer.log(
              'Notification sent successfully to token: ${token.substring(0, 10)}...');
        } catch (e) {
          developer.log(
              'Failed to send notification to token ${token.substring(0, 10)}...: $e');
          // Continue with next token even if one fails
          continue;
        }
      }
    } catch (e) {
      developer.log('Error in sendNotificationToAll: $e');
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
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': 'id-ID', // Set locale in headers
        },
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
              "body": message,
              "locale": "id-ID" // Add locale in data payload
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        developer.log('Notification sent successfully: ${response.body}');
      } else {
        developer.log(
            'Failed to send notification: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      developer.log('Error sending notification: $e');
    }
  }
}
