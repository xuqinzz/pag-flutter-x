# pag-flutter-x

A Flutter plugin for [PAG](https://pag.art/) with enhanced support for **Flutter Add-to-App** and **dynamic FlutterEngine lifecycle scenarios** on Android and iOS.

`pag-flutter-x` is based on the official [libpag/pag-flutter](https://github.com/libpag/pag-flutter) implementation and focuses on production environments where Flutter is embedded into existing native applications and `FlutterEngine` instances may be dynamically created, attached, detached, destroyed, and recreated.

> This project does not aim to replace the upstream PAG Flutter plugin.
> It focuses on compatibility and lifecycle improvements for complex Flutter + native hybrid architectures.

---

## Why pag-flutter-x?

The official PAG Flutter plugin provides the fundamental capabilities required to render PAG animations in Flutter.

For standard standalone Flutter applications, the upstream implementation may already satisfy most requirements.

However, production applications using **Flutter Add-to-App** often have more complex lifecycle models.

For example, an existing Android or iOS application may:

* Dynamically create and destroy `FlutterEngine` instances
* Attach and detach Flutter modules at runtime
* Recreate Flutter containers multiple times
* Frequently switch between native and Flutter pages
* Reuse or recreate Flutter runtime environments
* Manage native and Flutter lifecycle boundaries independently

These scenarios differ significantly from a standalone Flutter application where the Flutter engine typically remains alive for most of the application lifecycle.

For PAG, which involves native rendering resources and Flutter external textures, these lifecycle transitions may introduce rendering and resource-management issues.

`pag-flutter-x` focuses on making PAG more reliable in these environments.

---

## Goals

The project focuses on:

* Flutter Add-to-App compatibility
* Dynamic `FlutterEngine` lifecycle management
* PAG rendering stability across engine attach/detach cycles
* Correct resource handling when Flutter engines are destroyed or recreated
* Android and iOS native lifecycle integration
* External texture rendering
* Compatibility with newer Flutter versions
* Compatibility with upstream PAG SDK updates

The goal is to provide a reliable PAG integration for applications using **hybrid Flutter + native architectures**.

---

## Typical Architecture

`pag-flutter-x` is particularly useful for applications using an architecture similar to:

```text
Native Application
        │
        ├── Android / iOS Native
        │
        ├── Create FlutterEngine
        │          │
        │          └── Flutter Module
        │                  │
        │                  └── PAGView
        │
        ├── Attach / Detach Flutter UI
        │
        ├── Destroy FlutterEngine
        │
        └── Recreate FlutterEngine
```

In a standard Flutter application:

```text
Application
    │
    └── FlutterEngine
            │
            └── Flutter Application
                    │
                    └── PAGView
```

the `FlutterEngine` usually has a relatively stable lifecycle.

In an Add-to-App architecture, however, the engine may be repeatedly created and destroyed according to native application requirements.

This project focuses on PAG behavior across those lifecycle transitions.

---

## Use Cases

`pag-flutter-x` is intended for:

* Existing Android applications adopting Flutter incrementally
* Existing iOS applications adopting Flutter incrementally
* Flutter Add-to-App architectures
* Applications that dynamically load and unload Flutter modules
* Applications that dynamically create or destroy `FlutterEngine`
* Hybrid applications that use PAG animations inside Flutter pages
* Applications requiring PAG external texture rendering across complex lifecycle transitions

For standard standalone Flutter applications without these requirements, consider using the official PAG Flutter implementation first.

---

## Platform Support

| Platform / Feature              | Support |
| ------------------------------- | ------- |
| Android                         | ✅       |
| iOS                             | ✅       |
| Flutter Add-to-App              | ✅       |
| Dynamic FlutterEngine lifecycle | ✅       |
| External Texture Rendering      | ✅       |
| Local PAG assets                | ✅       |
| Remote PAG resources            | ✅       |
| Binary PAG data                 | ✅       |
| Animation lifecycle callbacks   | ✅       |

---

# Getting Started

Flutter uses `PAGView` to display and control PAG animations.

## Installation

Add the dependency to your `pubspec.yaml`.

### Use pag-flutter-x

```yaml
dependencies:
  pag:
    git:
      url: https://github.com/xuqinzz/pag-flutter-x.git
      ref: main
```

You may want to pin the dependency to a specific commit or release tag in production projects to ensure reproducible builds.

### Upstream PAG Flutter

If you do not need the lifecycle adaptations provided by this project, you can use the upstream implementation:

```yaml
dependencies:
  pag:
    git:
      url: https://github.com/libpag/pag-flutter.git
      ref: v1.0.9+4
```

For Flutter 3.29+, the upstream project provides:

```text
v1.0.9+flutter3.29
```

---

## Android

If code shrinking or obfuscation is enabled, add the following rule to your ProGuard / R8 configuration:

```proguard
-keep class org.libpag.**{*;}
```

This prevents PAG classes from being incorrectly removed or obfuscated.

---

# Usage

## Local Asset

Add the PAG file to your Flutter assets first:

```yaml
flutter:
  assets:
    - assets/
```

Then create a `PAGView`:

```dart
PAGView.asset(
  "assets/xxx.pag",
  repeatCount: PAGView.REPEAT_COUNT_LOOP,
  initProgress: 0.25,
  autoPlay: true,
)
```

### Parameters

* `repeatCount` — number of animation repetitions
* `initProgress` — initial animation progress
* `autoPlay` — whether the animation starts automatically

---

## Remote Resource

PAG animations can also be loaded from a URL:

```dart
PAGView.url(
  "https://example.com/animation.pag",
  repeatCount: PAGView.REPEAT_COUNT_LOOP,
  initProgress: 0.25,
  autoPlay: true,
)
```

---

## Binary Data

PAG data can be loaded directly from binary data:

```dart
PAGView.bytes(
  bytes,
  repeatCount: PAGView.REPEAT_COUNT_LOOP,
  initProgress: 0.25,
  autoPlay: true,
)
```

This is useful when PAG data has already been downloaded, cached, decrypted, or otherwise processed by the application.

---

# Animation Callbacks

`PAGView` provides animation lifecycle callbacks corresponding to the native PAG animation listener.

```dart
PAGView.asset(
  "assets/xxx.pag",
  onAnimationStart: () {
    // Animation started.
  },
  onAnimationEnd: () {
    // Animation completed.
  },
  onAnimationRepeat: () {
    // Animation repeated.
  },
  onAnimationCancel: () {
    // Animation cancelled.
  },
)
```

Available callbacks:

| Callback            | Description            |
| ------------------- | ---------------------- |
| `onAnimationStart`  | Animation starts       |
| `onAnimationEnd`    | Animation finishes     |
| `onAnimationRepeat` | Animation repeats      |
| `onAnimationCancel` | Animation is cancelled |

---

# Controlling PAGView

A `GlobalKey<PAGViewState>` can be used to access the state of a `PAGView` and control the animation programmatically.

```dart
final GlobalKey<PAGViewState> pagKey = GlobalKey<PAGViewState>();
```

Pass the key to `PAGView`:

```dart
PAGView.asset(
  "assets/xxx.pag",
  key: pagKey,
)
```

---

## Start

```dart
pagKey.currentState?.start();
```

## Pause

```dart
pagKey.currentState?.pause();
```

## Stop

```dart
pagKey.currentState?.stop();
```

## Set Progress

```dart
pagKey.currentState?.setProgress(0.5);
```

The progress value represents the playback position of the PAG animation.

---

## Get Layers Under a Point

You can query PAG layers at a specific coordinate:

```dart
pagKey.currentState?.getLayersUnderPoint(x, y);
```

This can be useful for implementing interaction with individual PAG layers.

---

# Flutter Add-to-App

One of the primary goals of `pag-flutter-x` is supporting PAG in Flutter Add-to-App architectures.

A typical native application may dynamically manage Flutter engines:

```text
Native Page
    │
    ├── Create FlutterEngine
    │
    ├── Attach Flutter UI
    │
    ├── Display PAGView
    │
    ├── Detach Flutter UI
    │
    └── Destroy FlutterEngine
```

Later, another Flutter module may create a new engine:

```text
Native Page
    │
    └── New FlutterEngine
            │
            └── New Flutter Module
                    │
                    └── PAGView
```

Because PAG rendering involves native resources and Flutter textures, plugin lifecycle management becomes particularly important when the Flutter engine does not live for the entire application process.

`pag-flutter-x` is designed to improve compatibility with these scenarios.

---

# Dynamic FlutterEngine Lifecycle

The primary lifecycle scenario addressed by this project is:

```text
FlutterEngine #1
      │
      ├── Plugin attached
      │
      ├── PAGView created
      │
      ├── PAG rendering
      │
      └── Engine destroyed
              │
              ▼
       Resources released
              │
              ▼
FlutterEngine #2
      │
      ├── Plugin attached again
      │
      ├── PAGView created again
      │
      └── PAG rendering continues normally
```

This is particularly relevant to large existing native applications where Flutter is used as a module rather than as the primary application runtime.

---

# Standalone Flutter vs Add-to-App

| Scenario                            | Upstream PAG Flutter                      | pag-flutter-x                    |
| ----------------------------------- | ----------------------------------------- | -------------------------------- |
| Standard Flutter application        | Recommended                               | Supported                        |
| Flutter Add-to-App                  | Depends on lifecycle architecture         | Focused use case                 |
| Long-lived FlutterEngine            | Supported                                 | Supported                        |
| Dynamically recreated FlutterEngine | May require additional lifecycle handling | Focused use case                 |
| Hybrid Android + Flutter            | Supported                                 | Enhanced lifecycle compatibility |
| Hybrid iOS + Flutter                | Supported                                 | Enhanced lifecycle compatibility |

`pag-flutter-x` is not intended to imply that the upstream plugin cannot be used with Add-to-App.

The difference is that this project specifically focuses on lifecycle edge cases encountered in production hybrid applications.

---

# Reporting Issues

If you encounter a problem, please create an issue in this repository.

For lifecycle or rendering issues, providing the following information will make diagnosis significantly easier:

```text
Flutter version:
PAG SDK version:
Platform:
OS version:
Device:
Standalone Flutter / Add-to-App:
FlutterEngine creation strategy:
FlutterEngine cached/reused:
FlutterEngine dynamically destroyed:
Steps to reproduce:
Expected behavior:
Actual behavior:
```

For Flutter Add-to-App issues, please also describe how the native application manages its `FlutterEngine`.

A minimal reproduction project is highly recommended whenever possible.

---

# Contributing

Contributions are welcome.

Areas where contributions are particularly useful include:

* Flutter Add-to-App compatibility
* FlutterEngine lifecycle handling
* Android lifecycle edge cases
* iOS lifecycle edge cases
* External texture lifecycle management
* Rendering stability
* Flutter version compatibility
* PAG SDK compatibility
* Reproducible test cases

If you find an issue, feel free to open an issue first to discuss the implementation or submit a pull request directly.

---

# Relationship with Upstream

This repository is based on the official PAG Flutter implementation:

**libpag/pag-flutter**

Upstream repository:

https://github.com/libpag/pag-flutter

PAG project:

https://github.com/Tencent/libpag

PAG website:

https://pag.art/

The purpose of `pag-flutter-x` is not to compete with or replace the upstream implementation.

Instead, this project focuses on production requirements and compatibility issues encountered when PAG is used inside **Flutter Add-to-App applications with complex native/Flutter lifecycle management**.

Where appropriate, generally applicable fixes and improvements may also be contributed back to the upstream ecosystem.

---

# Project Scope

The project intentionally focuses on PAG integration rather than providing a general-purpose Flutter engine management framework.

In scope:

* PAG Flutter integration
* PAG rendering lifecycle
* Flutter plugin lifecycle
* FlutterEngine recreation compatibility
* Native/Flutter lifecycle coordination
* External texture lifecycle
* Android/iOS integration

Out of scope:

* General FlutterEngine pooling
* Flutter navigation architecture
* Native application routing
* Generic Add-to-App frameworks

Keeping this scope narrow helps the project remain focused on PAG-specific integration problems.

---

# PAG

PAG is an open-source animation rendering solution that enables designers to export animations from Adobe After Effects and render them efficiently on multiple platforms.

For more information about PAG, see:

* PAG: https://pag.art/
* libpag: https://github.com/Tencent/libpag

---

# License

This project follows the licensing requirements of the upstream PAG Flutter project.

See the [`LICENSE`](./LICENSE) file for details.
