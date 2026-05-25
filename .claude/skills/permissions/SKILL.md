---
name: permissions
description: Use when a feature needs an OS permission (camera, photos, location, notifications). EatinPal does not currently ship `permission_handler` — surface the dep before adding. Covers request flow, rationale dialog, permanent-denial recovery, per-platform Info.plist / AndroidManifest entries.
---

# Skill: Permissions

## When to use

Adding a feature that needs OS-level user consent:

- **Camera** — barcode scan, photo capture (food image).
- **Photos / Gallery** — pick existing image.
- **Location** — restaurant pickers (future).
- **Notifications** — reminder pings (future).
- **Microphone** — voice search (future).
- **Files** — import/export CSV (future).

## Current state in EatinPal

`permission_handler` is **not** in `pubspec.yaml` yet. Adding it requires explicit user approval (see `.claude/rules/hands-off.md`).

When you propose a feature that needs a permission:

1. Surface the dependency request first.
2. Confirm the user wants the feature now (vs. faking it / deferring).
3. Then proceed with this skill's patterns.

## Pattern (once `permission_handler` is added)

### Request flow

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> _ensureCameraPermission(BuildContext context) async {
  final status = await Permission.camera.status;

  if (status.isGranted) return true;

  if (status.isDenied) {
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  if (status.isPermanentlyDenied) {
    if (!context.mounted) return false;
    await _showOpenSettingsDialog(context);
    return false;
  }

  return false;
}
```

### Rationale before requesting (recommended)

OS-native prompts give zero context. Show a small explainer FIRST so the user knows why:

```dart
Future<bool> _askWithRationale(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Camera access'),
      content: const Text('To scan barcodes on food labels, we need camera permission.'),
      actions: [
        TextButton(onPressed: () => ctx.pop(false), child: const Text('NOT NOW')),
        TextButton(onPressed: () => ctx.pop(true), child: const Text('CONTINUE')),
      ],
    ),
  );
  if (accepted != true) return false;
  return _ensureCameraPermission(context);
}
```

### Permanently denied recovery

```dart
Future<void> _showOpenSettingsDialog(BuildContext context) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Camera blocked'),
      content: const Text(
        'You\'ve previously denied camera access. Open Settings to enable it manually.',
      ),
      actions: [
        TextButton(onPressed: () => ctx.pop(false), child: const Text('CANCEL')),
        TextButton(onPressed: () => ctx.pop(true), child: const Text('OPEN SETTINGS')),
      ],
    ),
  );
  if (open == true) await openAppSettings();
}
```

## Per-platform configuration

### iOS — `ios/Runner/Info.plist`

Each permission needs a usage description (otherwise the request silently fails):

```xml
<key>NSCameraUsageDescription</key>
<string>Used to scan barcodes on food labels.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Used to pick a photo of your meal.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to suggest nearby restaurants.</string>
```

The string is shown verbatim in the system prompt — write it as user-facing copy, not engineer notes.

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>     <!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>                                            <!-- Android ≤12 -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>     <!-- Android 13+ -->
```

`permission_handler` documentation lists exactly which entries each `Permission.*` needs.

## Common patterns

### Check before navigating into a permission-required screen

```dart
void _onScanBarcodeTap(BuildContext context) async {
  final ok = await _askWithRationale(context);
  if (!ok || !context.mounted) return;
  context.push(RoutePaths.SCAN_BARCODE);
}
```

### Skip-once flag

If the user denied a non-critical permission, don't nag on every visit. Store a "asked once" flag in `LocalStorage`:

```dart
final asked = (await _storage.getBool(_NOTIF_PROMPT_ASKED_KEY)) ?? false;
if (asked) return;
await _askForNotifications(context);
await _storage.setBool(_NOTIF_PROMPT_ASKED_KEY, true);
```

(Where `_NOTIF_PROMPT_ASKED_KEY` is a `static const _UPPER_SNAKE_CASE` in the relevant scope — promote to `LocalStorageImpl` if app-wide.)

## Common pitfalls

- **No `NSXxxUsageDescription`** on iOS → request silently denied; you'll spend an hour debugging.
- **Asking on app launch** — feels invasive. Ask at the moment of need.
- **No rationale before native prompt** — user denies because they don't know why; recovery requires Settings.
- **Treating `isLimited` (iOS photos) as denied** — limited access is a valid grant; handle the subset.
- **Not handling `isPermanentlyDenied`** — user is stuck.
- **Re-prompting on every screen visit** — store a "asked once" flag and route through "open Settings" on subsequent denies.

## See also

- `lib/core/local/local_storage.dart` — for "asked once" / "rationale shown" flags
- `lib/core/widgets/app_snackbar.dart` — confirmation feedback after grant
- `pubspec.yaml` — `permission_handler` would be added here (surface first)
- `permission_handler` docs: <https://pub.dev/packages/permission_handler>
- iOS Info.plist keys: <https://developer.apple.com/documentation/bundleresources/information_property_list>
