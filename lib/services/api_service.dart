import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:ciputra_patroli/models/kejadian.dart';
import 'package:ciputra_patroli/models/patroli_checkpoint.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../models/satpam.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ApiService {
  // static const String baseUrl = "http://10.0.2.2:8000/api";
  static const String baseUrl = "https://ciputrapatroli.site/api";
  static const String relayBaseUrl = "https://ciputrapatroli.site/api/relay";
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<Satpam?> getSatpamById(String id) async {
    try {
      log('[DEBUG] Fetching satpam data for ID: $id');
      final response = await http.get(
        Uri.parse('$relayBaseUrl/satpam/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://ciputrapatroli.site/',
          'Origin': 'https://ciputrapatroli.site',
          'Connection': 'keep-alive',
        },
      );

      log('[DEBUG] Response status code: ${response.statusCode}');
      log('[DEBUG] Response headers: ${response.headers}');
      log('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          // Handle both direct object and wrapped object responses
          final data = jsonData is Map && jsonData.containsKey('data')
              ? jsonData['data']
              : jsonData;

          if (data == null) {
            log('[ERROR] No data found in response');
            return null;
          }

          // Convert the data to a Satpam object
          final satpam = Satpam.fromJson(data);
          log('[DEBUG] Successfully parsed satpam data: ${satpam.toString()}');
          return satpam;
        } catch (e, stackTrace) {
          log('[ERROR] Failed to parse satpam data: $e');
          log('[ERROR] Stack trace: $stackTrace');
          log('[ERROR] Raw response body: ${response.body}');
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 404) {
        log('[ERROR] Satpam not found with ID: $id');
        return null;
      } else if (response.statusCode == 403) {
        log('[ERROR] Access denied by server security');
        throw Exception('Access denied. Please try again later.');
      } else {
        log('[ERROR] Failed to fetch satpam data. Status code: ${response.statusCode}');
        log('[ERROR] Response body: ${response.body}');
        throw Exception('Failed to fetch satpam data: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('[ERROR] Error fetching satpam data: $e');
      log('[STACKTRACE] $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPenugasanById(String id) async {
    final response =
        await http.get(Uri.parse('$baseUrl/penugasan_patroli/$id'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);

      return jsonData.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Kejadian>> fetchAllKejadian() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/kejadian'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final kejadianList = data
            .map((item) {
              try {
                if (item != null) {
                  return Kejadian.fromMap(item);
                } else {
                  throw Exception('Item is null');
                }
              } catch (e) {
                print("Error mapping item: $e");
                return null;
              }
            })
            .where((item) => item != null)
            .toList();

        return kejadianList.cast<Kejadian>();
      } else {
        throw Exception(
            'Failed to load kejadians data, status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching kejadian data: $e");
      throw Exception('Failed to load kejadian data');
    }
  }

  Future<List<int>> fetchStatsPatroliSatpam(String satpamId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/patroli/stats/$satpamId'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      log(data.toString());
      return [
        data['total_patroli'] ?? 0,
        data['total_completed'] ?? 0,
        data['total_late'] ?? 0
      ];
    }
    return [0, 0, 0];
  }

  Future<List<Kejadian>> fetchKejadianWithNotification() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/kejadian?is_notifikasi=true'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final kejadianList = data
            .map((item) {
              try {
                if (item != null) {
                  return Kejadian.fromMap(item);
                } else {
                  throw Exception('Item is null');
                }
              } catch (e) {
                print("Error mapping item: $e");
                return null;
              }
            })
            .where((item) => item != null)
            .toList();

        return kejadianList.cast<Kejadian>();
      } else {
        throw Exception(
            'Failed to load kejadians with notification, status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching kejadian with notification data: $e");
      throw Exception('Failed to load kejadian with notification data');
    }
  }

  Future<void> sendNotification(
      String kejadianId, String title, String message) async {
    log("ini kejadian ${kejadianId}");
    final url = Uri.parse('$baseUrl/send-notification');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'kejadian_id': kejadianId,
        'title': title,
        'message': message,
      }),
    );

    log(response.statusCode.toString());

    if (response.statusCode == 200) {
      log('Notification sent successfully!');
    } else {
      log('Failed to send notification: ${response.body}');
    }
  }

  Future<bool> updateFcmToken(String satpamId, String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/satpam/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'satpam_id': satpamId,
          'fcm_token': fcmToken,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  Future<String?> getFcmTokenBySatpamId(String satpamId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/satpam/$satpamId/fcm-token'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['fcm_token'];
      }
      return null;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> refreshPatroliStats() async {
    try {
      // Get the current date in YYYY-MM-DD format
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);

      // Make API call to refresh stats
      final response = await http.get(
        Uri.parse('$baseUrl/api/patroli/stats?date=$formattedDate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        log('[DEBUG] Stats refreshed successfully');
      } else {
        log('[ERROR] Failed to refresh stats: ${response.statusCode}');
      }
    } catch (e) {
      log('[ERROR] Error refreshing stats: $e');
    }
  }

  Future<String?> _compressAndSaveImage(File imageFile) async {
    try {
      log('[DEBUG] Starting image compression...');

      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        log('[ERROR] Failed to decode image');
        return null;
      }

      // Calculate new dimensions while maintaining aspect ratio
      int maxWidth = 800; // Reduced from 1280 to 800
      int maxHeight = 800; // Reduced from 1280 to 800

      double aspectRatio = image.width / image.height;
      int targetWidth = image.width;
      int targetHeight = image.height;

      if (image.width > maxWidth) {
        targetWidth = maxWidth;
        targetHeight = (maxWidth / aspectRatio).round();
      }

      if (targetHeight > maxHeight) {
        targetHeight = maxHeight;
        targetWidth = (maxHeight * aspectRatio).round();
      }

      // Resize image if needed
      final resizedImage = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedPath =
          path.join(tempDir.path, 'compressed_$timestamp.jpg');

      // Save compressed image with quality 70 (reduced from 85)
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(
        img.encodeJpg(resizedImage, quality: 70),
      );

      // Get file size before and after compression
      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();

      log('[DEBUG] Image compression completed:');
      log('[DEBUG] Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      log('[DEBUG] Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      log('[DEBUG] Compression ratio: ${(compressedSize / originalSize * 100).toStringAsFixed(2)}%');

      return compressedPath;
    } catch (e, stackTrace) {
      log('[ERROR] Failed to compress image: $e');
      log('[STACKTRACE] $stackTrace');
      return null;
    }
  }

  Future<String?> uploadCheckpointPhoto({
    required File photoFile,
    required String patroliId,
    required String checkpointId,
  }) async {
    try {
      log('[DEBUG] Starting photo upload process...');

      // Validate file size before compression
      final fileSize = await photoFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        // 5MB limit before compression
        log('[ERROR] File size too large before compression: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        throw Exception('Ukuran file foto terlalu besar (maksimal 5MB)');
      }

      // Compress the image
      final compressedPath = await _compressAndSaveImage(photoFile);
      if (compressedPath == null) {
        throw Exception('Gagal mengompres foto');
      }

      final compressedFile = File(compressedPath);
      final compressedSize = await compressedFile.length();

      // Validate compressed file size (reduced from 2MB to 1MB)
      if (compressedSize > 1 * 1024 * 1024) {
        // 1MB limit after compression
        log('[ERROR] Compressed file still too large: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        await compressedFile.delete(); // Clean up
        throw Exception(
            'Ukuran file foto masih terlalu besar setelah kompresi (maksimal 1MB)');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/patroli/upload-checkpoint-photo'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      // Add fields
      request.fields['patroli_id'] = patroliId;
      request.fields['checkpoint_id'] = checkpointId;

      // Add compressed file
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          compressedPath,
        ),
      );

      log('[DEBUG] Sending upload request...');
      log('[DEBUG] Request fields: ${request.fields}');
      log('[DEBUG] File size being uploaded: ${(compressedSize / 1024).toStringAsFixed(2)} KB');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Clean up compressed file
      await compressedFile.delete();

      if (response.statusCode == 200) {
        try {
          var jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true &&
              jsonResponse['data']?['url'] != null) {
            return jsonResponse['data']['url'];
          } else {
            throw Exception(jsonResponse['message'] ?? 'Gagal mengupload foto');
          }
        } catch (e) {
          log('[ERROR] Error parsing JSON response: $e');
          throw Exception('Gagal memproses respons server');
        }
      } else {
        try {
          var errorResponse = json.decode(response.body);
          throw Exception(errorResponse['message'] ??
              'Gagal mengupload foto (${response.statusCode})');
        } catch (e) {
          throw Exception('Gagal mengupload foto (${response.statusCode})');
        }
      }
    } catch (e) {
      log('[ERROR] Error uploading checkpoint photo: $e');
      rethrow; // Rethrow to handle in the UI
    }
  }

  Future<String?> uploadPhoto(String kejadianId, File photoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/kejadian/upload-photo'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photoFile.path,
          filename: path.basename(photoFile.path),
        ),
      );

      request.fields['kejadian_id'] = kejadianId;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return jsonResponse['data']['url'];
      } else {
        print('Upload failed: ${jsonResponse['message']}');
        return null;
      }
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  Future<List<String>> uploadMultiplePhotos(
      String kejadianId, List<File> photos) async {
    List<String> uploadedUrls = [];

    for (var photo in photos) {
      String? url = await uploadPhoto(kejadianId, photo);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // Kejadian Methods
  Future<Map<String, dynamic>> saveKejadian(
      Map<String, dynamic> kejadianData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kejadian/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(kejadianData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save kejadian: ${response.body}');
      }
    } catch (e) {
      print('Error saving kejadian: $e');
      rethrow;
    }
  }

  Future<void> updateKejadian(
      String kejadianId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kejadian/update/$kejadianId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update kejadian: ${response.body}');
      }
    } catch (e) {
      print('Error updating kejadian: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getKejadianDetail(String kejadianId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kejadian/detail/$kejadianId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get kejadian detail: ${response.body}');
      }
    } catch (e) {
      print('Error getting kejadian detail: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllKejadian() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kejadian'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get kejadian list: ${response.body}');
      }
    } catch (e) {
      print('Error getting kejadian list: $e');
      rethrow;
    }
  }

  Future<List<PatroliCheckpoint>> getCheckpointsByPatroliId(
      String patroliId) async {
    try {
      log('[DEBUG] Fetching checkpoints for patroli ID: $patroliId');
      final response = await http.get(
        Uri.parse('$baseUrl/patroli/$patroliId/checkpoints'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      log('[DEBUG] Response status code: ${response.statusCode}');
      log('[DEBUG] Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        log('[DEBUG] Decoded response data: $responseData');

        // Handle both array and object responses
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
          log('[DEBUG] Response is a list with ${data.length} items');
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'] is List ? responseData['data'] : [];
          log('[DEBUG] Response contains data field with ${data.length} items');
        } else {
          data = [];
          log('[DEBUG] No valid data found in response');
        }

        final checkpoints = data.map((json) {
          try {
            // Ensure json is a Map<String, dynamic>
            if (json is Map) {
              // Convert all keys to strings and handle null values
              final Map<String, dynamic> typedJson = {};
              json.forEach((key, value) {
                if (key != null) {
                  typedJson[key.toString()] = value;
                }
              });

              log('[DEBUG] Processing checkpoint JSON: $typedJson');

              final checkpoint = PatroliCheckpoint.fromJson(typedJson);
              log('[DEBUG] Successfully created checkpoint:');
              log('[DEBUG] - ID: ${checkpoint.id}');
              log('[DEBUG] - Name: ${checkpoint.checkpointName}');
              log('[DEBUG] - Status: ${checkpoint.status}');
              log('[DEBUG] - Distance Status: ${checkpoint.distanceStatus}');
              log('[DEBUG] - Is Late: ${checkpoint.isLate}');

              return checkpoint;
            }
            throw Exception('Invalid checkpoint data format');
          } catch (e, stackTrace) {
            log('[ERROR] Error parsing checkpoint: $e');
            log('[ERROR] Stack trace: $stackTrace');
            rethrow;
          }
        }).toList();

        log('[DEBUG] Successfully processed ${checkpoints.length} checkpoints');
        return checkpoints;
      } else {
        log('[ERROR] Failed to load checkpoints: ${response.statusCode}');
        log('[ERROR] Error response body: ${response.body}');
        throw Exception('Failed to load checkpoints: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('[ERROR] Error fetching checkpoints: $e');
      log('[ERROR] Stack trace: $stackTrace');
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPatroliHistory(
      String satpamId) async {
    try {
      log('[DEBUG] Fetching patroli history for satpam ID: $satpamId');

      final response = await http.get(
        Uri.parse('$baseUrl/patroli/history/$satpamId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      log('[DEBUG] Response status code: ${response.statusCode}');
      log('[DEBUG] Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        log('[DEBUG] Decoded response data: $responseData');

        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
          log('[DEBUG] Response is a list with ${data.length} items');
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'] is List ? responseData['data'] : [];
          log('[DEBUG] Response contains data field with ${data.length} items');
        } else {
          data = [];
          log('[DEBUG] No valid data found in response');
        }

        final patroliList = data.map((json) {
          try {
            if (json is Map) {
              final Map<String, dynamic> typedJson = {};
              json.forEach((key, value) {
                if (key != null) {
                  typedJson[key.toString()] = value;
                }
              });

              log('[DEBUG] Processing patroli JSON: $typedJson');
              return typedJson;
            }
            throw Exception('Invalid patroli data format');
          } catch (e, stackTrace) {
            log('[ERROR] Error parsing patroli: $e');
            log('[ERROR] Stack trace: $stackTrace');
            rethrow;
          }
        }).toList();

        log('[DEBUG] Successfully processed ${patroliList.length} patroli records');
        return patroliList;
      } else {
        log('[ERROR] Failed to load patroli history: ${response.statusCode}');
        log('[ERROR] Error response body: ${response.body}');
        throw Exception(
            'Failed to load patroli history: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('[ERROR] Error fetching patroli history: $e');
      log('[ERROR] Stack trace: $stackTrace');
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> savePatroli(
      Map<String, dynamic> patroliData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patroli/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(patroliData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save patroli: ${response.body}');
      }
    } catch (e) {
      log('Error saving patroli: $e');
      rethrow;
    }
  }
}
