# 冻梨AI iOS 客户端

这是一个原生 iOS 壳工程：使用 `WKWebView` 加载冻梨AI 网页工作台，同时补齐 iOS 端麦克风、相机、附件上传、对话同步和安全区适配。

## 工程信息

- 工程：`DongliAI.xcodeproj`
- 目标：`DongliAI`
- Bundle ID：`top.jhcmzy.dongli.ios`
- 最低系统：iOS 15.0
- 语言：Swift 5 / UIKit
- 入口：`DongliAI/WebViewController.swift`
- 远程页面：`https://www.jhcmzy.top/dongli/`

## 为什么不是重新写一套聊天后端

iOS 壳复用线上工作台，登录、会员、对话记录、图片理解、ASR、TTS、技能插件都在同一套服务端。这样 iOS、Android、网页端看到的是同一份数据，不需要维护第二套账号和会话系统。

## 已实现

- `WKWebView` 加载工作台，支持 iPhone / iPad
- 安全区适配，键盘和滚动手势可用
- `WKUIDelegate` 媒体权限回调
- 麦克风：先请求 `AVAudioSession` 录音权限，再向 WebView 授予
- 相机：先请求 `AVCaptureDevice` 相机权限，再向 WebView 授予
- `Info.plist` 已写麦克风、相机、相册用途说明
- 录音会话使用 `.playAndRecord`，默认扬声器
- 外链使用 Safari 打开，站内链接留在 App
- 页面加载失败显示重试页

## 在 Mac 上编译

1. 用 Xcode 15 或更高版本打开 `DongliAI.xcodeproj`。
2. 选中 `DongliAI` Target → Signing & Capabilities：
   - Team 选择你的 Apple 开发者账号；
   - 如 Bundle ID 已被占用，改成自己的唯一 ID，例如 `top.jhcmzy.dongli.ios.dev`。
3. 连接 iPhone，选择真机运行。
4. 首次长按麦克风，系统会弹“冻梨AI 想访问麦克风”，选择“允许”。
5. 如果之前拒绝过：设置 → 冻梨AI → 麦克风，打开。

命令行编译模拟器版本：

```bash
xcodebuild \
  -project DongliAI.xcodeproj \
  -scheme DongliAI \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO
```

真机安装需要你自己的 Apple 开发者签名，不能直接复用 Android 的 keystore。

## 打 IPA

Xcode 菜单：

`Product` → `Archive` → `Distribute App` → `Ad Hoc` / `Development` / `App Store`

没有 Apple 开发者账号时，只能在模拟器运行，或用自己的免费个人 Team 做 7 天有效的真机调试包。

## 验收清单

- [ ] 打开 App 能进入登录页
- [ ] 登录后会话列表与网页端一致
- [ ] 长按麦克风首次弹系统授权，允许后能转文字
- [ ] 拒绝麦克风后设置里能重新打开
- [ ] 加号上传图片能识别
- [ ] 自动朗读能出声
- [ ] 横屏/竖屏不遮挡输入框
- [ ] 外链跳到 Safari，不把 App 卡死

## 当前限制

本工程是在 Windows 环境生成的完整 Xcode 工程源码，未在 macOS/Xcode 上实际编译，也未做 iPhone 真机回归。首次在 Mac 打开时如遇到签名或 Asset Catalog 警告，按 Xcode 提示选择 Team 即可。
