import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentBooksPage extends StatefulWidget {
  const StudentBooksPage({super.key});

  @override
  State<StudentBooksPage> createState() => _StudentBooksPageState();
}

class _StudentBooksPageState extends State<StudentBooksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Library Books"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Available Books"),
            Tab(text: "Issued Books"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _availableBooks(),
          _issuedBooks(),
        ],
      ),
    );
  }

  /// 📚 AVAILABLE BOOKS (FROM LIBRARY)
  Widget _availableBooks() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('library_books')
          .where('available', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No books available"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: const Icon(Icons.book, color: Colors.blue),
                title: Text(data['title'] ?? ''),
                subtitle: Text(
                  "Author: ${data['author'] ?? ''}\n"
                  "Edition: ${data['edition'] ?? ''}\n"
                  "Available: ${data['available']}",
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 📕 ISSUED BOOKS (STUDENT ONLY)
  Widget _issuedBooks() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('library_issued_books')
          .where('userType', isEqualTo: 'Student')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No books issued to you"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.purple),
                title: Text(data['bookTitle'] ?? ''),
                subtitle: Text(
                  "Issued On: ${data['issuedAt'] != null ? (data['issuedAt'] as Timestamp).toDate().toString().substring(0, 10) : '-'}\n"
                  "Status: ${data['returned'] ? 'Returned' : 'Issued'}",
                ),
                trailing: data['returned']
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.pending, color: Colors.orange),
              ),
            );
          },
        );
      },
    );
  }
}
