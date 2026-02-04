import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard.dart';

class StudentUpdateProfilePage extends StatefulWidget {
  const StudentUpdateProfilePage({super.key});

  @override
  State<StudentUpdateProfilePage> createState() =>
      _StudentUpdateProfilePageState();
}

class _StudentUpdateProfilePageState extends State<StudentUpdateProfilePage> {
  final _parentNameController = TextEditingController();
  final _parentMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodGroupController = TextEditingController();

  DateTime? _dob;
  bool _isLoading = false;

  String? _selectedCourse;
  String? _selectedBranch;
  String? _selectedYear;
  String? _selectedSection;

  List<String> _courses = [];
  List<String> _branches = [];
  List<String> _years = [];
  final List<String> _sections = ["A", "B", "C", "D"];

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
    _loadCourses();
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentMobileController.dispose();
    _addressController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  // ================= FETCH STUDENT =================
  Future<void> _fetchStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    setState(() {
      _parentNameController.text = data['parentName'] ?? '';
      _parentMobileController.text = data['parentMobile'] ?? '';
      _addressController.text = data['address'] ?? '';
      _bloodGroupController.text = data['bloodGroup'] ?? '';
      _selectedCourse = data['course'];
      _selectedBranch = data['branch'];
      _selectedYear = data['year'];
      _selectedSection = data['section'];
      if (data['dob'] != null) {
        _dob = DateTime.tryParse(data['dob']);
      }
    });
  }

  // ================= LOAD COURSES =================
  Future<void> _loadCourses() async {
    final doc = await FirebaseFirestore.instance
        .collection('admin_config')
        .doc('academics')
        .get();

    final map = (doc.data()?['courses'] as Map<String, dynamic>?) ?? {};
    if (!mounted) return;

    setState(() => _courses = map.keys.toList());
  }

  Future<void> _loadBranches(String course) async {
    final doc = await FirebaseFirestore.instance
        .collection('admin_config')
        .doc('academics')
        .get();

    final list =
        (doc.data()?['courses']?[course]?['branches'] as List<dynamic>? ?? [])
            .cast<String>();

    if (!mounted) return;
    setState(() {
      _branches = list;
      _selectedBranch = null;
    });
  }

  Future<void> _loadYears(String course) async {
    final doc = await FirebaseFirestore.instance
        .collection('admin_config')
        .doc('academics')
        .get();

    final total = doc.data()?['courses']?[course]?['years'] ?? 0;

    if (!mounted) return;
    setState(() {
      _years =
          List.generate(total, (i) => "${i + 1}${_suffix(i + 1)} Year");
      _selectedYear = null;
    });
  }

  String _suffix(int n) {
    if (n == 1) return "st";
    if (n == 2) return "nd";
    if (n == 3) return "rd";
    return "th";
  }

  // ================= UPDATE PROFILE =================
  Future<void> _updateProfile() async {
    if (_selectedCourse == null ||
        _selectedBranch == null ||
        _selectedYear == null ||
        _selectedSection == null ||
        _dob == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .set({
      'parentName': _parentNameController.text.trim(),
      'parentMobile': _parentMobileController.text.trim(),
      'address': _addressController.text.trim(),
      'bloodGroup': _bloodGroupController.text.trim(),
      'course': _selectedCourse,
      'branch': _selectedBranch,
      'year': _selectedYear,
      'section': _selectedSection,
      'dob': _dob!.toIso8601String(),
      'uid': user.uid,
      'role': 'student',

      // 🔥 SINGLE SOURCE OF TRUTH
      'profileCompleted': true,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentDashboard()),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _field(_parentNameController, "Parent Name"),
                _field(_parentMobileController, "Parent Mobile"),
                _field(_addressController, "Address"),
                _field(_bloodGroupController, "Blood Group"),

                _dropdown("Select Course", _selectedCourse, _courses, (v) {
                  setState(() {
                    _selectedCourse = v;
                    _branches.clear();
                    _years.clear();
                  });
                  _loadBranches(v!);
                  _loadYears(v);
                }),

                _dropdown("Select Branch", _selectedBranch, _branches,
                    (v) => setState(() => _selectedBranch = v)),

                _dropdown("Select Year", _selectedYear, _years,
                    (v) => setState(() => _selectedYear = v)),

                _dropdown("Select Section", _selectedSection, _sections,
                    (v) => setState(() => _selectedSection = v)),

                const SizedBox(height: 10),
                Text(_dob == null
                    ? "Select DOB"
                    : "${_dob!.day}-${_dob!.month}-${_dob!.year}"),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2003),
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2015),
                    );
                    if (d != null) setState(() => _dob = d);
                  },
                  child: const Text("Pick DOB"),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text("Update Profile"),
                ),
              ]),
            ),
    );
  }

  Widget _field(TextEditingController c, String l) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          decoration:
              InputDecoration(labelText: l, border: OutlineInputBorder()),
        ),
      );

  Widget _dropdown(
    String l,
    String? v,
    List<String> items,
    void Function(String?) onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          value: v,
          decoration:
              InputDecoration(labelText: l, border: OutlineInputBorder()),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      );
}
