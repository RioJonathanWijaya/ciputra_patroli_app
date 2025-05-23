import 'dart:developer';

import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/models/patroli_checkpoint.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/penugasan.dart';
import '../models/location.dart';

class FirebaseService {
  final dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://ciputrapatroli-default-rtdb.asia-southeast1.firebasedatabase.app/",
  ).ref();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<Lokasi?> getLokasiById(String id) async {
    final snapshot = await dbRef.child('lokasi').child(id).get();
    if (!snapshot.exists) return null;

    return Lokasi.fromJson(id, snapshot.value as Map);
  }

  Future<List<Lokasi>> getAllLokasi() async {
    final snapshot = await dbRef.child('lokasi').get();
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map;
    return data.entries.map((e) => Lokasi.fromJson(e.key, e.value)).toList();
  }

  Future<void> savePatroli(Patroli patroli) async {
    try {
      await dbRef.child('patroli').child(patroli.id).set(patroli.toMap());
      log("Patroli saved successfully with ID: ${patroli.id}");
    } catch (e) {
      print("Error saving Patroli: $e");
    }
  }

  Future<Patroli?> getPatroli(String patroliId) async {
    try {
      log('[DEBUG] Fetching patroli with ID: $patroliId');
      final snapshot = await dbRef.child('patroli').child(patroliId).get();

      if (!snapshot.exists) {
        log('[WARNING] Patroli not found with ID: $patroliId');
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      log('[DEBUG] Patroli data retrieved: $data');

      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      final Map<String, dynamic> typedData = Map<String, dynamic>.from(data);
      return Patroli.fromMap(typedData);
    } catch (e) {
      log('[ERROR] Error getting patroli: $e');
      return null;
    }
  }

  Future<void> saveCheckpoint(PatroliCheckpoint checkpoint) async {
    try {
      await dbRef
          .child('patroli_checkpoint')
          .child(checkpoint.id)
          .set(checkpoint.toJson());
      log("Patroli saved successfully with ID: ${checkpoint.id}");
    } catch (e) {
      print("Error saving Patroli: $e");
    }
  }

  Future<List<String>> getAllFCMTokens() async {
    final snapshot = await dbRef.child('satpam_fcm_tokens').get();
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map;

    return data.entries
        .map((e) => e.value['token'] as String?)
        .where((token) => token != null)
        .cast<String>()
        .toList();
  }

  Future<String?> getFcmToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> updateSatpamFcmToken(String satpamId) async {
    try {
      final token = await getFcmToken();
      if (token != null) {
        await dbRef.child('satpam_fcm_tokens').child(satpamId).set({
          'token': token,
          'updated_at': ServerValue.timestamp,
        });
        log('FCM token updated for satpam $satpamId');
      }
    } catch (e) {
      log('Error updating FCM token: $e', error: e);
    }
  }

  Future<String?> getSatpamFcmToken(String satpamId) async {
    try {
      final snapshot =
          await dbRef.child('satpam_fcm_tokens').child(satpamId).get();
      if (snapshot.exists) {
        return snapshot.child('token').value as String?;
      }
      return null;
    } catch (e) {
      log('Error getting satpam FCM token: $e', error: e);
      return null;
    }
  }

  void setupTokenRefreshListener(String satpamId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      log('FCM token refreshed: $newToken');
      await updateSatpamFcmToken(satpamId);
    });
  }

  Future<void> sendNotification({
    required String satpamId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final fcmToken = await getSatpamFcmToken(satpamId);
      if (fcmToken == null) {
        throw Exception('No FCM token found for satpam $satpamId');
      }

      await dbRef.child('notifications').push().set({
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'created_at': ServerValue.timestamp,
      });
      log('Notification sent to $satpamId');
    } catch (e) {
      log('Error sending notification: $e', error: e);
      rethrow;
    }
  }
}
