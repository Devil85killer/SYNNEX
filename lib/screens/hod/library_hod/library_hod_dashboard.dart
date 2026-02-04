import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'issue_books.dart';
import 'return_books.dart';
import 'view_issued_books.dart';
import 'add_book.dart';

class LibraryHODDashboard extends StatelessWidget {
  const LibraryHODDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/hod_login', (route) => false);
  }

  Widget card({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        color: Colors.blue.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
        title: const Text("Library HOD Dashboard"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          card(
              icon: Icons.library_add,
              label: "Add Book",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookPage()))),
          card(
              icon: Icons.book,
              label: "Issue Book",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssueBooksPage()))),
          card(
              icon: Icons.assignment_return,
              label: "Return Book",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReturnBooksPage()))),
          card(
              icon: Icons.list,
              label: "Issued Books",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewIssuedBooksPage()))),
        ],
      ),
    );
  }
}
