import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryIssuedBooksPage extends StatefulWidget {
  const LibraryIssuedBooksPage({Key? key}) : super(key: key);

  @override
  State<LibraryIssuedBooksPage> createState() =>
      _LibraryIssuedBooksPageState();
}

class _LibraryIssuedBooksPageState extends State<LibraryIssuedBooksPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String userType = 'Student';
  String? selectedCourse;
  String? selectedBranch;
  String? selectedYear;
  String? selectedSection;

  String? selectedUserId;
  String? selectedUserName;
  String? selectedBookTitle;

  final sections = ['A', 'B', 'C'];

  // 🔹 QUERY FOR STUDENT / TEACHER
  Query getUserQuery() {
    if (userType == 'Student') {
      return _db
          .collection('students')
          .where('course', isEqualTo: selectedCourse)
          .where('branch', isEqualTo: selectedBranch)
          .where('year', isEqualTo: selectedYear)
          .where('section', isEqualTo: selectedSection);
    } else {
      return _db
          .collection('teachers')
          .where('course', isEqualTo: selectedCourse)
          .where('branch', isEqualTo: selectedBranch);
    }
  }

  // 🔹 BOOK SELECT DIALOG
  void showBookSelectDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StreamBuilder<QuerySnapshot>(
          stream: _db.collection('library_books').snapshots(),
          builder: (_, s) {
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (s.data!.docs.isEmpty) {
              return const Center(child: Text("No books available"));
            }

            return ListView(
              children: s.data!.docs.map((doc) {
                final book = doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(book['title']),
                  subtitle: Text("Author: ${book['author']}"),
                  onTap: () {
                    setState(() {
                      selectedBookTitle = book['title'];
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // 🔹 ISSUE BOOK
  Future<void> issueBook(Map<String, dynamic> userData) async {
    if (selectedBookTitle == null ||
        selectedUserId == null ||
        selectedUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select user & book first")),
      );
      return;
    }

    await _db.collection('library_issued_books').add({
      'userId': selectedUserId,
      'userType': userType,
      'name': selectedUserName,
      'course': userData['course'],
      'branch': userData['branch'],
      'year': userType == 'Student' ? userData['year'] : null,
      'section': userType == 'Student' ? userData['section'] : null,
      'bookTitle': selectedBookTitle,
      'issuedAt': FieldValue.serverTimestamp(),
      'issuedBy': _auth.currentUser?.email,
      'returned': false,
    });

    setState(() {
      selectedBookTitle = null;
      selectedUserId = null;
      selectedUserName = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Book issued successfully 📚")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Library Issue Books"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // 🔹 FILTERS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField(
                  value: userType,
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      userType = v!;
                      selectedYear = null;
                      selectedSection = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: "User Type"),
                ),

                const SizedBox(height: 8),

                // COURSE
                StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('courses').snapshots(),
                  builder: (_, s) {
                    if (!s.hasData) return const SizedBox();
                    return DropdownButtonFormField(
                      value: selectedCourse,
                      items: s.data!.docs
                          .map((d) =>
                              DropdownMenuItem(value: d.id, child: Text(d.id)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedCourse = v;
                          selectedBranch = null;
                        });
                      },
                      decoration:
                          const InputDecoration(labelText: "Course"),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // BRANCH
                if (selectedCourse != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('courses')
                        .doc(selectedCourse)
                        .collection('branches')
                        .snapshots(),
                    builder: (_, s) {
                      if (!s.hasData) return const SizedBox();
                      return DropdownButtonFormField(
                        value: selectedBranch,
                        items: s.data!.docs
                            .map((d) => DropdownMenuItem(
                                value: d.id, child: Text(d.id)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedBranch = v),
                        decoration:
                            const InputDecoration(labelText: "Branch"),
                      );
                    },
                  ),

                if (userType == 'Student')
                  DropdownButtonFormField(
                    value: selectedYear,
                    items: const [
                      DropdownMenuItem(
                          value: '1st Year', child: Text('1st Year')),
                      DropdownMenuItem(
                          value: '2nd Year', child: Text('2nd Year')),
                      DropdownMenuItem(
                          value: '3rd Year', child: Text('3rd Year')),
                      DropdownMenuItem(
                          value: '4th Year', child: Text('4th Year')),
                    ],
                    onChanged: (v) => setState(() => selectedYear = v),
                    decoration: const InputDecoration(labelText: "Year"),
                  ),

                if (userType == 'Student')
                  DropdownButtonFormField(
                    value: selectedSection,
                    items: sections
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text("Section $s")))
                        .toList(),
                    onChanged: (v) => setState(() => selectedSection = v),
                    decoration:
                        const InputDecoration(labelText: "Section"),
                  ),
              ],
            ),
          ),

          // 🔹 USER LIST
          Expanded(
            child: (selectedCourse == null ||
                    selectedBranch == null ||
                    (userType == 'Student' &&
                        (selectedYear == null || selectedSection == null)))
                ? const Center(child: Text("Select filters"))
                : StreamBuilder<QuerySnapshot>(
                    stream: getUserQuery().snapshots(),
                    builder: (_, s) {
                      if (!s.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (s.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("No users found"));
                      }

                      return ListView(
                        children: s.data!.docs.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(data['name']),
                              subtitle: Text(
                                userType == 'Student'
                                    ? "Roll: ${data['rollNo']} | ${data['section']}"
                                    : "Employee ID: ${data['employeeId']}",
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.book),
                                onPressed: () {
                                  setState(() {
                                    selectedUserId = doc.id;
                                    selectedUserName = data['name'];
                                  });
                                  showBookSelectDialog();
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),

          // 🔹 SELECTED BOOK + CONFIRM
          if (selectedBookTitle != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    "Selected Book: $selectedBookTitle",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => issueBook({
                      'course': selectedCourse,
                      'branch': selectedBranch,
                      'year': selectedYear,
                      'section': selectedSection,
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text("Confirm Issue"),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
