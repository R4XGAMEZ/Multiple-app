package com.multidroid.shizuku;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.util.Log;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import rikka.shizuku.Shizuku;

public class ShizukuBridge {

    private static final String TAG = "ShizukuBridge";

    public static boolean isAvailable() {
        try { return Shizuku.pingBinder(); }
        catch (Exception e) { return false; }
    }

    public static boolean hasPermission() {
        try {
            if (Shizuku.isPreV11()) return false;
            return Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED;
        } catch (Exception e) { return false; }
    }

    public static void requestPermission(int requestCode) {
        Shizuku.requestPermission(requestCode);
    }

    public static String execCommand(String command) {
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"sh", "-c", command});
            BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()));
            StringBuilder output = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) output.append(line).append("\n");
            process.waitFor();
            return output.toString().trim();
        } catch (Exception e) {
            Log.e(TAG, "Command failed: " + command, e);
            return "";
        }
    }

    public static boolean launchInFreeform(String packageName, String activityName,
            int left, int top, int right, int bottom) {
        try {
            String bounds = left + "," + top + "," + right + "," + bottom;
            String cmd = "am start --activity-launch-bounds \"" + bounds + "\" -n "
                + packageName + "/" + activityName;
            execCommand(cmd);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Freeform launch failed", e);
            return false;
        }
    }

    public static void enableFreeformMode() {
        execCommand("settings put global enable_freeform_support 1");
        execCommand("settings put global force_resizable_activities 1");
    }

    public static boolean isFreeformSupported() {
        String result = execCommand("settings get global enable_freeform_support");
        return "1".equals(result.trim());
    }

    public static void forceStopApp(String packageName) {
        execCommand("am force-stop " + packageName);
    }

    public static int[] getScreenSize() {
        String result = execCommand("wm size");
        try {
            String[] parts = result.split(": ")[1].split("x");
            return new int[]{Integer.parseInt(parts[0].trim()), Integer.parseInt(parts[1].trim())};
        } catch (Exception e) { return new int[]{1080, 2400}; }
    }

    public static List<Map<String, String>> getInstalledApps(PackageManager pm) {
        List<Map<String, String>> apps = new ArrayList<>();
        List<ApplicationInfo> packages = pm.getInstalledApplications(PackageManager.GET_META_DATA);
        for (ApplicationInfo info : packages) {
            if ((info.flags & ApplicationInfo.FLAG_SYSTEM) == 0) {
                Map<String, String> app = new HashMap<>();
                app.put("package", info.packageName);
                app.put("name", pm.getApplicationLabel(info).toString());
                apps.add(app);
            }
        }
        return apps;
    }

    public static void setProxy(String host, int port) {
        execCommand("settings put global http_proxy " + host + ":" + port);
    }

    public static void clearProxy() {
        execCommand("settings delete global http_proxy");
    }

    public static long[] getRamInfo() {
        try {
            String result = execCommand("cat /proc/meminfo");
            long total = 0, available = 0;
            for (String line : result.split("\n")) {
                if (line.startsWith("MemTotal:"))
                    total = Long.parseLong(line.replaceAll("[^0-9]", "")) / 1024;
                if (line.startsWith("MemAvailable:"))
                    available = Long.parseLong(line.replaceAll("[^0-9]", "")) / 1024;
            }
            return new long[]{total, total - available};
        } catch (Exception e) {
            return new long[]{0, 0};
        }
    }
}
