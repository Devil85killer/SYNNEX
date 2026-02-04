import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountFeePage extends StatelessWidget {
  const AccountFeePage({super.key});

  // 🔒 TEMP: abhi hardcoded, baad me login se aayega
  final bool isHOD = true; // 👈 ONLY HOD CAN EDIT

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Fees"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('student_fees').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No fee records found"));
          }

          final fees = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fees.length,
            itemBuilder: (context, index) {
              final data = fees[index].data() as Map<String, dynamic>;

              final name = data['studentName'] ?? '';
              final total = data['totalFee'] ?? 0;
              final paid = data['paidFee'] ?? 0;
              final pending = total - paid;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Total: ₹$total\nPaid: ₹$paid\nPending: ₹$pending",
                  ),
                  trailing: isHOD
                      ? IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          tooltip: "Edit Fee (HOD only)",
                          onPressed: () {
                            _editFeeDialog(
                              context,
                              fees[index].id,
                              total,
                              paid,
                            );
                          },
                        )
                      : const Icon(Icons.lock, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================= EDIT DIALOG (HOD ONLY) =================
  void _editFeeDialog(
    BuildContext context,
    String docId,
    int totalFee,
    int paidFee,
  ) {
    final TextEditingController paidController =
        TextEditingController(text: paidFee.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Paid Fee"),
        content: TextField(
          controller: paidController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Paid Amount",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPaid = int.tryParse(paidController.text) ?? paidFee;

              await FirebaseFirestore.instance
                  .collection('student_fees')
                  .doc(docId)
                  .update({
                'paidFee': newPaid,
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
