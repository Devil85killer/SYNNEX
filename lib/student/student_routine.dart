import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentRoutinePage extends StatelessWidget {
  const StudentRoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Routine"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: Text(
          "📅 Routine Coming Soon...",
          style: GoogleFonts.poppins(fontSize: 20, color: Colors.blueGrey),
        ),
      ),
    );
  }
}
