'use strict';

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('desktop', {
  platform: process.platform,
  version: () => ipcRenderer.invoke('app:version'),
  retry: () => ipcRenderer.send('app:retry'),
  openExternal: (url) => ipcRenderer.send('app:open-external', url),
});
