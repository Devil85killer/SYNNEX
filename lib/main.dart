import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO; // ✅ Socket Import
import 'firebase_options.dart';

// ✅ WebRTC Service Import
import 'services/webrtc_service.dart';

// ================= STUDENT =================
import 'student/student_login.dart';
import 'student/student_dashboard.dart';

// ================= TEACHER =================
import 'screens/teacher/teacher_login.dart';
import 'screens/teacher/teacher_dashboard.dart';

// ================= ALUMNI =================
import 'screens/alumni/alumni_login.dart';
import 'screens/alumni/alumni_dashboard.dart';

// ================= ADMIN =================
import 'screens/admin/admin_login.dart';
import 'screens/admin/admin_dashboard.dart';

// ================= DEPARTMENT =================
import 'screens/department/department_login.dart';

// 🔥 GLOBAL NAVIGATOR KEY (Iska use karke hum notification dikhayenge)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔥 GLOBAL SOCKET VARIABLE
IO.Socket? socket;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SynergyApp());
}

/// 🔥 SOCKET CONNECTION FUNCTION (FINAL FIX)
void connectSocket(String token, String myMongoId) {
  // ⚠️ SERVER URL
  String socketUrl = 'https://synnex.onrender.com'; 

  // 1. ✅ SMART CHECK: Agar pehle se connected hai, toh dobara connect mat karo,
  // bas server ko bata do ki "Main hoon" (Setup Event).
  if (socket != null && socket!.connected) {
    print("⚠️ Socket already active. Forcing 'setup' for ID: $myMongoId");
    socket!.emit("setup", myMongoId); 
    return;
  }

  // 2. Agar connected nahi hai par object hai, toh saaf karo
  if (socket != null) {
    socket!.disconnect();
    socket = null;
  }

  try {
    print("🔌 Connecting to Socket: $socketUrl with ID: $myMongoId");

    socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableForceNew() // 🔥 Force New Connection (Zaroori hai)
        .setAuth({'token': token}) 
        .build());

    socket!.connect();

    socket!.onConnect((_) {
      print("✅ Socket Connected: ${socket!.id}");
      
      // 🔥 USER REGISTER KARNA (Sabse Important Line)
      print("📢 Sending 'setup' event for User: $myMongoId");
      socket!.emit("setup", myMongoId); 
      
      // WebRTC Init
      WebRTCService().init(socket);
    });

    socket!.onConnectError((data) => print("❌ Socket Connection Error: $data"));
    socket!.onDisconnect((_) => print("❌ Socket Disconnected"));

    // 📞 INCOMING CALL LISTENER
    socket!.on("incoming_call", (data) {
      print("🔔 Incoming Call Received: $data");

      // 🔥 UI NOTIFICATION (Web par pata chalega call aayi hai)
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text("📞 Incoming Call from ${data['callerId']}..."),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10), // 10 seconds tak dikhega
            action: SnackBarAction(
              label: "ANSWER",
              textColor: Colors.white,
              onPressed: () {
                // Future: Yahan se direct answer handle kar sakte ho
              },
            ),
          ),
        );
      }

      WebRTCService().handleIncomingCall(data);
    });

    socket!.on("call_error", (data) {
      print("❌ Call Error: $data");
    });

  } catch (e) {
    print("⚠️ Socket Logic Error: $e");
  }
}

class SynergyApp extends StatelessWidget {
  const SynergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Synergy Institute App",
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // 🔥 Ye zaroori hai SnackBar ke liye
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
      home: const WelcomePage(),
      routes: {
        '/student_login': (_) => const StudentLoginPage(),
        '/teacher_login': (_) => const TeacherLogin(),
        '/alumni_login': (_) => const AlumniLoginPage(),
        '/admin_login': (_) => const AdminLoginPage(),
        '/department_login': (_) => const DepartmentLogin(),
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Widget loginButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          height: 110,
          width: 280,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.blue),
                const SizedBox(width: 14),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("WELCOME TO SYNERGY INSTITUTE", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              loginButton(title: "Student Login", icon: Icons.school, onTap: () => Navigator.pushNamed(context, '/student_login')),
              const SizedBox(height: 15),
              loginButton(title: "Teacher Login", icon: Icons.person, onTap: () => Navigator.pushNamed(context, '/teacher_login')),
              const SizedBox(height: 15),
              loginButton(title: "Alumni Login", icon: Icons.people_alt, onTap: () => Navigator.pushNamed(context, '/alumni_login')),
              const SizedBox(height: 15),
              loginButton(title: "Admin Login", icon: Icons.admin_panel_settings, onTap: () => Navigator.pushNamed(context, '/admin_login')),
              const SizedBox(height: 15),
              loginButton(title: "Department Login", icon: Icons.account_balance, onTap: () => Navigator.pushNamed(context, '/department_login')),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}