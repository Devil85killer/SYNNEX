import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_dashboard.dart';

class TeacherUpdateProfile extends StatefulWidget {
  final String userId;
  const TeacherUpdateProfile({super.key, required this.userId});

  @override
  State<TeacherUpdateProfile> createState() => _TeacherUpdateProfileState();
}

class _TeacherUpdateProfileState extends State<TeacherUpdateProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _bloodGroup = TextEditingController();

  bool _saving = false;
  String? _teacherName;
  String? _teacherEmail;

  // 🔹 Dropdown selections
  String? _selectedCourse;
  String? _selectedBranch;

  // 🔹 Data lists
  List<String> _courses = [];
  List<String> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _loadCourses();
  }

  Future<void> _loadTeacherData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        setState(() {
          _teacherName = doc.data()?['name'] ?? '';
          _teacherEmail = doc.data()?['email'] ?? '';
          _mobile.text = doc.data()?['mobile'] ?? '';
          _dob.text = doc.data()?['dob'] ?? '';
          _bloodGroup.text = doc.data()?['bloodGroup'] ?? '';
          _selectedCourse = doc.data()?['course'];
          _selectedBranch = doc.data()?['branch'];
        });

        if (_selectedCourse != null) {
          _loadBranches(_selectedCourse!);
        }
      }
    } catch (e) {
      debugPrint("Error loading teacher data: $e");
    }
  }

  // 🔹 Load courses from Firestore
  Future<void> _loadCourses() async {
    final snapshot = await FirebaseFirestore.instance.collection('courses').get();
    final list = snapshot.docs.map((doc) => doc.id).toList();
    setState(() {
      _courses = list;
    });
  }

  // 🔹 Load branches for selected course
  Future<void> _loadBranches(String course) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(course)
        .collection('branches')
        .get();
    final list = snapshot.docs.map((doc) => doc.id).toList();
    setState(() {
      _branches = list;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourse == null || _selectedBranch == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select Course and Branch")));
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('teachers').doc(widget.userId).set({
        'mobile': _mobile.text.trim(),
        'dob': _dob.text.trim(),
        'bloodGroup': _bloodGroup.text.trim(),
        'course': _selectedCourse,
        'branch': _selectedBranch,
        'profileCompleted': true,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully ✅")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Profile"),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            width: 420,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Teacher Profile",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_teacherName != null && _teacherName!.isNotEmpty)
                    _readonlyField("Full Name", _teacherName!),
                  if (_teacherEmail != null && _teacherEmail!.isNotEmpty)
                    _readonlyField("Email", _teacherEmail!),
                  const SizedBox(height: 10),
                  _inputField("Mobile Number", _mobile, Icons.phone),
                  _inputField("Date of Birth (DD/MM/YYYY)", _dob, Icons.cake),
                  _inputField("Blood Group", _bloodGroup, Icons.bloodtype),

                  // 🔹 Course Dropdown
                  _buildDropdown(
                    label: "Select Course",
                    value: _selectedCourse,
                    items: _courses,
                    onChanged: (value) {
                      setState(() {
                        _selectedCourse = value;
                        _selectedBranch = null;
                      });
                      _loadBranches(value!);
                    },
                  ),

                  // 🔹 Branch Dropdown
                  _buildDropdown(
                    label: "Select Branch",
                    value: _selectedBranch,
                    items: _branches,
                    onChanged: (value) {
                      setState(() {
                        _selectedBranch = value;
                      });
                    },
                  ),

                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon: const Icon(Icons.save),
                    label: _saving
                        ? const Text("Saving...")
                        : const Text("Save Profile", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherDashboard()),
                      );
                    },
                    child: const Text("Go to Dashboard"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        readOnly: true,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.person, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.school, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: items.isEmpty ? null : onChanged,
      ),
    );
  }
}
