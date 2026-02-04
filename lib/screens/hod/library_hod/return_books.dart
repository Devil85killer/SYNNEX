import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnBooksPage extends StatelessWidget {
  const ReturnBooksPage({super.key});

  Future<void> returnBook(String id, BuildContext ctx) async {
    await FirebaseFirestore.instance.collection("issued_books").doc(id).update({
      "returned": true,
      "returnDate": DateTime.now().toString(),
    });

    ScaffoldMessenger.of(ctx)
        .showSnackBar(const SnackBar(content: Text("Book Returned")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Return Books"), backgroundColor: Colors.blue),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("issued_books")
            .where("returned", isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final books = snapshot.data!.docs;

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text("Book ID: ${data['bookId']}"),
                  subtitle: Text("Student: ${data['studentId']}"),
                  trailing: ElevatedButton(
                    onPressed: () => returnBook(data.id, context),
                    child: const Text("Return"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
