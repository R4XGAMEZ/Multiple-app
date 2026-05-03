# MultiDroid 📱

Multi-instance app manager — ek phone mein 6 virtual phones!

## Features

- 📱 **6 Virtual Instances** — Same app, alag alag accounts
- 🌐 **Per Instance Proxy** — Geonode se auto proxy (alag country)
- 🤖 **Macro Automation** — Image detection + auto click
- 👑 **Master Control** — Ek instance control karo, sab follow karein
- 🔊 **Volume Control** — Per instance + master volume
- ⚡ **Low End Optimized** — 2GB RAM pe bhi smooth
- 🔍 **Proxy Health Check** — Auto dead proxy replace

## Requirements

- Android 8.0+
- [Shizuku](https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api) app installed
- Developer Options → Freeform Windows → ON

## Build APK

### Via GitHub Actions (Recommended)
```
1. Repo fork karo
2. Code push karo main branch pe
3. Actions tab → Build MultiDroid APK
4. Artifacts se APK download karo
```

### Release APK (Tag se)
```bash
git tag v1.0.0
git push origin v1.0.0
# GitHub Releases mein APK mil jaayega
```

### Local Build (Termux)
```bash
flutter pub get
flutter build apk --release
```

## Setup

1. Shizuku install karo + start karo
2. MultiDroid open karo
3. Instance count choose karo (2/4/6)
4. App select karo jo clone karna hai
5. Har instance ke liye country/proxy set karo
6. Macros set karo
7. **Run All Macros** — Done! 🚀

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── models/
│   └── instance_model.dart      # Data models
├── services/
│   ├── app_state.dart           # State management
│   └── geonode_service.dart     # Proxy API
└── screens/
    ├── setup_screen.dart        # First time setup
    ├── home_grid.dart           # 3x2 grid view
    ├── instance_fullscreen.dart # Full screen instance
    ├── macro_setup.dart         # Macro configuration
    └── proxy_setup.dart         # Proxy selection

android/
├── AndroidManifest.xml
└── java/com/multidroid/
    ├── shizuku/ShizukuBridge.java
    ├── macro/MacroEngine.java
    └── accessibility/MultiDroidAccessibilityService.java
```

## Phases

- ✅ Phase 1 — Flutter UI + Shizuku + Grid
- 🔄 Phase 2 — VirtualApp integration
- 🔄 Phase 3 — Macro + OpenCV
- 🔄 Phase 4 — Master Control sync
- 🔄 Phase 5 — Polish + Optimization
