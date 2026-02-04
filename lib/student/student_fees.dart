import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentFeesPage extends StatelessWidget {
  const StudentFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fees & Payments"),
        backgroundColor: Colors.blue.shade700,
      ),
      backgroundColor: Colors.blue.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Fee Overview",
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _feeCard("Tuition Fee", "₹45,000", Colors.purple.shade100),
                _feeCard("Library Fee", "₹3,000", Colors.orange.shade100),
                _feeCard("Hostel Fee", "₹25,000", Colors.green.shade100),
                _feeCard("Exam Fee", "₹2,000", Colors.red.shade100),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(200, 50)),
                onPressed: () {},
                child: const Text("Pay Now"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _feeCard(String title, String amount, Color color) {
    return Container(
      height: 120,
      width: 230,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text(amount,
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900)),
          ],
        ),
      ),
    );
  }
}
