# ISBF Learning

The course catalog lock creates its `PluginStoreRow` with explicit plugin/key
attributes for Active Record's `create_or_find_by!` contract, then holds the row
lock through the surrounding transaction. Course creation and review regressions
run in `.github/workflows/isbf-plugin-regression.yml` with the notification suite.

Discourse 学习资源库插件。课程与资源入口为 `/isbf/learning`，主题、回复、审核和搜索复用 Discourse。课程按大一至大四归类；staff 可直接添加，普通成员可申请并由 staff 在原生 `/review` 批准或拒绝。已登录成员可以阅读资源并提交材料。所有非管理员（包括版主）的资料提交进入原生审核队列，仅管理员可直接发布、审核、编辑和删除学习资料。课程申请仍使用原有 staff 权限。资料贡献者名称与真实提交账号分别保存，名称不会改变 Topic/Post 作者。

## 配置与数据

- `isbf_learning_enabled`：资源库开关。
- `isbf_learning_category_id`：实际存在的资源分类 ID，不依赖固定 slug 或分类编号。
- `isbf_learning_storage_limit_mb`：私有附件存储上限，默认 512 MiB。

资源分类应限制为 `trust_level_0` 和 `staff` 拥有完整权限，避免向匿名访客开放；插件仍通过 Guardian 检查实际分类访问权限。插件仅在该资源分类内允许已激活、已批准且未被禁言或封禁的成员提交，保留原生审核，不修改全站 `create_topic_allowed_groups`。配置后在 Staging 核查访客、普通成员、staff 的真实读写与审核行为。

课程目录和附件元数据保存在 `PluginStore` 的 `isbf-learning` 命名空间。资源为原生 Topic/Post，首帖创建时写入课程、文件、外链、选填简介和贡献者名称的 Topic custom fields；审核完整保留这些字段。资源必须提供明确标题，并至少包含一个受保护附件链接或合法 HTTP(S) 外链。原生公共 `/uploads/` 和 `upload://` 附件不能作为资源库私有材料提交。

## 接口

登录后可使用 `GET /isbf/learning/courses` 获取 `{courses: [...]}`。`POST /isbf/learning/courses` 接受 `name` 与 `grade`（1 至 4）：staff 返回 `{success: true, pending: false, course: {...}}`；普通成员返回 `{success: true, pending: true, reviewable_id: ...}`，审批前不写入目录。同一申请人重复提交相同待审核申请复用原记录；拒绝后可重新申请。目录内已有同年级同名课程或非法值返回 422。

课程申请使用原生 `ReviewableIsbfLearningCourse` 和审核权限，ISBF-UI 通过官方 `registerReviewableComponent` 展示课程及年级。批准和目录写入受同一分布式互斥锁保护，锁覆盖原生审核事务的提交；不同用户申请同一课程时，批准复用已存在课程。写入失败不会批准申请，审核事务失败同时回滚目录。禁言、封禁、未获准及无分类权限的账号不能申请。

`GET /isbf/learning/resources` 接受 `course_id`、`page` 和 `q`，返回 `resources` 与 `has_more`；每项包含 `contributor`（纯文本贡献者名称）和 `can_delete`（当前用户是管理员且 Guardian 允许删除该主题时为 true）。普通列表按课程查询；有 `q` 时使用 Core Search 搜索资源库全部年级与课程，忽略当前课程筛选。两种查询均仅覆盖配置资源分类内当前用户可以访问的已发布资源。

分享窗口包含标题、选填简要介绍、链接和选填贡献者名称，使用 `POST /isbf/learning/resources`，参数为 `course_id`、`title`、`description`（可选）、`link`、`contributor`（可选）。贡献者输入去除首尾空白后最多 15 个 Unicode 码点，必须是单行字符串，拒绝换行、控制字符与对象/数组；按纯文本序列化。未提供、nil 或空白时采用原提交账号的 `name.presence || username`；此账号名称回退不受输入框 15 字限制。历史资料缺少该字段时同样回退到原提交账号。简介最多 300 个 Unicode 字符，支持换行；服务端拒绝超长、非字符串和非法控制字符，保存后按纯文本显示在资料标题下方，并参与限定学习库范围的原生搜索。空简介与历史资料保持原样。课程沿用页面当前选项。接口固定学习分类，不接受正文、标签、附件或其他话题参数；外链必须是完整 HTTP(S) 地址，最多 2048 字符，不接受本站链接、内嵌凭据或空白字符。返回 `success`、`pending` 和已发布的 `resource`；所有非管理员（包括版主）先进入原生 Reviewable，审核通过前不会出现资料卡片。

