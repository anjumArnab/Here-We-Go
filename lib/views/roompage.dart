import 'package:flutter/material.dart';
import '../models/connected_user.dart';
import '../services/location_service.dart';
import '../widgets/user_tile.dart';
import '../views/map_view.dart';
import '../views/settings_page.dart';
import '../widgets/action_button.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  bool _isLeavingRoom = false;
  bool _isTogglingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService.addListener(_onLocationServiceChanged);

    // Refresh room data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRoomData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService.removeListener(_onLocationServiceChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for location sharing
    if (state == AppLifecycleState.paused) {
      // App is going to background - you might want to handle this
    } else if (state == AppLifecycleState.resumed) {
      // App is back to foreground - refresh room data
      _refreshRoomData();
    }
  }

  void _onLocationServiceChanged() {
    if (mounted) {
      setState(() {
        // UI will rebuild with new data from LocationService
      });

      // Handle connection loss
      if (_locationService.connectionStatus == ConnectionStatus.error ||
          _locationService.connectionStatus == ConnectionStatus.disconnected) {
        _handleConnectionLoss();
      }
    }
  }

  void _handleConnectionLoss() {
    // Show dialog or navigate back if connection is lost
    if (_locationService.connectionStatus == ConnectionStatus.disconnected) {
      _showConnectionLostDialog();
    }
  }

  void _showConnectionLostDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Connection Lost'),
            content: Text(
              'You have been disconnected from the server. You will be returned to the home screen.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(
                    context,
                  ).popUntil((route) => route.isFirst); // Return to homepage
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _refreshRoomData() async {
    if (_locationService.isConnected &&
        _locationService.currentRoomId != null) {
      await _locationService.refreshRoomUsers();
    }
  }

  Future<void> _toggleLocationSharing() async {
    if (_isTogglingLocation) return;

    setState(() {
      _isTogglingLocation = true;
    });

    try {
      if (_locationService.isSharing) {
        // Stop location sharing
        await _locationService.stopLocationSharing();
        _showSnackBar('Location sharing stopped', isError: false);
      } else {
        // Start location sharing
        final success = await _locationService.startLocationSharing(
          highAccuracy: true,
          updateInterval: 5000, // 5 seconds
        );

        if (success) {
          _showSnackBar('Location sharing started', isError: false);
        } else {
          _showSnackBar(
            _locationService.lastError ?? 'Failed to start location sharing',
          );
        }
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isTogglingLocation = false;
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
          builder:
              (context) => AlertDialog(
                title: Text('Leave Room'),
                content: Text(
                  'Are you sure you want to leave this room? Your location sharing will stop.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text('Leave'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _navigateToMap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => MapView()));
  }

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => SettingsPage()));
  }

  List<ConnectedUser> _getConnectedUsers() {
    if (_locationService.users.isEmpty) {
      // Return empty list if no users
      return [];
    }

    return _locationService.users.map((user) {
      return ConnectedUser.fromLocationServiceUser(
        user,
        avatarColor: ConnectedUser.generateAvatarColor(user.name),
      );
    }).toList();
  }

  String _getRoomDisplayName() {
    if (_locationService.currentRoom != null) {
      return _locationService.currentRoom!.name;
    }
    return _locationService.currentRoomId ?? 'Unknown Room';
  }

  @override
  Widget build(BuildContext context) {
    final connectedUsers = _getConnectedUsers();
    final roomName = _getRoomDisplayName();

    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        await _leaveRoom();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Room: $roomName'),
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _isLeavingRoom ? null : _leaveRoom,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshRoomData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Connection and Location Status
              _buildStatusSection(),

              // Room Info
              if (_locationService.currentRoom != null) _buildRoomInfo(),

              // Connected Users List
              Expanded(child: _buildUsersList(connectedUsers)),

              // Bottom Buttons
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          // Connection Status
          _buildConnectionStatus(),

          // Location Sharing Status
          if (_locationService.isSharing) ...[
            SizedBox(height: 8),
            _buildLocationStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected =
        _locationService.connectionStatus == ConnectionStatus.connected;
    final statusColor = isConnected ? Color(0xFF2ECC71) : Colors.red;
    final statusText = isConnected ? 'Connected to server' : 'Connection error';
    final bgColor = isConnected ? Color(0xFFD4F7DC) : Colors.red[50];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border:
            isConnected ? null : Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_locationService.lastError != null)
            Icon(Icons.error_outline, color: Colors.red, size: 16),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Color(0xFF2196F3), size: 16),
          SizedBox(width: 8),
          Text(
            'Sharing location',
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          if (_locationService.currentLocation != null)
            Text(
              'Accuracy: ${_locationService.currentLocation!.accuracy.toInt()}m',
              style: TextStyle(color: Color(0xFF1976D2), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomInfo() {
    final room = _locationService.currentRoom!;
    final userCount = _locationService.users.length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.group, color: Colors.grey[600], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '$userCount ${userCount == 1 ? 'person' : 'people'} in room',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'ID: ${room.id}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<ConnectedUser> connectedUsers) {
    if (connectedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No users connected',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Waiting for others to join...',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRoomData,
      child: ListView.builder(
        itemCount: connectedUsers.length,
        itemBuilder: (context, index) {
          return UserTile(user: connectedUsers[index]);
        },
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Location Sharing Toggle Button
          ActionButton(
            text: _getLocationButtonText(),
            onPressed:
                (_isTogglingLocation || !_locationService.isConnected)
                    ? null
                    : _toggleLocationSharing,
            isPrimary: true,
            isLoading: _isTogglingLocation,
          ),

          SizedBox(height: 12),

          // Map View button (only show if someone is sharing location)
          if (_hasAnyLocationData()) ...[
            ActionButton(
              text: "View on Map",
              onPressed: _navigateToMap,
              isPrimary: false,
            ),
            SizedBox(height: 12),
          ],

          // Room Settings button
          ActionButton(
            text: "Room Settings",
            onPressed: _navigateToSettings,
            isPrimary: false,
          ),

          SizedBox(height: 12),

          // Leave Room button
          ActionButton(
            text: _isLeavingRoom ? "Leaving..." : "Leave Room",
            onPressed: _isLeavingRoom ? null : _leaveRoom,
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  String _getLocationButtonText() {
    if (_isTogglingLocation) {
      return _locationService.isSharing ? 'Stopping...' : 'Starting...';
    }
    return _locationService.isSharing
        ? 'Stop Sharing Location'
        : 'Start Sharing Location';
  }

  bool _hasAnyLocationData() {
    return _locationService.userLocations.isNotEmpty ||
        _locationService.currentLocation != null;
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action:
            isError
                ? SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                )
                : null,
      ),
    );
  }
}
