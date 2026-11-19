# Android 工程源码

这是冻梨AI 的 Android WebView 壳源码，复用线上工作台：

- `src/top/jhcmzy/dongli/MainActivity.java`：WebView、麦克风权限、文件选择、返回键处理。
- `AndroidManifest.xml`：网络、录音、相机权限。
- `res/`：图标、应用名等资源。

## 构建

1. 用 Android Studio 新建一个 Empty Views Activity 工程，包名 `top.jhcmzy.dongli`。
2. 用本目录的 `MainActivity.java`、`AndroidManifest.xml` 和 `res/` 替换对应文件。
3. 设置 `compileSdk` / `minSdk` 后构建 Debug APK。

或参考 `build_mic.sh` 使用 `aapt2`、`javac`、`d8`、`apksigner` 手动构建；脚本中的 SDK 路径和 keystore 路径需要按本机修改。

## 签名

仓库**不包含** `dongli.jks`、证书密码或已签名 APK。请使用自己的 keystore 签名：

```bash
apksigner sign --ks your-key.jks --out dongli.apk app-unsigned.apk
```

不要把签名文件、密码或正式发布 APK 提交到仓库。
