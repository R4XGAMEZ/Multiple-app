# MultiDroid — Phase 4

## What's new in Phase 4

### 1. Master Sync Touch Broadcast

**How it works:**
- Accessibility Service captures `TYPE_VIEW_CLICKED`, `TYPE_VIEW_TEXT_CHANGED`, `TYPE_VIEW_SCROLLED` events
- When Master Sync is ON, Java translates master's absolute screen coordinates to relative position (0.0–1.0) within its freeform window
- Same relative position is re-calculated for each slave's freeform bounds → `performClickAt()` fires for each slave
- Events pushed to Flutter via `EventChannel` (`com.multidroid/events`) for live log in `MasterSyncOverlay`

**New files:**
- `MultiDroidAccessibilityService.java` — updated with `broadcastClickToSlaves()`, `broadcastTextToSlaves()`, `broadcastScrollToSlaves()`
- `lib/widgets/master_sync_overlay.dart` — pulsing gold banner with event log + master instance selector
- `lib/services/bridge_service.dart` — `setMasterSync()`, `setInstanceBounds()`

---

### 2. Proxy per Instance Inject

**How it works:**
- `ProxyInjector.java` uses Shizuku to run: `settings put global http_proxy HOST:PORT`
- Also sets Java `System.setProperty()` for in-process proxy support
- `applyBeforeLaunch(instanceId)` method — call before each `am start` to set the right proxy
- Each instance's proxy stored in static `instanceProxyMap`
- `clearProxy()` removes or rotates to next available proxy

**New files:**
- `android/.../proxy/ProxyInjector.java`
- `lib/services/bridge_service.dart` — `setInstanceProxy()`, `clearInstanceProxy()`, `setGlobalProxy()`, `clearAllProxies()`

**MethodChannel calls added to MainActivity:**
- `set_instance_proxy` — {host, port, instance_id}
- `clear_instance_proxy` — {instance_id}
- `set_global_proxy` — {host, port}
- `clear_all_proxies`

---

### 3. Volume per Instance (Actual AudioManager)

**How it works:**
- `VolumeController.java` uses `AudioManager.setStreamVolume(STREAM_MUSIC, ...)` — real system volume change
- Fallback: `cmd media_session volume --set X --stream 3` via Shizuku ADB
- Per-instance state tracked in `float[] instanceVolumes` + `boolean[] instanceMuted`
- `setMasterVolume()` applies the highest effective instance volume to system
- `muteAll()` / `unmuteAll()` use `AudioManager.ADJUST_MUTE` flags

**New files:**
- `android/.../volume/VolumeController.java`

**MethodChannel calls:**
- `set_instance_volume` — {instance_id, volume (0.0–1.0), muted}
- `set_master_volume` — {volume}
- `mute_all` — {count}
- `unmute_all` — {count}

---

### 4. Run All Macros Engine

**How it works:**
- `BridgeService.startMacro()` passes full `MacroConfig` to Java `MacroEngine` via `MultiDroidAccessibilityService`
- Each instance gets its own `MacroEngine` scan loop running on main Handler
- Staggered launch: 200ms delay between instances to avoid overload
- `RunAllMacrosSheet` bottom sheet shows per-instance live status with individual RUN/STOP buttons
- `EventChannel` pushes `macro_started` / `macro_stopped` events back to Flutter for UI sync

**New files:**
- `lib/widgets/run_all_macros_engine.dart` — bottom sheet with per-instance controls
- `lib/services/bridge_service.dart` — `startMacro()`, `stopMacro()`, `stopAllMacros()`

**MethodChannel calls:**
- `start_macro` — {instance_id, scan_interval, random_delay, delay_after_ms, bounds_*, click_x, click_y}
- `stop_macro` — {instance_id}
- `stop_all_macros`

---

## EventChannel events (Java → Flutter)

| Event type | Data | Description |
|---|---|---|
| `service_connected` | — | Accessibility service came online |
| `master_click` | x, y | Master clicked at coords |
| `master_text` | text | Master typed text |
| `master_scroll` | scroll_x, scroll_y | Master scrolled |
| `master_sync_changed` | enabled, master_id | Sync toggled |
| `macro_started` | instance_id | Macro engine started |
| `macro_stopped` | instance_id | Macro engine stopped |
| `all_macros_stopped` | — | All macros stopped |

---

## Files changed vs Phase 3

### New files:
- `android/.../proxy/ProxyInjector.java`
- `android/.../volume/VolumeController.java`
- `lib/services/bridge_service.dart`
- `lib/widgets/master_sync_overlay.dart`
- `lib/widgets/run_all_macros_engine.dart`

### Updated files:
- `android/.../app/MainActivity.java` — EventChannel + 10 new method calls
- `android/.../accessibility/MultiDroidAccessibilityService.java` — master sync broadcast + macro bridge
- `lib/services/app_state.dart` — all Phase 4 methods wired to bridge
- `lib/screens/home_grid.dart` — MasterSyncOverlay + RunAllMacrosSheet integration
- `android/.../res/xml/accessibility_service_config.xml` — added scroll/text event types
- `android/.../AndroidManifest.xml` — MODIFY_AUDIO_SETTINGS + CHANGE_NETWORK_STATE

### Unchanged from Phase 3:
- `MacroEngine.java`
- `VirtualEngine.java`
- `ShizukuBridge.java`
- `lib/services/geonode_service.dart`
- `lib/services/shizuku_service.dart`
- `lib/services/virtual_engine_service.dart`
- `lib/services/installed_apps_service.dart`
- `lib/models/instance_model.dart`
- `lib/main.dart`
- `lib/screens/setup_screen.dart`
- `lib/screens/macro_setup.dart`
- `lib/screens/proxy_setup.dart`
- `lib/screens/instance_fullscreen.dart`
- `lib/screens/permissions_screen.dart`
- `pubspec.yaml`
