# isbf-one.com 生产部署记录

2026-10-07 更新：当前生产提交为 `52eebcedf40f7f623278f71921574a095b1864e0`。
默认密码登录及明显的邮箱验证码入口已上线，最新备份、回退版本和清理记录见
[邮箱验证码登录入口发布记录](login-email-code-entry-production.md)。经用户确认，
下文历史记录中的旧数据备份、旧回退容器和旧备份镜像已清理，不再作为恢复入口。

2026-10-04 将已备份的学院站点恢复到独立生产容器。主地址为
`https://isbf-one.com`，HTTP 和 `https://www.isbf-one.com` 均跳转到主域名。
用户已确认 ICP 备案和阿里云接入完成，并授权暂停开发站进行部署。

## 运行位置与版本

| 项目 | 配置 |
| --- | --- |
| ECS 公网 IP / 地域 | `8.155.132.213` / `cn-heyuan` |
| DNS | 根域名与 www 的 A 记录均指向 `8.155.132.213` |
| 生产部署目录 | `/home/codex/discourse-production` |
| 容器配置 | `containers/isbf_app.yml`，权限 `600` |
| 生产容器 / 重启策略 | `isbf_app` / `always` |
| 公网端口 | TCP 80、443；数据库和 Redis 不发布端口 |
| 生产持久数据 | `shared/standalone`，独立于开发数据库 |
| 首次发布源码 | `e90bcbf75395a911a0c8368e07cf8f253375ca09` |
| 邮件接入时的生产源码 | `1575e9c1de2ae36bd1a2bbf34371029fa3c751dc` |
| 备份源码基线 | `3d11a61699f737f797f6073d1cc3a84790536127` |
| 官方 Docker 部署源码 | `8d705a91866c320592ce851f30895ddb4c3e85fe` |
| 本地发布仓库 | `release.git`，只读挂载进构建容器 |
| 原开发容器 | `discourse_dev`，已停止，容器和原数据保留 |

首次发布提交相对备份基线仅修正八个插件测试文件，生产权限逻辑保持备份版本。
原工作区的分支、未提交源码和外部插件均保留。构建包含九个定制插件的实际文件。
基础镜像的部分克隆与本地仓库不兼容；`before_code` hook 使用完整的固定发布
检出替换临时构建容器的工作树，并保留 ignore 规则保护的依赖缓存。

## 数据恢复与验证

原生备份为 `site-20261003-221122-v20261002060453.tar.gz`，包含数据库及上传文件。
SHA256 为：

```text
74eddd583745aa5c87ec5fbd29bc03e1d5500f40c4be6f4fbd2215d507dca8bf
```

先通过本机 `127.0.0.1:8080` 恢复并验收，再切换到公网 HTTPS。

| 项目 | 核验结果 |
| --- | --- |
| 用户 / 主题帖 / 帖子 | 12 / 44 / 71 |
| 上传记录 | 恢复时 19；后台清理后 17 |
| 默认主题 | ID 4，`ISBF Campus Feed`，无编译错误 |
| 登录 / 注册限制 | 保持 `login_required=true`、`invite_only=true` |
| 首次恢复时发信 | `DISCOURSE_DISABLE_EMAILS="yes"`，未配置 SMTP；后续已启用，见下文 |

恢复时原始 19 条上传及文件均完整。后台正常清理了两条 2026-09-30 创建、
无上传引用的旧记录（ID 23、24）；保留的 17 个上传文件仍均完整。
原备份未修改，审计见生产目录的 `deploy/upload-cleanup-audit.json`。

九个插件均加载成功：学院角色、账号切换、匿名发布、日历、探索、审核、通知、
转发、浏览量。账号关联、匿名池、日历及浏览量等插件表计数与备份一致。
没有重新执行会重设设置和分类权限的 `academy_roles:setup`。

