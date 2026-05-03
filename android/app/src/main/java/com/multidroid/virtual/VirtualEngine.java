package com.multidroid.virtual;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.List;

/**
 * VirtualApp Engine — App cloning + isolated storage per instance
 * Uses Android multi-user + isolated process approach
 */
public class VirtualEngine {

    private static final String TAG = "VirtualEngine";
    private static final String VIRTUAL_DIR = "virtual_instances";

    private final Context context;

    public VirtualEngine(Context context) {
        this.context = context;
    }

    // ── Instance Storage ──────────────────────────────────────────────────

    // Get isolated data dir for each instance
    public File getInstanceDir(int instanceId) {
        File baseDir = new File(context.getFilesDir(), VIRTUAL_DIR);
        File instanceDir = new File(baseDir, "instance_" + instanceId);
        if (!instanceDir.exists()) instanceDir.mkdirs();
        return instanceDir;
    }

    // Get shared prefs path for instance
    public File getInstanceSharedPrefs(int instanceId, String appPackage) {
        File dir = new File(getInstanceDir(instanceId), "shared_prefs");
        if (!dir.exists()) dir.mkdirs();
        return new File(dir, appPackage + ".xml");
    }

    // Get databases path for instance
    public File getInstanceDatabaseDir(int instanceId) {
        File dir = new File(getInstanceDir(instanceId), "databases");
        if (!dir.exists()) dir.mkdirs();
        return dir;
    }

    // ── App Cloning ───────────────────────────────────────────────────────

    // Clone app for N instances — creates isolated dirs
    public boolean cloneApp(String packageName, int instanceCount) {
        try {
            for (int i = 0; i < instanceCount; i++) {
                File instanceDir = getInstanceDir(i);
                File appDir = new File(instanceDir, packageName);
                if (!appDir.exists()) appDir.mkdirs();

                // Create sub-dirs
                new File(appDir, "shared_prefs").mkdirs();
                new File(appDir, "databases").mkdirs();
                new File(appDir, "cache").mkdirs();
                new File(appDir, "files").mkdirs();

                Log.d(TAG, "Instance " + i + " dir created: " + appDir.getAbsolutePath());
            }
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Clone failed", e);
            return false;
        }
    }

    // Check if app is already cloned
    public boolean isCloned(String packageName, int instanceId) {
        File appDir = new File(getInstanceDir(instanceId), packageName);
        return appDir.exists();
    }

    // Delete instance data (reset)
    public boolean resetInstance(int instanceId, String packageName) {
        try {
            File appDir = new File(getInstanceDir(instanceId), packageName);
            return deleteDir(appDir);
        } catch (Exception e) {
            return false;
        }
    }

    // Get instance data size in MB
    public long getInstanceSizeMB(int instanceId) {
        File dir = getInstanceDir(instanceId);
        return getDirSize(dir) / (1024 * 1024);
    }

    // ── Freeform Launch via Shizuku ───────────────────────────────────────

    // Calculate freeform bounds for each instance in grid
    public static int[] getFreeformBounds(int instanceId, int screenW, int screenH,
                                           int totalInstances) {
        int cols = 2;
        int rows = totalInstances / cols;
        int col = instanceId % cols;
        int row = instanceId / cols;

        int cellW = screenW / cols;
        int cellH = screenH / rows;

        return new int[]{
            col * cellW,        // left
            row * cellH,        // top
            (col + 1) * cellW,  // right
            (row + 1) * cellH   // bottom
        };
    }

    // Build am start command with freeform bounds
    public static String buildFreeformCommand(String packageName, String activityName,
                                               int[] bounds) {
        return String.format(
            "am start --activity-launch-bounds \"%d,%d,%d,%d\" " +
            "--windowingMode 5 -n %s/%s",
            bounds[0], bounds[1], bounds[2], bounds[3],
            packageName, activityName
        );
    }

    // ── Utils ─────────────────────────────────────────────────────────────

    private boolean deleteDir(File dir) {
        if (dir.isDirectory()) {
            for (File child : dir.listFiles()) deleteDir(child);
        }
        return dir.delete();
    }

    private long getDirSize(File dir) {
        long size = 0;
        if (dir.isDirectory()) {
            for (File file : dir.listFiles()) {
                size += file.isDirectory() ? getDirSize(file) : file.length();
            }
        }
        return size;
    }

    // Get main activity of an app
    public static String getMainActivity(PackageManager pm, String packageName) {
        try {
            return pm.getLaunchIntentForPackage(packageName)
                .getComponent().getClassName();
        } catch (Exception e) {
            return packageName + ".MainActivity";
        }
    }
}
