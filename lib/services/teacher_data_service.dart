import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 current teacher info
  Future<Map<String, dynamic>?> getCurrentTeacher() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('teachers').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// 🔹 All available books
  Stream<QuerySnapshot> availableBooks() {
    return _db
        .collection('library_books')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  /// 🔹 Issued books for teacher
  Stream<QuerySnapshot> issuedBooks() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('library_issued')
        .where('userType', isEqualTo: 'teacher')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  /// 🔹 Exam results (view only)
  Stream<QuerySnapshot> examResults({
    required String course,
    required String branch,
  }) {
    return _db
        .collection('exam_results')
        .where('course', isEqualTo: course)
        .where('branch', isEqualTo: branch)
        .where('published', isEqualTo: true)
        .snapshots();
  }
}
