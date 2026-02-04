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

// 🔥 1. GLOBAL NAVIGATOR KEY (Call Screen Popup ke liye zaroori)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔥 2. GLOBAL SOCKET VARIABLE (Puri App mein access karne ke liye)
IO.Socket? socket;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 FIREBASE INIT
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SynergyApp());
}

/// 🔥 3. SOCKET CONNECTION FUNCTION
/// Is function ko apne Login Page par call karna jab user login ho jaye (Token milne ke baad).
void connectSocket(String token) {
  if (socket != null && socket!.connected) return;

  // ⚠️ IMPORTANT: Replace '192.168.1.5' with your PC's IP address.
  // If using Android Emulator, use 'http://10.67.251.188:3000'
  // If using Web, use 'http://localhost:3000'
  String socketUrl = 'http://localhost:3000'; // Change based on platform

  socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({'token': token}) // JWT Token bhejna zaroori hai
      .build());

  socket!.connect();

  socket!.onConnect((_) {
    print("✅ Socket Connected via main.dart: ${socket!.id}");
    
    // ✅ 4. INIT WEBRTC SERVICE
    WebRTCService().init(socket);
  });

  socket!.onDisconnect((_) => print("❌ Socket Disconnected"));

  // ✅ 5. GLOBAL LISTENER FOR INCOMING CALLS
  socket!.on("incoming_call", (data) {
    print("🔔 Incoming Call Received globally: $data");
    WebRTCService().handleIncomingCall(data);
  });
}

class SynergyApp extends StatelessWidget {
  const SynergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Synergy Institute App",
      debugShowCheckedModeBanner: false,

      // 🔥 6. KEY LINK KARO
      navigatorKey: navigatorKey,

      // ✅ LOCALIZATION
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],

      // ✅ WELCOME PAGE
      home: const WelcomePage(),

      routes: {
        // -------- STUDENT --------
        '/student_login': (_) => const StudentLoginPage(),
        '/student_dashboard': (_) => StudentDashboard(),

        // -------- TEACHER --------
        '/teacher_login': (_) => const TeacherLogin(),
        '/teacher_dashboard': (_) => TeacherDashboard(),

        // -------- ALUMNI --------
        '/alumni_login': (_) => const AlumniLoginPage(),
        '/alumni_dashboard': (_) => AlumniDashboard(),

        // -------- ADMIN --------
        '/admin_login': (_) => const AdminLoginPage(),
        '/admin_dashboard': (_) => AdminDashboard(),

        // -------- DEPARTMENT --------
        '/department_login': (_) => const DepartmentLogin(),
      },
    );
  }
}

// =======================================
//            WELCOME PAGE
// =======================================

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Widget loginButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: SizedBox(
          height: 110,
          width: 280,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.blue),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "WELCOME TO SYNERGY INSTITUTE OF ENGINEERING & TECHNOLOGY",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            loginButton(
              title: "Student Login",
              icon: Icons.school,
              onTap: () => Navigator.pushNamed(context, '/student_login'),
            ),
            const SizedBox(height: 15), // Spacing
            loginButton(
              title: "Teacher Login",
              icon: Icons.person,
              onTap: () => Navigator.pushNamed(context, '/teacher_login'),
            ),
            const SizedBox(height: 15),
            loginButton(
              title: "Alumni Login",
              icon: Icons.people_alt,
              onTap: () => Navigator.pushNamed(context, '/alumni_login'),
            ),
            const SizedBox(height: 15),
            loginButton(
              title: "Admin Login",
              icon: Icons.admin_panel_settings,
              onTap: () => Navigator.pushNamed(context, '/admin_login'),
            ),
            const SizedBox(height: 15),
            loginButton(
              title: "Department Login",
              icon: Icons.account_balance,
              onTap: () => Navigator.pushNamed(context, '/department_login'),
            ),
          ],
        ),
      ),
    );
  }
}