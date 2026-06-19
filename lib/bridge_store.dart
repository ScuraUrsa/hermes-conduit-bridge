/// Riverpod store for Bridge messages.
///
/// Provides reactive state for received push messages.
library bridge_store;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bridge_client.dart';

/// Riverpod provider for the BridgeClient singleton.
final bridgeClientProvider = Provider<BridgeClient>((ref) => bridgeClient);

/// Riverpod provider for the list of received messages.
final bridgeMessagesProvider =
    StateNotifierProvider<BridgeMessagesNotifier, List<BridgeMessage>>((ref) {
  final client = ref.watch(bridgeClientProvider);
  return BridgeMessagesNotifier(client);
});

/// State notifier that accumulates received messages.
class BridgeMessagesNotifier extends StateNotifier<List<BridgeMessage>> {
  BridgeMessagesNotifier(BridgeClient client) : super([]) {
    client.addMessageListener(_onMessage);
  }

  void _onMessage(BridgeMessage msg) {
    state = [...state, msg];
  }

  /// Clear all messages.
  void clear() {
    state = [];
    bridgeClient.clearMessages();
  }

  /// Get the last message (or null).
  BridgeMessage? get lastMessage =>
      state.isNotEmpty ? state.last : null;

  /// Get unread count.
  int get unreadCount => bridgeClient.unreadCount;
}

/// Provider for connection state.
final bridgeConnectionProvider = StateProvider<bool>((ref) {
  final client = ref.watch(bridgeClientProvider);
  client.addConnectionListener((connected) {
    // This would need a ref.read in a real app — simplified for test use
  });
  return client.isConnected;
});
