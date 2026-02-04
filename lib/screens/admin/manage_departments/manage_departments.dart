import 'package:flutter/material.dart';
import 'department_staff.dart';

class ManageDepartments extends StatelessWidget {
  const ManageDepartments({super.key});

  @override
  Widget build(BuildContext context) {
    final departments = [
      {
        'label': 'Accounts Department',
        'collection': 'accounts_department'
      },
      {
        'label': 'Library Department',
        'collection': 'library_department'
      },
      {
        'label': 'Exam Department',
        'collection': 'exam_department'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.2,
        ),
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final dept = departments[index];

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dept['label']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DepartmentStaffPage(
                          departmentName: dept['label']!,
                          collectionName: dept['collection']!,
                        ),
                      ),
                    );
                  },
                  child: const Text("View Staff"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
