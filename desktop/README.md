# 冻梨AI 桌面端

把 [冻梨AI 工作台](https://www.jhcmzy.top/dongli/) 变成一个可以长期驻留在 Windows、macOS、Ubuntu / Linux 上的桌面应用。

桌面端不是重新实现一套聊天业务，而是用 **Electron 原生壳**承载现有网页工作台：登录态、会话、语音、图片上传、技能插件都继续由同一套服务提供，桌面端只负责窗口、权限、外链、更新与三平台分发。

> 当前状态：源码版 `1.0.0`，Windows 安装包已在本地验证；macOS / Linux 由 GitHub Actions 在对应系统上构建。

## 功能

- 原生窗口：最小尺寸、窗口位置记忆、单实例、原生菜单。
- 登录态持久化：使用 Electron 独立会话，关闭再打开仍保持登录。
- 麦克风 / 通知权限：只对冻梨AI 可信域名放行。
- 安全边界：`contextIsolation` + `sandbox`，关闭 Node 注入；外链交给系统浏览器。
- 断网兜底：服务不可达时显示可重试的离线页，而不是空白窗口。
- 三平台构建：Windows NSIS 安装包、macOS Universal DMG / ZIP、Linux AppImage / DEB。
- 自动发布：推送 `v*` 标签后，GitHub Actions 自动构建并创建 GitHub Release。

## 快速启动

需要 Node.js 20+（本机验证使用 Node.js 22）。

```bash
git clone https://github.com/wang123y45/dongliAI.git
cd dongliAI/desktop
npm install
npm run dev
```

默认加载 `https://www.jhcmzy.top/dongli/`。如果要连本地服务或测试环境：

```powershell
# Windows PowerShell
$env:DONGLI_URL="http://127.0.0.1:19091/"; npm run dev
```

```bash
# macOS / Linux
DONGLI_URL=http://127.0.0.1:19091/ npm run dev
```

也可以使用 `npm start`，效果与 `npm run dev` 相同。

## 打包

```bash
npm run dist:win     # Windows：dist/dongli-ai-1.0.0-x64-setup.exe
npm run dist:mac     # macOS：dist/*.dmg、dist/*.zip（Universal）
npm run dist:linux   # Linux：dist/*.AppImage、dist/*.deb
```

不建议在 Windows 上交叉构建 macOS 包；macOS 的签名、公证和 Universal 合并应在 macOS 或 GitHub Actions 上完成。Linux 包同理，推荐在 Ubuntu runner 上构建。

## 项目结构

```text
dongli-desktop/
├── electron/
│   ├── main.js          # 窗口、菜单、权限、导航、单实例
│   ├── preload.js       # 最小桥接：重试、外链、版本号
│   └── error.html       # 服务不可达时的离线页
├── build/
│   ├── icon.png         # 1024×1024 主图标
│   ├── icon.ico         # Windows
│   └── icon.icns        # macOS
├── assets/brand/        # 品牌源图（不参与运行）
├── scripts/make-icons.py
├── docs/
│   ├── DESIGN.md        # 设计理念与架构取舍
│   └── DEPLOY.md        # GitHub 公开发布流程
├── .github/workflows/build.yml
├── electron-builder.yml
└── package.json
```

## 发布

完整步骤见 [docs/DEPLOY.md](docs/DEPLOY.md)。最短路径：

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions 会并行构建 Windows / macOS / Linux，并把安装包挂到同名的 GitHub Release。

## 已知边界

- 应用依赖线上工作台；离线时只能显示重试页，不能继续对话。
- 当前未接入自动更新（`electron-updater`），升级通过下载新安装包完成。
- macOS 包默认未签名 / 未公证，首次打开需要在“系统设置 → 隐私与安全性”中允许。
- Windows 安装包默认未做代码签名，可能出现 SmartScreen 提示。
- Linux 主要验证 AppImage 与 Debian 包；其他发行版需自行补依赖。

## 许可

代码使用 MIT License。冻梨AI 名称、Logo、图标等品牌资产不随 MIT 授权开放，详见 [NOTICE](NOTICE)。

