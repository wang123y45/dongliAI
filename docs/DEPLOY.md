# 公开发布与部署

目标：源码在 GitHub 公开；网页端可独立部署；桌面端通过 GitHub Actions 自动构建 Windows / macOS / Linux 安装包；iOS 通过 GitHub Actions 构建未签名 IPA，Mac 上可本地编译并正式签名。

## 1. 仓库

```text
https://github.com/wang123y45/dongliAI
```

Public，默认分支 `main`。源码目录：

```text
web/        Node 工作台服务端与前端
desktop/    Electron 桌面壳
ios/        Xcode 工程
android/    Android 工程源码
docs/       设计理念与部署说明
```

## 2. 首次推送

```bash
git init
git add .
git commit -m "feat: 冻梨AI multi-platform workbench"
git branch -M main
git remote add origin https://github.com/wang123y45/dongliAI.git
git push -u origin main
```

如果 Git 身份未配置：

```bash
git config user.name "Your Name"
git config user.email "you@example.com"
```

## 3. 网页端部署

### 3.1 运行

```bash
cd web
PORT=19091 HOST=127.0.0.1 node server.js
```

Node 18+；服务端只使用内置模块，没有额外 npm 依赖。

首次启动创建：

```text
web/data/users.json
web/data/settings.json
web/data/session_secret.txt
web/data/admin_initial_password.txt
```

这些文件不要提交。管理员首次登录后应立即在后台修改密码。后台路径 `/admin`，在其中配置：

- 聊天接口 Base URL / 模型名
- 视觉接口 Base URL / 模型名
- ASR 接口 Base URL / 模型名
- API Key、系统提示词、每日额度、试用天数
- TTS 音色与语速

### 3.2 Nginx

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

HTTPS 证书可使用 Certbot / 宝塔面板申请。不要把 Node 端口直接暴露到公网。

### 3.3 systemd

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

```bash
systemctl daemon-reload
systemctl enable --now dongli-ai
systemctl status dongli-ai
```

## 4. 桌面端

```bash
cd desktop
npm ci
npm start
```

构建当前平台：

```bash
npm run dist:win
npm run dist:mac
npm run dist:linux
```

- Windows 上构建 Windows NSIS 安装包。
- macOS 的 Universal DMG/签名/公证在 macOS 或 `macos-latest` 上完成。
- Linux AppImage/DEB 在 Ubuntu 或 `ubuntu-latest` 上完成。
- 未签名包首次运行会被 SmartScreen 或 Gatekeeper 提示，这是正常现象；正式分发建议购买证书。

### 4.1 GitHub Actions

工作流：`.github/workflows/build-desktop.yml`，默认在 `desktop/` 目录执行 npm 命令。

手动触发：Actions → **Build desktop apps** → Run workflow。

打标签自动发 Release：

```bash
git tag v1.0.0
git push origin v1.0.0
```

流程：

1. Windows / macOS / Ubuntu 三个 runner 并行构建。
2. 上传 `desktop/dist/**/*` 为 artifact。
3. Release job 汇总产物，创建同名 GitHub Release。

Release 下载页形如：

```text
https://github.com/wang123y45/dongliAI/releases/tag/v1.0.0
```

### 4.2 签名

Windows 未签名会提示未知发布者；正式分发配置：

```text
CSC_LINK
CSC_KEY_PASSWORD
```

macOS 正式分发需要 Apple Developer ID 证书、公证和 `APPLE_ID` / `APPLE_APP_SPECIFIC_PASSWORD` / `APPLE_TEAM_ID`。当前 workflow 设置 `CSC_IDENTITY_AUTO_DISCOVERY=false`，保证没有证书的 fork 也能构建未签名包。

## 5. iOS

### 5.1 GitHub Actions 生成未签名 IPA

仓库已提供 `.github/workflows/build-ios.yml`，在 macOS runner 上构建并打包未签名 IPA：

1. 打开 Actions → **Build iOS unsigned IPA** → **Run workflow**。
2. 运行成功后，在该次 run 的 **Artifacts** 下载 `dongli-ios-unsigned`。
3. 解压得到 `DongliAI-unsigned.ipa`。
4. 用 Sideloadly / AltStore 选择该 IPA，用自己的 Apple ID 签名后安装到 iPhone。
5. 免费个人 Apple ID 签名通常 7 天有效；正式分发需要 Apple Developer 账号和 Ad Hoc / App Store 证书。

未签名 IPA 不能直接双击安装，也不能绕过 Apple 的签名校验；它只是把“编译 + 打包”放到 GitHub 的 macOS 机器上完成。

### 5.2 Mac 本地编译与正式签名

1. Mac 安装 Xcode 15+。
2. 打开 `ios/DongliAI.xcodeproj`。
3. Target → Signing & Capabilities 选择自己的 Team。
4. Bundle ID 默认 `top.jhcmzy.dongli.ios`，被占用时改成唯一 ID。
5. 连接 iPhone，Run；首次麦克风会弹系统授权。
6. 要正式 IPA：`Product → Archive → Distribute App`（Development / Ad Hoc / App Store）。

Windows 环境不能编译 iOS，也不能完成 Apple 签名；CI 只能产出未签名包，真机安装仍需自签或开发者证书。

命令行模拟器构建：

```bash
cd ios
xcodebuild \
  -project DongliAI.xcodeproj \
  -scheme DongliAI \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO
```

## 6. Android

`android/` 提供 Java WebView 工程源码和资源；签名文件 `dongli.jks` 不在仓库中。使用 Android Studio 新建/导入工程，或参考 `android/build_mic.sh` 用 Gradle 构建，并使用自己的 keystore 签名。

## 7. 版本节奏

```text
main       日常开发，保持可运行
v1.0.0     首个公开版本
v1.0.1     Bug fix
v1.1.0     新功能
```

每次发版修改 `desktop/package.json` 的 `version`，提交后打同名 tag。网页端版本可在 `web/public/manifest.json` 或页面标题中体现。

## 8. 常见问题

### Actions 找不到 package-lock.json

`desktop/package-lock.json` 已提交；如果改动依赖，先在本地 `npm install` 更新 lock。

### 下载链接 404

确认 `web/public/download/` 下存在对应文件；该目录默认被 `.gitignore` 排除，安装包应通过 GitHub Release 或服务器单独分发，不提交进 Git。

### 网页端样式正常但接口 401/404

检查 Nginx 是否正确去掉 `/dongli/` 前缀，以及后台配置的 API Base URL 是否包含 `/v1`。

### iOS 无法真机安装

没有签名 Team 或 Bundle ID 冲突；在 Xcode 中选择自己的 Team 并改成唯一 Bundle ID。
