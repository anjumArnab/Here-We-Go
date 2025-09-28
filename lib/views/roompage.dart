import 'package:flutter/material.dart';
import 'package:herewego/models/connected_user.dart';
import 'package:herewego/widgets/user_tile.dart';
import '../views/map_view.dart';
import '../views/settings_page.dart';
import '../widgets/action_button.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  String roomId = "room_123";
  bool isConnectedToServer = true;
  bool isLocationSharing = false;

  List<ConnectedUser> connectedUsers = [
    ConnectedUser(
      name: "John Doe",
      isCurrentUser: true,
      locationStatus: LocationStatus.ready,
      initials: "JD",
      avatarColor: Color(0xFF4A90E2),
    ),
    ConnectedUser(
      name: "Alice Smith",
      isCurrentUser: false,
      locationStatus: LocationStatus.sharing,
      initials: "AS",
      avatarColor: Color(0xFFFF9500),
    ),
    ConnectedUser(
      name: "Bob Johnson",
      isCurrentUser: false,
      locationStatus: LocationStatus.waiting,
      initials: "BJ",
      avatarColor: Color(0xFFE74C3C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Room: $roomId'),
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
            // Connection Status
            _buildConnectionStatus(),

            // Connected Users List
            Expanded(
              child: ListView.builder(
                itemCount: connectedUsers.length,
                itemBuilder: (context, index) {
                  return UserTile(user: connectedUsers[index]);
                },
              ),
            ),

            // Bottom Buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFD4F7DC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(0xFF2ECC71),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Connected to server',
            style: TextStyle(
              color: Color(0xFF27AE60),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Start Sharing Location button
          ActionButton(
            text:
                isLocationSharing
                    ? 'Stop Sharing Location'
                    : 'Start Sharing Location',
            onPressed: () {
              setState(() {
                isLocationSharing = !isLocationSharing;
                // Update current user's status using copyWith
                connectedUsers[0] = connectedUsers[0].copyWith(
                  locationStatus:
                      isLocationSharing
                          ? LocationStatus.sharing
                          : LocationStatus.ready,
                );
              });
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => MapView()));
            },
            isPrimary: true,
          ),

          SizedBox(height: 12),

          // Room Settings button
          ActionButton(
            text: "Room Settings",
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => SettingsPage()));
            },
            isPrimary: false,
          ),
        ],
      ),
    );
  }
}
