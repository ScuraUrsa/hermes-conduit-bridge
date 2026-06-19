package io.cogwheel.conduit;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

/**
 * Test receiver for Hermes Notification Bridge E2E tests.
 *
 * Responds to ADB broadcast intents to allow automated verification
 * of push message delivery without manual inspection.
 *
 * Intent actions:
 *   hermes.test.GET_LAST_MESSAGE    — returns last received push message as JSON
 *   hermes.test.GET_NOTIFICATION_COUNT — returns unread notification count
 *   hermes.test.CLEAR_MESSAGES      — clears all received messages
 *   hermes.test.SET_BRIDGE_URL      — sets Bridge WebSocket URL at runtime
 */
public class TestReceiver extends BroadcastReceiver {
    private static final String TAG = "HermesTestReceiver";

    // These are set by the Flutter app via MethodChannel
    public static String lastMessageJson = null;
    public static int unreadCount = 0;
    public static String bridgeUrl = "ws://localhost:8655/events/ws";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (action == null) return;

        Log.d(TAG, "Received broadcast: " + action);

        switch (action) {
            case "hermes.test.GET_LAST_MESSAGE":
                Intent result = new Intent("hermes.test.LAST_MESSAGE_RESULT");
                result.putExtra("message", lastMessageJson != null ? lastMessageJson : "null");
                result.putExtra("unread_count", unreadCount);
                context.sendBroadcast(result);
                Log.d(TAG, "Last message: " + (lastMessageJson != null ? lastMessageJson : "null"));
                break;

            case "hermes.test.GET_NOTIFICATION_COUNT":
                // setResultCode carries the count back
                setResultCode(unreadCount);
                setResultData(String.valueOf(unreadCount));
                Log.d(TAG, "Unread count: " + unreadCount);
                break;

            case "hermes.test.CLEAR_MESSAGES":
                lastMessageJson = null;
                unreadCount = 0;
                Log.d(TAG, "Messages cleared");
                break;

            case "hermes.test.SET_BRIDGE_URL":
                String url = intent.getStringExtra("url");
                if (url != null && !url.isEmpty()) {
                    bridgeUrl = url;
                    Log.d(TAG, "Bridge URL set to: " + url);
                }
                break;

            default:
                Log.w(TAG, "Unknown action: " + action);
                break;
        }
    }
}
