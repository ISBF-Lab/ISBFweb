# ISBF Moderation

Discourse Plugin，为国金综合平台提供严重举报、暂时隐藏与原生管理审核。无需修改 Core 或新建数据表。

## 接口

`POST /isbf/moderation/severe-reports.json`

```json
{ "post_id": 123, "reason": "不少于十个字符的具体严重举报原因", "confirmed": true }
```

成功返回：

```json
{ "post_id": 123, "hidden": true, "reviewable_id": 456 }
```

只接受整数 ID、去除首尾空白后 10–2000 个字符的原因和 JSON 布尔值 `true`。所有正常登录账号，包括 TL0，均可举报自己当前有权限阅读的正常论坛主题首帖或回复，包括管理人员发布的内容。访客、匿名模式替身、禁言、封禁、未激活或 staged 账号不能提交；私信、系统事件、已删除、已隐藏、非公开展示的主题内容不能首次提交。

同一账号的重复提交返回相同审核记录，不新增分数或修改原始严重举报原因。失去分类访问权限的账号不能通过重复提交获取记录。新严重举报复用原生 `notify_moderators` PostAction；已有普通举报升级时保留原生举报类型和原因，仅补充审计信息，不重复创建 PostAction 或 ReviewableScore。已同意并保留、已忽略或已拒绝的普通举报通过原生 `needs_review!` 重新进入待审，复用原来的 score 和 PostAction；原始审核结论、审核人和时间保存在审计 context，原生审核历史和历史统计保留。

## 保留与原生审核

- 以帖子行锁串行处理创建、升级与原生严重审核，使用事务保存原生举报、严重标记与 `Post.hide!`。首帖隐藏按 Core 行为同时隐藏主题。
- 原生 `ReviewableScore.context` 记录严重举报原因、时间和原始 context，原生 Reviewable payload 保存待审标记、最新严重举报时间及对应 score ID；原生 PostCustomField 保存保留标记。
- 使用原生每日举报额度和每帖动作限流，不授予普通账号 `take_action` 或 `queue_for_review` 权限。
- `force_review` 使低分严重举报可见。注册原生 custom reviewable filter，并在 `Reviewable.list_for` 待审查询中注入它；在分页前将严重举报置顶、按最新严重举报时间倒序，保留其他记录的原生排序和所有权限、筛选、认领与分页条件。
- Admin/Developer 对应真实 Discourse staff 权限，仍须通过原生目标审核权限。原生“不同意并恢复”清除标记并恢复内容；原生同意或删除动作保留隐藏与保留标记。非 staff 分类组审核员可在其原生权限范围看见脱敏记录，不能处理严重举报；普通举报审核能力不受影响。
- 作者编辑、举报撤回、Core 手工 unhide 或自动恢复不能释放保留。严重举报对应的原生举报撤回会被拒绝，保留审计证据。

## 内容与实时通知

所有非 staff，包括作者、可阅读普通隐藏帖的用户组和非 staff 分类组审核员，都无法通过 Guardian 控制的帖子、原始正文、cooked、展开与历史接口读取保留正文。Post/BasicPost、话题摘要、用户活动和原生严重审核序列化隐藏原始正文、摘要、图片、编辑原因及审核说明、会话和笔记。原生搜索与 topic excerpts 已排除 hidden 帖。

事务成功后通过 Core `Post.publish_message!`，按真实分类 `secure_audience_publish_messages` 权限发送 `/isbf/moderation/posts`：

```json
{ "post_id": 123, "topic_id": 789, "hidden": true }
```

原生有效恢复动作发送 `hidden: false`。事务回滚不发送本 Plugin 的通知和延期的原生帖子变更通知。已经收到内容的外部邮件、已有引用副本和用户保存的离线副本无法由服务器追回。

`isbf_severe_reports_enabled` 仅关闭新提交。既有保留、内容保护、原生审核与审核优先排序始终生效；卸载 Plugin 会移除这些保护，应先处理所有保留。

提供前端标记：Site `isbf_severe_reports_enabled`；Post `isbf_can_severe_report`、`isbf_severe_report_pending`；TopicListItem `isbf_can_severe_report`。本文中的 Post pending 标记表示内容仍有保留，包括审核同意后仍保持隐藏的内容。

## 验证与兼容性

实现已按服务器 Core `f97a681f813ef716903c892e251182314ce5bdab` 方法契约核对。需要 Rails 支持 `ActiveRecord.after_all_transactions_commit`。升级 Core 时须验证审核动作、serializer、PostRevisor、队列 filter 和 MessageBus 权限。

在完整 Discourse 测试 checkout 中安装此 Plugin 后运行：

```sh
LOAD_PLUGINS=1 bundle exec rspec plugins/isbf-moderation/spec
bundle exec rubocop plugins/isbf-moderation
```

CI 复用官方 `discourse/.github` Plugin 工作流。测试覆盖 TL0、staff、访客、封禁/禁言、私密分类、首帖/回复、普通举报升级、重复提交、真实数据库并发、事务失败回滚、直接内容与序列化保护、作者编辑/撤回、原生审核恢复/同意/删除、低分与跨页优先排序、分类权限和成功后实时通知。并发组关闭测试事务，只清理其自己创建的记录，必须独立串行运行。

本地仅可执行实际可用的静态验证；没有 Ruby/完整 Discourse 的环境不能以静态检查代替上述集成验证。部署前须以完整测试结果为门槛，并回归访客、普通账号、staff、分类组审核员与私密分类的真实页面。
