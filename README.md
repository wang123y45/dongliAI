# 冻梨AI / Dongli AI

冻梨AI 是一个多端 AI 工作台：网页端提供完整对话、图片理解、长按语音转写、TTS 朗读、技能插件、会员与后台管理；桌面端、Android 和 iOS 通过原生壳复用同一套线上工作台，不复制第二套账号与聊天后端。

- 线上工作台：<https://www.jhcmzy.top/dongli/>
- 管理后台：<https://www.jhcmzy.top/dongli/admin>
- 源码仓库：<https://github.com/wang123y45/dongliAI>

## 目录

```text
web/        Node.js 工作台服务端 + 前端页面 + 品牌资产
desktop/    Electron 桌面壳（Windows / macOS / Linux）
ios/        iOS 原生 WKWebView 工程（Xcode）
android/    Android WebView 工程源码
docs/       设计理念与公开发布流程
```

## 设计理念

**一个业务内核，多个原生入口。**

- 登录、会员、会话、图片理解、ASR、TTS、技能、后台配置全部由 `web/` 的服务端提供，只有一个事实来源。
- 桌面、Android、iOS 只承担壳层职责：窗口/应用生命周期、麦克风与相机权限、外链、安全边界、分发。
- 网页修一次，所有端同时受益；不维护第二套聊天逻辑。

具体取舍见 [docs/DESIGN.md](docs/DESIGN.md)：为什么用 Electron、为什么 iOS 用 WKWebView、安全边界如何收窄，以及不做什么。

## 功能

- 对话：流式回复、历史会话、会员每日额度、试用期。
- 多模态：上传图片做画面/文字理解；加号上传附件；长按录音转文字。
- 语音：TTS 回复，多音色、语速设置。
- 技能：通用、联网搜索、图片理解、写作、总结、翻译、代码、PPT 大纲、数据分析。
- 账号：注册/登录、HttpOnly 会话、管理员后台；API 地址和模型配置只在后台维护，不在前端暴露。
- 多端：Windows 安装包、macOS ZIP、Linux 源码启动、Android APK、iOS Xcode 工程与 GitHub Actions 未签名 IPA。

## 快速启动

### 网页端

需要 Node.js 18+（推荐 20/22）。服务端只使用 Node 内置模块，不需要额外安装依赖。

```bash
cd web
node server.js
```

默认监听 `0.0.0.0:19091`，可用环境变量覆盖：

```bash
PORT=19091 HOST=0.0.0.0 node server.js
```

首次启动会在 `web/data/` 下生成会话密钥、用户库和管理员初始密码；管理员密码文件为 `data/admin_initial_password.txt`。`data/` 已在 `.gitignore` 中排除，不能提交。

后台进入 `/admin`，配置聊天、视觉、ASR 三个 OpenAI 兼容接口的 Base URL、模型名和密钥。默认示例指向本机：

```text
chat     http://127.0.0.1:18081/v1
vision   http://127.0.0.1:18082/v1
asr      http://127.0.0.1:18083/v1
```

### 桌面端

```bash
cd desktop
npm install
npm start
```

默认加载线上 `https://www.jhcmzy.top/dongli/`；开发时可指定本地地址：

```bash
DONGLI_URL=http://127.0.0.1:19091/ npm start
```

打包：

```bash
npm run dist:win
npm run dist:mac
npm run dist:linux
```

macOS 的签名/公证和 Universal 合并应在 macOS 或 GitHub Actions 上完成，不建议 Windows 交叉构建 macOS 包。

### iOS

仓库提供 `.github/workflows/build-ios.yml`：在 GitHub Actions 的 macOS runner 上构建未签名 IPA。

1. Actions → **Build iOS unsigned IPA** → **Run workflow**。
2. 运行完成后在该次 run 的 Artifacts 下载 `dongli-ios-unsigned`，解压得到 `DongliAI-unsigned.ipa`。
3. 用 Sideloadly / AltStore 选择 IPA，以自己的 Apple ID 签名安装；免费账号签名通常 7 天有效。

本地正式签名：用 Xcode 15+ 打开 `ios/DongliAI.xcodeproj`：

1. 选择 `DongliAI` Target → Signing & Capabilities，选择自己的 Team。
2. Bundle ID 默认 `top.jhcmzy.dongli.ios`；如被占用改成自己的唯一 ID。
3. 连接 iPhone 真机运行；首次长按麦克风时允许麦克风权限。
4. 要正式 IPA：`Product → Archive → Distribute App`。

工程是原生 WKWebView 壳，复用线上工作台；麦克风、相机、相册用途已在 `Info.plist` 声明。Windows 环境不能编译/签名 iOS；未签名 IPA 不能直接安装，真机仍需自签或开发者证书。

### Android

`android/` 是 WebView 工程源码，包含 `AndroidManifest.xml`、`MainActivity.java` 和资源。签名用的 `dongli.jks` **不在仓库中**，请使用自己的签名文件构建；参考 `android/build_mic.sh`。

## 部署

### Web 生产部署

Node 进程建议只监听回环地址，由 Nginx 反向代理并终止 TLS：

```bash
cd /www/wwwroot/dongli-ai
PORT=19091 HOST=127.0.0.1 node server.js
```

systemd 示例：

```ini
[Unit]
Description=Dongli AI Workbench
After=network.target

[Service]
WorkingDirectory=/www/wwwroot/dongli-ai
ExecStart=/usr/bin/node server.js
Environment=PORT=19091
Environment=HOST=127.0.0.1
Restart=always
User=www

[Install]
WantedBy=multi-user.target
```

Nginx 关键配置：

```nginx
location /dongli/ {
    proxy_pass http://127.0.0.1:19091/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
    proxy_read_timeout 300s;
}
```

注意：应用内路由同时支持根路径和 `/dongli/` 前缀；如果反代路径与根路径不一致，需按现网 Nginx 重写规则核对下载路由。

### 源码公开与 Release

桌面端 workflow 在根目录 `.github/workflows/build-desktop.yml`，推送 `v*` 标签会并行构建 Windows / macOS / Linux，并把产物挂到 GitHub Release。详细步骤见 [docs/DEPLOY.md](docs/DEPLOY.md)。

## 安全与边界

- 不提交 `data/`、用户库、会话、管理员密码、会话密钥。
- 不提交 Android 签名文件、证书、Token、API Key。
- 服务端会话使用 HttpOnly Cookie；管理员密码只在服务端生成/校验。
- 桌面端 `contextIsolation` + `sandbox`，关闭 Node 注入；只对可信域名开放麦克风/通知。
- iOS 只对 `*.jhcmzy.top` 放行媒体权限；外链交系统 Safari。
- 本项目不包含任何模型权重；模型文件需自行部署并通过后台配置。

## 许可

代码使用 MIT License。冻梨AI 名称、Logo、图标等品牌资产不随 MIT 授权开放，详见 [NOTICE](NOTICE)。
