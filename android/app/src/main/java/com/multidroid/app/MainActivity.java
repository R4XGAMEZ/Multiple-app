package com.multidroid.app;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.AudioManager;
import android.provider.Settings;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import com.multidroid.accessibility.MultiDroidAccessibilityService;
import com.multidroid.macro.MacroEngine;
import com.multidroid.proxy.ProxyInjector;
import com.multidroid.shizuku.ShizukuBridge;
import com.multidroid.virtual.VirtualEngine;
import com.multidroid.volume.VolumeController;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import rikka.shizuku.Shizuku;

import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {

    private static final String TAG = "MultiDroid";
    private static final String METHOD_CHANNEL  = "com.multidroid/bridge";
    private static final String EVENT_CHANNEL   = "com.multidroid/events";

    // Shizuku permission request code
    private static final int SHIZUKU_CODE = 1001;

    private MethodChannel.Result pendingResult;
    private VirtualEngine virtualEngine;
    private VolumeController volumeController;

    // EventChannel sink — used to push events from Java → Flutter
    public static EventChannel.EventSink eventSink;

    private final Shizuku.OnRequestPermissionResultListener permListener =
        (code, result) -> {
            if (code == SHIZUKU_CODE && pendingResult != null) {
                pendingResult.success(result == PackageManager.PERMISSION_GRANTED);
                pendingResult = null;
            }
        };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        virtualEngine   = new VirtualEngine(this);
        volumeController = new VolumeController(this);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        Shizuku.addRequestPermissionResultListener(permListener);

        // ── EventChannel: Java → Flutter push events ──────────────────────
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
            .setStreamHandler(new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object args, EventChannel.EventSink sink) {
                    eventSink = sink;
                    Log.d(TAG, "EventChannel listening");
                }
                @Override
                public void onCancel(Object args) {
                    eventSink = null;
                }
            });

        // ── MethodChannel: Flutter → Java calls ───────────────────────────
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {

                    // ── Shizuku ──────────────────────────────────────────
                    case "shizuku_available":
                        result.success(ShizukuBridge.isAvailable()); break;

                    case "shizuku_has_permission":
                        result.success(ShizukuBridge.hasPermission()); break;

                    case "shizuku_request_permission":
                        pendingResult = result;
                        ShizukuBridge.requestPermission(SHIZUKU_CODE); break;

                    // ── Freeform ─────────────────────────────────────────
                    case "freeform_supported":
                        result.success(ShizukuBridge.isFreeformSupported()); break;

                    case "enable_freeform":
                        ShizukuBridge.enableFreeformMode();
                        result.success(true); break;

                    case "launch_freeform":
                        result.success(ShizukuBridge.launchInFreeform(
                            call.argument("package"),
                            call.argument("activity"),
                            call.<Integer>argument("left"),
                            call.<Integer>argument("top"),
                            call.<Integer>argument("right"),
                            call.<Integer>argument("bottom")
                        )); break;

                    case "get_screen_size":
                        result.success(ShizukuBridge.getScreenSize()); break;

                    case "exec_command":
                        result.success(ShizukuBridge.execCommand(
                            call.argument("command"))); break;

                    case "force_stop":
                        ShizukuBridge.forceStopApp(call.argument("package"));
                        result.success(true); break;

                    // ── Installed Apps ───────────────────────────────────
                    case "get_installed_apps":
                        result.success(ShizukuBridge.getInstalledApps(
                            getPackageManager())); break;

                    case "get_main_activity":
                        result.success(VirtualEngine.getMainActivity(
                            getPackageManager(), call.argument("package"))); break;

                    // ── Virtual Engine ───────────────────────────────────
                    case "clone_app":
                        result.success(virtualEngine.cloneApp(
                            call.argument("package"),
                            call.<Integer>argument("count"))); break;

                    case "reset_instance":
                        result.success(virtualEngine.resetInstance(
                            call.<Integer>argument("instance_id"),
                            call.argument("package"))); break;

                    case "instance_size_mb":
                        result.success((int) virtualEngine.getInstanceSizeMB(
                            call.<Integer>argument("instance_id"))); break;

                    // ── Accessibility ─────────────────────────────────────
                    case "accessibility_enabled":
                        result.success(MultiDroidAccessibilityService.isRunning()); break;

                    case "open_accessibility_settings":
                        startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
                        result.success(true); break;

                    case "perform_click":
                        if (MultiDroidAccessibilityService.instance != null) {
                            result.success(MultiDroidAccessibilityService.instance
                                .performClickAt(
                                    call.<Integer>argument("x"),
                                    call.<Integer>argument("y")));
                        } else result.success(false);
                        break;

                    case "perform_swipe":
                        if (MultiDroidAccessibilityService.instance != null) {
                            result.success(MultiDroidAccessibilityService.instance
                                .performSwipe(
                                    call.<Integer>argument("x1"),
                                    call.<Integer>argument("y1"),
                                    call.<Integer>argument("x2"),
                                    call.<Integer>argument("y2"),
                                    300));
                        } else result.success(false);
                        break;

                    case "perform_type":
                        if (MultiDroidAccessibilityService.instance != null) {
                            result.success(MultiDroidAccessibilityService.instance
                                .performType(call.argument("text")));
                        } else result.success(false);
                        break;

                    // ── Phase 4: Master Sync ──────────────────────────────
                    case "set_master_sync":
                        if (MultiDroidAccessibilityService.instance != null) {
                            MultiDroidAccessibilityService.instance.setMasterSync(
                                Boolean.TRUE.equals(call.<Boolean>argument("enabled")),
                                call.<Integer>argument("master_id"));
                        }
                        result.success(true); break;

                    case "set_instance_bounds":
                        if (MultiDroidAccessibilityService.instance != null) {
                            MultiDroidAccessibilityService.instance.setInstanceBounds(
                                call.<Integer>argument("instance_id"),
                                call.<Integer>argument("left"),
                                call.<Integer>argument("top"),
                                call.<Integer>argument("right"),
                                call.<Integer>argument("bottom"));
                        }
                        result.success(true); break;

                    // ── Phase 4: Proxy Inject ─────────────────────────────
                    // Injects HTTP proxy for a specific freeform instance via ADB
                    case "set_instance_proxy":
                        boolean pOk = ProxyInjector.setProxy(
                            call.argument("host"),
                            call.argument("port"),
                            call.<Integer>argument("instance_id"));
                        result.success(pOk); break;

                    case "clear_instance_proxy":
                        boolean clOk = ProxyInjector.clearProxy(
                            call.<Integer>argument("instance_id"));
                        result.success(clOk); break;

                    case "set_global_proxy":
                        boolean gpOk = ProxyInjector.setGlobalProxy(
                            call.argument("host"),
                            call.argument("port"));
                        result.success(gpOk); break;

                    case "clear_all_proxies":
                        ProxyInjector.clearAllProxies();
                        result.success(true); break;

                    // ── Phase 4: Volume per Instance ──────────────────────
                    // Controls AudioManager stream volumes via Shizuku
                    case "set_instance_volume":
                        boolean vOk = volumeController.setVolume(
                            call.<Integer>argument("instance_id"),
                            (double) call.<Double>argument("volume"),
                            Boolean.TRUE.equals(call.<Boolean>argument("muted")));
                        result.success(vOk); break;

                    case "set_master_volume":
                        boolean mvOk = volumeController.setMasterVolume(
                            (double) call.<Double>argument("volume"));
                        result.success(mvOk); break;

                    case "mute_all":
                        volumeController.muteAll(
                            call.<Integer>argument("count"));
                        result.success(true); break;

                    case "unmute_all":
                        volumeController.unmuteAll(
                            call.<Integer>argument("count"));
                        result.success(true); break;

                    // ── Phase 4: Macro Engine Bridge ──────────────────────
                    case "start_macro":
                        if (MultiDroidAccessibilityService.instance != null) {
                            MultiDroidAccessibilityService.instance.startMacro(
                                call.<Integer>argument("instance_id"),
                                call.<Double>argument("scan_interval").floatValue(),
                                Boolean.TRUE.equals(call.<Boolean>argument("random_delay")),
                                call.<Long>argument("delay_after_ms"),
                                call.<Integer>argument("bounds_left"),
                                call.<Integer>argument("bounds_top"),
                                call.<Integer>argument("bounds_right"),
                                call.<Integer>argument("bounds_bottom"),
                                (double) call.<Double>argument("click_x"),
                                (double) call.<Double>argument("click_y"));
                            result.success(true);
                        } else result.success(false);
                        break;

                    case "stop_macro":
                        if (MultiDroidAccessibilityService.instance != null) {
                            MultiDroidAccessibilityService.instance.stopMacro(
                                call.<Integer>argument("instance_id"));
                        }
                        result.success(true); break;

                    case "stop_all_macros":
                        if (MultiDroidAccessibilityService.instance != null) {
                            MultiDroidAccessibilityService.instance.stopAllMacros();
                        }
                        result.success(true); break;

                    case "get_ram_info":
                        long[] ramInfo = ShizukuBridge.getRamInfo();
                        result.success(new long[]{ramInfo[0], ramInfo[1]}); break;

                    case "freeze_instance":
                        ShizukuBridge.execCommand(
                            "am freeze " + call.argument("package") +
                            " 2>/dev/null || true");
                        result.success(true); break;

                    case "unfreeze_instance":
                        ShizukuBridge.execCommand(
                            "am unfreeze " + call.argument("package") +
                            " 2>/dev/null || true");
                        result.success(true); break;

                    default:
                        result.notImplemented();
                }
            });
    }

    // Push an event from Java side to Flutter EventChannel
    public static void pushEvent(String type, Map<String, Object> data) {
        if (eventSink == null) return;
        Map<String, Object> event = new HashMap<>(data);
        event.put("type", type);
        // Must run on main thread
        new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
            if (eventSink != null) eventSink.success(event);
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Shizuku.removeRequestPermissionResultListener(permListener);
    }
}
