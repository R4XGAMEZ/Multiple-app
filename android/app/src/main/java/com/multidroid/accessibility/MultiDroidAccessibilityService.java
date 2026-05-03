package com.multidroid.accessibility;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.graphics.Path;
import android.graphics.Rect;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;

import com.multidroid.app.MainActivity;
import com.multidroid.macro.MacroEngine;

import java.util.HashMap;
import java.util.Map;

/**
 * MultiDroidAccessibilityService — Phase 4
 *
 * Phase 4 additions:
 *  1. Master Sync Touch Broadcast — captures touches on master instance,
 *     re-fires them on all slave instances via EventChannel + back to
 *     perform_click on each slave's freeform position
 *  2. Macro Engine integration — startMacro/stopMacro with real config
 *  3. EventChannel push for all master actions
 */
public class MultiDroidAccessibilityService extends AccessibilityService {

    private static final String TAG = "MDAccessibility";
    public static MultiDroidAccessibilityService instance;

    private MacroEngine macroEngine;
    private final Handler handler = new Handler(Looper.getMainLooper());

    // Master sync state
    private boolean masterSyncEnabled = false;
    private int masterInstanceId = 0;

    // Freeform bounds per instance — set by Flutter when instances launch
    private final Map<Integer, int[]> instanceBounds = new HashMap<>();

    // ── Lifecycle ─────────────────────────────────────────────────────────

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        macroEngine = new MacroEngine(this);
        Log.d(TAG, "Accessibility Service connected!");
        pushEvent("service_connected", new HashMap<>());
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (!masterSyncEnabled) return;

