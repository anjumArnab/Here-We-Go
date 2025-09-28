// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/location_service.dart';
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

  final LocationService _locationService = LocationService();
  bool _isConnecting = false;
  bool _isJoiningRoom = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with example data
    serverUrlController.text = 'https://abc123.ngrok.io';
    roomIdController.text = 'room_123';
    nameController.text = 'John Doe';

    // Listen to LocationService changes
    _locationService.addListener(_onLocationServiceChanged);
  }

  void _onLocationServiceChanged() {
    if (mounted) {
      setState(() {
        _errorMessage = _locationService.lastError;
      });
    }
  }

  Future<void> _connectAndJoinRoom() async {
    // Validate input
    if (_validateInput()) {
      setState(() {
        _isConnecting = true;
        _errorMessage = null;
      });

      try {
        // Connect to server
        final serverUrl = serverUrlController.text.trim();
        final connected = await _locationService.connect(serverUrl);

        if (!connected) {
          setState(() {
            _isConnecting = false;
            _errorMessage =
                _locationService.lastError ?? 'Failed to connect to server';
          });
          return;
        }

        // Join the room
        setState(() {
          _isJoiningRoom = true;
        });

        final roomId = roomIdController.text.trim();
        final userName = nameController.text.trim();
        final joined = await _locationService.joinRoom(
          roomId: roomId,
          userName: userName,
        );

        setState(() {
          _isConnecting = false;
          _isJoiningRoom = false;
        });

        if (joined) {
          // Successfully joined room, navigate to RoomPage
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => RoomPage()),
            );
          }
        } else {
          setState(() {
            _errorMessage = _locationService.lastError ?? 'Failed to join room';
          });
        }
      } catch (e) {
        setState(() {
          _isConnecting = false;
          _isJoiningRoom = false;
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        });
      }
    }
  }

  void _navigateToRoomCreation() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => RoomCreationPage()));
  }

  bool _validateInput() {
    if (serverUrlController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a server URL';
      });
      return false;
    }

    if (roomIdController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a room ID';
      });
      return false;
    }

    if (nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return false;
    }

    return true;
  }

  String _getConnectButtonText() {
    if (_isConnecting && !_isJoiningRoom) {
      return 'Connecting...';
    } else if (_isJoiningRoom) {
      return 'Joining Room...';
    }
    return 'Connect';
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationServiceChanged);
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
                SizedBox(height: 20),
                // Title
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

                // Connection Status
                if (_locationService.connectionStatus !=
                    ConnectionStatus.disconnected) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  Container(
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
                  ),
                  SizedBox(height: 20),
                ],

                // Server URL field
                InputField(
                  label: 'Server URL',
                  controller: serverUrlController,
                  enabled: !_isConnecting,
                ),
                SizedBox(height: 20),
                // Room ID field
                InputField(
                  label: 'Room ID',
                  controller: roomIdController,
                  enabled: !_isConnecting,
                ),
                SizedBox(height: 20),
                // Your Name field
                InputField(
                  label: 'Your Name',
                  controller: nameController,
                  enabled: !_isConnecting,
                ),
                SizedBox(height: 40),
                // Connect button
                ActionButton(
                  text: _getConnectButtonText(),
                  onPressed: _isConnecting ? null : _connectAndJoinRoom,
                  isPrimary: true,
                  isLoading: _isConnecting,
                ),
                SizedBox(height: 16),
                // Create New Room button
                ActionButton(
                  text: _isConnecting ? "Connecting..." : "Create New Room",
                  onPressed: _isConnecting ? null : _navigateToRoomCreation,
                  isPrimary: false,
                  isLoading: _isConnecting && !_isJoiningRoom,
                ),
              ],
            ),
          ),
        ),
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
}
