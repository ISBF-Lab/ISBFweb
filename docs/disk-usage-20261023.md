# 磁盘占用盘点（2026-10-23）

本记录补充[当天清理记录](disk-cleanup-20261023.md)，回应清理后约 90 GB 数据的具体构成。

统计时根分区实际已用 89.87 GB（83.70 GiB），使用率为 90%。90% 是占用率；GB 与 GiB 的单位不同。

| 类别 | 占用（GiB） | 路径 |
| --- | ---: | --- |
| Docker 镜像、容器和缓存 | 24.00 | `/var/lib/containerd；/var/lib/docker` |
| 开发源码、发布与测试目录 | 17.71 | `/home/codex/discourse` |
| luo 的部署、测试与备份 | 16.38 | `/home/luo` |
| tangency 的开发和回退目录 | 5.99 | `/home/tangency` |
| Codex 程序包、会话及工作树 | 5.61 | `/home/codex/.codex` |
| 交换文件 | 4.00 | `/swapfile` |
| Node/npm 工具、缓存及其他用户文件 | 2.61 | `/home/codex/.nvm；.npm；.cache 等` |
| 生产持久数据、共享插件及发布配置 | 2.26 | `/home/codex/discourse-production` |
| 系统软件、日志、其他文件及文件系统开销 | 5.15 | `/usr；/var/log；/var/cache 等` |

## 占用大的具体目录

- 项目 `deploy-work/`：14.22 GiB，包含历次发布工作树、源码副本、资源包、编译产物和回退资料。
- 较大子目录包括 `account-link-admin-20261010/` 约 2.00 GiB、`release/` 约 1.53 GiB、`account-device-email-code-20261010/` 约 1.32 GiB、`frontend-consistency-20261012/` 约 1.17 GiB。
- `/home/luo/backup/`：7.33 GiB；该账号其余约 9 GiB 主要是测试和部署目录。
- luo 较大目录包括 `isbf-name-gradient-deployments/` 约 1.76 GiB、`isbf-pinned-bar/` 约 1.22 GiB、`isbf-resume-deployments/` 约 1.16 GiB。
- `/home/codex/.codex/packages/app-server-daemon/releases/`：约 3.33 GiB；会话目录 `/home/codex/.codex/sessions/` 约 1.04 GiB。
- `/home/tangency/.vscode-server/`：2.61 GiB；另有校友、组队、置顶等历史回退和开发目录。
- Docker 的 containerd 解包层约 18.95 GiB、压缩内容约 4.83 GiB；不能把镜像列表的标称大小直接相加。
- 生产 PostgreSQL 数据目录约 0.39 GiB；三份原生备份合计约 0.26 GiB。

## 统计方式与边界

本轮只读统计文件分配块，不读取业务文件、凭据或会话内容，不继续删除数据。为补齐普通账号无法遍历的目录，使用既有本地镜像运行受限的只读目录统计；工具无网络、无 Docker socket、未挂载生产数据库，结束后自动删除。生产共享目录通过现有容器内的只读 du 单独统计。

普通账号最初只能统计到项目的约 12.01 GiB；补齐权限后实际为约 17.71 GiB，差额主要位于旧发布目录及开发数据库。因此不能将权限不足时的 du 输出当作完整占用。

生产目录的父级与子级未重复相加。末行“系统软件、日志、其他文件及文件系统开销”按已用空间余额归类，包含操作系统目录、文件系统元数据、跨目录硬链接统计差异和扫描期间的后台写入，不代表某个单独目录的直接测量。

原始目录统计、扫描错误记录与分类 JSON 保存于 `deploy-work/disk-cleanup-20261023/usage-*.tsv` 和 `disk-usage-breakdown.json`。目录大小只用于解释占用，不代表目录内容已全部被判定为可删除。
