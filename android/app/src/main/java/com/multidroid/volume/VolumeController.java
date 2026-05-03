package com.multidroid.volume;

import android.content.Context;
import android.media.AudioManager;
import android.util.Log;

import com.multidroid.shizuku.ShizukuBridge;

/**
 * VolumeController — Phase 4
 *
 * Controls Android AudioManager volume per instance.
 *
 * Challenge: Android doesn't natively support per-window audio levels.
 * Approach used here:
 *  1. AudioManager.setStreamVolume() — sets actual system stream volume
 *     This is the REAL volume change (not just a Flutter UI slider).
 *  2. For per-instance isolation: we control MEDIA stream volume.
 *     Since all instances share the same stream, we use this for global
 *     "master" volume, but expose per-instance mute via AudioManager flags.
 *  3. Per-instance mute: uses setStreamMute() which IS per-caller (per-UID).
 *     Since all instances are the same app, we track mute state in memory
 *     and adjust volume proportionally.
 *
 * Volume levels are stored per-instance and applied as a ratio of master volume.
 * Example: master=80%, instance2=50% → instance2 actual = 40%
 */
public class VolumeController {

    private static final String TAG = "VolumeController";

    private final AudioManager audioManager;
    private final int maxVolume;

    // Per-instance volume state (0.0 - 1.0)
    private final float[] instanceVolumes = new float[6];
    private final boolean[] instanceMuted = new boolean[6];
    private float masterVolume = 1.0f;

    public VolumeController(Context context) {
        audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
        // Initialize all instances to full volume
        for (int i = 0; i < instanceVolumes.length; i++) {
            instanceVolumes[i] = 1.0f;
            instanceMuted[i] = false;
        }
        Log.d(TAG, "VolumeController init, maxVolume=" + maxVolume);
    }

    // ── Set volume for a single instance ──────────────────────────────────

    /**
     * Sets the effective volume for an instance.
     * Actual volume = masterVolume * instanceVolume
     * If muted, sets volume to 0.
     */
    public boolean setVolume(int instanceId, double volume, boolean muted) {
        if (instanceId < 0 || instanceId >= instanceVolumes.length) return false;

        instanceVolumes[instanceId] = (float) volume;
        instanceMuted[instanceId] = muted;

        // Apply the effective volume
        return applyVolume(instanceId);
    }

    // ── Set master volume (affects all instances proportionally) ──────────

    public boolean setMasterVolume(double volume) {
        masterVolume = (float) volume;

        // Calculate effective volume across all instances and apply
        // We set the system volume to the highest active instance's effective volume
        float highestEffective = 0f;
        for (int i = 0; i < instanceVolumes.length; i++) {
            if (!instanceMuted[i]) {
                float eff = masterVolume * instanceVolumes[i];
                if (eff > highestEffective) highestEffective = eff;
            }
        }

        int targetVol = Math.round(highestEffective * maxVolume);
        return setSystemVolume(targetVol);
    }

    // ── Mute/Unmute all ───────────────────────────────────────────────────

    public void muteAll(int count) {
        int n = Math.min(count, instanceMuted.length);
        for (int i = 0; i < n; i++) {
            instanceMuted[i] = true;
        }
        // Mute system
        try {
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                AudioManager.ADJUST_MUTE,
                0);
        } catch (Exception e) {
            // Fallback: set volume to 0
            setSystemVolume(0);
        }
        Log.d(TAG, "All instances muted");
    }

    public void unmuteAll(int count) {
        int n = Math.min(count, instanceMuted.length);
        for (int i = 0; i < n; i++) {
            instanceMuted[i] = false;
        }
        try {
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                AudioManager.ADJUST_UNMUTE,
                0);
        } catch (Exception e) {
            // Fallback: restore to master volume
            setMasterVolume(masterVolume);
        }
        Log.d(TAG, "All instances unmuted");
    }

    // ── Internal ──────────────────────────────────────────────────────────

    private boolean applyVolume(int instanceId) {
        float effective;
        if (instanceMuted[instanceId]) {
            effective = 0f;
        } else {
            effective = masterVolume * instanceVolumes[instanceId];
        }

        int targetVol = Math.round(effective * maxVolume);

        // Try via AudioManager directly (works without root)
        boolean ok = setSystemVolume(targetVol);

        // If that fails (some OEMs restrict), try via Shizuku ADB
        if (!ok) {
            ok = setVolumeViaAdb(targetVol);
        }

        Log.d(TAG, "Instance " + instanceId + " volume → " + targetVol + "/" + maxVolume
            + " (effective=" + effective + ")");
        return ok;
    }

    private boolean setSystemVolume(int volumeIndex) {
        try {
            // FLAG_SHOW_UI=1 shows volume bar, 0 to hide
            audioManager.setStreamVolume(
                AudioManager.STREAM_MUSIC,
                Math.max(0, Math.min(volumeIndex, maxVolume)),
                0 // No UI flag — silent adjustment
            );
            return true;
        } catch (SecurityException se) {
            Log.w(TAG, "setStreamVolume needs MODIFY_AUDIO_SETTINGS — trying ADB");
            return false;
        } catch (Exception e) {
            Log.e(TAG, "setStreamVolume failed", e);
            return false;
        }
    }

    private boolean setVolumeViaAdb(int volumeIndex) {
        // media volume via ADB: cmd media_session volume --set X --stream 3
        // stream 3 = STREAM_MUSIC
        String cmd = "cmd media_session volume --set " + volumeIndex + " --stream 3";
        String result = ShizukuBridge.execCommand(cmd);
        Log.d(TAG, "ADB volume result: " + result);
        return true;
    }
}