- 九插件联合 RSpec：170 项，0 失败；八个修改的 Ruby 文件通过 `bin/lint --fix`。
- 使用真实管理员和普通成员验证身份、列表、日历、探索设置、通知及后台权限。
  普通成员访问后台返回 404，管理员返回 200；临时只读 API 密钥已删除。
- 登录页标题为 `ISBF-Space`，引用默认主题 ID 4；29 个脚本和样式均返回 200。
- 本机及外网 HTTPS 健康检查返回 200，TLS 校验为 0。
- HTTP 和 HTTPS www 请求均返回 301，目标为 HTTPS 根域名。
- 页面不再引用 `localhost:3000` 或临时 `isbf-one.com:8080` 地址。

报告、构建和恢复日志位于生产目录的 `deploy/`，发布清单为 `deploy/manifest.json`。
首次恢复时关闭了常规发信，后续已接入 SMTP。管理员测试邮件等指定邮件类型
可以绕过 `disable_emails`，不能将该设置理解为所有邮件类型的绝对阻断。
最终维护只读锁已解除，站点可正常写入；备份恢复开关已关闭。

## HTTPS 与续签

官方 SSL 与 Let's Encrypt 模板签发的 RSA、ECDSA 证书覆盖根域名和 www，
本次证书有效期至 2027-01-02。证书与账户状态持久化在 `ssl/`、`letsencrypt/`。
root 的 acme.sh cron 已安装；使用实际 cron 环境运行的续签检查成功，识别
证书尚未到期，下一次续签时间为 2026-12-02。

宿主机代理监听 `127.0.0.1:17897`。`isbf_proxy` 仅在 Docker 网桥
`172.17.0.1:17897` 转发到该代理，不监听公网。生产容器经代理联网，并只读
挂载宿主机 CA bundle，保持 TLS 校验。宿主机代理须持续可用；地址变化时需
同步更新生产配置及转发脚本。

配置的 `run` 段保存启动时的 cron 代理、CA 环境设置，并使用系统信任根加
中间证书校验证书链。当前容器已应用；使用完整配置重建时会再次安装。

## 维护与重建

2026-10-07 此前发布官方活动四格布局，当时的后端生产提交为
`d57b39a0d6c721db10f955de66ec027d4b01e545`，日历插件版本为 `0.3.0`。
最新备份、验收和回退信息见[官方活动布局发布记录](isbf-official-activity-layout.md)。
默认主题的标题修复源码提交为
`d9173c9b5d34545b2ea02ba8eb9bf30c18b689d6`，已直接同步生产主题。
后续新建消息的标题校验提示修复提交为
`a342c72d270357036377bc61c3a00c8d43872049`，也以增量方式同步到默认主题；
详见[标题校验修复记录](isbf-composer-title-validation.md)。
备份、验收和回退信息见[官方消息日历生产发布记录](isbf-official-calendar-production.md)。
同日此前的账号切换后台路由修复见
[账号切换路由修复记录](account-switch-resolver-fix.md)。2026-10-04 的学号邀请码
发布记录见[学号邀请码生产发布记录](academy-student-invitations-production.md)。

由具有当前 Docker socket 权限的用户执行：

```bash
cd /home/codex/discourse-production
docker exec isbf_app sv status nginx unicorn postgres redis
curl --noproxy '*' --resolve isbf-one.com:443:127.0.0.1 \
  https://isbf-one.com/srv/status
```

长时间维护使用持久只读键。CLI 默认 `discourse enable_readonly` 使用 60 秒
临时键，命令退出后不能持续续期。

```bash
docker exec isbf_app rails runner \
  'Discourse.enable_readonly_mode(Discourse::USER_READONLY_MODE_KEY)'

# 维护完成后
docker exec isbf_app rails runner \
  'Discourse.disable_readonly_mode(Discourse::USER_READONLY_MODE_KEY)'
```

更新前创建新备份，记录提交，并使 `release.git` 与 `params.version` 一致。
检查容量后用完整配置重建：

