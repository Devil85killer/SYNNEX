import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatifyAuthService {
  // ✅ URL Setup (Web & Mobile both point to Render)
  static String get baseUrl {
    return "https://synnex.onrender.com/api";
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
        const String webVapidKey = "BO7k7SfDVXPv4KjKgsO_ShKHN2CuaRZpCnAg5Tk4zBSVbnRzY21wVLHAp1sAeFshMAfE2pniSYDPtY73vmyL6_E";

        // Token fetch karo
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
    
    print("🔄 Syncing User: ${firebaseUser.uid} ($role)");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "uid": firebaseUser.uid,          // ✅ FIX: Backend ye maang raha tha
        "firebaseUid": firebaseUser.uid,  // Backup ke liye rakh lo
        "email": firebaseUser.email,
        "name": name,
        "role": role,
        "fcmToken": fcmToken,             // Web/Mobile token
      }),
    );

    print("📡 Response: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Chatify sync failed: ${res.body}");
    }

    final data = jsonDecode(res.body);

    // ✅ Safety Check: Kabhi kabhi response structure alag ho sakta hai
    // Agar data['user']['_id'] hai toh wo lo, nahi toh data['user']['chatifyUserId']
    final chatifyUserId = data['user']['_id'] ?? data['user']['chatifyUserId'];
    final token = data['token'];

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
        "fcmToken": fcmToken,
      },
      SetOptions(merge: true),
    );

    debugPrint("✅ CHATIFY SYNC DONE → Correct ID Saved: $chatifyUserId");

    // Map return karo taaki login page isme se token nikal sake
    return {
      "chatifyUserId": chatifyUserId,
      "token": token,
    };
  }
}