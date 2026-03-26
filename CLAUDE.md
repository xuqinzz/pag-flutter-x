# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 Flutter 插件项目，为 Flutter 提供 PAG（Portable Animated Graphics）动画组件支持，使用外接纹理（Texture Registry）方式实现。

支持平台：
- **Android**（Java + Kotlin）
- **iOS**（Objective-C）
- **HarmonyOS**（ArkTS/ETS）

## 常用命令

### 开发调试

```bash
# 在 example 目录下运行示例应用
cd example
flutter run

# 分析 Dart 代码
flutter analyze

# 格式化 Dart 代码
dart format .

# 检查 pubspec.yaml 有效性
flutter pub publish --dry-run
```

### 平台特定构建

```bash
# Android - 在 example/android 目录下
./gradlew build
./gradlew assembleDebug

# iOS - 在 example/ios 目录下
pod install
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug
```

## 架构设计

### 核心架构

插件采用 **Flutter Texture Registry** 架构实现跨平台渲染：

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter 层 (Dart)                       │
│                    lib/pag.dart                             │
│         PAGView (StatefulWidget)                            │
│              ↓                                              │
│         Texture (widget) ←── textureId                      │
└──────────────────────┬──────────────────────────────────────┘
                       │ MethodChannel (flutter_pag_plugin)
┌──────────────────────┼──────────────────────────────────────┐
│                      ↓                                       │
│  ┌───────────────────┴───────────────────┐                  │
│  │           原生平台层                   │                  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐  │                  │
│  │  │ Android │ │   iOS   │ │ Harmony │  │                  │
│  │  │ (Java)  │ │ (Obj-C) │ │ (ArkTS) │  │                  │
│  │  └────┬────┘ └────┬────┘ └────┬────┘  │                  │
│  │       └───────────┴───────────┘       │                  │
│  │                ↓                       │                  │
│  │  ┌─────────────────────────────────┐  │                  │
│  │  │     TextureRegistry (Surface)   │  │                  │
│  │  │         ↓                       │  │                  │
│  │  │     PAGSurface (libpag SDK)     │  │                  │
│  │  │         ↓                       │  │                  │
│  │  │     PAGPlayer (渲染控制)         │  │                  │
│  │  └─────────────────────────────────┘  │                  │
│  └───────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### 关键组件

**Dart 层 (lib/pag.dart)**
- `PAGView`: 主要 Widget，支持三种构造方式：
  - `PAGView.asset()` - 加载 Flutter assets
  - `PAGView.network()` - 加载网络资源
  - `PAGView.bytes()` - 加载二进制数据
- `PAGViewState`: 管理单个 PAG 实例的生命周期和 MethodChannel 通信
- `PAG`: 全局配置类（缓存、多线程设置）

**Android 层**
- `FlutterPagPlugin.java`: MethodChannel 处理器，管理插件生命周期
- `FlutterPagPlayer.java`: 继承 `PAGPlayer`，封装动画控制和 ValueAnimator
- `DataLoadHelper.kt`: Kotlin 单例，处理网络资源下载和缓存（内存+磁盘 LRU）
- `WorkThreadExecutor.java`: 单例线程池，控制多线程渲染开关

**iOS 层**
- `FlutterPagPlugin.m`: MethodChannel 处理器
- `TGFlutterPagRender`: 实现 `FlutterTexture` 协议，封装 PAG 渲染
- `TGFlutterPagDownloadManager`: 网络资源下载和本地缓存管理

**HarmonyOS 层**
- `FlutterPagPlugin.ets`: MethodChannel 处理器
- `FlutterPagPlayer.ets`: 继承 PAGPlayer，使用 ArkUI Animator 驱动动画

### 重要设计细节

#### 1. 纹理缓存机制（Android）

Android 端实现了 PAG 实例缓存机制：
- `freeEntryPool`: 复用已释放的 TextureEntry，避免频繁创建/销毁 Surface
- `useCache`: 通过 `PAG.enableCache()` 控制，默认开启
- `maxFreePoolSize`: 通过 `PAG.setCacheSize()` 配置，默认 10 个

#### 2. 多线程渲染（Android）

通过 `WorkThreadExecutor` 控制：
- 默认开启多线程（`multiThread = true`）
- `flush()`、`updateBufferSize()`、`clear()` 等操作在后台线程执行
- 使用 `synchronized` 保护关键区域避免竞态条件
- 可通过 `PAG.enableMultiThread(false)` 关闭

#### 3. 资源加载策略

网络资源加载采用三级缓存：
1. **内存缓存**: LruCache (Android) / NSCache (iOS)
2. **磁盘缓存**: DiskLruCache (Android) / 文件系统 (iOS)，默认 30MB
3. **网络下载**: HttpURLConnection (Android) / NSURLSession (iOS)

#### 4. 平台差异注意点

**Android**:
- 支持纹理复用缓存机制
- 支持多线程渲染切换
- 使用 ValueAnimator 驱动动画进度

**iOS**:
- 使用 CADisplayLink 驱动渲染
- 实现了 `FlutterTexture` 协议

**HarmonyOS**:
- 使用 ArkUI 的 Animator 驱动
- 注意类型转换问题（double/int），代码中有 `+ 0.00001`  workaround

## MethodChannel API

Channel 名称: `flutter_pag_plugin`

| 方法名 | 参数 | 说明 |
|--------|------|------|
| `initPag` | assetName/url/bytesData, repeatCount, initProgress, autoPlay | 初始化 PAG，返回 textureId |
| `start` | textureId | 开始播放 |
| `stop` | textureId | 停止播放（回到初始进度） |
| `pause` | textureId | 暂停播放 |
| `setProgress` | textureId, progress | 设置播放进度 (0-1) |
| `release` | textureId | 释放资源 |
| `getLayersUnderPoint` | textureId, x, y | 获取点击位置下的图层名 |
| `enableCache` | cacheEnabled | 开关缓存（Android） |
| `setCacheSize` | cacheSize | 设置缓存大小（Android） |
| `enableMultiThread` | multiThreadEnabled | 开关多线程（Android） |

回调事件（invokeMethod: `PAGCallback`）:
- `onAnimationStart`
- `onAnimationEnd`
- `onAnimationCancel`
- `onAnimationRepeat`

## 依赖说明

**Android** (android/build.gradle):
- `com.tencent.tav:libpag:4.3.68` - PAG 核心库
- `com.jakewharton:disklrucache:2.0.2` - 磁盘缓存

**iOS** (ios/flutter_pag_plugin.podspec):
- `libpag` - 通过 CocoaPods 引入

**HarmonyOS** (ohos/oh-package.json5):
- `@tencent/libpag` - PAG 鸿蒙版本
