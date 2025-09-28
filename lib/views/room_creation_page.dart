// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:herewego/services/location_service.dart';
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
  final TextEditingController userNameController = TextEditingController();

  final LocationService _locationService = LocationService();

  bool autoStartLocationSharing = true;
  bool showRouteBetweenUsers = true;
  bool roomExpires24Hours = false;
  bool _isCreatingRoom = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with default values or passed parameters
    serverUrlController.text = 'https://abc123.ngrok.io';
    roomNameController.text = 'Friends Meetup';
    userNameController.text = 'John Doe';

    // Listen to LocationService changes
    _locationService.addListener(_onLocationServiceChanged);

    // Generate a random room ID if not provided
    _generateRoomId();
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationServiceChanged);
    serverUrlController.dispose();
    roomNameController.dispose();
    roomIdController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  void _onLocationServiceChanged() {
    if (mounted) {
      setState(() {
        _errorMessage = _locationService.lastError;
      });
    }
  }

  void _generateRoomId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 10000).toString().padLeft(4, '0');
    roomIdController.text = 'room_$randomSuffix';
  }

  Future<void> _createRoom() async {
    // Validate inputs
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isCreatingRoom = true;
      _errorMessage = null;
    });

    try {
      // Check if we need to connect to server first
      if (!_locationService.isConnected ||
          _locationService.serverUrl != serverUrlController.text.trim()) {
        // Connect to server
        final serverUrl = serverUrlController.text.trim();
        final connected = await _locationService.connect(serverUrl);

        if (!connected) {
          setState(() {
            _isCreatingRoom = false;
            _errorMessage =
                _locationService.lastError ?? 'Failed to connect to server';
          });
          return;
        }
      }

      // Prepare room settings
      final roomSettings = <String, dynamic>{
        'autoStartLocationSharing': autoStartLocationSharing,
        'showRouteBetweenUsers': showRouteBetweenUsers,
        'roomExpires24Hours': roomExpires24Hours,
        'expirationTime':
            roomExpires24Hours
                ? DateTime.now().add(Duration(hours: 24)).toIso8601String()
                : null,
      };

      // Create the room
      final success = await _locationService.createRoom(
        roomName:
            roomNameController.text.trim().isEmpty
                ? 'Unnamed Room'
                : roomNameController.text.trim(),
        creatorName: userNameController.text.trim(),
        customRoomId:
            roomIdController.text.trim().isEmpty
                ? null
                : roomIdController.text.trim(),
        settings: roomSettings,
      );

      setState(() {
        _isCreatingRoom = false;
      });

      if (success) {
        // Show success message
        _showSnackBar('Room created successfully!', isError: false);

        // Auto-start location sharing if enabled
        if (autoStartLocationSharing) {
          _startLocationSharing();
        }

        // Return success to previous screen
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = _locationService.lastError ?? 'Failed to create room';
        });
      }
    } catch (e) {
      setState(() {
        _isCreatingRoom = false;
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _startLocationSharing() async {
    try {
      await _locationService.startLocationSharing(
        highAccuracy: true,
        updateInterval: 5000, // 5 seconds
      );
    } catch (e) {
      // Don't show error for location sharing failure if room creation succeeded
      debugPrint('Failed to start location sharing: ${e.toString()}');
    }
  }

  bool _validateInputs() {
    if (serverUrlController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a server URL';
      });
      return false;
    }

    if (userNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return false;
    }

    if (roomIdController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Room ID cannot be empty';
      });
      return false;
    }

    // Validate room ID format (optional)
    final roomId = roomIdController.text.trim();
    if (roomId.contains(' ') || roomId.length < 3) {
      setState(() {
        _errorMessage =
            'Room ID must be at least 3 characters and contain no spaces';
      });
      return false;
    }

    return true;
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

                      // Connection Status
                      if (_locationService.connectionStatus !=
                          ConnectionStatus.disconnected) ...[
                        _buildConnectionStatus(),
                        SizedBox(height: 20),
                      ],

                      // Error message
                      if (_errorMessage != null) ...[
                        _buildErrorMessage(),
                        SizedBox(height: 20),
                      ],

                      // Server URL field (only show if not connected)
                      if (!_locationService.isConnected) ...[
                        InputField(
                          label: 'Server URL',
                          controller: serverUrlController,
                          enabled: !_isCreatingRoom,
                        ),
                        SizedBox(height: 20),
                      ],

                      // Your Name field
                      InputField(
                        label: 'Your Name',
                        controller: userNameController,
                        enabled: !_isCreatingRoom,
                      ),

                      SizedBox(height: 20),

                      // Room Name field
                      InputField(
                        label: 'Room Name (Optional)',
                        controller: roomNameController,
                        enabled: !_isCreatingRoom,
                      ),

                      SizedBox(height: 20),

                      // Room ID field
                      InputField(
                        label: 'Custom Room ID (Optional)',
                        controller: roomIdController,
                        enabled: !_isCreatingRoom,
                      ),

                      SizedBox(height: 20),

                      // Room Settings section
                      _buildRoomSettingsSection(),

                      SizedBox(height: 40),

                      // Create Room button
                      ActionButton(
                        onPressed: _isCreatingRoom ? null : _createRoom,
                        text:
                            _isCreatingRoom
                                ? 'Creating Room...'
                                : 'Create Room',
                        isPrimary: true,
                        isLoading: _isCreatingRoom,
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

  Widget _buildConnectionStatus() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
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

        _buildToggleItem(
          title: "Auto-start location sharing",
          subtitle: "Start sharing location immediately after joining",
          value: autoStartLocationSharing,
          onChanged:
              _isCreatingRoom
                  ? null
                  : (value) {
                    setState(() {
                      autoStartLocationSharing = value;
                    });
                  },
        ),

        SizedBox(height: 12),

        _buildToggleItem(
          title: "Show route between users",
          subtitle: "Display navigation routes on the map",
          value: showRouteBetweenUsers,
          onChanged:
              _isCreatingRoom
                  ? null
                  : (value) {
                    setState(() {
                      showRouteBetweenUsers = value;
                    });
                  },
        ),

        SizedBox(height: 12),

        _buildToggleItem(
          title: "Room expires in 24 hours",
          subtitle: "Automatically delete room after 24 hours",
          value: roomExpires24Hours,
          onChanged:
              _isCreatingRoom
                  ? null
                  : (value) {
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
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
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

  Color _getStatusColor() {
    switch (_locationService.connectionStatus) {
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_locationService.connectionStatus) {
      case ConnectionStatus.connecting:
        return Icons.sync;
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.error:
        return Icons.error;
      case ConnectionStatus.disconnected:
        return Icons.signal_wifi_off;
    }
  }

  String _getStatusText() {
    switch (_locationService.connectionStatus) {
      case ConnectionStatus.connecting:
        return 'Connecting to server...';
      case ConnectionStatus.connected:
        return 'Connected to ${_locationService.serverUrl}';
      case ConnectionStatus.error:
        return 'Connection failed';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
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
