import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

/// Owns the single Socket.IO connection. Services depend on this instead of
/// holding a raw `Socket`, so connection setup lives in one place.
class SocketClient {
  io.Socket? _socket;

  bool get hasSocket => _socket != null;
  bool get isConnected => _socket?.connected ?? false;

  /// Create a socket for [url] and connect. Any previous socket is disposed.
  void connect(String url) {
    disconnect();
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(AppConstants.socketReconnectionAttempts)
          .setReconnectionDelay(AppConstants.socketReconnectionDelayMs)
          .setTimeout(AppConstants.socketTimeoutMs)
          .build(),
    );
    _socket!.connect();
  }

  /// Listen to a server event. No-op when there is no socket.
  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  /// Send an event to the server. No-op when there is no socket.
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void onConnect(void Function() handler) =>
      _socket?.onConnect((_) => handler());

  void onDisconnect(void Function(dynamic reason) handler) =>
      _socket?.onDisconnect(handler);

  void onConnectError(void Function(dynamic error) handler) =>
      _socket?.onConnectError(handler);

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
