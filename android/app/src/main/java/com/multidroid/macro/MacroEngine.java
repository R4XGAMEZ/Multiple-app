package com.multidroid.macro;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.graphics.Bitmap;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.media.Image;
import android.media.ImageReader;
import android.media.projection.MediaProjection;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;

/**
 * MacroEngine — Screenshot capture + Template matching + Auto click
 * Uses MediaProjection for screen capture + Accessibility for click inject
 */
public class MacroEngine {

    private static final String TAG = "MacroEngine";

    private AccessibilityService accessibilityService;
    private final Handler handler = new Handler(Looper.getMainLooper());

    // Per-instance scan state
    private final Map<Integer, Boolean> runningInstances = new HashMap<>();
    private final Map<Integer, Runnable> scanRunnables = new HashMap<>();

    public MacroEngine(AccessibilityService service) {
        this.accessibilityService = service;
    }

    // ── Start/Stop ────────────────────────────────────────────────────────

    public void startMacro(int instanceId, MacroConfig config) {
        runningInstances.put(instanceId, true);

        Runnable scanRunnable = new Runnable() {
            @Override
            public void run() {
                if (!Boolean.TRUE.equals(runningInstances.get(instanceId))) return;

                // Perform scan + click
                performScan(instanceId, config);

                // Schedule next scan
                long intervalMs = (long)(config.scanIntervalSeconds * 1000);
                if (config.randomDelay) {
                    // Add random 0-50% delay for anti-bot
                    intervalMs += (long)(Math.random() * intervalMs * 0.5);
                }
                handler.postDelayed(this, intervalMs);
            }
        };

        scanRunnables.put(instanceId, scanRunnable);
        handler.post(scanRunnable);
        Log.d(TAG, "Macro started for instance " + instanceId);
    }

    public void stopMacro(int instanceId) {
        runningInstances.put(instanceId, false);
        Runnable r = scanRunnables.remove(instanceId);
        if (r != null) handler.removeCallbacks(r);
        Log.d(TAG, "Macro stopped for instance " + instanceId);
    }

    public void stopAllMacros() {
        for (int id : runningInstances.keySet()) stopMacro(id);
    }

    // ── Scan + Match ──────────────────────────────────────────────────────

    private void performScan(int instanceId, MacroConfig config) {
        try {
            // Take screenshot of instance area
            Bitmap screenshot = captureInstanceArea(
                config.boundsLeft, config.boundsTop,
                config.boundsRight, config.boundsBottom
            );
            if (screenshot == null) return;

            // Template match
            MatchResult match = templateMatch(screenshot, config.targetBitmap, config.threshold);

            if (match.found) {
                Log.d(TAG, "Match found at " + match.x + "," + match.y
                    + " confidence=" + match.confidence);

                // Calculate absolute click position
                int absX = config.boundsLeft + match.x + config.clickOffsetX;
                int absY = config.boundsTop + match.y + config.clickOffsetY;

                // Inject click via Accessibility
                performClick(absX, absY);

                // Delay after click
                if (config.delayAfterClickMs > 0) {
                    try { Thread.sleep(config.delayAfterClickMs); }
                    catch (InterruptedException ignored) {}
                }
            }

            screenshot.recycle();

        } catch (Exception e) {
            Log.e(TAG, "Scan error for instance " + instanceId, e);
        }
    }

    // ── Template Matching (manual — no OpenCV dependency) ─────────────────

    /**
     * Simple template matching using pixel comparison
     * Scans screenshot for target image
     */
    private MatchResult templateMatch(Bitmap source, Bitmap template, float threshold) {
        if (source == null || template == null) return new MatchResult(false, 0, 0, 0);

        int sw = source.getWidth(), sh = source.getHeight();
        int tw = template.getWidth(), th = template.getHeight();

        if (tw > sw || th > sh) return new MatchResult(false, 0, 0, 0);

        float bestScore = 0;
        int bestX = 0, bestY = 0;

        // Stride — check every 4px for speed on low-end devices
        int stride = 4;

        for (int y = 0; y <= sh - th; y += stride) {
            for (int x = 0; x <= sw - tw; x += stride) {
                float score = computeSimilarity(source, template, x, y);
                if (score > bestScore) {
                    bestScore = score;
                    bestX = x;
                    bestY = y;
                }
            }
        }

        boolean found = bestScore >= threshold;
        return new MatchResult(found, bestX + tw/2, bestY + th/2, bestScore);
    }

    private float computeSimilarity(Bitmap source, Bitmap template, int offsetX, int offsetY) {
        int tw = template.getWidth(), th = template.getHeight();
        long match = 0, total = 0;

        // Sample every 3rd pixel for speed
        for (int y = 0; y < th; y += 3) {
            for (int x = 0; x < tw; x += 3) {
                int sp = source.getPixel(offsetX + x, offsetY + y);
                int tp = template.getPixel(x, y);
                if (colorSimilar(sp, tp, 30)) match++;
                total++;
            }
        }

        return total == 0 ? 0 : (float) match / total;
    }

    private boolean colorSimilar(int c1, int c2, int tolerance) {
        return Math.abs(((c1 >> 16) & 0xFF) - ((c2 >> 16) & 0xFF)) <= tolerance &&
               Math.abs(((c1 >> 8) & 0xFF) - ((c2 >> 8) & 0xFF)) <= tolerance &&
               Math.abs((c1 & 0xFF) - (c2 & 0xFF)) <= tolerance;
    }

    // ── Auto Click via Accessibility ──────────────────────────────────────

    public void performClick(int x, int y) {
        if (accessibilityService == null) return;
        try {
            Path path = new Path();
            path.moveTo(x, y);

            GestureDescription.Builder builder = new GestureDescription.Builder();
            builder.addStroke(new GestureDescription.StrokeDescription(path, 0, 50));

            accessibilityService.dispatchGesture(builder.build(),
                new AccessibilityService.GestureResultCallback() {
                    @Override
                    public void onCompleted(GestureDescription gestureDescription) {
                        Log.d(TAG, "Click completed at " + x + "," + y);
                    }
                }, null);
        } catch (Exception e) {
            Log.e(TAG, "Click failed", e);
        }
    }

    // ── Screen Capture ────────────────────────────────────────────────────

    private Bitmap captureInstanceArea(int left, int top, int right, int bottom) {
        // Will use MediaProjection when granted
        // For now returns null — implemented when projection available
        return null;
    }

    // ── Data Classes ──────────────────────────────────────────────────────

    public static class MacroConfig {
        public Bitmap targetBitmap;
        public int clickOffsetX, clickOffsetY;
        public float scanIntervalSeconds = 1.0f;
        public float threshold = 0.85f;
        public boolean randomDelay = true;
        public long delayAfterClickMs = 500;
        public int boundsLeft, boundsTop, boundsRight, boundsBottom;
    }

    public static class MatchResult {
        public boolean found;
        public int x, y;
        public float confidence;

        MatchResult(boolean found, int x, int y, float confidence) {
            this.found = found;
            this.x = x;
            this.y = y;
            this.confidence = confidence;
        }
    }
}
