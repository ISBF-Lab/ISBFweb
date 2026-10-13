# 管理员权限开关上线记录

2026-10-11 11:41:48（北京时间）发布完成。配置入口：
https://isbf-one.com/admin/plugins/discourse-academy-roles/moderator-permissions

原生 `admin` 身份对应开发者，原生 `moderator` 且无 `admin` 身份的账号对应管理员。开发者拥有完整权限，可以调整所有管理员共享的 20 项开关；全部开关默认关闭，保存后后端按新权限处理请求。邀请及学号查看始终仅限开发者。具体规则见 [管理员权限制度](admin-permissions.md)。

## 已发布版本

| 项目 | 版本 |
| --- | --- |
| 核心 | `1e444b0ba4eee6e9df8633a9e538e0f2bc6c0f7f` |
| 镜像 | `sha256:6a2e4be046b34895b4174fe6fe0f41d39946ff5cca892a09759788be2cf17dcc` |
| 学习插件 | `a8c3ffc9a098ef2ac568dffc0675fc709bc3c288` |
| 官方插件 | `443a666b514d948b246d5c1debec43c065cb213a` |

生产版本配置、两个外部插件固定版本以及 `local_discourse/isbf_app:latest` 已更新。全部 61 个插件保留，仅更新默认主题的 6 个指定字段。发布前后的其他主题字段、账号身份、信任等级、管理组成员关系和业务数据摘要相同。未执行数据库迁移或数据库恢复。

## 本次验收范围

此前已通过 858 项核心测试、369 项权限及相关业务测试、31 项前端测试，以及桌面和手机预览。预览实际验证了开发者保存权限、管理员默认拒绝、同一会话撤销权限，并清理了临时登录会话。

用户明确要求“别重复验证”，本次发布接受上述结果，没有再次运行测试或生产浏览器验收。发布只执行必要的服务启动、源文件一致性及无关数据完整性检查，全部完成。`production-report.json` 中 `deployed` 为 `true`，`browser_verification.production_suite_repeated` 为 `false`；不能将预览结果表述为本次生产浏览器验收结果。

## 运行环境与恢复资料

用户确认两个旧测试环境均未使用并授权停止，已停止 `isbf_personal_release_d7a42d5931` 和 `isbf_account_device_code_test_20261010`，保留容器及存储。其他测试环境未停止；本次预览 Web 进程在发布前停止。

数据库及上传备份留在生产容器的 `/shared/admin-permissions-backups/20261011-1e444b0ba4ee`，目录权限 `700`、文件权限 `600`。生产部署资料位于服务器 `/home/codex/discourse-production/deploy/admin-permissions-20261011`，包含发布前资料、最终报告及 `release-artifacts`。后者保留核心与外部插件 Git bundles、完整版本清单、原验证结果，以及本次取消重复浏览器验收的 `publication-script.py` 和 `publication-instruction.json`。

回滚基线为核心 `fe244909fd34dea373961305e6981d1217c72418`，镜像 `sha256:6916623a30dcd043862d6bfd691f66cbc485525b3dbda34ec2603f2a45a94d58`。采用现有发布工具保存的核心、外部链接、资源清单、六个主题字段及配置恢复流程；恢复代码时不应覆盖发布后的用户数据。
