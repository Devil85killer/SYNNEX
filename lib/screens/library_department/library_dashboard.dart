import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// LIBRARY PAGES
import 'library_addbook.dart';
import 'library_books.dart';
import 'library_issued.dart';
import 'library_profile.dart';
import 'library_login.dart';

class LibraryDashboard extends StatelessWidget {
  const LibraryDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Library Department"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            tooltip: "My Profile",
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LibraryProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LibraryLogin(),
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
              icon: Icons.add_box,
              title: "Add Books",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibraryAddBookPage(),
                  ),
                );
              },
            ),
            _dashboardCard(
              icon: Icons.menu_book,
              title: "All Books",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibraryBooksPage(),
                  ),
                );
              },
            ),
            _dashboardCard(
              icon: Icons.assignment_return,
              title: "Issued Books",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibraryIssuedBooksPage(),
                  ),
                );
              },
            ),
            _dashboardCard(
              icon: Icons.person,
              title: "My Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibraryProfilePage(),
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
  Widget _dashboardCard({
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
            Icon(icon, size: 48, color: Colors.purple),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
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
