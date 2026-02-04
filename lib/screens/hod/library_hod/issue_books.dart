import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IssueBooksPage extends StatefulWidget {
  const IssueBooksPage({super.key});

  @override
  State<IssueBooksPage> createState() => _IssueBooksPageState();
}

class _IssueBooksPageState extends State<IssueBooksPage> {
  final studentId = TextEditingController();
  final bookId = TextEditingController();

  Future<void> issueBook() async {
    await FirebaseFirestore.instance.collection("issued_books").add({
      "studentId": studentId.text.trim(),
      "bookId": bookId.text.trim(),
      "issueDate": DateTime.now().toString(),
      "returned": false,
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Book Issued")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Issue Book"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: studentId, decoration: const InputDecoration(labelText: "Student UID")),
          TextField(controller: bookId, decoration: const InputDecoration(labelText: "Book ID")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: issueBook, child: const Text("Issue Book"))
        ]),
      ),
    );
  }
}