服务端仍使用原生 NewPostManager、Topic/Post 和审核流程。新资料保存 `isbf_learning_link`、`isbf_learning_description` 和 `isbf_learning_contributor`，审核 payload 保留这些字段，卡片标题直接打开链接，不重复显示内部正文。原生主题标题校验继续生效。历史附件资料与原生管理员编辑功能保留，原有 `POST /posts` 的资源字段仍受分类、身份、附件权限和审核限制。

学习资料沿用原生 `ReviewableQueuedPost`，只有管理员可在原生 `/review` 列表、详情、菜单、编辑及审核动作中查看或操作这些记录；版主与分类审核组成员均无权操作。贡献者与简介保留在 queued payload 中，管理员可从审核详情查看。批准保留真实提交者和资料元数据，拒绝不创建资料。普通论坛审核记录及课程申请的 staff 权限不变；客户端不能通过原生 `/posts` 传入 `reviewed_queued_post` 绕过资料审核。Site serializer 声明 `resource_contributor: true` 和 `resource_admin_management: true` 供主题识别接口能力。

`DELETE /isbf/learning/resources/:id` 使用数字 Topic ID，仅管理员且通过原生 Guardian 删除权限时可调用；目标必须属于当前学习库的有效可见资源，普通主题、私信与无课程关联主题不可通过该接口删除。删除调用原生 `PostDestroyer` 软删除首帖与主题，不接受客户端的永久销毁参数，不清除资料元数据或私有文件。资源从列表、分页和搜索消失，普通用户（包括原作者）的私有文件访问立即撤销。学习资料的原生 Topic/首帖删除、编辑和恢复入口同样仅限管理员；管理员通过原生恢复流程恢复资源后，文件权限重新按主题可见性检查。

配置的学习分类从 TopicQuery 默认查询中排除，包含最新、热门、排行榜、筛选及直接分类列表，普通成员和 staff 均适用。资料库使用自己的受权限控制的列表和限定范围的原生搜索；已有资料也不会出现在首页、探索或右栏最近讨论。审核队列、直接主题读取及全站搜索不因该列表排除而改变。

## 附件保护与备份

附件保存在 `/shared/isbf-learning-private`，通过登录后受权限控制的 `/isbf/learning/files/:uuid` 下载，不创建公共 Discourse Upload。部署时必须把此目录保存在持久存储，并确认其不在 Web 服务器静态文件公开范围。可用 `ISBF_LEARNING_STORAGE_PATH` 指定独立私有存储目录；不要配置到公开上传目录。

未绑定或待审核附件仅允许上传者和 staff 访问；已发布附件还必须通过资源主题的 Guardian 权限与可见状态检查。资源被删除、隐藏、取消可见或进入严重违规处理状态时，普通用户的附件访问撤销，包括原作者。外部链接的访问控制由外部站点决定，插件不能撤销已下载的副本，也不能把公开外链变成私有文件。

数据库备份必须与私有附件目录备份配套：数据库包含课程、文件元数据及资源关联，私有目录包含实际文件。默认 Discourse 上传备份不能被视为已经包含此独立目录。GitHub 仅保存代码。上线前确认备份与恢复流程，并在恢复后核查关联和下载权限。禁用插件不会删除已有主题、元数据或私有文件；回滚代码应保留这些数据。已有任何 `ReviewableIsbfLearningCourse` 记录时，禁止回退到未注册该类型的旧插件版本：Core 对未知审核类型的处理可能删除记录。可先恢复旧主题，同时保留新审核类型，再部署向前修复；不得通过删除申请记录完成回滚。

## 验证

