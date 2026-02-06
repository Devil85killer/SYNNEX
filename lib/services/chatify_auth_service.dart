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

  // 🔥 UPDATED SYNC FUNCTION WITH CALLBACK & SPEED OPTIMIZATION
  static Future<Map<String, dynamic>> syncUser({
    required User firebaseUser,
    required String role, 
    required String name,
    required Function(String message) onStatusChange, // 🗣️ UI Update Callback
  }) async {
    String? fcmToken;
    
    debugPrint("\n=================================================");
    debugPrint("🚀 STARTING CHATIFY AUTH PROCESS");
    debugPrint("=================================================");
    
    // -----------------------------------------------------------
    // 🔥 EVENT 1: GENERATING FCM TOKEN (Optimized with Timeout)
    // -----------------------------------------------------------
    onStatusChange("👉 STEP 1: Generating FCM Token..."); // UI Update
    
    try {
      // ⚡ FAST: 2 second se jyada wait nahi karega
      fcmToken = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 2), 
        onTimeout: () => null
      );
      
      if (fcmToken != null) {
        debugPrint("✅ FCM TOKEN GENERATED: $fcmToken");
      } else {
        debugPrint("⚠️ FCM Token skipped (Timeout)");
      }
    } catch (e) {
      debugPrint("❌ FCM ERROR: $e");
    }

    // -----------------------------------------------------------
    // 🔥 EVENT 2: SENDING DATA TO BACKEND
    // -----------------------------------------------------------
    final uri = Uri.parse("$baseUrl/auth/sync-user");
    
    onStatusChange("👉 STEP 2: Connecting to Backend Server..."); // UI Update
    debugPrint("🌐 URL: $uri");

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

      onStatusChange("👉 STEP 3: Server Response Received"); // UI Update
      debugPrint("📡 Status Code: ${res.statusCode}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("Sync Failed: ${res.body}");
      }

      final data = jsonDecode(res.body);
      final chatifyUserId = data['user']['_id'] ?? data['user']['chatifyUserId'];
      final token = data['token'];

      if (chatifyUserId == null) {
        throw Exception("Missing ID from Backend");
      }

      // -----------------------------------------------------------
      // 🔥 EVENT 3: BACKGROUND SAVING (FIRE & FORGET)
      // -----------------------------------------------------------
      onStatusChange("💾 Saving Data in Background..."); // UI Update
      
      // Ye function background mein chalega, hum user ko wait nahi karayenge
      _saveDataInBackground(
        chatifyUserId: chatifyUserId, 
        token: token, 
        name: name, 
        role: role, 
        firebaseUser: firebaseUser, 
        fcmToken: fcmToken
      );

      // ✅ SUCCESS MESSAGE
      onStatusChange("✅ Login Successful! Welcome $name");
      
      // Thoda sa delay taaki user message padh sake
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        "chatifyUserId": chatifyUserId,
        "token": token,
      };

    } catch (e) {
      debugPrint("❌ ERROR: $e");
      onStatusChange("❌ Error: ${e.toString()}");
      return {};
    }
  }

  // 🔄 BACKGROUND TASK: Ye UI block nahi karega
  static void _saveDataInBackground({
    required String chatifyUserId,
    required String token,
    required String name,
    required String role,
    required User firebaseUser,
    String? fcmToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String firestoreCollection = role == "student" ? "students" : 
                                  (role == "teacher" ? "teachers" : "alumni_users");

      debugPrint("⏳ Background Save Started...");

      // ⚡ PARALLEL EXECUTION: Sab kuch ek saath save hoga
      await Future.wait([
        // 1. Local Storage
        prefs.setString('uid', chatifyUserId),
        prefs.setString('token', token),
        prefs.setString('name', name),
        prefs.setString('role', role),

        // 2. Firestore Sync
        FirebaseFirestore.instance.collection("users").doc(firebaseUser.uid).set(
          {"role": role}, SetOptions(merge: true)
        ),
        
        // 3. Firestore Collection Sync
        FirebaseFirestore.instance.collection(firestoreCollection).doc(firebaseUser.uid).set(
          {
            "chatifyUserId": chatifyUserId,
            "chatifyJwt": token,
            "fcmToken": fcmToken,
          },
          SetOptions(merge: true),
        )
      ]);

      debugPrint("🎉 Background Data Saved Successfully!");
      
    } catch (e) {
      debugPrint("⚠️ Background Save Error: $e");
    }
  }
}