        try {
            int type = event.getEventType();

            if (type == AccessibilityEvent.TYPE_VIEW_CLICKED) {
                handleMasterClick(event);
            } else if (type == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
                handleMasterText(event);
            } else if (type == AccessibilityEvent.TYPE_VIEW_SCROLLED) {
                handleMasterScroll(event);
            }
        } catch (Exception e) {
            Log.e(TAG, "Event handling error", e);
        }
    }

    @Override
    public void onInterrupt() {
        Log.d(TAG, "Service interrupted");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        instance = null;
        if (macroEngine != null) macroEngine.stopAllMacros();
    }

    // ── Phase 4: Master Sync Touch Broadcast ──────────────────────────────

    public void setMasterSync(boolean enabled, int masterId) {
        this.masterSyncEnabled = enabled;
        this.masterInstanceId = masterId;
        Log.d(TAG, "Master sync: " + enabled + " master=" + masterId);

        Map<String, Object> data = new HashMap<>();
        data.put("enabled", enabled);
        data.put("master_id", masterId);
        pushEvent("master_sync_changed", data);
    }

    /**
     * Register freeform bounds for an instance.
     * Flutter calls this after each instance launches.
     */
    public void setInstanceBounds(int instanceId, int left, int top, int right, int bottom) {
        instanceBounds.put(instanceId, new int[]{left, top, right, bottom});
        Log.d(TAG, "Bounds set for instance " + instanceId +
            ": " + left + "," + top + " → " + right + "," + bottom);
    }

    private void handleMasterClick(AccessibilityEvent event) {
        AccessibilityNodeInfo node = event.getSource();
        if (node == null) return;

        Rect bounds = new Rect();
        node.getBoundsInScreen(bounds);
        int cx = bounds.centerX();
        int cy = bounds.centerY();
        node.recycle();

        Log.d(TAG, "Master click at " + cx + "," + cy);

        // Push to Flutter EventChannel
        Map<String, Object> data = new HashMap<>();
        data.put("x", cx);
        data.put("y", cy);
        pushEvent("master_click", data);

        // Mirror click on all slave instances
        broadcastClickToSlaves(cx, cy);
    }

    private void handleMasterText(AccessibilityEvent event) {
        if (event.getText() == null || event.getText().isEmpty()) return;
        String text = event.getText().get(0).toString();
        Log.d(TAG, "Master text: " + text);

        Map<String, Object> data = new HashMap<>();
        data.put("text", text);
        pushEvent("master_text", data);

        // Broadcast text to all slaves
        broadcastTextToSlaves(text);
    }

    private void handleMasterScroll(AccessibilityEvent event) {
        int scrollX = event.getScrollX();
        int scrollY = event.getScrollY();
        int fromX = event.getFromIndex();
        int toX = event.getToIndex();

        Map<String, Object> data = new HashMap<>();
        data.put("scroll_x", scrollX);
        data.put("scroll_y", scrollY);
        pushEvent("master_scroll", data);

        broadcastScrollToSlaves(scrollX, scrollY);
    }

    /**
     * Mirrors a click from master to all slave instances.
     * Translates absolute screen coords relative to each slave's freeform window.
     */
    private void broadcastClickToSlaves(int masterX, int masterY) {
        int[] masterBounds = instanceBounds.get(masterInstanceId);
        if (masterBounds == null) {
            // No bounds known — just replay at same coords on all instances
            for (Map.Entry<Integer, int[]> entry : instanceBounds.entrySet()) {
                if (entry.getKey() != masterInstanceId) {
                    performClickAt(masterX, masterY);
                }
            }
            return;
        }

        // Calculate relative position within master window (0.0 to 1.0)
        float masterW = masterBounds[2] - masterBounds[0];
        float masterH = masterBounds[3] - masterBounds[1];
        float relX = (masterX - masterBounds[0]) / masterW;
        float relY = (masterY - masterBounds[1]) / masterH;

        // Re-fire on each slave instance at proportional position
        for (Map.Entry<Integer, int[]> entry : instanceBounds.entrySet()) {
            int slaveId = entry.getKey();
            if (slaveId == masterInstanceId) continue;

            int[] slaveBounds = entry.getValue();
            float slaveW = slaveBounds[2] - slaveBounds[0];
            float slaveH = slaveBounds[3] - slaveBounds[1];

            int slaveX = (int) (slaveBounds[0] + relX * slaveW);
            int slaveY = (int) (slaveBounds[1] + relY * slaveH);

            // Small stagger delay so gestures don't overlap
            int delayMs = slaveId * 30;
            handler.postDelayed(() -> performClickAt(slaveX, slaveY), delayMs);

            Log.d(TAG, "Slave " + slaveId + " click at " + slaveX + "," + slaveY);
        }
    }

    private void broadcastTextToSlaves(String text) {
        // For text we just find focused field and type
        for (Map.Entry<Integer, int[]> entry : instanceBounds.entrySet()) {
            if (entry.getKey() != masterInstanceId) {
                handler.post(() -> performType(text));
            }
        }
    }

    private void broadcastScrollToSlaves(int scrollX, int scrollY) {
        int[] masterBounds = instanceBounds.get(masterInstanceId);
        if (masterBounds == null) return;

        // Scroll from center of each slave window
        for (Map.Entry<Integer, int[]> entry : instanceBounds.entrySet()) {
            int slaveId = entry.getKey();
            if (slaveId == masterInstanceId) continue;

            int[] sb = entry.getValue();
            int cx = (sb[0] + sb[2]) / 2;
            int cy = (sb[1] + sb[3]) / 2;

            // Scroll as swipe gesture
            int swipeEndY = cy - (scrollY > 0 ? 100 : -100);
            handler.postDelayed(() ->
                performSwipe(cx, cy, cx, swipeEndY, 200), slaveId * 50L);
        }
    }

    // ── Phase 4: Macro Engine Integration ─────────────────────────────────

    public boolean startMacro(int instanceId, float scanInterval, boolean randomDelay,
                               long delayAfterMs, int left, int top, int right, int bottom,
                               double clickX, double clickY) {
        if (macroEngine == null) {
            macroEngine = new MacroEngine(this);
        }

        MacroEngine.MacroConfig config = new MacroEngine.MacroConfig();
        config.scanIntervalSeconds = scanInterval;
        config.randomDelay = randomDelay;
        config.delayAfterClickMs = delayAfterMs;
        config.boundsLeft = left;
        config.boundsTop = top;
        config.boundsRight = right;
        config.boundsBottom = bottom;
        // clickX/Y are relative (0.0-1.0) within the instance bounds
        config.clickOffsetX = (int) (clickX * (right - left));
        config.clickOffsetY = (int) (clickY * (bottom - top));
        config.threshold = 0.80f;

        macroEngine.startMacro(instanceId, config);

        Map<String, Object> data = new HashMap<>();
        data.put("instance_id", instanceId);
        pushEvent("macro_started", data);

        Log.d(TAG, "Macro started for instance " + instanceId);
        return true;
    }

    public void stopMacro(int instanceId) {
        if (macroEngine != null) macroEngine.stopMacro(instanceId);
        Map<String, Object> data = new HashMap<>();
        data.put("instance_id", instanceId);
        pushEvent("macro_stopped", data);
    }

    public void stopAllMacros() {
        if (macroEngine != null) macroEngine.stopAllMacros();
        pushEvent("all_macros_stopped", new HashMap<>());
    }

    // ── Gestures ──────────────────────────────────────────────────────────

    public boolean performClickAt(int x, int y) {
        try {
            Path path = new Path();
            path.moveTo(x, y);

            GestureDescription gesture = new GestureDescription.Builder()
                .addStroke(new GestureDescription.StrokeDescription(path, 0, 50))
                .build();

            dispatchGesture(gesture, new GestureResultCallback() {
                @Override public void onCompleted(GestureDescription g) {}
                @Override public void onCancelled(GestureDescription g) {
                    Log.w(TAG, "Click cancelled at " + x + "," + y);
                }
            }, null);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Click failed", e);
            return false;
        }
    }

    public boolean performSwipe(int x1, int y1, int x2, int y2, long durationMs) {
        try {
            Path path = new Path();
            path.moveTo(x1, y1);
            path.lineTo(x2, y2);

            GestureDescription gesture = new GestureDescription.Builder()
                .addStroke(new GestureDescription.StrokeDescription(path, 0, durationMs))
                .build();

            dispatchGesture(gesture, null, null);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Swipe failed", e);
            return false;
        }
    }

    public boolean performType(String text) {
        try {
            AccessibilityNodeInfo focus = findFocus(AccessibilityNodeInfo.FOCUS_INPUT);
            if (focus != null) {
                Bundle args = new Bundle();
                args.putCharSequence(
                    AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text);
                focus.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args);
                focus.recycle();
                return true;
            }
            return false;
        } catch (Exception e) {
            Log.e(TAG, "Type failed", e);
            return false;
        }
    }

    // ── Utils ─────────────────────────────────────────────────────────────

    public static boolean isRunning() {
        return instance != null;
    }

    private void pushEvent(String type, Map<String, Object> data) {
        MainActivity.pushEvent(type, data);
    }
}
