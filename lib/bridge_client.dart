/// WebSocket client for the Hermes Notification Bridge.
///
/// Connects to the Bridge via WebSocket, receives push messages,
/// and dispatches them to listeners (notification handler, Riverpod store).
library bridge_client;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'bridge_config.dart';

/// Represents a push message received from the Bridge.
class BridgeMessage {
  final String id;
  final String type;
  final String source;
  final String priority;
  final String? title;
  final String body;
  final Map<String, dynamic>? action;
  final bool voice;
  final String? ttsText;
  final Map<String, dynamic>? metadata;
  final int createdAt;

  BridgeMessage({
    required this.id,
    required this.type,
    required this.source,
    required this.priority,
    this.title,
    required this.body,
    this.action,
    this.voice = false,
    this.ttsText,
    this.metadata,
    required this.createdAt,
  });

  factory BridgeMessage.fromJson(Map<String, dynamic> json) {
    return BridgeMessage(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'notification',
      source: json['source'] as String? ?? 'system',
      priority: json['priority'] as String? ?? 'normal',
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      action: json['action'] as Map<String, dynamic>?,
      voice: json['voice'] as bool? ?? false,
      ttsText: json['tts_text'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'source': source,
    'priority': priority,
    'title': title,
    'body': body,
    'action': action,
    'voice': voice,
    'tts_text': ttsText,
    'metadata': metadata,
    'created_at': createdAt,
  };
}

/// Callback type for message listeners.
typedef MessageCallback = void Function(BridgeMessage message);

/// Callback type for connection state changes.
typedef ConnectionCallback = void Function(bool connected);

/// Manages the WebSocket connection to the Notification Bridge.
class BridgeClient {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _intentionalClose = false;

  final List<MessageCallback> _messageListeners = [];
  final List<ConnectionCallback> _connectionListeners = [];

  /// Last received message (for test queries).
  BridgeMessage? lastMessage;

  /// Number of unread messages received since last clear.
  int unreadCount = 0;

  /// Whether the client is currently connected.
  bool get isConnected => _channel != null;

  /// Connect to the Notification Bridge.
  void connect({String? url}) {
    _intentionalClose = false;
    _doConnect(url ?? BridgeConfig.wsUrl);
  }

  void _doConnect(String url) {
    try {
      _channel?.sink.close();
    } catch (_) {}

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _reconnectAttempts = 0;
      _notifyConnection(true);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final event = json['event'] as String?;

      if (event == 'message') {
        final msgData = json['data'] as Map<String, dynamic>;
        final msg = BridgeMessage.fromJson(msgData);
        lastMessage = msg;
        unreadCount++;
        _notifyMessage(msg);
      }
      // heartbeat events are ignored
    } catch (e) {
      // Malformed message — ignore
    }
  }

  void _onError(dynamic error) {
    _notifyConnection(false);
    _scheduleReconnect();
  }

  void _onDone() {
    _notifyConnection(false);
    if (!_intentionalClose) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_intentionalClose) return;

    final delay = min(
      BridgeConfig.reconnectBaseDelaySeconds * pow(2, _reconnectAttempts).toInt(),
      BridgeConfig.reconnectMaxDelaySeconds,
    );
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _doConnect(BridgeConfig.wsUrl);
    });
  }

  /// Disconnect from the Bridge.
  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _notifyConnection(false);
  }

  /// Clear all received messages (for test reset).
  void clearMessages() {
    lastMessage = null;
    unreadCount = 0;
  }

  /// Get the last received message as JSON string (for ADB test broadcast).
  String getLastMessageJson() {
    if (lastMessage == null) return 'null';
    return jsonEncode(lastMessage!.toJson());
  }

  /// Get unread count (for ADB test broadcast).
  int getUnreadCount() => unreadCount;

  // --- Listeners ---

  void addMessageListener(MessageCallback callback) {
    _messageListeners.add(callback);
  }

  void removeMessageListener(MessageCallback callback) {
    _messageListeners.remove(callback);
  }

  void addConnectionListener(ConnectionCallback callback) {
    _connectionListeners.add(callback);
  }

  void removeConnectionListener(ConnectionCallback callback) {
    _connectionListeners.remove(callback);
  }

  void _notifyMessage(BridgeMessage msg) {
    for (final listener in _messageListeners) {
      listener(msg);
    }
  }

  void _notifyConnection(bool connected) {
    for (final listener in _connectionListeners) {
      listener(connected);
    }
  }
}

/// Global singleton for app-wide access.
final bridgeClient = BridgeClient();
