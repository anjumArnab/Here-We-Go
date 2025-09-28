import 'package:flutter/material.dart';
import 'package:herewego/widgets/action_button.dart';
import 'package:herewego/widgets/input_field.dart';

class RoomCreationPage extends StatefulWidget {
  const RoomCreationPage({super.key});

  @override
  State<RoomCreationPage> createState() => _RoomCreationPageState();
}

class _RoomCreationPageState extends State<RoomCreationPage> {
  final TextEditingController serverUrlController = TextEditingController();
  final TextEditingController roomNameController = TextEditingController();
  final TextEditingController roomIdController = TextEditingController();

  bool autoStartLocationSharing = true;
  bool showRouteBetweenUsers = true;
  bool roomExpires24Hours = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with default values
    serverUrlController.text = 'https://abc123.ngrok.io';
    roomNameController.text = 'Friends Meetup';
  }

  @override
  void dispose() {
    serverUrlController.dispose();
    roomNameController.dispose();
    roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Create Room'),
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
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and subtitle
                      _buildTitleSection(),

                      SizedBox(height: 32),

                      // Server URL field
                      InputField(
                        label: 'Server URL',
                        controller: serverUrlController,
                      ),

                      SizedBox(height: 20),

                      // Room Name field
                      InputField(
                        label: 'Room Name (Optional)',
                        controller: roomNameController,
                      ),

                      SizedBox(height: 20),
                      // Room Settings section
                      _buildRoomSettingsSection(),

                      SizedBox(height: 40),

                      // Create Room button
                      ActionButton(
                        onPressed: () {
                          // Handle create room action
                          _createRoom();
                        },
                        text: 'Create Room',
                      ),
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

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Set up a new room for location sharing',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoomSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Room Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(height: 12),
        _buildToggleItem(
          title: "Room expires in 24 hours",
          value: roomExpires24Hours,
          onChanged: (value) {
            setState(() {
              roomExpires24Hours = value;
            });
          },
        ),
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
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
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

  void _createRoom() {
    // Validate inputs
    if (serverUrlController.text.trim().isEmpty) {
      _showSnackBar('Please enter a server URL');
      return;
    }

    if (roomIdController.text.trim().isEmpty) {
      _showSnackBar('Room ID cannot be empty');
      return;
    }

    // Create room logic here
    print('Creating room with:');
    print('Server URL: ${serverUrlController.text}');
    print(
      'Room Name: ${roomNameController.text.isEmpty ? 'Unnamed Room' : roomNameController.text}',
    );
    print('Room ID: ${roomIdController.text}');
    print('Auto-start location sharing: $autoStartLocationSharing');
    print('Show route between users: $showRouteBetweenUsers');
    print('Room expires in 24 hours: $roomExpires24Hours');

    // Show success message
    _showSnackBar('Room created successfully!');

    // Navigate back or to room page
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RoomPage()));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
