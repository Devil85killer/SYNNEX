import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      'Dashboard',             // 0
      'Manage Departments',    // 1
      'Manage Courses',        // 2
      'Approve Students',      // 3
      'Routine',               // 4
      'Attendance',            // 5
      'Complaints',            // 6
      'All Alumni',            // 7
      'All Jobs',              // 8  ⭐ NEW ⭐
      'Logout',                // 9
    ];

    return Container(
      width: 230,
      color: Colors.blue.shade800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          for (var i = 0; i < menuItems.length; i++)
            ListTile(
              selected: i == selectedIndex,
              selectedTileColor: Colors.blue.shade600,
              title: Text(
                menuItems[i],
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight:
                      i == selectedIndex ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () => onItemSelected(i),
            ),
        ],
      ),
    );
  }
}
