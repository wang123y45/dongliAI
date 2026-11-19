'use strict';

const { app, BrowserWindow, Menu, shell, session, ipcMain, screen, dialog, nativeImage } =
  require('electron');
const path = require('node:path');
const fs = require('node:fs');

// 桌面端默认连接线上工作台；本地调试可用 DONGLI_URL 指向本地服务。
const APP_URL = (process.env.DONGLI_URL || 'https://www.jhcmzy.top/dongli/').replace(/\/?$/, '/');
const APP_NAME = '冻梨AI';
const APP_ID = 'top.jhcmzy.dongli';

const TRUSTED_HOSTS = new Set([
  'www.jhcmzy.top',
  'jhcmzy.top',
  'localhost',
  '127.0.0.1',
  '::1',
]);

let mainWindow = null;
let showingError = false;
let isQuitting = false;

app.setName(APP_NAME);
app.setAppUserModelId(APP_ID);

function trustedUrl(raw) {
  try {
    const url = new URL(raw);
    if (url.protocol !== 'https:' && url.protocol !== 'http:') return false;
    if (!TRUSTED_HOSTS.has(url.hostname)) return false;
    if (url.protocol === 'http:' && !['localhost', '127.0.0.1', '::1'].includes(url.hostname)) {
      return false;
    }
    return true;
  } catch {
    return false;
  }
}

function trustedOrigin(raw) {
  try {
    const url = new URL(raw);
    return trustedUrl(url.origin);
  } catch {
    return false;
  }
}

function appIcon() {
  const icon = app.isPackaged
    ? path.join(process.resourcesPath, 'icon.png')
    : path.join(__dirname, '..', 'build', 'icon.png');
  return fs.existsSync(icon) ? nativeImage.createFromPath(icon) : undefined;
}

function windowStateFile() {
  return path.join(app.getPath('userData'), 'window-state.json');
}

function loadWindowState() {
  try {
    const state = JSON.parse(fs.readFileSync(windowStateFile(), 'utf8'));
    if (
      Number.isFinite(state.width) &&
      Number.isFinite(state.height) &&
      Number.isFinite(state.x) &&
      Number.isFinite(state.y)
    ) {
      const visible = screen.getAllDisplays().some((display) => {
        const area = display.workArea;
        return (
          state.x < area.x + area.width &&
          state.x + state.width > area.x &&
          state.y < area.y + area.height &&
          state.y + state.height > area.y
        );
      });
      if (visible) return state;
    }
  } catch {
    // 首次启动或状态文件损坏时使用默认尺寸。
  }
  return { width: 1180, height: 820 };
}

function saveWindowState(win) {
  if (!win || win.isDestroyed()) return;
  try {
    const bounds = win.getNormalBounds();
    fs.writeFileSync(
      windowStateFile(),
      JSON.stringify({
        x: bounds.x,
        y: bounds.y,
        width: bounds.width,
        height: bounds.height,
      }),
      'utf8',
    );
  } catch {
    // 状态保存失败不影响主流程。
  }
}

