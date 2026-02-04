import 'package:flutter/material.dart';

class TeacherRoutinePage extends StatelessWidget {
  const TeacherRoutinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Teacher Routine"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "My Class Routine",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: const [
                  RoutineTile(
                    day: "Monday",
                    subject: "Data Structures",
                    time: "10:00 AM - 11:00 AM",
                    room: "Lab 204",
                  ),
                  RoutineTile(
                    day: "Tuesday",
                    subject: "Operating Systems",
                    time: "11:00 AM - 12:00 PM",
                    room: "Room 105",
                  ),
                  RoutineTile(
                    day: "Wednesday",
                    subject: "Database Systems",
                    time: "2:00 PM - 3:00 PM",
                    room: "Room 108",
                  ),
                  RoutineTile(
                    day: "Thursday",
                    subject: "Networks",
                    time: "9:00 AM - 10:00 AM",
                    room: "Room 102",
                  ),
                  RoutineTile(
                    day: "Friday",
                    subject: "AI & ML",
                    time: "12:00 PM - 1:00 PM",
                    room: "Room 210",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutineTile extends StatelessWidget {
  final String day;
  final String subject;
  final String time;
  final String room;

  const RoutineTile({
    Key? key,
    required this.day,
    required this.subject,
    required this.time,
    required this.room,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blue),
        title: Text(
          "$day - $subject",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("$time\nRoom: $room"),
        isThreeLine: true,
      ),
    );
  }
}
