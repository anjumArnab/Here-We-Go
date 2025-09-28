import 'package:flutter/material.dart';
import '../views/room_history_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool autoShareLocation = true;
  bool highAccuracyGPS = false;
  bool backgroundLocation = true;

  String userName = "John Doe";
  String userEmail = "john.doe@gmail.com";
  String currentRoom = "room_123";
  String serverUrl = "https://abc123.ngrok.io";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Settings Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      _buildProfileSection(),

                      SizedBox(height: 24),

                      // Location Settings Section
                      _buildLocationSettingsSection(),

                      SizedBox(height: 24),

                      // Connection Section
                      _buildConnectionSection(),

                      SizedBox(height: 24),

                      // Room History
                      _buildMenuItemWithArrow(
                        "Room History",
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RoomHistoryPage(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 16),

                      // Help & Support
                      _buildMenuItemWithArrow("Help & Support"),

                      SizedBox(height: 32),

                      // Leave Room Button
                      _buildLeaveRoomButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildSection(
      title: "Profile",
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'JD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Edit button
            TextButton(
              onPressed: () {
                // Handle edit profile
                print('Edit profile pressed');
              },
              child: Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSettingsSection() {
    return _buildSection(
      title: "Location Settings",
      child: Column(
        children: [
          _buildToggleItem(
            title: "Auto-share location",
            value: autoShareLocation,
            onChanged: (value) {
              setState(() {
                autoShareLocation = value;
              });
            },
          ),
          SizedBox(height: 12),
          _buildToggleItem(
            title: "High accuracy GPS",
            value: highAccuracyGPS,
            onChanged: (value) {
              setState(() {
                highAccuracyGPS = value;
              });
            },
          ),
          SizedBox(height: 12),
          _buildToggleItem(
            title: "Background location",
            value: backgroundLocation,
            onChanged: (value) {
              setState(() {
                backgroundLocation = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSection() {
    return _buildSection(
      title: "Connection",
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Room: $currentRoom',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Server: $serverUrl',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle change connection
                    print('Change connection pressed');
                  },
                  child: Text(
                    'Change',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildToggleItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: Colors.black87)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF2ECC71),
            activeTrackColor: Color(0xFF2ECC71).withOpacity(0.3),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemWithArrow(String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            print('$title pressed');
          },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: Colors.black87)),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRoomButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Handle leave room
          _showLeaveRoomDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFEBEE),
          foregroundColor: Color(0xFFE74C3C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          'Leave Room',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showLeaveRoomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Leave Room'),
          content: Text('Are you sure you want to leave the current room?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle actual leave room logic
                print('User left the room');
              },
              child: Text('Leave', style: TextStyle(color: Color(0xFFE74C3C))),
            ),
          ],
        );
      },
    );
  }
}
