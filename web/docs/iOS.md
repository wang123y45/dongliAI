# 冻梨AI iOS 可用方案

## 结论

iOS 端优先用“Safari / PWA + 服务端 ASR”，这是当前成本最低、可立即验证的方案；要做独立 App，再用 WKWebView 壳，不要另写一套聊天页面。

## 一、Safari / PWA（推荐先上线）

当前网页已补：

- `manifest.json`，可“添加到主屏幕”
- `apple-mobile-web-app-capable` 与主题色
- iOS 优先选择 `audio/mp4` 录音
- iOS 麦克风被拒绝时的设置提示
- 长按按钮禁用文本选择与系统菜单

使用要求：

1. 必须通过 `https://www.jhcmzy.top/dongli/` 访问，HTTP 不能调用麦克风。
2. 使用 Safari 或 iOS 14.5+ 的现代浏览器；微信、抖音等内嵌浏览器可能拦截 `getUserMedia`，点右上角“在 Safari 打开”。
3. 第一次长按麦克风，系统会弹权限；选择“允许”。
4. 如果误点拒绝：iPhone 设置 > Safari > 麦克风 > 允许，然后刷新。
5. 录音格式为 `audio/m4a`；实测 `http://127.0.0.1:18083/v1/audio/transcriptions` 已能接收 `audio/mp4`（m4a）并返回文本；`/api/asr` 仍保持原始 multipart 转发。

## 二、WKWebView 原生壳（需要独立 App 时）

关键点不是页面，而是原生层必须实现麦克风授权代理；否则 WKWebView 里 `getUserMedia` 会直接失败。

`Info.plist` 必须包含：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>冻梨AI 需要使用麦克风，把你说的话转成文字。</string>
```

`WKWebView` 配置：

```swift
let config = WKWebViewConfiguration()
config.allowsInlineMediaPlayback = true
config.mediaTypesRequiringUserActionForPlayback = []
let webView = WKWebView(frame: .zero, configuration: config)
webView.uiDelegate = self
```

授权代理（iOS 15+）：

```swift
func webView(
    _ webView: WKWebView,
    requestMediaCapturePermissionFor origin: WKSecurityOrigin,
    initiatedByFrame frame: WKFrameInfo,
    type: WKMediaCaptureType,
    decisionHandler: @escaping (WKPermissionDecision) -> Void
) {
    guard origin.host == "www.jhcmzy.top" || origin.host == "jhcmzy.top" else {
        decisionHandler(.deny)
        return
    }

    switch type {
    case .microphone, .cameraAndMicrophone:
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                decisionHandler(granted ? .grant : .deny)
            }
        }
    case .camera:
        decisionHandler(.prompt)
    @unknown default:
        decisionHandler(.deny)
    }
}
```

进入页面前配置音频会话：

```swift
let session = AVAudioSession.sharedInstance()
try? session.setCategory(.playAndRecord, mode: .default,
                         options: [.defaultToSpeaker, .allowBluetooth])
try? session.setActive(true)
```

注意：

- 必须使用 HTTPS；ATS 不需要额外放开 HTTP。
- `WKUIDelegate` 不实现上面的代理，iOS 端麦克风一定不可用。
- 页面里的“长按”要保留用户手势，不能在 `load` 后自动调用 `getUserMedia`。
- 上架审核时，`NSMicrophoneUsageDescription` 文案要明确说明录音用途。
- 若使用 `AVAudioSession` 播放 TTS，录音开始前先暂停播放，避免占用音频通道。

## 三、版本边界

- iOS 15+：WKWebView + 上述代理，推荐。
- iOS 14.5–14.8：Safari/WKWebView 的 MediaRecorder 可用性因系统版本而异，建议先走 Safari/PWA；WKWebView 需要真机验证。
- iOS 14.5 以下：不建议做网页录音，改用“录音文件上传”或原生 AVAudioRecorder。

## 四、验收清单

1. Safari 打开 `https://www.jhcmzy.top/dongli/`，登录。
2. 第一次长按麦克风出现系统权限弹窗。
3. 允许后长按 2 秒，松开出现“正在转文字”。
4. 输入框出现识别文字并自动发送。
5. 拒绝权限后再次长按，页面提示去设置；从设置允许后刷新可恢复。
6. WKWebView 版重复以上步骤；如果没有权限弹窗，先检查 `WKUIDelegate` 代理是否实现。
