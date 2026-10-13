# isbf-one.com 域名接入历史记录

2026-10-04 已完成独立生产部署，正式地址为 `https://isbf-one.com`。
当前配置、恢复结果和维护命令见[生产部署记录](isbf-one-production-deployment.md)。
以下内容保留为部署前的检查与恢复历史，不能代表当前生产状态。

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

## 2026-10-04 复核

北京时间 12:25 至 12:26 在宿主机重新检查：

| 项目 | 当前结果 |
| --- | --- |
| 根域名与 www 解析 | 系统解析器均返回 `8.155.132.213` |
| 本机公网 IP | 阿里云实例元数据 `eipv4` 返回 `8.155.132.213` |
| 运行容器 | `discourse_dev`，镜像 `discourse/discourse_dev:release` |
| 网页端口 | 宿主机仍仅发布 `127.0.0.1:3000`，容器内监听 3000 |
| 本机健康检查 | `GET http://127.0.0.1:3000/srv/status` 返回 `200` 和 `ok` |
| 域名主机名检查 | 向 3000 发送 `Host: isbf-one.com` 返回 `403`，页面明确显示 `Blocked hosts: isbf-one.com` |
| HTTP/HTTPS 入口 | 宿主机仍没有监听 80、443 的服务 |
| 官方生产部署 | `/var/discourse` 仍不存在 |
| 宿主机管理权限 | `codex` 属于 `docker` 组，Docker 查询可用；`sudo -n true` 仍要求交互认证 |

当前 DNS 已指向本机，接入域名无需重新添加 A 记录。域名请求的 403 来自开发环境的主机名检查；这次检查时，下面历史恢复记录中的主机名放行没有在当前网页进程中生效。健康检查返回 200 不能证明域名请求已通过。

网页服务已监听 3000，因此此时不要重复执行下面的历史恢复命令。正式接入仍需要按「正式接入步骤」建立生产部署、迁入现有数据库、主题及插件，并配置 80、443 与 HTTPS；只修改 DNS 或放行开发主机名不能完成正式上线。

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

### 当前学院站点的实施顺序

以下步骤用于准备生产部署，当前尚未执行生产构建或数据恢复。

1. 在阿里云 ECS 控制台确认当前实例的安全组入方向允许 TCP 80、443，并确认 `isbf-one.com` 的备案接入状态。DNS 已指向当前实例。
2. 从现有站点后台「备份」创建包含上传文件的备份，并下载到服务器之外。数据库备份包含用户、帖子、设置和主题；插件源代码需要另存。单独导出当前默认主题 ID 4，保存其设置和组件关系。参见[官方备份与恢复说明](https://meta.discourse.org/t/create-download-and-restore-a-backup-of-your-discourse-database/122710)。
3. 将工作区中的已跟踪改动、未跟踪源码和外部插件纳入发布候选版本，记录准确提交。2026-10-04 检查时分支为 `feature/isbf-per-post-anonymous`，HEAD 为 `d91ef8456b91ed8301947c5e46a372642c96b01f`；该提交尚不包含工作区里的全部成果。
4. 使用管理员账号准备独立的 `/var/discourse` 生产部署目录和持久化数据目录。生产构建必须使用学院仓库的发布版本和完整插件源代码，再设置域名、管理员邮箱、发信配置及 HTTPS。
5. 在新生产容器中恢复备份；恢复目标的 Discourse 版本应与来源匹配，并提前安装所需插件。生产数据库独立于开发数据库。恢复后核对域名相关设置、登录回调、旧链接和邮件发送设置。
6. 验证域名访问、登录、邀请、主题资源、上传文件、匿名发布、日历、通知及审核功能，再记录上线版本。需要重新运行学院权限初始化任务时，先核对该任务会重设的设置和权限，参见[插件说明](../plugins/discourse-academy-roles/README.md)。

2026-10-04 检查到以下插件以软链接加载，目标文件在开发容器内均可读取。迁移时需要保存实际源码，并在生产构建中安装；只复制软链接不能确保新容器能访问其目标。

| 插件 | 当前软链接目标 |
| --- | --- |
| `isbf-explore` | `/opt/isbf-releases/isbf-explore/40e1b54ffef384e60502b98ee321349dc8946595` |
| `isbf-moderation` | `/opt/isbf-releases/isbf-moderation/03e26a811be2b789f6ea4b2ac42283a0e5a74e98` |
| `isbf-notifications` | `/src/tmp/isbf-notifications-release-20261001` |
| `isbf-views` | `/src/tmp/isbf-views-fc1db69` |

当时宿主机有约 3.5 GiB 内存，约 1.1 GiB 可用，4 GiB swap 已使用约 2.4 GiB；磁盘可用约 13 GiB。开发容器内 PostgreSQL 数据目录约 336 MiB，上传文件约 6.3 MiB。构建、代码快照及备份前应重新检查容量，并安排开发服务暂停窗口或扩容，为生产构建留出资源。

### 准备生产配置

下面命令由 root 或已完成 sudo 认证的管理员执行，只准备配置目录。当前 Docker 已安装。

```bash
git clone https://github.com/discourse/discourse_docker.git /var/discourse
cd /var/discourse
cp samples/standalone.yml containers/app.yml
```

编辑 `containers/app.yml`，在保留样例其他配置的基础上：

- 设置 `DISCOURSE_HOSTNAME` 为 `isbf-one.com`，填写管理员邮箱和实际 SMTP 配置。
- 启用 `templates/web.ssl.template.yml` 和 `templates/web.letsencrypt.ssl.template.yml`，发布 `80:80` 和 `443:443`。
- 配置构建读取学院仓库的发布提交，并安装所有学院插件。官方模板的 `code` hook 支持在代码更新前调整来源，`params.version` 用于指定版本；具体提交必须等发布候选版本保存后确定。参见[官方 Docker 模板](https://github.com/discourse/discourse_docker/blob/main/templates/web.template.yml)和[hooks 说明](https://github.com/discourse/discourse_docker#hooks)。
- 使用新生产部署的持久化目录保存数据库及上传文件，保持与当前 `/home/codex/discourse/data/postgres` 分离。

上述配置完成、发布源码可访问且 80、443 已放行后，再执行下方的构建命令。新生产容器启动并不代表原站点的数据与定制功能已经迁移；需要继续完成备份恢复和功能验证。

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