GitHub Actions 通过 Discourse 官方插件测试工作流执行 Rails RSpec，Core 固定为可获取的上游提交 `f18a1985b22e5d4c0a0fffd6f91812105467afdb`。站点自有 Core 的版本另随发布备份保存，因此此 CI 不等同于域名站点的运行回归。另有 Ruby 语法检查。CI 需要官方工作流提供的 Ruby、PostgreSQL、Redis 和 Discourse 测试依赖；这是独立测试 checkout，不是已有服务器容器。

可在该 Core 的独立测试 checkout 中运行：

```sh
LOAD_PLUGINS=1 bundle exec rspec plugins/isbf-learning/spec
```

测试规格覆盖课程权限、贡献者校验和作者归属、原生审核及元数据保留、管理员专属资料审核与维护、原生接口绕过、软删除与恢复、查询范围和附件存储/访问约束。这些新增规格需要 CI 执行，不能视为已通过的 Rails 回归。本机未启动完整 Discourse，未执行 Rails 集成测试或浏览器回归；语法检查不能证明实际 UI、移动端、亮暗模式、Admin 隔离或部署后的文件下载行为。合并部署前须由 CI 和 Staging 验证。

## 独立资料库

资料库复用本插件的审核、原生 Topic/Post、搜索及管理员维护权限，入口为 `/isbf/library`。`isbf_learning_enabled` 仍是插件总开关；新增 `isbf_library_enabled` 默认关闭，`isbf_library_category_id` 默认 0，必须配置为不同于课程资源的真实分类 ID。类别权限采用课程资源相同的登录用户规则。目录从空开始，不自动生成示例数据。

`GET/POST /isbf/library/categories` 读取或添加分类（创建参数 `name`）；`GET/POST /isbf/library/groups` 读取或添加分组（创建参数 `name`、`category_id`，该参数是目录分类 UUID，不是 Discourse 分类整数 ID）。目录保存到独立 PluginStore `isbf-library` 的 `categories`、`groups`。staff 直接添加，普通成员通过 `ReviewableIsbfLibraryDirectory` 申请，原生动作 `approve_directory` / `reject_directory` 审核；分组必须关联已批准的分类。同范围同名重复申请去重，审核与 PluginStore 写入使用同一原生数据库事务和目录互斥锁。

`GET /isbf/library/resources` 使用 `group_id` 或 `q` 和零起点 `page`；没有筛选时返回空列表。有 `q` 时原生 Search 搜索资料库全部有效分组，与课程资源隔离。`POST` 接受 `group_id`、`title`、`link`、可选 `description` 和 `contributor`。仅分享外部链接，不新增上传接口。返回同样的 `success`、`pending`、`resource`；资料带 `category` 和 `group` 目录信息。资源使用独立 `isbf_library_*` Topic 字段，管理员编辑沿用 `/posts/:id.json` 的顶层 `title` 与首帖字段，删除沿用 `DELETE /isbf/library/resources/:id`。

所有非 admin（包括版主）投稿进入管理员专属原生审核。原生发帖与修订统一按实际分类校验所属库，拒绝跨库字段/目录 ID、匿名和公共附件；已有课程资料及其私有附件机制不变。禁用资料库不会移除已有资料的管理员维护限制，两个已配置资源分类继续从社区列表排除，全站搜索保留 Guardian 权限。

回滚时可关闭资料库入口/新增发布并恢复旧主题，但保留当前插件的权限钩子和全部审核类型。存在新目录申请记录时，不得回退到未注册 `ReviewableIsbfLibraryDirectory` 的旧插件版本；不删除历史目录、资料或申请。发布前备份数据库、主题、插件、分类配置和既有私有附件目录。

## 已部署课程资源权限兼容

资料库改造保留实际站点的学院权限集成：课程资源的 `can_manage?` 接受 admin 或原有 `academy_can?(:manage_resources)`，`can_review?` 接受 admin 或原有 `academy_can?(:review_resources)`；课程目录保留学院角色开关关闭时的原生 staff 回退。课程附件的未绑定、待审核及已发布访问规则沿用已部署实现。以上委派权限只作用于课程资源；资料库的直接发布、编辑、删除及投稿审核始终要求原生 admin，目录则沿用原生 staff。
