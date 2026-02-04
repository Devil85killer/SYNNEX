import 'package:flutter/material.dart';

// ACCOUNTS PAGES
import 'account_fee.dart';
import 'account_transaction.dart';
import 'account_profile.dart';
import 'account_login.dart';

class AccountDashboard extends StatelessWidget {
  const AccountDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accounts Department"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            tooltip: "My Profile",
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountLogin(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _dashboardCard(
              context,
              icon: Icons.credit_card,
              title: "Student Fees",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountFeePage(),
                  ),
                );
              },
            ),
            _dashboardCard(
              context,
              icon: Icons.history,
              title: "Transactions",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountTransactionPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= DASHBOARD CARD =================
  Widget _dashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
