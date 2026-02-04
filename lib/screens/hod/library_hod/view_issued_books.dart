import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewIssuedBooksPage extends StatelessWidget {
  const ViewIssuedBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Issued Books"), backgroundColor: Colors.blue),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("issued_books").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final books = snapshot.data!.docs;

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text("Book: ${data['bookId']}"),
                  subtitle: Text("Student: ${data['studentId']}\nReturned: ${data['returned']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
