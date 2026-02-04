import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  static Stream<QuerySnapshot> getJobs() {
    return FirebaseFirestore.instance
        .collection("jobs")
        .orderBy("postedAt", descending: true)
        .snapshots();
  }
}
