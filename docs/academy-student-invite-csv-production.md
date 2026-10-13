# 学号邀请码 CSV 批量生成生产发布

2026-10-07 备份清理：本文的旧备份、旧回退容器和旧镜像已按用户确认的清单删除。
最新备份和回退入口见[邮箱验证码登录入口发布记录](login-email-code-entry-production.md)。

生产站点：<https://isbf-one.com>。发布完成于 2026-10-07 12:29（北京时间）。
生产首页、健康检查和新管理员资源均返回 200，维护锁已解除。

## 版本和入口

- 学院插件版本：`0.2.0`。
- 发布提交：`2d0f89de43d12d79763f28036b1bf71a600d492f`。
- 上一生产提交：`d57b39a0d6c721db10f955de66ec027d4b01e545`。
- 发布工作树：`deploy-work/academy-bulk-release-20261007`。
- 生产发布仓库默认分支：`student-invite-csv-20261007`；容器配置的
  `params.version` 同步为发布提交，其他配置保持一致。
- 管理入口：<https://isbf-one.com/admin/plugins/discourse-academy-roles/student-invites/bulk>。

拥有 `admin: true` 的站点管理员可上传 UTF-8 CSV，每行一个学号，支持
`student_number` 或“学号”表头，也支持无表头文件。每批最多 1500 条学号、
文件最大 1 MiB；生成后自动下载结果 CSV。已有学号直接跳过，结果只包含
本次新生成的邀请码。详细规则见[使用指南](academy-invitation-guide.md)。

## 构建和检查

只发布学院插件和相关文档，不包含原工作区其他插件、主题、核心或依赖修改，
没有新增数据库迁移。复用当前完整生产镜像，离线编译学院插件及资源清单，
保留未经修改的核心前端资源。构建容器限制为 1280 MiB 内存、无额外 swap、
0.75 核 CPU；数据库备份和发布检查的临时容器限制为 768 MiB、无额外 swap、
0.5 核 CPU，均已删除。

发布前 58 项后端检查、7 项前端检查（27 个断言）及格式检查通过。
生产只检查管理员页面、实际 CSV 上传接口、新管理员资源和 HTTPS 健康状态。
上传检查使用已有学号，返回 `created=0, skipped=1, failed=0`，没有新建邀请码
或账号，没有导出旧邀请码。管理员页面、批量接口和管理员资源均返回 200。

现有学号注册记录、对应邀请记录、主题字段、主题设置、站点设置的 SHA-256
与切换前一致。运行环境变量、启动命令、数据挂载、端口及重启策略保留，
邮件设置没有调整。仅限本机的临时检查 API 密钥已删除。
此前 502 的处理和共享主机资源限制见[故障记录](production-502-20261007.md)。

## 备份和回退

完整数据库与上传文件的原生备份保存在容器持久目录：

```text
/shared/student-invite-csv-20261007/before-student-invite-csv-20261007-v20261006160545.tar.gz
bytes: 38670611
SHA256: 020076828e63c42778a2da0b0930ce6e884a00ab54bbbfbda81c821a3ea2a465
```

压缩完整性及数据库、上传文件目录检查通过，保留此前备份。
生产操作记录在 `/home/codex/discourse-production/deploy/student-invite-csv-20261007/`，
目录权限为 `700`；旧容器完整配置和 YAML 副本为 `600`，不写入代码仓库。

新镜像为 `local_discourse/isbf_app:student-invite-csv-20261007`，同时更新 `latest`。
旧镜像为 `local_discourse/isbf_app:before-student-invite-csv-20261007`；旧容器
`isbf_app_before_student_invite_csv_20261007` 已停止，自动重启关闭。

代码回退时先停止新容器，再恢复旧容器名称、原重启策略、旧 YAML 配置及
发布仓库默认分支，并将 `latest` 恢复为旧镜像。两个容器共用生产数据挂载，
必须保证只运行其中一个。本次没有新增迁移，代码回退可沿用当前数据库，
避免恢复旧备份覆盖发布后产生的账户、帖子或邀请码。

构建和检查记录另存于 `deploy-work/academy-bulk-invitations-20261007/`，
包括 `release.json`、`production-report.json`、`verification.json` 和
`qunit-report.json`。
