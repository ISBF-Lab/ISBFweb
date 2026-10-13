# ISBF Calendar

Discourse 插件，提供 `/isbf/calendar`、`/isbf/workbench` 和仅当前用户可访问的个人日程 API。界面由 `themes/isbf-campus-feed` 实现。社区活动继续使用 Discourse Events 原生接口和话题。

## 官方时间项

依赖 `discourse-academy-roles` 的 `academy_roles_enabled`、`academy_official_category` 和 `academy_official_group`。官方发布者在分类首帖的发布或编辑窗口填写时间项；编辑仍遵守该首帖的 Guardian 权限。官方组须具有相应的发帖和编辑权限。

每条消息最多 20 个时间项，名称最多 120 字。时间项可以是活动或截止日期，使用北京时间 `Asia/Shanghai`。活动可以省略结束时间，此时存储为一个时间点。仅日期的截止项表示整天，不推断具体截止时刻；全天日期范围的结束时刻为次日北京时间零点，且不包含该时刻。

时间项通过 `isbf_official_calendar_items` JSON 字符串与首帖一同提交，包含 `title`、`schedule_kind`（`event` / `deadline`）、`starts_at`、`ends_at`、`all_day`。时间必须为带时区的 ISO 8601 字符串，数据库存 UTC。编辑已有时间项必须附带它的 `id` 和 `revision`。保留 ID 表示修改或排序，省略该项表示取消，新项不传 ID；已取消的 ID 不可复用。仅排序和普通正文编辑不会产生新的源版本。

从 0.3.0 起，活动支持可选的 `location`（最多 255 字）、`organizer`（最多 120 字）和报名截止项。报名截止仍是一条可单独导入日历的 `deadline` 时间项；活动请求的 `registration_deadline_index` 指向同一数组中该截止项的零基下标，设为 `null` 可解除关联。关联必须属于同一消息，一个截止项最多关联一个活动。响应使用稳定的 `registration_deadline_id`。活动和报名截止分别计入 20 个时间项上限。

旧客户端省略新字段时保留已有地点、主办方和仍在请求数组中的截止关联；传入空值可以清除。历史活动不自动匹配历史截止日期。地点、主办方和关联记录在首帖修订前后数据中，但不会增加个人日历的时间版本或触发改期通知；个人导入快照仍只包含名称、类型和时间。

首帖详情提供逐项添加按钮；消息流只显示摘要。每个用户与源时间项之间有唯一索引，重复请求返回已有记录。导入项保存当时的信息，私人备注最多 2000 字，仅本人可编辑和删除；官方名称、类型和时间不可直接修改。

官方变更通过提交后的后台任务发送站内通知，并在日历顶部跨月份列出待确认项。接受更新才替换个人快照，私人备注保留；保留原信息仅忽略当前源版本，之后的新版本仍提示。删除时间项或消息会标记取消，保留个人记录和备注。隐藏、私有化或失去访问权限的消息不会通过日历或通知暴露新的信息。

## API

- `GET /isbf/api/entries.json?from=<ISO8601>&to=<ISO8601>`：当前用户在时间范围内的行程，范围最多 62 天。
- `GET /isbf/api/entries/:id.json`：本人单条行程，可用于通知跨月定位。
- `POST /isbf/api/entries.json`：创建手动行程，返回 201。
- `PATCH /isbf/api/entries/:id.json`：修改手动行程，或仅更新官方导入项的 `note`。
- `DELETE /isbf/api/entries/:id.json`：删除本人行程。
- `POST /isbf/api/official-items/:id/add.json`：传入 `revision`，新增返回 201，已添加返回 200。
- `GET /isbf/api/entry-updates.json`：所有月份的待确认变更。
- `POST /isbf/api/entries/:id/accept-update.json`：传入 `revision`，返回更新后的行程。
- `POST /isbf/api/entries/:id/dismiss-update.json`：传入 `revision`，保留当前信息并忽略该源版本，成功返回 204。

手动行程写入参数放在 `entry` 对象中：`title`、`starts_at`、`ends_at`、`all_day`、`note`。添加或确认时源版本过期返回 409；客户端刷新最新信息，重新由用户决定。用户不能访问其他人的行程。

行程响应包含 `source_item_id`、`accepted_revision`、`needs_update`、`cancelled`、`source_unavailable`、`source_url` 和 `latest_source`。后者仅在当前用户仍可访问源消息时包含最新内容；无法访问的取消项仅暴露取消状态与版本。

不支持重复日程、到点提醒、自然语言识别或外部日历集成。

## 验证与部署

使用独立数据库运行插件测试，不重置运行中的开发站点：

```sh
RAILS_ENV=test LOAD_PLUGINS=1 RAILS_DB=isbf_calendar_test bin/rake db:create db:migrate
RAILS_ENV=test LOAD_PLUGINS=1 RAILS_DB=isbf_calendar_test bin/rspec plugins/isbf-calendar/spec
```

迁移 `20261006101910_add_official_calendar_items.rb` 为增量变更，旧手动行程无需回填。`20261006160545_add_official_activity_details.rb` 增加活动地点、主办方和截止关联，旧记录的文本字段为空、关联为空。先部署插件并运行迁移，再部署主题界面。已有历史官方消息在编辑首帖时补充时间项即可。

线上主题 ID 4 的更新必须先导出新备份并比对当前字段，仅同步本功能涉及的字段或增量补丁，保留其设置、组件和其他更新；不要导入旧的完整主题覆盖。确认 JavaScript、测试和明暗主题样式均编译通过，再验证首帖发布、逐项添加、改期通知、确认与保留、取消，以及原有手动日程和社区活动。
