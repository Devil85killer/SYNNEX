import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentAttendancePage extends StatelessWidget {
  const StudentAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Report"),
        backgroundColor: Colors.blue.shade700,
      ),
      backgroundColor: Colors.blue.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Attendance Overview",
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900)),
            const SizedBox(height: 20),
            _attendanceRow("January", "95%"),
            _attendanceRow("February", "88%"),
            _attendanceRow("March", "92%"),
            _attendanceRow("April", "98%"),
            _attendanceRow("May", "94%"),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Overall Attendance: 93%",
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _attendanceRow(String month, String percent) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(month,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: Text(percent,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
