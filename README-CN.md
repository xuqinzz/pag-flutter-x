# 项目介绍
为Flutter打造的PAG动画组件，以外接纹理的方式实现。

**注：如果遇到使用问题请在本仓库提 issue 与作者讨论，或直接提交 pr 参与共建。**

[**PAG官网**](https://pag.art/)

# 快速上手
Flutter侧通过PAGView来使用动画

### 引用
```
dependencies:
  pag: 1.0.0
```

Android端混淆文件中配置，避免影响
```
-keep class org.libpag.**{*;}
```

### 使用本地资源
```
PAGView.asset(
    "assets/xxx.pag", //flutter侧资源路径
    repeatCount: PagView.REPEAT_COUNT_LOOP, // 循环次数
    initProgress: 0.25, // 初始进度
    key: pagKey,  // 利用key进行主动调用
    autoPlay: true, // 是否自动播放
  )
```
### 使用网络资源
```
PAGView.url(
    "xxxx", //网络链接
    repeatCount: PagView.REPEAT_COUNT_LOOP, // 循环次数
    initProgress: 0.25, // 初始进度
    key: pagKey,  // 利用key进行主动调用
    autoPlay: true, // 是否自动播放
  )
```
### 使用二进制数据
```
PAGView.bytes(
    "xxxx", //网络链接
    repeatCount: PagView.REPEAT_COUNT_LOOP, // 循环次数
    initProgress: 0.25, // 初始进度
    key: pagKey,  // 利用key进行主动调用
    autoPlay: true, // 是否自动播放
  )
```
### 可以在PAGView中加入回调参数
以下回调与原生PAG监听对齐
```
PAGView.asset(
    ...
    onAnimationStart: (){  // 开始
      // do something
    },
    onAnimationEnd: (){   // 结束
      // do something
    },
    onAnimationRepeat: (){ // 重复
      // do something
    },
    onAnimationCancel: (){ // 取消
      // do something
    },
```

### 动态替换图片图层

PAG 文件中的可编辑图片图层可在初始化时通过 `images` 参数替换，列表下标对应 PAGFile 中可编辑图片的顺序（0-based），传 `null` 表示跳过该位置。

```dart
PAGView.asset(
  "assets/xxx.pag",
  images: [
    PAGImageEdit(imageBytes),  // 替换第 0 个可编辑图片图层
    null,                       // 跳过第 1 个
    PAGImageEdit(otherBytes),  // 替换第 2 个
  ],
)
```

`PAGImageEdit` 接受 `Uint8List?` 类型，支持 JPEG、PNG、WebP 等常见格式的二进制数据。

### 动态替换文字图层

PAG 文件中的可编辑文字图层可在初始化时通过 `texts` 参数替换，列表下标对应 PAGFile 中可编辑文字的顺序（0-based），传 `null` 表示跳过该位置。

```dart
PAGView.asset(
  "assets/xxx.pag",
  texts: [
    PAGTextEdit(
      text: '替换文字',         // 文字内容
      fontSize: 24,             // 字号（可选）
      fillColor: 0xFFFF0000,    // 填充色，0xAARRGGBB 格式（可选）
      strokeColor: 0xFF000000,  // 描边色，0xAARRGGBB 格式（可选）
      fontFamily: 'PingFang SC', // 字体（可选）
      fontStyle: 'Bold',         // 字体样式（可选）
    ),
    null,  // 跳过第 1 个
  ],
)
```

所有字段均为可选，仅传入需要修改的属性即可，未设置的属性保持 PAG 文件中的原始值。

### 同时替换图片和文字

```dart
PAGView.asset(
  "assets/xxx.pag",
  autoPlay: true,
  images: [PAGImageEdit(avatarBytes)],
  texts: [PAGTextEdit(text: '用户昵称', fillColor: 0xFFFFFFFF)],
)
```

### 通过key获取state进行主动调用
```
  final GlobalKey<PAGViewState> pagKey = GlobalKey<PAGViewState>();
  
  //传入key值
  PAGView.url(key:pagKey）
  
  //播放
  pagKey.currentState?.start();
  
  //暂停
  pagKey.currentState?.pause();  
  
  //停止
  pagKey.currentState?.stop();  
  
  //设置进度
  pagKey.currentState?.setProgress(xxx);
  
  //获取坐标位置的图层名list
  pagKey.currentState?.getLayersUnderPoint(x,y);
```
