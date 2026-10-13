# 校园论坛头像框安装记录

当前生产版本为 `0.3.0`，支持后台上传、个人授予、撤销和 CSV 批量授予。
前半部分保留首次安装和 `0.2.1` 修正记录；当前固定版本及回退方式见文末 `0.3.0` 记录。

2026-10-10 已在 `https://isbf-one.com` 安装头像框适配版，插件总数由 60 增至
61。保留原有插件、账号关联的管理员权限限制、登录页面和数据库主题功能。
用户默认不佩戴头像框，六款均向所有用户开放。

用户在 `/my/preferences/profile` 通过下拉列表选择头像框后点击“保存变更”。首页、发帖入口
和账号菜单使用静态首帧；帖子、用户卡片和个人资料保留动画，并遵循系统的
减少动画设置。匿名账号不输出头像框，原生群组徽标继续显示。

## 固定版本与部署（0.2.1 历史记录）

- 上游：<https://github.com/asa0w0/discourse-avatar-frames>，提交
  `ff92abd14b27dd4651af3829469e8845ebc1fc00`，保留 Apache 2.0 许可及原图。
- 本地适配仓库：`plugins/discourse-avatar-frames`，分支
  `isbf-campus-20261010`，提交 `e75e0d8a12150c16beccb9fe15a33881123ba335`。
- 持久源码：
  `/shared/discourse-avatar-frames-releases/e75e0d8a12150c16beccb9fe15a33881123ba335/discourse-avatar-frames`，
  包含匹配的 `.release-commit`。
- 生产源码保持最新账号权限版本
  `c0f4739d143a4efbb4e7f19dafadcd56a5302a58`。安装期间重新核对最新运行状态，
  将其账号菜单权限改动与头像插槽合并。
- 最新修正镜像基于首次头像框已验收镜像 `local_discourse/isbf_app:avatar-frames-20261010`。
  原有 60 个插件的文件摘要、隐藏文件、链接目标和发布标记完全保留；最终核对
  13,108 个源码文件。本次保留原有 294 个资源条目，新增修正后的 JavaScript 与 source map，合计 296 个。

已验收镜像为 `local_discourse/isbf_app:avatar-frames-followup-cached-20261010`，并于 15:16
（UTC+8）更新 `local_discourse/isbf_app:latest`：

```text
sha256:59de4194a15727c661ce16355a7dc2c1f712a8eb79f3afc3d6a6f496a3a30c31
```

生产容器未重建，只重启 Web 服务；数据库和 Redis 持续运行，没有数据库迁移
或批量修改用户头像框。运行容器的不可变 `.Image` 仍为创建时的
`sha256:d7392bb5d64fd8cb127fdf0f594bf8e890faf6346a449f3fbde6fc190fef8ae8`，
后续构建须核对实际运行源码及上述已验收镜像。

完整构建配置 `containers/isbf_app.yml` 已增加固定版本安装 hook，并将
`params.version` 同步到上述生产提交。该提交已保存在本地 `release.git` 的
`avatar-frames-base-20261010` 分支。配置备份为生产目录中的
`containers/isbf_app.yml.before-avatar-frames-20261010`，保持原受限权限。

增量安装时使用 `discourse` 用户执行 `bin/rails`。静态资源链接必须指向
`/var/www/discourse/plugins/discourse-avatar-frames/public`，与插件加载器的
预期路径一致。准备阶段发现的执行用户及资源链接差异已经修正。

## 主题与设置

基于实际数据库主题 ID 4 修改以下五个字段；保留其他字段、设置及最新账号
权限改动，发布前逐项核对原值，并在事务内更新。

| 字段 ID | 字段 |
| --- | --- |
| 224 | `discourse/components/isbf-v2-composer-options.gjs` |
| 226 | `discourse/components/isbf-v2-account-menu.gjs` |
| 227 | `discourse/components/isbf-v2-feed-card.gjs` |
| 197 | `common/scss`，追加头像容器样式 |
| 200 | `discourse/components/isbf-v2-shell.gjs` |

管理员通过 `avatar_frames_enabled` 启停，通过 `avatar_frames_config` 设置款式、
名称及信任等级或群组条件。默认配置保留六款 `tl0`，用户未选择时没有头像框。
服务器验证选择权限，列表批量预加载头像框；关闭功能或撤销权限后不展示失效
选项，并保留用户其他资料字段的正常编辑能力。实现细节见插件 `README.md`。

## 验收与回退

隔离数据库中的八项请求检查通过；生产更新账号权限后，仅补检受影响的关联
账号案例，确认普通用户返回 403、管理员收到头像框数据。桌面和手机预览
完成选择、移除、保存及刷新，信息流、账号菜单、帖子和减少动画设置正常。

