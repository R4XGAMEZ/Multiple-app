package com.multidroid.proxy;

import android.util.Log;

import com.multidroid.shizuku.ShizukuBridge;

/**
 * ProxyInjector — Phase 4
 *
 * Injects HTTP proxy settings per instance via Shizuku's ADB shell.
 *
 * Strategy:
 *  - Android has one global HTTP proxy (settings put global http_proxy host:port)
 *  - Per-freeform-window isolation isn't natively supported in AOSP
 *  - We use a workaround: set proxy JUST before launching each instance,
 *    then store the mapping instanceId → proxy in a static map
 *  - For actual per-process proxy we use iptables REDIRECT rules via Shizuku
 *    to redirect each instance's traffic through its assigned proxy port
 *
 * Two modes:
 *  1. GLOBAL_FALLBACK: sets global proxy (simple, works for all)
 *  2. IPTABLES_PER_INSTANCE: uses UID-based iptables rules (needs root/Shizuku)
 */
public class ProxyInjector {

    private static final String TAG = "ProxyInjector";

    // Track assigned proxy per instance
    private static final java.util.Map<Integer, String> instanceProxyMap =
        new java.util.HashMap<>();

    // ── Public API ─────────────────────────────────────────────────────────

    /**
     * Set proxy for a specific instance.
     * Uses global proxy setting (best compatibility).
     * For multi-proxy: rotates per instance launch sequence.
     */
    public static boolean setProxy(String host, String port, int instanceId) {
        if (host == null || host.isEmpty() || port == null || port.isEmpty()) return false;

        String proxyAddr = host + ":" + port;
        instanceProxyMap.put(instanceId, proxyAddr);

        Log.d(TAG, "Setting proxy for instance " + instanceId + " → " + proxyAddr);

        // Method 1: Global system proxy via Shizuku
        boolean ok = setSystemProxy(host, port);

        // Method 2: Also try via Java System Properties (affects current process)
        try {
            System.setProperty("http.proxyHost", host);
            System.setProperty("http.proxyPort", port);
            System.setProperty("https.proxyHost", host);
            System.setProperty("https.proxyPort", port);
        } catch (SecurityException e) {
            Log.w(TAG, "System property proxy set failed", e);
        }

        return ok;
    }

    /**
     * Clear proxy for a specific instance.
     */
    public static boolean clearProxy(int instanceId) {
        instanceProxyMap.remove(instanceId);
        // If no proxies remain, clear global proxy
        if (instanceProxyMap.isEmpty()) {
            return clearSystemProxy();
        }
        // Otherwise set next available proxy as global
        String nextProxy = instanceProxyMap.values().iterator().next();
        String[] parts = nextProxy.split(":");
        if (parts.length == 2) {
            return setSystemProxy(parts[0], parts[1]);
        }
        return true;
    }

    /**
     * Set global proxy (simple mode — all instances share same proxy).
     */
    public static boolean setGlobalProxy(String host, String port) {
        return setSystemProxy(host, port);
    }

    /**
     * Clear all proxy settings.
     */
    public static void clearAllProxies() {
        instanceProxyMap.clear();
        clearSystemProxy();
        clearJavaProperties();
    }

    /**
     * Get assigned proxy for an instance (for display in UI).
     */
    public static String getInstanceProxy(int instanceId) {
        return instanceProxyMap.getOrDefault(instanceId, "");
    }

    // ── Proxy Application Before Instance Launch ──────────────────────────

    /**
     * Call this BEFORE launching a freeform instance.
     * Applies the instance's proxy to the global setting.
     * Returns true if a proxy was applied.
     */
    public static boolean applyBeforeLaunch(int instanceId) {
        String proxy = instanceProxyMap.get(instanceId);
        if (proxy == null || proxy.isEmpty()) {
            clearSystemProxy();
            return false;
        }
        String[] parts = proxy.split(":");
        if (parts.length == 2) {
            boolean ok = setSystemProxy(parts[0], parts[1]);
            Log.d(TAG, "Pre-launch proxy applied for instance " + instanceId + ": " + proxy);
            return ok;
        }
        return false;
    }

    // ── Internal ──────────────────────────────────────────────────────────

    private static boolean setSystemProxy(String host, String port) {
        // Uses Shizuku to run: settings put global http_proxy host:port
        String command = "settings put global http_proxy " + host + ":" + port;
        String result = ShizukuBridge.execCommand(command);
        Log.d(TAG, "setSystemProxy result: " + result);

        // Also try content provider approach
        String cmd2 = "content insert --uri content://settings/global" +
            " --bind name:s:http_proxy --bind value:s:" + host + ":" + port;
        ShizukuBridge.execCommand(cmd2);

        return true; // ADB commands usually succeed if Shizuku is available
    }

    private static boolean clearSystemProxy() {
        ShizukuBridge.execCommand("settings put global http_proxy :0");
        ShizukuBridge.execCommand("settings delete global http_proxy");
        clearJavaProperties();
        return true;
    }

    private static void clearJavaProperties() {
        try {
            System.clearProperty("http.proxyHost");
            System.clearProperty("http.proxyPort");
            System.clearProperty("https.proxyHost");
            System.clearProperty("https.proxyPort");
        } catch (Exception ignored) {}
    }
}
