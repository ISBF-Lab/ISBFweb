# 2026-10-08 排序插件上线记录

用户最初选择手动部署，在重建失败后授权代为修复和完成部署，随后要求跳过线上验证。

## 部署结果

- 2026-10-08 17:28:38（UTC+8），`./launcher rebuild isbf_app` 成功退出，新容器已启动。
- 17:32:45，开启 `latest_topics_order_by_created`，原值为 `false`。
- 插件版本为 `0.1.0`，固定源码版本为 `10004ccf5090d85f80da529aeb4ecb4f3b7b1205`。
- 按用户要求，没有执行部署后的线上页面、接口或浏览器验证。

## 重建失败的原因与修复

用户粘贴时将 `export HTTPS_PROXY=http://127.0.0.1:17897` 和 `cd` 接在同一行。
本次构建使用了正确的本机代理，容器内继续使用已有的 `172.17.0.1:17897` 代理配置。

原账号切换覆盖安装钩子来自 `5db48c2297ee545f4e6c95d19e53ec6ff91f990b`，
只接受旧版本控制器的校验和；固定源码已包含另一版删除账号修复，因此触发
`Plugin file changed`。旧覆盖还会改变现有管理前端所依赖的删除账号返回格式。

处理时保留了固定源码中的控制器和前端，移除了过期的覆盖钩子，保留官方消息、学习及排序插件的安装钩子。
生产数据库已执行 `20261008000000` 迁移，两个 `account_link_id` 字段已为 bigint，
但当前源码漏带了迁移文件。因此增加独立恢复脚本，只恢复这个已执行过的原文件：

```text
/shared/isbf-account-switch-rebuild-compat/20261008/restore-account-switch-migration.sh
```

脚本校验原文件 SHA-256 为
`7343ad9d35b27639ba6440d38189270f15917227d5c57adca0de3053dc9e5571`，
确认目标不是符号链接，并在文件已存在时检查其内容一致。
旧发布目录仍提供该原文件，后续不要删除安装钩子所依赖的持久目录。

## 备份与回退

重建前恢复了失败后停止的旧容器，并保存原配置副本和当前镜像。
配置副本位于生产 `containers` 目录：

```text
isbf_app.yml.before-latest-created-order-repair-20261008T090638Z
isbf_app.yml.before-migration-restore-hook-20261008T091335Z
```

部署前镜像保留为 `local_discourse/isbf_app:before-latest-created-order-20261008`。
原有完整备份保留在生产目录：

```text
/shared/account-switch-deleted-user-20261007/before-account-switch-deleted-user-20261008-071312-v20261008000000.tar.gz
```

该备份约 50.8 MB，已在生产容器内确认含数据库和上传文件，校验和为
`bd4004b9973908e40d251263c25c61ca59826b8f2dbcd56d26a33810507853a0`。
将备份导出到开发目录的操作被自动审批拒绝，改用这个既有生产备份，没有导出用户数据。

要恢复活动时间排序，可关闭 `latest_topics_order_by_created` 并刷新页面。
完整回退应使用部署前镜像和相应配置，保留持久数据；不要直接恢复过期的覆盖安装钩子。

## 检查范围与记录

插件此前通过 18 项 RSpec、6 项 QUnit 和 3 项系统测试。
本次配置修复检查了 YAML 内容，确认只修改上述安装步骤；恢复脚本和设置启用脚本通过语法检查。
部署辅助 Ruby 脚本的 `bin/lint --fix` 因开发容器缺少 `rubocop` 和 `stree` 可执行文件未能运行完整检查。

构建日志、设置启用结果和配置修复报告保存在权限受限的
`deploy-work/latest-created-order-20261008/`，日志未作为公开文档输出。