首次生产使用临时只读凭据验收桌面和手机：七个选项、六款静态图片、工作台入口
正常；商城查询成功并完成三条商品的渲染，校友地图完成 Leaflet 初始化，
登录页面保留两种登录入口。无 JavaScript 错误、损坏的脚本或样式及失败的
站内资源请求；没有保存真实用户资料，临时验收凭据已删除。

证据、构建定义、当前主题导出和五个字段的更新前后内容保存在
`deploy-work/avatar-frames-20261010/`，重点查看
`candidate-validation-report.json`、`production-installation-report.json`、
`production-browser-report.json`、`build-config-report.json` 和
`deployment-final-report.json`。

需要停用时先关闭 `avatar_frames_enabled`。需要撤回安装时，确认链接仍指向
本次版本，再移除新增的插件及静态资源链接，用 `tools/theme-changes.json`
恢复这五个字段的 `before` 值、恢复 `assets-manifest-before.json`，重启 Web。
保留数据库、其他插件及账号权限改动；构建配置只撤销新增的头像框 hook，
继续保留最新生产提交。上一份已验收的账号权限镜像为
`local_discourse/isbf_app:account-link-admin-complete-20261010`。


## 旧接口提醒、资料页对齐与下拉选择修正

本次插件版本为 `0.2.1`。原适配代码使用 `api.modifyClass("model:user")`，
触发 Discourse 自 2026.8 标记的 `discourse.modify-class-model` 弃用提醒。
改为在 pre-initializer 中通过 `addModelMethod` 扩展保存方法；沿用原生请求，
仅在保存成功后同步服务端返回的头像框。该核心用户模型自定义的 `save()`
不会触发通用 `afterSave` 回调，因此没有直接改用该回调。

头像框选择改为原生下拉列表，显示一张当前选项的静态预览，七个选项包含
“不使用头像框”。受权限限制的选项保持禁用。个人资料头像使用图片 wrapper
插槽作为定位基准；将头像外边距移到 wrapper，并排除主题对装饰图片的头像
边框、圆角和尺寸规则。桌面及手机的头像与头像框中心偏差均小于 1px，头像框
保持头像尺寸的 120%。群组徽标插槽继续保留。

初次更新仍命中生产旧样式缓存，后续刷新了 `stylesheet-manifest`，重新编译
头像框及 RTL 两份样式，并通过 `clear_plugin_cache!` 刷新该插件的样式 URL。
缓存目录原属容器内不存在的 UID/GID 1002；仅将生产样式 manifest 目录和文件
交给 Web 用户 `discourse`，确保编译器可以更新。已将新签名、CSS 和可用的
source map 一并补入已验收镜像。增量更新样式且核心提交不变时，须同步刷新
文件系统样式签名和插件样式 URL，Web 重启本身不会替换旧的缓存引用。

隔离账号验证下拉选择、移除、成功保存后立即同步、失败保存保持当前用户的
原选择以及刷新后的持久化。生产桌面及手机验证下拉、头像框对齐、旧模型接口
提醒消失，并完成商城商品渲染、校友地图及登录入口检查。生产资料页仅在浏览器
内临时显示预览头像框，没有保存真实用户资料；临时只读凭据已删除。

本次其他 60 个插件与 13,108 个源码文件、隐藏文件、软链接和发布标记保持
预期状态。默认主题的全部 128 个字段摘要与设置保持不变。固定构建 hook 已
更新到本文当前提交，配置备份为
`containers/isbf_app.yml.before-avatar-frames-followup-20261010`。
证据及脚本位于 `deploy-work/avatar-frames-20261010/followup/`。

仅撤回本次修正时，保留主题和数据库，将头像框插件链接恢复到首次安装提交
`b6c635f1b93d9128aa483e73155eb26a1fecbcf0`，恢复该目录的
`generated-manifest-before.json`、`assets-manifest-before.json` 和
`stylesheet-manifest-before`，刷新头像框样式缓存并重启 Web；构建 hook 只恢复
这一固定提交。首次已验收镜像仍为 `local_discourse/isbf_app:avatar-frames-20261010`。


## 后台管理与 CSV 批量授予（0.3.0）

生产发布完成于 `2026-10-10T21:17:39.335890+08:00`。管理员入口：
`/admin/plugins/discourse-avatar-frames/frames`，即「插件 → 头像框」。

原有六款头像框通过幂等 fixture 迁入独立目录，保留字符串 ID、公开权限和已佩戴的
`avatar_frame` 用户自定义字段。新头像框使用 UUID，默认「授予后可用」，也可改为
公开。仅管理员可以上传、编辑、授予、撤销和导入，版主没有这些写入权限。

后台接受正方形 PNG/APNG，保留上传原始动画并生成静态首帧，受站点图片大小及
像素上限约束。默认图像优化流程会移除 APNG 帧，因此该上传类型跳过优化、缩小和
PNG 转 JPEG；静态版本单独注册并持有上传引用。旧主题的 UUID 图片地址由插件
路由兼容，不更新当前数据库主题。制作及使用说明见 `docs/avatar-frame-authoring.md`。

