# isbf-one.com 手动部署最新话题排序插件

本说明起草于 2026-10-08 的只读检查，随后补入用户授权处理重建失败时的配置修复。
本次已完成重建和启用，详见[上线记录](production-deployment-20261008.zh_CN.md)。

当前生产部署目录为 `/home/codex/discourse-production`，容器为 `isbf_app`，配置为
`containers/isbf_app.yml`。`shared/standalone` 挂载到容器的 `/shared`。现有配置通过
`hooks.after_code` 安装官方消息和学习插件，并恢复账号切换插件已执行的历史迁移文件。
账号切换插件源码已包含在固定版本 `10004ccf5090d85f80da529aeb4ecb4f3b7b1205` 中。
新增排序插件配置时保留这些项目。

## 1. 备份并检查资源

先在论坛后台创建包含上传文件的完整备份，并下载保存。在服务器执行：

```bash
cd /home/codex/discourse-production
cp -p containers/isbf_app.yml containers/isbf_app.yml.before-latest-created-order
df -h .
free -h
```

`launcher` 要求 Docker 数据所在磁盘至少有 **5 GiB 可用空间**，不足时会在重建前退出。
这只是启动检查的门槛，构建期间还会消耗空间，应预留更多余量。
2026-10-08 首次检查时，40 GB 系统盘只有约 **2.6 GiB** 可用空间，内存约 3.5 GiB。
用户随后已完成扩容，重建前根文件系统约 99 GiB，可用空间约 60 GiB。
以后重建仍需检查当时的剩余空间。

选择维护时间，避免同时运行开发构建和浏览器测试。其他发布进行期间暂缓此次重建。

### 磁盘空间不足：扩容系统盘

这台服务器的根文件系统是 `/dev/vda3`，类型为 `ext4`，整块系统盘是 `/dev/vda`。
`growpart` 和 `resize2fs` 已安装。以下设备名仅适用于本次检查的服务器；换服务器后需重新确认。

1. 在阿里云 ECS 控制台选择当前实例的系统盘，先创建快照。
2. 将系统盘从 40 GB 扩容到所需容量，例如 80 GB。扩容和快照涉及费用，以控制台显示为准。
   支持在线扩容时选择在线扩容；云盘容量增加后，还需要扩展服务器内的分区和文件系统。
3. 在服务器执行 `lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS`，确认 `vda` 已显示新增容量。
   如果仍为 40 GB，先完成控制台扩容，暂不执行下面的分区命令。
4. 确认云盘扩容完成、根分区仍为 `vda3` 且文件系统仍为 `ext4` 后，执行：

   ```bash
   sudo LC_ALL=en_US.UTF-8 growpart /dev/vda 3
   sudo resize2fs /dev/vda3
   df -h /
   ```

   `growpart` 使用磁盘名和分区编号两个参数；`resize2fs` 使用分区路径。
   如果任何一步报错，先排查，不继续重建。

5. 确认可用空间明显超过 5 GiB，再继续本文的插件安装和重建步骤。

