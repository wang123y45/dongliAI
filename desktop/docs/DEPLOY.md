# 公开发布指南

目标：源码在 GitHub 公开，Windows / macOS / Linux 安装包由 GitHub Actions 自动构建，并通过 GitHub Release 对外分发。

## 0. 前置条件

- GitHub 账号
- 本机已安装 Node.js 20+、Git
- 仓库为 **Public**
- 仓库的 Actions 默认权限允许读取仓库内容（默认即可；Release 任务已在 workflow 内声明 `contents: write`）

## 1. 创建公开仓库

在 GitHub 网页端新建仓库：

- Repository name：`dongliAI`
- Visibility：**Public**
- 不要勾选 “Add a README file / .gitignore / license”，本地已经有文件

创建后拿到仓库地址：

```text
https://github.com/wang123y45/dongliAI.git
```

## 2. 首次推送

在项目目录执行：

```bash
cd desktop
git init
git add .
git commit -m "feat: 冻梨AI desktop shell for Windows, macOS and Linux"
git branch -M main
git remote add origin https://github.com/wang123y45/dongliAI.git
git push -u origin main
```

如果本机没有配置 Git 身份：

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

也可以不配置全局，只在当前仓库配置：

```bash
git config user.name "Your Name"
git config user.email "you@example.com"
```

## 3. 触发三平台构建

两种方式：

### 方式 A：手动触发

GitHub → Actions → **Build desktop apps** → **Run workflow** → 选择 `main` 分支。

构建完成后，在该次运行页面底部下载三个 artifact：

- `desktop-windows-latest`：Windows NSIS 安装包
- `desktop-macos-latest`：macOS Universal DMG / ZIP
- `desktop-ubuntu-latest`：Linux AppImage / DEB

### 方式 B：打版本标签，自动创建 Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

`v*` 标签会触发 `.github/workflows/build-desktop.yml`：

1. 三个 runner 并行构建
2. 上传构建产物为 artifact
3. `release` job 汇总产物，创建同名 GitHub Release
4. Release 页面自动生成变更说明

发布后的下载页形如：

```text
https://github.com/wang123y45/dongliAI/releases/tag/v1.0.0
```

## 4. 产物命名

| 平台 | 文件 | 说明 |
|---|---|---|
| Windows | `dongli-ai-1.0.0-x64-setup.exe` | NSIS 安装包，可选择安装目录 |
| macOS | `dongli-ai-1.0.0-universal.dmg` | Apple Silicon + Intel |
| macOS | `dongli-ai-1.0.0-universal.zip` | 免安装压缩包 |
| Linux | `dongli-ai-1.0.0-x64.AppImage` | 直接运行 |
| Linux | `dongli-ai-1.0.0-x64.deb` | Debian / Ubuntu 安装包 |

实际文件名以 `dist/` 和 Release 页面为准。

## 5. 本地手动构建

```bash
npm ci

# 当前系统对应命令
npm run dist:win
npm run dist:mac
npm run dist:linux
```

产物在 `dist/`。

- Windows 上可构建 Windows 包。
- macOS 包建议在 macOS 或 `macos-latest` 上构建。
- Linux 包建议在 Ubuntu 或 `ubuntu-latest` 上构建。
- 不建议用 Windows 交叉打 macOS 包；Universal 合并、签名和公证都依赖 macOS 工具链。

## 6. 签名与信任（可选但推荐）

### Windows

未签名时，用户首次运行可能看到 SmartScreen “未知发布者”。正式分发建议购买代码签名证书，并在 CI 中配置：

```text
CSC_LINK
CSC_KEY_PASSWORD
```

electron-builder 会自动识别这两个环境变量。

### macOS

未签名 / 未公证时，用户需要在“系统设置 → 隐私与安全性”中点击“仍要打开”。正式分发建议：

- Apple Developer ID Application 证书
- `notarize` 配置
- CI 中配置 `APPLE_ID`、`APPLE_APP_SPECIFIC_PASSWORD`、`APPLE_TEAM_ID`

当前仓库默认关闭自动签名发现：

```yaml
env:
  CSC_IDENTITY_AUTO_DISCOVERY: "false"
```

这样没有证书的 fork 也能构建出未签名包。

## 7. 把下载入口放到官网

网页端的“下载手机 APP”目前指向 APK。桌面端可以新增一个下载入口，链接到：

```text
https://github.com/wang123y45/dongliAI/releases/latest
```

建议按平台给三个按钮：

- Windows → `.../releases/latest`（用户自行选择 `.exe`）
- macOS → 同一 Release 页面
- Linux → 同一 Release 页面

如果以后接入自动更新，Release 里需要保留 `latest.yml` / `latest-mac.yml` / `latest-linux.yml`。当前 workflow 上传的是 `dist/**/*`，这些文件会一并进入 Release。

## 8. 常见问题

### Actions 构建失败，提示找不到 `package-lock.json`

首次提交前先在本地执行 `npm install`，生成 `package-lock.json`，一起提交。

### macOS 构建提示无法创建 Universal 包

确认 runner 是 macOS，且 `electron-builder` 版本为 26.x；Universal 构建需要同时下载 x64 与 arm64 的 Electron。

### Linux 缺少 `libfuse2`

AppImage 在部分 Ubuntu 版本需要：

```bash
sudo apt install libfuse2
```

DEB 包会通过系统包管理器处理依赖。

### Release 没有自动创建

检查：

- tag 是否以 `v` 开头
- workflow 是否在 tag push 时触发
- 仓库 Settings → Actions → General 是否允许 Actions 运行
- `permissions: contents: write` 是否被组织策略覆盖

### 安装包太大

Electron 的运行时体积是主要原因。可以在后续版本评估 Tauri，或只保留当前平台的安装包。

## 9. 版本节奏建议

```text
main       日常开发，保持可运行
v1.0.0     首个公开版本
v1.0.1     Bug fix / 小改动
v1.1.0     新功能
```

每次发版只改 `package.json` 的 `version`，提交后打同名 tag：

```bash
npm version patch --no-git-tag-version
git add package.json package-lock.json
git commit -m "chore: release v1.0.1"
git tag v1.0.1
git push origin main
git push origin v1.0.1
```


