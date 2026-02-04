import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStudentToDepartment({
    required String studentUid,
    required String department, // library | exam | accounts
  }) async {
    final adminDoc = await _firestore
        .collection('admin_students')
        .doc(studentUid)
        .get();

    if (!adminDoc.exists) {
      throw Exception('Student not found in admin_students');
    }

    final studentData = adminDoc.data()!;

    await _firestore
        .collection('${department}_students')
        .doc(studentUid)
        .set({
      ...studentData,
      'addedAt': FieldValue.serverTimestamp(),
      'source': 'admin',
    });
  }
}
