import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'fee_structure.dart';
import 'student_fee_status.dart';
import 'add_fine.dart';

class AccountsHODDashboard extends StatelessWidget {
  const AccountsHODDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/hod_login', (route) => false);
  }

  Widget dashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: Colors.blue.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accounts HOD Dashboard"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.1,
          children: [
            dashboardCard(
              icon: Icons.attach_money,
              label: "Fee Structure",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeeStructurePage()),
              ),
            ),
            dashboardCard(
              icon: Icons.list_alt,
              label: "Students Fee Status",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentFeeStatusPage()),
              ),
            ),
            dashboardCard(
              icon: Icons.money_off,
              label: "Add Fine",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFinePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
