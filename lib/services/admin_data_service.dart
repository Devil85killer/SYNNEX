import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Get all departments
  Stream<List<String>> getDepartments() {
    return _firestore.collection('departments').snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toList(),
        );
  }

  /// 🔹 Get branches of a department
  Stream<List<String>> getBranches(String department) {
    return _firestore
        .collection('departments')
        .doc(department)
        .collection('branches')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => d.id).toList(),
        );
  }

  /// 🔹 Get students
  Stream<List<Map<String, dynamic>>> getStudents({
    required String department,
    required String branch,
  }) {
    return _firestore
        .collection('departments')
        .doc(department)
        .collection('branches')
        .doc(branch)
        .collection('students')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {
                    'id': d.id,
                    ...d.data(),
                  })
              .toList(),
        );
  }

  /// 🔹 Get teachers
  Stream<List<Map<String, dynamic>>> getTeachers({
    required String department,
    required String branch,
  }) {
    return _firestore
        .collection('departments')
        .doc(department)
        .collection('branches')
        .doc(branch)
        .collection('teachers')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {
                    'id': d.id,
                    ...d.data(),
                  })
              .toList(),
        );
  }
}
