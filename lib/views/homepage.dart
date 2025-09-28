import 'package:flutter/material.dart';
import '../views/room_creation_page.dart';
import '../views/roompage.dart';
import '../widgets/action_button.dart';
import '../widgets/input_field.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController serverUrlController = TextEditingController();
  final TextEditingController roomIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with example data
    serverUrlController.text = 'https://abc123.ngrok.io';
    roomIdController.text = 'room_123';
    nameController.text = 'John Doe';
  }

  @override
  void dispose() {
    serverUrlController.dispose();
    roomIdController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('HereWeGo'),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Connect with Friends',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                // Subtitle
                Text(
                  'Share your location in real-time',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40),

                // Server URL field
                InputField(
                  label: 'Server URL',
                  controller: serverUrlController,
                ),

                SizedBox(height: 20),

                // Room ID field
                InputField(label: 'Room ID', controller: roomIdController),

                SizedBox(height: 20),

                // Your Name field
                InputField(label: 'Your Name', controller: nameController),

                SizedBox(height: 40),

                // Connect button
                ActionButton(
                  text: "Connect",
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (context) => RoomPage()));
                  },
                  isPrimary: true,
                ),

                SizedBox(height: 16),

                // Create New Room button
                ActionButton(
                  text: "Create New Room",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RoomCreationPage(),
                      ),
                    );
                  },
                  isPrimary: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