每次 CSV 导入先选择一款头像框，首列填写用户名或邮箱，可包含 `username` 或
`email` 表头，支持 UTF-8/BOM。空行忽略，按实际用户去重，单次最多 50,000 条，
以 200 人为一批追加授予。后台展示进度、新授予、已有、未匹配和失败明细；重试从
已处理位置继续，不覆盖原有拥有者。授予永久有效且不自动佩戴，首次授予发送站内
通知，重复授予不重复通知。撤销受限头像框时会清除该用户的佩戴；停用款式保留授予。

新增数据库表 `avatar_frames`、`avatar_frame_grants`、`avatar_frame_imports`，
只执行插件目录中的迁移及 fixtures，没有核心迁移、schema dump 或真实用户测试授予。
全局开关仍为 `avatar_frames_enabled`，旧 `avatar_frames_config` 隐藏并保留以供回退；
新款式及权限通过后台管理，不再从旧配置解析。

固定插件提交：`7799ffe00571fc8247c0aafff99b0132e9c74fb3`，持久源码：
`/shared/discourse-avatar-frames-releases/7799ffe00571fc8247c0aafff99b0132e9c74fb3/discourse-avatar-frames`。
已验收镜像为 `local_discourse/isbf_app:avatar-frames-management-cached-20261010`，已标记为 `local_discourse/isbf_app:latest`：

```text
sha256:a76144b45e3ee5a4b502ef231bc413d8e61ca0866917463d55aff2497554fc08
```

该镜像基于 `local_discourse/isbf_app:avatar-frames-followup-cached-20261010`，保留原有 61 个插件中的其他 60 个插件，
最终逐项验证 13,164 个文件、隐藏文件、软链接和共享发布标记。
保留原有 296 个前端 manifest 条目，并新增 6 个插件 main/admin/shared chunk 与
source map 条目。头像框及后台的普通和 RTL 共 4 份样式、source map 和样式签名
`7::0.0.19:d64df2535347684a80fae50d6427d19c4e2d43ce` 均进入镜像。文件系统样式签名更新后再重启 Web，
避免进程持有旧签名。样式目录及 manifest 归 `discourse` 用户。

生产容器未重建，核心仍为 `c0f4739d143a4efbb4e7f19dafadcd56a5302a58`，
默认主题 ID 4 的全部 128 个字段摘要及设置保持不变。Web 重启会通过 Pitchfork
重启 Sidekiq；当前容器没有独立 `/etc/service/sidekiq` 服务。发布脚本等待旧后台
进程退出，最初 20 秒等待不足已修正为 90 秒。另清理了一个未注册、空闲且两次 TERM
均未退出的旧孤立进程；两次保护性回退记录及清理证据保留在管理发布目录。首轮只读验收还遇到
站点 API 认证阶段的 Redis 等待超时，后续请求恢复，最终页面验收通过。

74 项 RSpec 通过，针对全部改动文件的 `bin/lint --fix` 通过。隔离预览验证了上传、
单人授予、真实 CSV 后台任务、通知链接、资料页保存，以及手机端撤销后清除佩戴。
生产使用临时只读凭据验证桌面和手机的目录、上传表单、下拉选择及头像对齐，并完成
工作台、商城商品渲染、校友地图初始化及登录入口检查；没有保存真实用户资料，
验收凭据已删除，独立预览凭据也已撤销并停止其容器。

完整构建 hook 已只更新头像框这一固定提交；其他配置及核心版本保持不变。
受限备份为 `containers/isbf_app.yml.before-avatar-frames-management-20261010`。
证据和脚本位于 `deploy-work/avatar-frames-20261010/management/`，主要文件包括
`release.json`、`candidate-validation-report.json`、`production-installation-report.json`、
`preview-browser-report.json`、`production-browser-report.json`、`build-config-report.json`
和 `deployment-final-report.json`。

需要停用时关闭 `avatar_frames_enabled`。仅回退本次后台功能时，恢复插件链接到
`e75e0d8a12150c16beccb9fe15a33881123ba335`，还原管理发布目录中的 `generated-manifest-before.json`、
`assets-manifest-before.json` 和 `stylesheet-manifest-before`，将样式 manifest 交给
`discourse`，重启 Web 并等待后台工作进程完全更新。保留新增目录、授予、导入表和
上传文件，不执行反向迁移或删除用户数据。构建 hook 只恢复这一插件固定提交。
前一已验收镜像为 `local_discourse/isbf_app:avatar-frames-followup-cached-20261010`，镜像 ID 为
`sha256:59de4194a15727c661ce16355a7dc2c1f712a8eb79f3afc3d6a6f496a3a30c31`。回退期间新增 UUID 款式可能暂不显示；重新发布后
保留的授予和佩戴字段可继续使用。
