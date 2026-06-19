/// Configuration for the Hermes Notification Bridge client.
///
/// Set the Bridge URL before calling [BridgeClient.connect].
class BridgeConfig {
  /// WebSocket URL of the Notification Bridge.
  /// Default: ws://localhost:8655/events/ws
  static String wsUrl = 'ws://localhost:8655/events/ws';

  /// HTTP URL for REST endpoints (health, messages, stats).
  static String httpUrl = 'http://localhost:8655';

  /// Auth key for Bridge (if required).
  static String? authKey;

  /// Reconnection delay in seconds (exponential backoff base).
  static int reconnectBaseDelaySeconds = 1;

  /// Maximum reconnection delay in seconds.
  static int reconnectMaxDelaySeconds = 30;
}
