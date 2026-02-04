import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryBooksPage extends StatelessWidget {
  const LibraryBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Library Books"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('library_books')
            .orderBy('title')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No books found in library",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final books = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;
              
              // Data safety check (agar koi field missing ho to crash na kare)
              final title = data['title'] ?? 'No Title';
              final author = data['author'] ?? 'Unknown';
              final quantity = data['quantity'] ?? 0;
              final available = data['available'] ?? 0;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: const Icon(Icons.menu_book, color: Colors.purple),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Author: $author"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Qty: $quantity",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Avail: $available",
                        style: TextStyle(
                          color: available > 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
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