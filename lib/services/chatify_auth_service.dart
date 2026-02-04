import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatifyAuthService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api";
    } else {
      return "http://10.67.251.188:3000/api";
    }
  }

  static Future<Map<String, dynamic>> syncUser({
    required User firebaseUser,
    required String role, 
    required String name,
  }) async {
    String? fcmToken;
    
    // 🔥 1. FCM Setup & Permission (Web Fix)
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Web/iOS ke liye permission maangna zaroori hai
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 User granted notification permission');
        
        // 🔥 VAPID Key (Sirf Web ke liye zaroori hai)
        // Ye key tumhare project se mili hai
        const String webVapidKey = "BO7k7SfDVXPv4KjKgsO_ShKHN2CuaRZpCnAg5Tk4zBSVbnRzY21wVLHAp1sAeFshMAfE2pniSYDPtY73vmyL6_E";

        // Token fetch karo (Web ke liye VAPID key pass hogi, Mobile ke liye null)
        fcmToken = await messaging.getToken(
          vapidKey: kIsWeb ? webVapidKey : null,
        );
      } else {
        debugPrint('❌ User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint("❌ Error fetching FCM token: $e");
    }

    debugPrint("📱 FINAL FCM TOKEN TO SEND: $fcmToken");

    // 🔥 2. Backend Sync API Call
    final uri = Uri.parse("$baseUrl/auth/sync-user");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "firebaseUid": firebaseUser.uid,
        "email": firebaseUser.email,
        "name": name,
        "role": role,
        "fcmToken": fcmToken, // ✅ Ab ye Web par bhi NULL nahi hoga
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Chatify sync failed: ${res.body}");
    }

    final data = jsonDecode(res.body);

    final chatifyUserId = data["user"]["chatifyUserId"];
    final token = data["token"];

    if (chatifyUserId == null || token == null) {
      throw Exception("Invalid Chatify response: Missing IDs or Token");
    }

    String collection;
    if (role == "student") {
      collection = "students";
    } else if (role == "teacher") {
      collection = "teachers";
    } else {
      collection = "alumni_users";
    }

    // 💾 3. Firestore Updates
    await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid)
        .set({"role": role}, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(firebaseUser.uid)
        .set(
      {
        "chatifyUserId": chatifyUserId,
        "chatifyJwt": token,
        "fcmToken": fcmToken, // ✅ Firestore mein backup
      },
      SetOptions(merge: true),
    );

    debugPrint("✅ CHATIFY SYNC DONE → Correct ID Saved: $chatifyUserId");

    return {
      "chatifyUserId": chatifyUserId,
      "token": token,
    };
  }
}