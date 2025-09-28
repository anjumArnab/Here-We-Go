import 'package:flutter/material.dart';
import 'package:herewego/services/location_service.dart';
import '../views/room_history_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocationService _locationService = LocationService();

  // Location settings
  bool _autoShareLocation = true;
  bool _highAccuracyGPS = true;
  bool _backgroundLocation = true;

  // Loading states
  bool _isLeavingRoom = false;
  bool _isUpdatingSettings = false;

  @override
  void initState() {
    super.initState();
    _locationService.addListener(_onLocationServiceChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationServiceChanged);
    super.dispose();
  }

  void _onLocationServiceChanged() {
    if (mounted) {
      setState(() {
        // UI will rebuild with new data from LocationService
      });
    }
  }

  void _loadSettings() {
    // Load settings from LocationService or shared preferences
    setState(() {
      // These could be loaded from SharedPreferences or LocationService
      _highAccuracyGPS = true; // Default to high accuracy
      _autoShareLocation = true; // Default to auto-share
      _backgroundLocation = true; // Default to background location
    });
  }

  Future<void> _updateLocationSettings() async {
    if (_isUpdatingSettings) return;

    setState(() {
      _isUpdatingSettings = true;
    });

    try {
      // If currently sharing location, restart with new settings
      if (_locationService.isSharing) {
        await _locationService.stopLocationSharing();
        await _locationService.startLocationSharing(
          highAccuracy: _highAccuracyGPS,
          updateInterval: 5000, // 5 seconds
        );
        _showSnackBar('Location settings updated', isError: false);
      }
    } catch (e) {
      _showSnackBar('Failed to update location settings: ${e.toString()}');
    } finally {
      setState(() {
        _isUpdatingSettings = false;
      });
    }
  }

  Future<void> _leaveRoom() async {
    final confirm = await _showLeaveRoomDialog();
    if (!confirm) return;

    setState(() {
      _isLeavingRoom = true;
    });

    try {
      await _locationService.leaveRoom();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showSnackBar('Left room successfully', isError: false);
      }
    } catch (e) {
      setState(() {
        _isLeavingRoom = false;
      });
      _showSnackBar('Error leaving room: ${e.toString()}');
    }
  }

  Future<bool> _showLeaveRoomDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Leave Room'),
              content: Text(
                'Are you sure you want to leave the current room? Your location sharing will stop.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Leave',
                    style: TextStyle(color: Color(0xFFE74C3C)),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = _getCurrentUserName();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
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
                  // Handle name update - this would require server support
                  Navigator.of(context).pop();
                  _showSnackBar('Profile updated', isError: false);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showChangeConnectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Change Connection'),
            content: Text(
              'To change server connection, you need to leave the current room and connect to a different server from the home screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _leaveRoom();
                },
                child: Text('Leave Room', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  String _getCurrentUserName() {
    return _locationService.currentUserName ?? 'Unknown User';
  }

  String _getCurrentRoomId() {
    return _locationService.currentRoomId ?? 'No Room';
  }

  String _getCurrentRoomName() {
    return _locationService.currentRoom?.name ?? 'Unknown Room';
  }

  String _getCurrentServerUrl() {
    return _locationService.serverUrl ?? 'No Connection';
  }

  String _getUserInitials() {
    final name = _getCurrentUserName();
    if (name.isEmpty || name == 'Unknown User') return 'U';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

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

                      // Current Location Status
                      if (_locationService.isSharing)
                        _buildCurrentLocationSection(),

                      if (_locationService.isSharing) SizedBox(height: 24),

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
                      _buildMenuItemWithArrow(
                        "Help & Support",
                        onTap: () {
                          _showHelpDialog();
                        },
                      ),

                      SizedBox(height: 32),

                      // Leave Room Button (only show if in a room)
                      if (_locationService.currentRoomId != null)
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
                  _getUserInitials(),
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
                    _getCurrentUserName(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _locationService.isConnected
                        ? 'Connected to room'
                        : 'Not connected',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _locationService.isConnected
                              ? Colors.green[600]
                              : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Edit button
            TextButton(
              onPressed: _showEditProfileDialog,
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
            subtitle: "Automatically start sharing when joining rooms",
            value: _autoShareLocation,
            onChanged: (value) {
              setState(() {
                _autoShareLocation = value;
              });
              // Save to preferences here
            },
          ),
          SizedBox(height: 12),
          _buildToggleItem(
            title: "High accuracy GPS",
            subtitle: "Use GPS for more precise location (uses more battery)",
            value: _highAccuracyGPS,
            onChanged: (value) {
              setState(() {
                _highAccuracyGPS = value;
              });
              _updateLocationSettings();
            },
          ),
          SizedBox(height: 12),
          _buildToggleItem(
            title: "Background location",
            subtitle: "Continue sharing when app is in background",
            value: _backgroundLocation,
            onChanged: (value) {
              setState(() {
                _backgroundLocation = value;
              });
              // This would require additional configuration
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
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _locationService.isConnected
                            ? Colors.green
                            : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _locationService.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _locationService.isConnected
                            ? Colors.green[700]
                            : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room: ${_getCurrentRoomName()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ID: ${_getCurrentRoomId()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Server: ${_getCurrentServerUrl()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showChangeConnectionDialog,
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

  Widget _buildCurrentLocationSection() {
    final location = _locationService.currentLocation;

    return _buildSection(
      title: "Current Location",
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Sharing Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            if (location != null) ...[
              SizedBox(height: 8),
              Text(
                'Accuracy: ${location.accuracy.toInt()}m',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Updated: ${_formatTime(location.timestamp)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (location.speed != null && location.speed! > 0)
                Text(
                  'Speed: ${(location.speed! * 3.6).toStringAsFixed(1)} km/h',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
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
    String? subtitle,
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _isUpdatingSettings ? null : onChanged,
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
      onTap: onTap,
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
        onPressed: _isLeavingRoom ? null : _leaveRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFEBEE),
          foregroundColor: Color(0xFFE74C3C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child:
            _isLeavingRoom
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFE74C3C),
                    ),
                  ),
                )
                : Text(
                  'Leave Room',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Help & Support'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HereWeGo Location Sharing',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Join or create rooms to share location'),
                Text('• Toggle location sharing on/off'),
                Text('• View friends on map in real-time'),
                Text('• Adjust GPS accuracy settings'),
                SizedBox(height: 16),
                Text(
                  'Need more help?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Contact support or check documentation online.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
