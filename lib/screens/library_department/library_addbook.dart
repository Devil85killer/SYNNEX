import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryAddBookPage extends StatefulWidget {
  const LibraryAddBookPage({Key? key}) : super(key: key);

  @override
  State<LibraryAddBookPage> createState() => _LibraryAddBookPageState();
}

class _LibraryAddBookPageState extends State<LibraryAddBookPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final title = TextEditingController();
  final author = TextEditingController();
  final edition = TextEditingController();
  final quantity = TextEditingController();

  Future<void> addBook() async {
    await _db.collection('library_books').add({
      'title': title.text.trim(),
      'author': author.text.trim(),
      'edition': edition.text.trim(),
      'quantity': int.tryParse(quantity.text) ?? 0,
      'available': int.tryParse(quantity.text) ?? 0,
      'addedBy': _auth.currentUser?.email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Book"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: author, decoration: const InputDecoration(labelText: "Author")),
            TextField(controller: edition, decoration: const InputDecoration(labelText: "Edition")),
            TextField(
              controller: quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addBook,
              child: const Text("Add Book"),
            ),
          ],
        ),
      ),
    );
  }
}
