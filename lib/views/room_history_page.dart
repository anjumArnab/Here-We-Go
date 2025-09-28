import 'package:flutter/material.dart';
import 'package:herewego/services/location_service.dart';
import 'package:herewego/widgets/room_tile.dart';
import 'package:herewego/views/roompage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RoomHistoryItem {
  final String roomId;
  final String roomName;
  final String serverUrl;
  final DateTime joinedAt;
  final DateTime lastActive;
  final int participantCount;
  final bool wasCreator;

  RoomHistoryItem({
    required this.roomId,
    required this.roomName,
    required this.serverUrl,
    required this.joinedAt,
    required this.lastActive,
    required this.participantCount,
    required this.wasCreator,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'serverUrl': serverUrl,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'participantCount': participantCount,
      'wasCreator': wasCreator,
    };
  }

  factory RoomHistoryItem.fromJson(Map<String, dynamic> json) {
    return RoomHistoryItem(
      roomId: json['roomId'] ?? '',
      roomName: json['roomName'] ?? 'Unknown Room',
      serverUrl: json['serverUrl'] ?? '',
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
      lastActive: DateTime.tryParse(json['lastActive'] ?? '') ?? DateTime.now(),
      participantCount: json['participantCount'] ?? 0,
      wasCreator: json['wasCreator'] ?? false,
    );
  }
}

class RoomHistoryPage extends StatefulWidget {
  const RoomHistoryPage({super.key});

  @override
  State<RoomHistoryPage> createState() => _RoomHistoryPageState();
}

class _RoomHistoryPageState extends State<RoomHistoryPage> {
  final LocationService _locationService = LocationService();
  List<RoomHistoryItem> _roomHistory = [];
  bool _isLoading = true;
  bool _isRejoining = false;
  String? _rejoiningRoomId;

  @override
  void initState() {
    super.initState();
    _loadRoomHistory();
    _addCurrentRoomToHistory();
  }

  Future<void> _loadRoomHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('room_history') ?? [];

      _roomHistory =
          historyJson
              .map((item) => RoomHistoryItem.fromJson(jsonDecode(item)))
              .toList();