function installMenu() {
  const isMac = process.platform === 'darwin';
  const template = [
    ...(isMac
      ? [
          {
            label: APP_NAME,
            submenu: [
              { role: 'about', label: `关于 ${APP_NAME}` },
              { type: 'separator' },
              { role: 'services' },
              { type: 'separator' },
              { role: 'hide' },
              { role: 'hideOthers' },
              { role: 'unhide' },
              { type: 'separator' },
              { role: 'quit', label: `退出 ${APP_NAME}` },
            ],
          },
        ]
      : [
          {
            label: '文件',
            submenu: [
              { label: '打开官网', click: () => shell.openExternal(APP_URL) },
              { type: 'separator' },
              { role: 'quit', label: '退出' },
            ],
          },
        ]),
    {
      label: '编辑',
      submenu: [
        { role: 'undo', label: '撤销' },
        { role: 'redo', label: '重做' },
        { type: 'separator' },
        { role: 'cut', label: '剪切' },
        { role: 'copy', label: '复制' },
        { role: 'paste', label: '粘贴' },
        { role: 'selectAll', label: '全选' },
      ],
    },
    {
      label: '视图',
      submenu: [
        { role: 'reload', label: '重新载入' },
        { role: 'forceReload', label: '强制刷新' },
        { type: 'separator' },
        { role: 'resetZoom', label: '实际大小' },
        { role: 'zoomIn', label: '放大' },
        { role: 'zoomOut', label: '缩小' },
        { type: 'separator' },
        { role: 'togglefullscreen', label: '切换全屏' },
        ...(app.isPackaged ? [] : [{ type: 'separator' }, { role: 'toggleDevTools', label: '开发者工具' }]),
      ],
    },
    {
      label: '窗口',
      submenu: [
        { role: 'minimize', label: '最小化' },
        ...(isMac ? [{ role: 'zoom', label: '缩放' }] : []),
      ],
    },
    {
      label: '帮助',
      submenu: [
        { label: '冻梨AI 网页版', click: () => shell.openExternal(APP_URL) },
        {
          label: 'GitHub 项目',
          click: () => shell.openExternal('https://github.com/wang123y45/dongliAI'),
        },
        { type: 'separator' },
        { role: 'about', label: '关于' },
      ],
    },
  ];

  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

function configurePermissions() {
  const allowedPermissions = new Set([
    'media',
    'notifications',
    'clipboard-sanitized-write',
    'fullscreen',
  ]);

  session.defaultSession.setPermissionCheckHandler((_webContents, permission, requestingOrigin) => {
    return trustedOrigin(requestingOrigin) && allowedPermissions.has(permission);
  });

  session.defaultSession.setPermissionRequestHandler((webContents, permission, callback, details) => {
    const origin = details?.requestingUrl || webContents.getURL();
    callback(trustedOrigin(origin) && allowedPermissions.has(permission));
  });
}

function createWindow() {
  const state = loadWindowState();
  const options = {
    width: state.width,
    height: state.height,
    ...(Number.isFinite(state.x) && Number.isFinite(state.y) ? { x: state.x, y: state.y } : {}),
    minWidth: 920,
    minHeight: 640,
    show: false,
    title: APP_NAME,
    backgroundColor: '#f4f7fb',
    autoHideMenuBar: false,
    icon: appIcon(),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      webviewTag: false,
      spellcheck: true,
      backgroundThrottling: false,
      allowRunningInsecureContent: false,
    },
  };

  mainWindow = new BrowserWindow(options);
  showingError = false;

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
    mainWindow.focus();
  });

  mainWindow.on('close', () => saveWindowState(mainWindow));
  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  const wc = mainWindow.webContents;

  wc.setWindowOpenHandler(({ url }) => {
    if (trustedUrl(url)) return { action: 'allow' };
    if (/^https?:\/\//i.test(url)) shell.openExternal(url);
    return { action: 'deny' };
  });

  wc.on('will-navigate', (event, url) => {
    if (url.startsWith('file://') && url.includes('error.html')) return;
    if (url === APP_URL || trustedUrl(url)) return;
    event.preventDefault();
    if (/^https?:\/\//i.test(url)) shell.openExternal(url);
  });

  wc.on('will-redirect', (event, url) => {
    if (url.startsWith('file://') && url.includes('error.html')) return;
    if (url === APP_URL || trustedUrl(url)) return;
    event.preventDefault();
    if (/^https?:\/\//i.test(url)) shell.openExternal(url);
  });

  wc.on('did-fail-load', (_event, errorCode, errorDescription, validatedURL, isMainFrame) => {
    if (!isMainFrame || errorCode === -3 || showingError) return;
    loadErrorPage({ code: errorCode, description: errorDescription, url: validatedURL });
  });

  wc.on('render-process-gone', (_event, details) => {
    if (details.reason === 'clean-exit') return;
    dialog.showMessageBox(mainWindow, {
      type: 'error',
      title: '页面进程异常',
      message: '冻梨AI 页面进程意外退出，窗口将重新载入。',
      detail: `原因：${details.reason}`,
      buttons: ['重新载入'],
    }).then(() => loadApp());
  });

  loadApp();
}

function loadApp() {
  if (!mainWindow || mainWindow.isDestroyed()) return;
  showingError = false;
  mainWindow.loadURL(APP_URL).catch((error) => {
    if (showingError) return;
    loadErrorPage({ code: error?.errno || '', description: error?.message || '无法连接工作台' });
  });
}

function loadErrorPage({ code, description, url }) {
  if (!mainWindow || mainWindow.isDestroyed() || showingError) return;
  showingError = true;
  mainWindow
    .loadFile(path.join(__dirname, 'error.html'), {
      query: {
        url: APP_URL,
        code: String(code || ''),
        description: String(description || '网络连接失败'),
        failed: String(url || ''),
      },
    })
    .catch(() => {
      // 离线页本身加载失败时保留原生窗口，用户可通过菜单重新载入。
      showingError = false;
    });
}

ipcMain.on('app:retry', () => loadApp());

ipcMain.on('app:open-external', (_event, url) => {
  if (typeof url === 'string' && /^https?:\/\//i.test(url)) shell.openExternal(url);
});

ipcMain.handle('app:version', () => app.getVersion());

const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (!mainWindow) return;
    if (mainWindow.isMinimized()) mainWindow.restore();
    mainWindow.show();
    mainWindow.focus();
  });

  app.whenReady().then(() => {
    app.setAboutPanelOptions({
      applicationName: APP_NAME,
      applicationVersion: app.getVersion(),
      copyright: 'Copyright © 2026 冻梨AI',
      website: APP_URL,
    });
    configurePermissions();
    installMenu();
    createWindow();
  });

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });

  app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
  });

  app.on('before-quit', () => {
    isQuitting = true;
  });
}

// 显式引用，避免部分打包器在静态分析时误删。
void isQuitting;