依据阿里云的[扩容 Linux 云盘说明](https://help.aliyun.com/zh/ecs/user-guide/resize-linux-cloud-disks)。
这些步骤需要由部署人员手动执行，本次检查没有扩容磁盘或修改分区。

### 磁盘空间不足：备份旧发布副本后清理

不扩容时，可先把旧发布副本完整保存到服务器外，再清理。检查时
`/home/codex/discourse/deploy-work` 约占 3.3 GB，以下目录是较早的发布源码副本：

| 目录                                | 检查时占用 |
| ----------------------------------- | ---------- |
| `release`                           | 约 1.6 GB  |
| `calendar-release-20261006`         | 约 278 MB  |
| `activity-layout-release-20261007`  | 约 278 MB  |
| `academy-bulk-release-20261007`     | 约 278 MB  |
| `login-code-entry-release-20261007` | 约 365 MB  |

不能只凭“旧发布”判断可以删除：`release` 和 `calendar-release-20261006` 中的
`feature/isbf-per-post-anonymous` 分支指向 `3d11a61699f737f797f6073d1cc3a84790536127`，
该提交未保存在生产裸仓库或当前开发仓库中；`release` 中还存在被 Git 忽略的文件。
备份应包含完整目录和 `.git`，确认外部副本可读取后，才删除明确不再使用的旧目录。
在同一系统盘上创建并保留压缩包不能作为释放空间的办法。

保留当前 `account-switch-deleted-user-release-20261007` 发布源码、开发容器、生产容器及回退容器，
并保留 `/home/codex/discourse-production/shared`、配置、数据库、上传文件和备份。
不要整目录清空 `tmp`，其中有 `isbf-preserve-20261003-221122` 保存副本。

检查时 Docker 构建缓存为 0，可回收镜像空间几乎为 0，普通清缓存不足以解决问题。
已停止的测试容器 `isbf_account_switch_test_20261007` 约占 436 MB，删除它也不能单独达到重建门槛。
`launcher` 提供的自动清理会移除满足时间条件的停止容器和未使用镜像，可能包括回退资源；
不要直接接受自动清理，也不要执行整机的 `docker system prune -a --volumes`。

清理前重新确认目录和容器用途，清理后用 `df -h /` 检查剩余空间。
磁盘空间不足的排查阶段只做了只读检查，没有执行清理。

## 2. 保存插件源码

当前开发目录与生产目录位于同一服务器，可执行：

```bash
mkdir -p shared/standalone/discourse-latest-created-order
cp -a /home/codex/discourse/plugins/discourse-latest-created-order/. \
  shared/standalone/discourse-latest-created-order/
```

若开发目录在另一台机器，先上传完整的 `discourse-latest-created-order` 插件目录到该位置。
插件目录应直接包含 `plugin.rb`、`config` 和 `assets`，不要多嵌套一层目录。

## 3. 添加生产安装钩子

打开 `containers/isbf_app.yml`。在**已有的 `hooks` → `after_code` 列表末尾追加一项**：

```yaml
- exec:
    cmd:
      - ln -sfn /shared/discourse-latest-created-order /var/www/discourse/plugins/discourse-latest-created-order
```

上例中的 `- exec` 与现有 `after_code` 下的其他 `- exec` 对齐。使用空格缩进。
保留已有的 `hooks`、`before_code`、`after_code`、模板、挂载、版本和环境变量。
不要新增第二个同名 `after_code` 键，否则 YAML 解析可能覆盖原有插件安装步骤。

源码放在生产持久目录并由构建钩子安装，可以让后续重建继续加载插件。

## 4. 重建生产容器

在上述生产部署目录，由拥有 Docker 权限的用户执行：

```bash
./launcher rebuild isbf_app
```

安装新插件需要构建其前端资源。重建期间会暂时无法访问站点。
该流程对应 Discourse 的[自托管插件安装说明](https://meta.discourse.org/t/install-plugins-on-a-self-hosted-site/19157)。

### 命令粘贴错误

每条命令单独一行。如需使用本机已配置的代理：

```bash
export HTTPS_PROXY=http://127.0.0.1:17897
cd /home/codex/discourse-production
./launcher rebuild isbf_app
```

不要把 `export` 和 `cd` 接在一起，`17897cd` 会成为错误的代理端口值，并出现
`not a valid identifier`。

### 账号切换插件出现 `Plugin file changed`

2026-10-08，固定源码已更新到 `10004ccf5090d85f80da529aeb4ecb4f3b7b1205`，但原有
`5db48c2297ee545f4e6c95d19e53ec6ff91f990b` 覆盖安装清单仍只接受旧控制器的校验和。
这是两个发布来源不一致；不要删掉校验断言或直接让旧控制器覆盖新版源码。

本次处理保留了已上线版本的控制器及前端，移除了旧覆盖安装钩子，并增加：

```yaml
- bash /shared/isbf-account-switch-rebuild-compat/20261008/restore-account-switch-migration.sh
```

该脚本只恢复历史文件 `20261008000000_widen_account_switch_link_references.rb`，
先校验其 SHA-256，再安装或确认已有文件一致。生产数据库已记录该迁移，两个关联字段已为 bigint。
恢复文件可保留完整迁移历史。原发布目录、恢复脚本和现有安装钩子依赖的持久目录应继续保留。

修复脚本和部署记录位于 `deploy-work/latest-created-order-20261008/`。
配置副本保存在生产 `containers` 目录，当前部署前镜像保留为
`local_discourse/isbf_app:before-latest-created-order-20261008`。

重建失败且旧 `isbf_app` 容器仍存在、构建容器已退出时，可先执行 `docker start isbf_app`
恢复服务，再修正配置后重建。不要反复重建或删除数据库。

## 5. 启用并验证

重建成功后，访问：

<https://isbf-one.com/admin/site_settings?filter=latest_topics_order_by_created>

开启 `latest_topics_order_by_created`，刷新论坛。检查全站、分类和标签的默认“最新”列表：
置顶仍在前面，其他话题按创建日期从新到旧排序。回复不会将旧话题排到较新话题之前。
手动选择的排序以及“热门”“排行”“未读”等列表继续使用原有规则。

从服务器验证健康接口：

```bash
curl --noproxy '*' --resolve isbf-one.com:443:127.0.0.1 \
  https://isbf-one.com/srv/status
```

应得到 HTTP 200 和正常健康响应。部署记录应保存实际时间、插件版本 `0.1.0`、备份位置及验证结果。

## 恢复原有排序

关闭 `latest_topics_order_by_created` 并刷新，即恢复原生按活动时间排序。
如果要卸载插件，删除本次添加的 `after_code` 项，并在停机后的重建准备中移除插件链接及安装目录，
保留站点数据库和上传文件，再重建。完整配置回退应以部署前保存的副本为依据。
