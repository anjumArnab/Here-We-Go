import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService with WidgetsBindingObserver {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Flutter local notifications plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // App lifecycle state
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  // Notification channel details
  static const String _channelId = 'chat_messages';
  static const String _channelName = 'Chat Messages';
  static const String _channelDescription = 'Notifications for new chat messages';

  // Getters
  bool get isAppInBackground =>
      _appLifecycleState == AppLifecycleState.paused ||
      _appLifecycleState == AppLifecycleState.inactive ||
      _appLifecycleState == AppLifecycleState.hidden;

  bool get isAppInForeground => _appLifecycleState == AppLifecycleState.resumed;

  AppLifecycleState get appLifecycleState => _appLifecycleState;

  /// Initialize the notification service
  Future<void> initialize() async {
    developer.log('Initializing NotificationService');

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    // Create notification channel
    await _createNotificationChannel();

    developer.log('NotificationService initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {

    // Android permission
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // IOS permission
    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Create notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}');
    // TODO: Navigate to ChatPage when notification is tapped
  }

  /// Show chat message notification
  Future<void> showMessageNotification({
    required String senderId,
    required String message,
    String? roomId,
  }) async {
    // Only show notification if app is in background
    if (!isAppInBackground) {
      developer.log('App is in foreground, skipping notification');
      return;
    }

    developer.log('Showing notification for message from $senderId');

    // Notification details for android devices
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    // Notification details for ios devices
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combined notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generate unique notification ID
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // Show notification
    await _notificationsPlugin.show(
      notificationId,
      'New message from $senderId',
      message,
      notificationDetails,
      payload: roomId,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// App lifecycle state change handler
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    developer.log('App lifecycle state changed: $state');
  }

  /// Dispose resources
  void dispose() {
    developer.log('Disposing NotificationService');
    WidgetsBinding.instance.removeObserver(this);
  }
}