      // Sort by last active (most recent first)
      _roomHistory.sort((a, b) => b.lastActive.compareTo(a.lastActive));
    } catch (e) {
      debugPrint('Error loading room history: $e');
      _roomHistory = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addCurrentRoomToHistory() async {
    if (_locationService.currentRoomId == null) return;

    final currentRoom = RoomHistoryItem(
      roomId: _locationService.currentRoomId!,
      roomName: _locationService.currentRoom?.name ?? 'Current Room',
      serverUrl: _locationService.serverUrl ?? '',
      joinedAt: DateTime.now(),
      lastActive: DateTime.now(),
      participantCount: _locationService.users.length,
      wasCreator: false, // This would need to be tracked in LocationService
    );

    await _saveRoomToHistory(currentRoom);
  }

  Future<void> _saveRoomToHistory(RoomHistoryItem room) async {
    try {
      // Remove existing entry for the same room to avoid duplicates
      _roomHistory.removeWhere(
        (item) =>
            item.roomId == room.roomId && item.serverUrl == room.serverUrl,
      );

      // Add the updated room to the beginning
      _roomHistory.insert(0, room);

      // Keep only the last 20 rooms
      if (_roomHistory.length > 20) {
        _roomHistory = _roomHistory.take(20).toList();
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          _roomHistory.map((item) => jsonEncode(item.toJson())).toList();

      await prefs.setStringList('room_history', historyJson);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error saving room history: $e');
    }
  }

  Future<void> _clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('room_history');

      setState(() {
        _roomHistory.clear();
      });

      _showSnackBar('History cleared successfully', isError: false);
    } catch (e) {
      _showSnackBar('Error clearing history: ${e.toString()}');
    }
  }

  Future<void> _rejoinRoom(RoomHistoryItem room) async {
    if (_isRejoining) return;

    setState(() {
      _isRejoining = true;
      _rejoiningRoomId = room.roomId;
    });

    try {
      // First check if we need to connect to a different server
      bool needsConnection =
          !_locationService.isConnected ||
          _locationService.serverUrl != room.serverUrl;

      if (needsConnection) {
        final connected = await _locationService.connect(room.serverUrl);
        if (!connected) {
          _showSnackBar('Failed to connect to server: ${room.serverUrl}');
          return;
        }
      }

      // Leave current room if in one
      if (_locationService.currentRoomId != null) {
        await _locationService.leaveRoom();
      }

      // Try to join the historical room
      // We need the user's name - get it from current user or prompt
      String userName = _locationService.currentUserName ?? 'User';
      if (userName.isEmpty || userName == 'User') {
        userName = await _promptForUserName();
        if (userName.isEmpty) return;
      }

      final success = await _locationService.joinRoom(
        roomId: room.roomId,
        userName: userName,
      );

      if (success) {
        // Update the room's last active time
        final updatedRoom = RoomHistoryItem(
          roomId: room.roomId,
          roomName: room.roomName,
          serverUrl: room.serverUrl,
          joinedAt: room.joinedAt,
          lastActive: DateTime.now(),
          participantCount: _locationService.users.length,
          wasCreator: room.wasCreator,
        );

        await _saveRoomToHistory(updatedRoom);

        // Navigate to room page
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => RoomPage()),
          );
        }
      } else {
        _showSnackBar(_locationService.lastError ?? 'Failed to join room');
      }
    } catch (e) {
      _showSnackBar('Error rejoining room: ${e.toString()}');
    } finally {
      setState(() {
        _isRejoining = false;
        _rejoiningRoomId = null;
      });
    }
  }

  Future<String> _promptForUserName() async {
    final TextEditingController nameController = TextEditingController();
    String result = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Enter Your Name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please enter your name to rejoin the room:'),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  result = nameController.text.trim();
                  Navigator.of(context).pop();
                },
                child: Text('Join'),
              ),
            ],
          ),
    );

    return result;
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
                _clearAllHistory();
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  String _getRoomStatus(RoomHistoryItem room) {
    // Check if this is the current room
    if (_locationService.currentRoomId == room.roomId &&
        _locationService.serverUrl == room.serverUrl) {
      return 'Current';
    }

    // Check connection status
    if (!_locationService.isConnected ||
        _locationService.serverUrl != room.serverUrl) {
      return 'Rejoin';
    }

    // Default to rejoin for historical rooms
    return 'Rejoin';
  }

  Color _getRoomStatusColor(String status) {
    switch (status) {
      case 'Current':
        return const Color(0xFF2ECC71);
      case 'Rejoin':
        return const Color(0xFF4A90E2);
      case 'Offline':
        return const Color(0xFF999999);
      case 'Expired':
        return const Color(0xFF999999);
      default:
        return const Color(0xFF4A90E2);
    }
  }

  Color _getAvatarColor(String roomId) {
    final colors = [
      const Color(0xFF4A90E2),
      const Color(0xFFFF9500),
      const Color(0xFFE74C3C),
      const Color(0xFF2ECC71),
      const Color(0xFF9B59B6),
      const Color(0xFFF39C12),
      const Color(0xFF1ABC9C),
      const Color(0xFFE67E22),
    ];

    final hash = roomId.hashCode.abs();
    return colors[hash % colors.length];
  }

  String _getRoomInitials(String roomName) {
    if (roomName.isEmpty) return 'R';

    final words = roomName.trim().split(RegExp(r'[_\s]+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return roomName[0].toUpperCase();
  }

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
        actions: [
          if (!_isLoading && _roomHistory.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: _showClearHistoryDialog,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadRoomHistory,
                child:
                    _roomHistory.isEmpty
                        ? _buildEmptyState()
                        : _buildHistoryList(),
              ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No Room History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Rooms you join or create will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._roomHistory.map((room) {
              final status = _getRoomStatus(room);
              final isRejoining =
                  _isRejoining && _rejoiningRoomId == room.roomId;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: RoomTile(
                  avatar: _getRoomInitials(room.roomName),
                  avatarColor: _getAvatarColor(room.roomId),
                  title: room.roomName,
                  subtitle:
                      '${room.participantCount} participants • ${_formatTimeAgo(room.lastActive)}',
                  url: room.serverUrl,
                  status: isRejoining ? 'Joining...' : status,
                  statusColor: _getRoomStatusColor(status),
                  onTap:
                      status == 'Rejoin' && !_isRejoining
                          ? () => _rejoinRoom(room)
                          : null,
                  isLoading: isRejoining,
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // Clear All History Button
            if (_roomHistory.isNotEmpty)
              Center(
                child: TextButton(
                  onPressed: _showClearHistoryDialog,
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
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
