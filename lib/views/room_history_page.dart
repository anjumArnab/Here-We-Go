import 'package:flutter/material.dart';
import 'package:herewego/widgets/room_tile.dart';

class RoomHistoryPage extends StatefulWidget {
  const RoomHistoryPage({super.key});

  @override
  State<RoomHistoryPage> createState() => _RoomHistoryPageState();
}

class _RoomHistoryPageState extends State<RoomHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Room History'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Items
              RoomTile(
                avatar: 'R1',
                avatarColor: const Color(0xFF4A90E2),
                title: 'room_123',
                subtitle: '3 participants • 2 hours ago',
                url: 'https://abc123.ngrok.io',
                status: 'Rejoin',
                statusColor: const Color(0xFF4A90E2),
              ),

              RoomTile(
                avatar: 'R2',
                avatarColor: const Color(0xFFFF9500),
                title: 'ROOM-2024-XYZ',
                subtitle: '5 participants • Yesterday',
                url: 'https://def456.ngrok.io',
                status: 'Offline',
                statusColor: const Color(0xFF999999),
              ),

              RoomTile(
                avatar: 'R3',
                avatarColor: const Color(0xFFFF3B30),
                title: 'weekend_trip',
                subtitle: '2 participants • Last week',
                url: 'https://ghi789.ngrok.io',
                status: 'Expired',
                statusColor: const Color(0xFF999999),
              ),

              const SizedBox(height: 32),

              // Clear All History Button
              Center(
                child: TextButton(
                  onPressed: () {
                    _showClearHistoryDialog();
                  },
                  child: const Text(
                    'Clear All History',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All History'),
          content: const Text(
            'Are you sure you want to clear all room history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Add your clear history logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared successfully')),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
