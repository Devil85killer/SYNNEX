import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb ke liye zaroori hai

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize(String chatifyUserId, String jwt, String baseUrl) async {
    // 1. Request Permission (Browser/Phone aapse permission mangega)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true, 
      announcement: false, 
      badge: true, 
      carPlay: false,
      criticalAlert: false, 
      provisional: false, 
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');

      // 2. Get Token (Web ke liye VAPID key ke saath)
      String? token;
      
      try {
        if (kIsWeb) {
          // 🔥 WEB SPECIFIC: VAPID Key yahan lagayi hai
          token = await _fcm.getToken(
            vapidKey: "BO7k7SfDVXPv4KjKgsO_ShKHN2CuaRZpCnAg5Tk4zBSVbnRzY21wVLHAp1sAeFshMAfE2pniSYDPtY73vmyL6_E",
          );
        } else {
          // Mobile (Android/iOS) ke liye normal token
          token = await _fcm.getToken();
        }

        if (token != null) {
          print("🔥 FCM Token Generated: $token");
          // 3. Send to Backend (MongoDB mein save karne ke liye)
          await _saveToken(token, chatifyUserId, jwt, baseUrl);
        }
      } catch (e) {
        print("❌ Error fetching FCM token: $e");
      }
    } else {
      print('❌ User declined or has not accepted permission');
    }
  }

  static Future<void> _saveToken(String token, String userId, String jwt, String baseUrl) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/update-fcm"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwt"
        },
        body: jsonEncode({
          "chatifyUserId": userId,
          "fcmToken": token,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Token successfully synced with Backend");
      } else {
        print("❌ Backend Error: ${response.body}");
      }
    } catch (e) {
      print("❌ Error calling update-fcm API: $e");
    }
  }
}