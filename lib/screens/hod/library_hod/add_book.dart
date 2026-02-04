import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final title = TextEditingController();
  final author = TextEditingController();
  final stock = TextEditingController();

  Future<void> addBook() async {
    await FirebaseFirestore.instance.collection("books").add({
      "title": title.text,
      "author": author.text,
      "stock": int.parse(stock.text),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Book Added")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Book"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: "Book Title")),
          TextField(controller: author, decoration: const InputDecoration(labelText: "Author")),
          TextField(controller: stock, decoration: const InputDecoration(labelText: "Stock")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: addBook, child: const Text("Add Book"))
        ]),
      ),
    );
  }
}
