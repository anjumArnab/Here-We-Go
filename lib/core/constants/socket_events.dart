/// Socket.IO event names shared with `herewego-server/server.js`.
class SocketEvents {
  SocketEvents._();

  // Client -> server
  static const String joinRoom = 'join-room';
  static const String leaveRoom = 'leave-room';
  static const String shareLocation = 'share-location';
  static const String getAllLocations = 'get-all-locations';
  static const String sendMessage = 'send-message';
  static const String getChatHistory = 'get-chat-history';

  // Server -> client
  static const String joinedRoom = 'joined-room';
  static const String userJoined = 'user-joined';
  static const String userLeft = 'user-left';
  static const String locationUpdate = 'location-update';
  static const String existingLocations = 'existing-locations';
  static const String allLocations = 'all-locations';
  static const String locationShared = 'location-shared';
  static const String newMessage = 'new-message';
  static const String chatHistory = 'chat-history';
  static const String error = 'error';
}
