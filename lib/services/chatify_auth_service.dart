import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatifyAuthService {
  // ✅ Backend URL
  static String get baseUrl {
    return "https://synnex.onrender.com/api";
  }

  static Future<Map<String, dynamic>> syncUser({
    required User firebaseUser,
    required String role, 
    required String name,
  }) async {
    String? fcmToken;
    
    debugPrint("\n=================================================");
    debugPrint("🚀 STARTING CHATIFY AUTH PROCESS");
    debugPrint("=================================================");

    // -----------------------------------------------------------
    // 🔥 EVENT 1: GENERATING FCM TOKEN
    // -----------------------------------------------------------
    debugPrint("👉 STEP 1: Generating FCM Token...");
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Web VAPID Key (Only needed for Web)
        const String webVapidKey = "BO7k7SfDVXPv4KjKgsO_ShKHN2CuaRZpCnAg5Tk4zBSVbnRzY21wVLHAp1sAeFshMAfE2pniSYDPtY73vmyL6_E";
        fcmToken = await messaging.getToken(vapidKey: kIsWeb ? webVapidKey : null);
        
        debugPrint("✅ FCM TOKEN GENERATED!");
        debugPrint("🔑 TOKEN: $fcmToken");
      } else {
        debugPrint("⚠️ Permission Denied.");
      }
    } catch (e) {
      debugPrint("❌ FCM ERROR: $e");
    }

    // -----------------------------------------------------------
    // 🔥 EVENT 2: SENDING DATA TO BACKEND
    // -----------------------------------------------------------
    final uri = Uri.parse("$baseUrl/auth/sync-user");
    
    debugPrint("\n👉 STEP 2: Connecting to Backend Server...");
    debugPrint("🌐 URL: $uri");
    debugPrint("📤 Uploading Data: Name: $name | Role: $role");

    try {
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uid": firebaseUser.uid,
          "firebaseUid": firebaseUser.uid,
          "email": firebaseUser.email,
          "name": name,
          "role": role,
          "fcmToken": fcmToken,
        }),
      );

      debugPrint("\n👉 STEP 3: Server Response Received");
      debugPrint("📡 Status Code: ${res.statusCode}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint("❌ FAILURE: ${res.body}");
        throw Exception("Sync Failed: ${res.body}");
      }

      final data = jsonDecode(res.body);
      final chatifyUserId = data['user']['_id'] ?? data['user']['chatifyUserId'];
      final token = data['token'];

      if (chatifyUserId == null) {
        throw Exception("Missing ID from Backend");
      }

      // -----------------------------------------------------------
      // 🔥 EVENT 4: DETAILED STORAGE REPORT (UPDATED)
      // -----------------------------------------------------------
      
      String mongoCollection = "users"; 
      String firestoreCollection = role == "student" ? "students" : 
                                  (role == "teacher" ? "teachers" : "alumni_users");

      debugPrint("\n✅ ✅ LOGIN & SYNC SUCCESSFUL!");
      debugPrint("=================================================");
      debugPrint("📂 DATABASE STORAGE REPORT (SABOOT)");
      debugPrint("=================================================");
      debugPrint("1️⃣  USER PROFILE (Your Data):");
      debugPrint("    📍 MongoDB Collection  : '$mongoCollection'");
      debugPrint("    📍 Firestore Collection: '$firestoreCollection'");
      debugPrint("    🆔 Chat ID (Mongo)     : $chatifyUserId");
      
      debugPrint("\n2️⃣  MESSAGES KAHAN STORE HO RAHE HAIN? (Check Here):");
      debugPrint("    📂 Collection Name : 'messages'"); // ✅ Collection Name
      debugPrint("    📍 Location        : MongoDB Compass -> Database 'synnex'");
      debugPrint("    💾 Data Fields     : { text: 'Hi', senderId: '...', roomId: '...' }");
      debugPrint("    ⚠️ Note            : This collection is created automatically when the first message is sent.");

      debugPrint("\n3️⃣  KIS SE BAAT KI (Chat History):");
      debugPrint("    📂 Collection Name : 'chatrooms'");
      debugPrint("    💾 Data Structure  : { participants: [User1, User2] }");

      debugPrint("\n4️⃣  NOTIFICATIONS (FCM):");
      debugPrint("    📍 Saved In        : MongoDB 'users' collection");
      debugPrint("=================================================\n");

      // -----------------------------------------------------------
      // 🔥 EVENT 5: LOCAL STORAGE
      // -----------------------------------------------------------
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', chatifyUserId);
      await prefs.setString('token', token);
      await prefs.setString('name', name);
      await prefs.setString('role', role);

      // -----------------------------------------------------------
      // 🔥 EVENT 6: FIRESTORE SYNC
      // -----------------------------------------------------------
      await FirebaseFirestore.instance.collection("users").doc(firebaseUser.uid).set({"role": role}, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection(firestoreCollection).doc(firebaseUser.uid).set(
        {
          "chatifyUserId": chatifyUserId,
          "chatifyJwt": token,
          "fcmToken": fcmToken,
        },
        SetOptions(merge: true),
      );

      debugPrint("🎉 PROCESS FINISHED SUCCESSFULLY\n");

      return {
        "chatifyUserId": chatifyUserId,
        "token": token,
      };

    } catch (e) {
      debugPrint("❌ ERROR: $e");
      return {};
    }
  }
}