```bash
cd /home/codex/discourse-production
./launcher rebuild isbf_app
```

首次发布镜像尚未包含续签调整，不能直接销毁后使用它重建容器。邮件接入时
使用的现有生产镜像已核验包含 cron 环境和证书链调整；仅修改运行时环境变量
可以复用这个镜像重新创建容器。单纯重启现有容器不会加载宿主机 YAML 的改动。
当前邮件开关由环境强制覆盖，单独修改后台设置不会生效。

### STARTTLS 提示修正（2026-10-06）

已复用当前生产镜像重新创建 `isbf_app`，生产提交仍为
`403bce2f3c83711a5f2891eef0b82d6941e5ae5c`。仅将
`DISCOURSE_SMTP_ENABLE_START_TLS` 从 false 改为 true，覆盖镜像中保存的旧值；
`DISCOURSE_SMTP_FORCE_TLS=true`、465 端口和 `peer` 证书验证继续生效。
运行时 `enable_starttls_auto=false`、`tls=true`，后台 STARTTLS 检查已无问题。

变更前完整备份为
`shared/standalone/starttls-20261006-075935/before-starttls-20261006-075935-v20261004090640.tar.gz`，
已校验 gzip 完整性，并确认归档包含数据库和上传文件。SHA256：

```text
353caa3ddc80315aba749c563a79e74a45b0779d9e56afbcf3003deb8eccffe3
```

重建后 HTTPS 健康检查通过，SMTP TLS 证书验证与认证通过，未发送测试邮件。
用户、主题帖、帖子、上传计数仍为 13 / 31 / 53 / 20，所有上传文件完整；
默认主题 ID 4、主题字段与设置哈希、账号关联和审计记录计数均与变更前一致。
维护只读锁已解除。验收报告位于生产目录
`deploy/starttls-20261006-075935/`。

旧容器保留为 `isbf_app_before_starttls_20261006_075935`，已停止且重启策略为
`no`。回退时先停止新容器，再恢复旧配置与旧容器，避免两个容器同时使用相同
数据库卷。删除配置中的变量无法覆盖复用镜像内的旧值；本次首次切换因此在
验收时自动回退，明确设为 true 后重建成功。

## 启用邮件发送

2026-10-04 已接入阿里云邮件推送并开启常规发信：

| 项目 | 当前值 |
| --- | --- |
| 服务区域 | 华东 1（杭州） |
| 发件人 / SMTP 用户名 | `noreply@mail.isbf-one.com` |
| SMTP 主机 / 端口 | `smtpdm.aliyun.com` / `465` |
| 认证 / 加密 / 证书验证 | `login` / 隐式 TLS / `peer` |
| 发信开关 | `DISCOURSE_DISABLE_EMAILS="no"` |
| 投递验证 | TLS 与认证通过；一封论坛测试邮件获 SMTP `250` 接收 |
| 收件箱确认 | 用户已确认测试邮件进入收件箱 |

SMTP 接入后，之前打开的页面可能仍显示“所有外发电子邮件已被全局禁用”。
2026-10-04 排查确认运行中的 `disable_emails` 和浏览器新页面预加载值均为 `no`，
并通过 `SiteSetting.notify_clients!(:disable_emails)` 同步当前状态给在线页面。
环境变量变更不会自动更新已经加载的浏览器设置；刷新页面可获取新值。
遇到此提示应同时核对运行中的邮件开关与新页面设置，无需为旧页面提示重建容器。

变更前原生备份为
`isbf-before-smtp-20261004-124812-v20261004090640.tar.gz`。变更前后用户、主题帖、
帖子、上传计数均为 13 / 27 / 48 / 17，默认主题 ID 4 无编译错误、所有插件
保持加载、上传文件完整。发信配置加载后 HTTPS 健康检查返回 200，维护只读
锁已解除。此次只修改邮件配置，保留接入前生产源码和镜像。

