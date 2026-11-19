# Web 工作台

Node.js 服务端 + 单页工作台 + 管理后台。所有端共用这一套业务接口。

## 运行

```bash
node server.js
```

环境变量：

| 变量 | 默认 | 说明 |
|---|---|---|
| `PORT` | `19091` | 监听端口 |
| `HOST` | `0.0.0.0` | 生产建议 `127.0.0.1`，由 Nginx 反代 |
| `ADMIN_PASSWORD` | 随机生成 | 首次创建管理员时使用 |

首次启动会在 `data/` 生成用户库、设置、会话密钥和管理员初始密码。`data/` 不提交 Git。

## 路由

- `/`、`/dongli/`：工作台
- `/admin`：管理后台
- `/api/...`：登录、会话、上传、TTS、ASR、管理接口
- `/download/...`：安装包下载（下载文件放在 `public/download/`，该目录不提交 Git）

## 配置

登录后台后配置三个 OpenAI 兼容接口：

- Chat：`/v1/chat/completions`
- Vision：`/v1/chat/completions` + 图片消息
- ASR：`/v1/audio/transcriptions`

默认配置只是本机示例，不包含真实密钥。模型权重、API Key、TTS 服务均需自行部署。
