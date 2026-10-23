# 磁盘清理记录（2026-10-23）

用户要求检查磁盘并删除旧的不必要备份，随后明确授权删除旧容器。清理采用精确清单，未使用全局 prune、强制删除或卷删除。

## 实际结果

| 指标 | 清理前 | 清理后 |
| --- | --- | --- |
| 根分区使用率 | 99% | 90% |
| 普通用户可用空间 | 1.25 GiB | 10.16 GiB |

根分区实际释放约 8.91 GiB（9,562,976,256 字节）。删除 8 份重复源码副本、36 个旧备份镜像标签及 21 个已停止或从未启动的旧容器。镜像共享层仍由保留版本使用，不能将标签标称大小相加作为释放量。

## 已删除的重复源码副本

删除前逐项确认无跟踪及未跟踪修改、提交已合入本地 main、各本地分支提交仍在保留仓库中，并排除任何容器直接挂载的目录。使用工作树所属仓库的移除命令；独立副本按路径删除。

- `deploy-work/login-code-entry-release-20261007`，提交 `52eebcedf40f7f623278f71921574a095b1864e0`。
- `deploy-work/auth-page-release-20261009`，提交 `f5cede9c7a624d32c951c280fb910218d441a6a4`。
- `deploy-work/auth-center-fix-20261011/release`，提交 `67706a5a30d71ff0b6793e5b8f55a85c4fe3ebb5`。
- `deploy-work/workspace-pr-20261013/worktree`，提交 `69587a82bd9bd20fc781192011c5f48bf35c194c`。
- `deploy-work/workspace-pr-20261017/worktree`，提交 `e58ded382006c4ba412a74dd7fef419168246329`。
- `deploy-work/academy-bulk-release-20261007`，提交 `2d0f89de43d12d79763f28036b1bf71a600d492f`。
- `deploy-work/activity-layout-release-20261007`，提交 `d57b39a0d6c721db10f955de66ec027d4b01e545`。
- `deploy-work/workspace-pr-20261018/worktree`，提交 `6ed6e2a20fd50e44466678e108219ef7b8b505d9`。

## 已删除的旧容器

每项删除前再次核对名称、ID、停止状态及无自动重启策略。只删除容器及其可写层，宿主机挂载目录保留。

- `isbf_resume_verified_image_20261013`（`3833eb50f16b`）。
- `isbf_resume_inventory_20261013_184710_v2`（`8e5e7698b028`）。
- `isbf_resume_inventory_20261013_184710`（`c706b5809085`）。
- `isbf_resume_final_smoke_20261013_184710`（`2aaedda7e996`）。
- `isbf_resume_release_20261013_184710_offline`（`8cbe8ad841c7`）。
- `isbf_resume_release_20261013_184710`（`839a49404c6d`）。
- `isbf_avatar_calibration_preview_20261011`（`e4a87d686151`）。
- `isbf_avatar_calibration_build_20261011`（`e103decdc9d4`）。
- `isbf_resume_workbench_20261011_211314_app`（`b0eb15de7cd9`）。
- `isbf_resume_workbench_20261011_211314`（`3fb4058ec94d`）。
- `isbf_resume_generator_test_20261011_182659`（`03b29972a9be`）。
- `isbf_personal_release_d7a42d5931`（`f81256be256b`）。
- `isbf_admin_permissions_base_audit_20261011`（`70bfcdc4c022`）。
- `isbf_account_device_image_metadata_20261011`（`4e3b99c39e3a`）。
- `isbf_admin_permissions_test_20261011`（`cd388c2736c1`）。
- `isbf_account_device_code_test_20261010`（`1dc583f39af5`）。
- `isbf_avatar_frames_test_20261010`（`ca5f2f391323`）。
- `isbf_account_link_admin_test_20261010`（`b059a4c4520b`）。
- `isbf_app_before_auth_page_20261009`（`8c2335da9c49`）。
- `isbf_account_switch_test_20261007`（`e52587f1fe25`）。
- `isbf_app_before_account_switch_deleted_user_20261008`（`d75b27d6a0c5`）。

## 保留范围与验证

- `isbf_app`、`isbf_proxy`、`discourse_dev` 的容器 ID、镜像、启动时间和运行状态与清理前一致；`isbf_frontend_preview_20261012` 保持停止。
- 三份原生备份（2026-10-09、10-16、10-23）均保留，目录为 `/home/codex/discourse-production/shared/standalone/backups/default/`。
- 生产共享插件、数据库、上传及私有文件目录、部署回退脚本、主题备份、审阅证据和当前开发工作树保留。
- 最近三份恢复镜像及 `latest` 的标签与 ID 核对未变；其他容器引用的镜像亦保留。

- `local_discourse/isbf_app:deleted-replies-20261021-deeb83874f16` → `sha256:b123c346da720576e70f15ceaf6baad20bf4cbac5f66c6bd43b402ede16e3cc2`。
- `local_discourse/isbf_app:feed-name-colors-20261021-26d552c5e0ad` → `sha256:3a3c759f4597d7c01221bacf438e1e9a73ff0063c111d94e12c03d2fbc252074`。
- `local_discourse/isbf_app:dialog-consistency-20261020-5109370e6bf4` → `sha256:8179d4c6c2476f4e48bbe5142edb4a4feeb8222dfc50f02c62cab5e6c3c38101`。
- `local_discourse/isbf_app:latest` → `sha256:38308d121da3faee01d9c99fcdbdabcc40da13e0271361dd38c688bb85e84a24`。

历史发布记录中涉及的 36 个旧镜像标签已从本机移除，确切清单在本次审计结果中。保留镜像仍需配合当前共享插件、资源清单及数据库主题使用，不能独立代表后续热更新。参见[部署完整性记录](workbench-plugins-missing-20261010.md)。

`deploy-work/release` 与 `calendar-release-20261006` 仍保留，后者包含主仓库尚无的两个历史分支提交。`/home/luo/backup` 和 `/home/tangency` 因账号目录权限不可读取，本次未清理；未绕过权限或使用容器挂载读取。

## Git 关联修复与后续清理要求

清理时发现保留的 `account-switch-deleted-user-release-20261007` 工作树共享了已删除旧副本的 Git 元数据。已将其重新登记到主仓库，重建索引，保留源码文件；提交仍为 `10004ccf5090d85f80da529aeb4ecb4f3b7b1205`，包含未跟踪文件的状态检查为空。该工作树目前为 detached HEAD，原分支名称与提交已记录在审计清单中。

后续清理不能只检查副本自身是否干净或提交是否合并。删除包含 `.git` 目录的副本前，须检查 `git rev-parse --path-format=absolute --git-common-dir`、所属仓库的 `git worktree list --porcelain` 及全部保留工作树的 `.git` 指针；先迁移或保留共用元数据，再删除重复副本。容器挂载关系与待交接 CI 工作树也须一并核对。

## 审计文件

- `deploy-work/disk-cleanup-20261023/plan.json`：清理前容器、镜像、源码版本、保留边界及用户授权。
- `deploy-work/disk-cleanup-20261023/actions.jsonl`：每项操作的退出状态，包含已纠正的仓库定位失败。
- `deploy-work/disk-cleanup-20261023/result.json`：实际空间差值及保留项验证。
- `deploy-work/disk-cleanup-20261023/git-repair.json`：保留工作树的 Git 关联修复结果。

本次仅执行磁盘维护与记录，未修改应用业务代码。
