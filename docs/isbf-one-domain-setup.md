# isbf-one.com 域名接入记录

## 已确认的配置

2026-10-03 在当前服务器检查到以下状态。进程和网络配置可能变化，操作前应重新验证。

| 项目 | 检查结果 |
| --- | --- |
| 域名 | `isbf-one.com` |
| DNS 服务商 | 阿里云，权威服务器为 `dns21.hichina.com`、`dns22.hichina.com` |
| 根域名 A 记录 | `isbf-one.com → 8.155.132.213`，TTL 为 600 秒 |
| www A 记录 | `www.isbf-one.com → 8.155.132.213`，TTL 为 600 秒 |
| 根域名 AAAA 记录 | 未查询到 |
| 本机公网 IP | 阿里云实例元数据 `eipv4` 返回 `8.155.132.213` |
| 阿里云地域 | `cn-heyuan`，广东河源 |
| 代码目录 | `/home/codex/discourse` |
| 运行容器 | `discourse_dev`，镜像 `discourse/discourse_dev:release` |
| 网页端口 | 宿主机 `127.0.0.1:3000` 转发到容器 3000 端口 |
| 其他已发布端口 | 8025、9292、9405，均只绑定宿主机回环地址 |
| 公网 HTTP/HTTPS 入口 | 检查时宿主机没有监听 80、443 的服务 |
| 官方生产部署目录 | 检查时 `/var/discourse` 不存在 |

域名已正确解析到当前服务器，接入这台服务器无需重建 A 记录。

当前用户为 `codex`，`sudo -n true` 提示需要交互认证。环境未发现阿里云 CLI 或阿里云认证环境变量；阿里云安全组规则和域名 ICP 备案状态尚未核实。服务器命令行访问不能替代阿里云控制台登录权限。

## 本次网页服务恢复

检查时容器内 PostgreSQL、Redis、Sidekiq 和前端构建进程仍在运行，但没有网页进程监听 3000。沿用[开发站点故障排查](development-service-troubleshooting.md)中的恢复方式，单独启动网页服务，并允许两个域名通过开发环境主机名检查：

```bash
docker exec -d -u discourse:discourse -w /src \
  -e RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
  -e LD_PRELOAD=/usr/lib/libjemalloc.so \
  -e NO_COLOR=1 \
  -e RAILS_DEVELOPMENT_HOSTS=isbf-one.com,www.isbf-one.com \
  discourse_dev bash -lc \
  'exec bin/pitchfork -p 3000 -x >> /tmp/isbf-rails-domain-20261003.log 2>&1'
```

执行恢复命令前，必须确认 3000 没有监听，避免重复启动。`-x` 使用现有 Sidekiq，不再启动第二份后台任务。

验证结果：

- 启动输出出现 `Pitchfork ready on http://localhost:3000`，三个网页工作进程启动。
- 宿主机 `http://127.0.0.1:3000/srv/status` 返回 `200` 和 `ok`。
- 通过本地端口发送 `Host: isbf-one.com`，首页返回 `200`，标题为 `ISBF-Space`。
- 首页仍包含 `http://localhost:3000` 链接。允许域名通过主机名检查不等于设置了正式站点地址。

这些结果仅验证本机服务；公网域名访问尚未接通。开发服务在容器重启后需要重新启动，仍需要按照故障排查文档完善进程监护。

## 正式接入步骤

1. 保存当前数据库、上传文件、后台主题、自定义插件和未提交代码。按[学院论坛开发协作规范](academy-development-workflow.md)确定生产部署使用的代码版本和数据，生产环境采用独立部署目录及数据库。
2. 使用 [Discourse 官方生产安装指南](https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md)建立生产部署，安装向导中的域名填写 `isbf-one.com`。自定义插件和后台主题需要纳入这次部署和数据迁移，默认新安装不会自动包含当前开发站的内容。
3. 在阿里云 ECS 安全组和服务器防火墙中开放 TCP 80、443，生产服务也必须实际监听这两个端口。数据库、Redis、邮件捕获和开发端口继续保持内网访问。
4. 根据阿里云当前规则确认 ICP 备案：该服务器位于中国内地，对外提供域名网站服务需要完成备案。详见[阿里云网站备案说明](https://help.aliyun.com/zh/ecs/user-guide/build-a-website/)。备案状态需要通过阿里云或工信部查询确认。
5. DNS 和端口满足条件后，官方安装器会申请 HTTPS 证书。使用 `isbf-one.com` 作为主地址；如需支持 `www.isbf-one.com`，另外配置覆盖 www 的证书和跳转到主地址的规则。
6. 如果迁移现有站点，检查站点设置中的旧地址、登录提供商回调地址及帖子中的旧链接。详见[官方修改域名说明](https://meta.discourse.org/t/change-the-domain-name-or-rename-your-discourse/16098)。

官方 Docker 生产部署创建后，其配置文件 `/var/discourse/containers/app.yml` 的 `env` 下应包含：

```yaml
DISCOURSE_HOSTNAME: 'isbf-one.com'
```

修改已有生产配置后，在生产部署目录执行：

```bash
cd /var/discourse
./launcher rebuild app
```

该命令适用于官方生产部署，不适用于当前 `discourse_dev` 容器。

当前开发配置会显示详细错误页面，且站点地址仍为 localhost；正式上线应使用生产环境，而不是直接公开开发容器。

## 验证命令

在当前宿主机检查 DNS 与本机服务：

```bash
dig @dns21.hichina.com +noall +answer isbf-one.com A
dig @dns21.hichina.com +noall +answer www.isbf-one.com A
ss -ltn '( sport = :80 or sport = :443 or sport = :3000 )'
curl --noproxy '*' --max-time 10 http://127.0.0.1:3000/srv/status
curl --noproxy '*' --max-time 10 -I -H 'Host: isbf-one.com' http://127.0.0.1:3000/
```

正式部署完成后，从服务器以外的网络检查 `https://isbf-one.com`：证书覆盖域名，首页、登录、主题资源、上传文件及消息通知都正常，生成的链接使用正式域名。
