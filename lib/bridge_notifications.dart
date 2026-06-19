/// Local notification handler for Bridge push messages.
///
/// Shows Android notifications when the app is backgrounded.
library bridge_notifications;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'bridge_client.dart';

/// Manages local notifications for Bridge messages.
class BridgeNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification plugin.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  /// Show a notification for a Bridge message.
  Future<void> showNotification(BridgeMessage message) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'hermes_bridge_channel',
      'Hermes Notifications',
      channelDescription: 'Push notifications from Hermes Agent',
      importance: message.priority == 'urgent'
          ? Importance.max
          : Importance.defaultImportance,
      priority: message.priority == 'urgent'
          ? Priority.max
          : Priority.defaultPriority,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      message.hashCode, // unique ID per message
      message.title ?? 'Hermes',
      message.body,
      details,
      payload: message.id, // pass message ID for tap handling
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // The app handles navigation based on the payload (message ID)
    // This is wired up in the Conduit integration layer
  }
}

/// Global singleton.
final bridgeNotifications = BridgeNotifications();
