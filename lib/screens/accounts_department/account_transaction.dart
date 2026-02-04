import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountTransactionPage extends StatelessWidget {
  const AccountTransactionPage({super.key});

  // 🔒 TEMP: baad me login se aayega
  final bool isHOD = true; // 👈 ONLY HOD CAN ADD

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("College Transactions"),
        backgroundColor: Colors.teal,
        actions: [
          if (isHOD)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Add Transaction (HOD)",
              onPressed: () => _addTransactionDialog(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('account_transactions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No transactions found"));
          }

          final txns = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: txns.length,
            itemBuilder: (context, index) {
              final data = txns[index].data() as Map<String, dynamic>;

              final type = data['type'] ?? 'IN'; // IN / OUT
              final amount = data['amount'] ?? 0;
              final from = data['from'] ?? '';
              final to = data['to'] ?? '';
              final reason = data['reason'] ?? '';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    type == 'IN' ? Icons.arrow_downward : Icons.arrow_upward,
                    color: type == 'IN' ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  title: Text(
                    "₹$amount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    "From: $from\nTo: $to\nReason: $reason",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================= ADD TRANSACTION (HOD ONLY) =================
  void _addTransactionDialog(BuildContext context) {
    final amountController = TextEditingController();
    final fromController = TextEditingController();
    final toController = TextEditingController();
    final reasonController = TextEditingController();
    String type = 'IN';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Transaction"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'IN', child: Text("Money In")),
                  DropdownMenuItem(value: 'OUT', child: Text("Money Out")),
                ],
                onChanged: (v) => type = v!,
                decoration: const InputDecoration(
                  labelText: "Transaction Type",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fromController,
                decoration: const InputDecoration(
                  labelText: "From (payer)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: "To (receiver)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  int.tryParse(amountController.text.trim()) ?? 0;

              await FirebaseFirestore.instance
                  .collection('account_transactions')
                  .add({
                'type': type,
                'amount': amount,
                'from': fromController.text.trim(),
                'to': toController.text.trim(),
                'reason': reasonController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
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