生产容器重启策略仍为 `always`。变更前容器保留为
`isbf_app_before_smtp_20261004_125405`，已停止且重启策略为 `no`；回退时必须
先停止新生产容器，不能让两个容器同时使用相同数据库卷。SMTP 参数保存在
权限为 `600` 的 `containers/isbf_app.yml`，临时录入文件接入后删除。
验证报告为 `deploy/smtp-auth-verification.json`、`smtp-test-verification.json`、
`smtp-final-state.json`，配置参考副本已隐藏密码，不可直接用于启动。

以下保留接入流程。先选择邮件服务并取得 SMTP 服务器地址、
端口、认证用户名、SMTP 密码或授权码，以及服务商允许使用的发件人地址。
这些参数不能通过购买域名或启用 HTTPS 自动获得。

如使用阿里云邮件推送，可使用 `mail.isbf-one.com` 作为独立发信子域名，
按控制台提供的实际值配置域名验证、SPF、DKIM、DMARC、MX 记录，再创建
例如 `noreply@mail.isbf-one.com` 的发信地址并设置 SMTP 密码。
SMTP 主机须对应发信地址所在的服务区域。参考
[发信域名配置](https://help.aliyun.com/zh/direct-mail/user-guide/how-to-configure-sending-domain-names)
和[SMTP 发信配置](https://help.aliyun.com/zh/direct-mail/user-guide/send-emails-using-smtp)。

用户已确认邮件推送区域为华东 1（杭州）、发信域名已验证通过，且已创建
`noreply@mail.isbf-one.com`。服务器 SMTP 接入已完成，测试邮件已获服务商接收。
以下保留从零开通步骤，供后续维护参考。

1. 登录[邮件推送控制台](https://dm.console.aliyun.com/)，核对计费说明并开通。
2. 服务区域选择华东 1（杭州）。
3. 在“发信域名”中新增 `mail.isbf-one.com`，打开“配置”查看实际 DNS 记录。
4. 若域名和服务属于同一阿里云账户且满足自动配置条件，可使用控制台的自动
   解析；否则到域名解析控制台逐项填写提供的 DNS 记录，随后执行域名验证。
5. 验证成功后创建发信地址 `noreply@mail.isbf-one.com`，设置该地址的 SMTP
   密码，再交由服务器操作人员配置与验证投递。杭州 SMTP 主机为
   `smtpdm.aliyun.com`，SSL 端口为 465。

截至 2026-10-04，官方说明每个阿里云主账户共有 2,000 封免费发信额度，
每天最多免费发送 200 封；不是永久每天免费 200 封。免费额度用完后，
按量单价为 2 元 / 1,000 封，实际账户剩余额度和计费以控制台为准。参见
[计费说明](https://help.aliyun.com/zh/direct-mail/billing-methods/)、
[开通流程](https://help.aliyun.com/zh/direct-mail/purchase-procedure)及
[SMTP 区域与端口](https://help.aliyun.com/zh/direct-mail/smtp-endpoints)。

已准备交互式凭据录入脚本。用户在服务器终端执行：

```bash
sudo python3 /home/codex/discourse-production/deploy/prepare-smtp.py
```

脚本确认杭州区域和域名验证状态，隐藏输入并重复确认 SMTP 密码，收集后续
测试邮件的收件地址。参数仅写入 `shared/smtp-setup.json`，权限为 `600`、
归服务器操作账户 `codex` 所有，位于部署仓库忽略的共享目录且不挂载到网站。
脚本不会开启发信、发送邮件或重启服务。接入完成后删除这份临时凭据文件；
实际密码仅保留在受保护的生产配置中，避免额外副本。

由有权限的操作人员编辑生产配置 `containers/isbf_app.yml` 的现有 `env` 段。
以下是端口 465 的参数示例，主机、账号和密码必须换成真实服务商提供的值；
发件人地址必须经过服务商授权，不能任意填写。避免重复定义相同环境变量。

```yaml
  DISCOURSE_SMTP_ADDRESS: "填写服务商的SMTP主机"
  DISCOURSE_SMTP_PORT: 465
  DISCOURSE_SMTP_USER_NAME: "填写SMTP用户名"
  DISCOURSE_SMTP_PASSWORD: "填写SMTP密码或授权码"
  DISCOURSE_SMTP_FORCE_TLS: true
  DISCOURSE_SMTP_OPENSSL_VERIFY_MODE: peer
  DISCOURSE_NOTIFICATION_EMAIL: "填写已授权的发件人地址"
  DISCOURSE_DISABLE_EMAILS: "no"
```

端口 465 使用隐式 TLS，连接建立时即加密。保留 `DISCOURSE_SMTP_FORCE_TLS: true`，
无需设置 `DISCOURSE_SMTP_ENABLE_START_TLS: false`：强制 TLS 已会自动关闭
STARTTLS 协商。后台的 STARTTLS 检查只读取 `smtp_enable_start_tls`，显式设为
false 仍会出现“外发电子邮件配置已禁用 STARTTLS”的提示，即使连接已使用 TLS。
使用基础镜像完整构建时，删除这一行可恢复默认值 true。复用生产镜像重新创建
容器时，Docker 会继承镜像中的环境变量；若镜像仍保存了 false，需要在配置中
明确设置 `DISCOURSE_SMTP_ENABLE_START_TLS: true` 来覆盖旧值。两种处理均保留
`DISCOURSE_SMTP_FORCE_TLS: true`，实际 SMTP 连接继续使用隐式 TLS。
参见 `app/models/global_setting.rb` 的 `smtp_settings` 和
`app/services/problem_check/starttls_disabled.rb`。

若服务商指定端口 587 / STARTTLS，则将端口设为 587、`FORCE_TLS` 设为 false、
`ENABLE_START_TLS` 设为 true。认证方式如有要求，通过
`DISCOURSE_SMTP_AUTHENTICATION` 设置为服务商指定的值。配置 SMTP 后可移除
`DISCOURSE_SKIP_EMAIL_SETUP`。密码或授权码只写入权限为 `600` 的实际配置，
不要写进版本库、部署文档或聊天记录；生成日志和配置副本时也不要输出密码。

配置后先检查磁盘容量和配置语法、创建当前生产备份，再执行上面的完整重建
命令，保留续签调整。只运行 `docker restart` 不会加载修改后的宿主机配置。
发信需要服务器向外连接服务商的 SMTP 端口，不需要对公网开放本机 SMTP 入站
端口。根据服务商端口要求检查出站规则；阿里云 ECS 默认限制端口 25。

重建后在后台邮件页面向站点负责人指定的收件地址发送一封测试邮件，并核对
收件箱、垃圾邮件、发信日志及 SPF / DKIM 结果。测试投递成功后再启用正常
通知发送；邮件成功发送不会改变站点当前的邀请注册限制。

## 回退

开发数据库仍在 `/home/codex/discourse/data/postgres`，原容器内部外部插件和依赖
均保留。先停止生产服务以释放内存，再恢复开发容器：

```bash
cd /home/codex/discourse-production
./launcher stop isbf_app
docker start discourse_dev
docker exec -d -u discourse:discourse -w /src \
  -e RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
  -e LD_PRELOAD=/usr/lib/libjemalloc.so \
  -e NO_COLOR=1 \
  discourse_dev bash -lc \
  'exec bin/pitchfork -p 3000 >> /tmp/isbf-development-recovery.log 2>&1'
```

先确认 3000 无网页进程，避免重复启动；前端也需要重新启动，参见
[开发站故障排查](development-service-troubleshooting.md)。开发站仍在本机回环端口，
不会自动接替生产域名。原交付包仍在
`/home/codex/discourse/tmp/isbf-preserve-20261003-221122/`。

生产站有新写入后，回退前必须备份新的生产数据，不能用旧开发数据覆盖新写入。
