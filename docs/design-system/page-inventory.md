# 待统一主题的页面清单

整理日期：2026-10-11。用途：在开始全站 UI 重构前，确定页面范围、已有参考及设计缺口。本次只新增清单，没有修改 UI、业务代码、主题设置或线上数据。

## 范围与判断依据

先读 [UI 状态](ui-status.md)、[tokens](tokens.md)、[组件规范](components.md)、[Reference Map](reference-map.md) 和 [来源说明](references/README.md)。本清单补充实际路由，不改变上述文档的 Approved 范围。

- **已确认 Legacy**：设计规范已明确列为 Legacy，且当前可读模板/路由仍使用对应原生内层。已有页面壳和局部 CSS 补丁保留为复用依据，重构目标是未批准的区域。
- **待核验**：有原生实现、定制覆盖或入口，但缺少完整 Approved 依据。没有批准不等于外观一定不符合；先逐区域核验，再确定需要改造的部分。
- **后台单独确认**：核心后台仍是 Legacy，定制插件后台没有完整公共设计参考。需要先确认后台是否采用论坛主题，以及表格、管理表单的复用规则。
- **条件范围**：仓库中存在的插件、动态筛选路由和辅助界面不等于当前线上已启用。不能按目录存在就认定它们是线上待重构页面。

URL 中 `:username`、`:name`、`:id` 等表示路由参数；`…` 表示下文列明的子路由，不是字面 URL。按页面组统计，查询参数、动态对象、重定向和弹窗入口不重复计页。

核心路由依据：[app-route-map.js](../../frontend/discourse/app/routes/app-route-map.js)、[admin-route-map.js](../../frontend/discourse/admin/routes/admin-route-map.js)。主题覆盖依据：[已验收 shell](references/theme-4/javascripts/discourse/components/isbf-v2-shell.gjs.txt)、[完整 common.scss](references/theme-4/common/common.scss.txt)、[列表出口](references/theme-4/javascripts/discourse/connectors/topic-list-item/isbf-feed-card.gjs.txt)、[普通帖子接管条件](references/theme-4/javascripts/discourse/lib/topic-card-scope.js.txt)。

当前工作区主题与已验收数据库快照存在差异，部分校友、商城、学习模块在工作区不完整。当前线上配色、字体、插件开关及所有页面的浏览器效果未在本次重新读取。下面是有源码依据的重构范围，不是当前线上逐页视觉验收报告。

## 已确认 Legacy：论坛用户页面

共 14 个页面组。Approved ID 对应 [UI 状态](ui-status.md)，组件 ID 对应 [组件规范](components.md)。标有设计缺口的页面不能直接套用另一用途的组件外观。

| ID  | 页面组               | URL / 子页面                                                   | 当前源码                                                                                                                                                                                                                  | 需要调整的区域                                           | 可复用参考与缺口                                                     |
| --- | -------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | -------------------------------------------------------------------- |
| F01 | 账号设置             | `/u/:username/preferences/account`                             | [account.gjs](../../frontend/discourse/app/templates/preferences/account.gjs)                                                                                                                                             | 设置导航、账号字段、关联账号、保存/危险操作及反馈        | A01/A11 仅限适用外层和资料顶部；C08 提供工程能力，完整设置表单未批准 |
| F02 | 安全设置             | `/u/:username/preferences/security`                            | [security.gjs](../../frontend/discourse/app/templates/preferences/security.gjs)                                                                                                                                           | 密码、二次验证、通行密钥、会话及授权列表的排版/状态      | 保留真实安全流程；没有 Approved 管理表格及安全表单外观               |
| F03 | 个人资料编辑         | `/u/:username/preferences/profile`                             | [profile.gjs](../../frontend/discourse/app/templates/preferences/profile.gjs)                                                                                                                                             | 简介、资料字段、头像/背景上传控件、保存和验证            | A11 只批准公开资料顶部，不批准资料编辑表单；A14 仅头像叠层           |
| F04 | 其余偏好设置         | `/u/:username/preferences/…`，完整子页面见下表                 | [preferences.gjs](../../frontend/discourse/app/templates/preferences.gjs)、[preferences/](../../frontend/discourse/app/templates/preferences/)                                                                            | 各页表单、选择器、复选项、保存条与状态                   | 统一设置表单方案需人工确认；插件字段分别核验                         |
| F05 | 书签                 | `/u/:username/activity/bookmarks`                              | [user/bookmarks.gjs](../../frontend/discourse/app/templates/user/bookmarks.gjs)、[bookmark-list.gjs](../../frontend/discourse/app/components/bookmark-list.gjs)                                                           | 搜索、条目、提醒/编辑动作、空态和分页                    | A01 仅外层；C12 明确排除书签，不能直接套公开活动预览                 |
| F06 | 草稿                 | `/u/:username/activity/drafts`                                 | [drafts.js](../../frontend/discourse/app/routes/user-activity/drafts.js)、[user/stream.gjs](../../frontend/discourse/app/templates/user/stream.gjs)                                                                       | 草稿条目、继续编辑/删除、批量动作、空态                  | 已有文字换行补丁不等于完整设计；专有条目方案缺失                     |
| F07 | 待审核内容           | `/u/:username/activity/pending`                                | [pending.gjs](../../frontend/discourse/app/templates/user-activity/pending.gjs)                                                                                                                                           | 待审核条目、审核信息、删除与空态                         | 保留审核权限和内容可见性；没有 Approved 待审核条目                   |
| F08 | 个人私信列表         | `/u/:username/messages` 及个人/群组/标签子列表                 | [user/messages.gjs](../../frontend/discourse/app/templates/user/messages.gjs)、[user-private-messages/](../../frontend/discourse/app/templates/user-private-messages/)                                                    | 多级导航、私信条目、筛选、归档和未读状态                 | A01 仅实际接管外层；普通信息流/公开预览不覆盖私信                    |
| F09 | 完整搜索             | `/search`                                                      | [full-page-search.gjs](../../frontend/discourse/app/templates/full-page-search.gjs)、[search-result-entries.gjs](../../frontend/discourse/app/components/search-result-entries.gjs)                                       | 高级条件、结果条目、分类/用户/标签结果、分页与无结果状态 | A01 外层和语义 token；C08 右栏搜索不能替代完整搜索表单               |
| F10 | 标签目录             | `/tags`                                                        | [tags/index.gjs](../../frontend/discourse/app/templates/tags/index.gjs)                                                                                                                                                   | 标签分组、列表、目录工具栏和批量创建界面                 | shell 的 explore 类型不代表 A06 分类探索已接管；标签目录方案缺失     |
| F11 | 群组目录与创建       | `/g`、`/g/custom/new`                                          | [groups/index.gjs](../../frontend/discourse/app/templates/groups/index.gjs)、[groups/new.gjs](../../frontend/discourse/app/templates/groups/new.gjs)                                                                      | 整体布局、群组列表、筛选、创建表单                       | A01 shell 没有 `/g` 接管；不能强行复制论坛 shell，先确认扩展方案     |
| F12 | 群组详情、成员与活动 | `/g/:name`、`members`、`requests`、`activity/…`、`permissions` | [group.gjs](../../frontend/discourse/app/templates/group.gjs)、[group/index.gjs](../../frontend/discourse/app/templates/group/index.gjs)、[group/activity.gjs](../../frontend/discourse/app/templates/group/activity.gjs) | 群组顶部、成员/请求、活动导航、加入动作及权限说明        | 没有 Approved 群组页；公开资料顶部和校友目录仅提供可讨论的局部参考   |
| F13 | 群组管理             | `/g/:name/manage/…`                                            | [group/manage.gjs](../../frontend/discourse/app/templates/group/manage.gjs)、[group/manage/](../../frontend/discourse/app/templates/group/manage/)                                                                        | 管理导航、资料、成员、邮件、权限与配置表单/表格          | 管理表单和表格规范缺失，保留原有授权及验证                           |
| F14 | 群组私信             | `/g/:name/messages`、`inbox`、`archive`                        | [group/messages.gjs](../../frontend/discourse/app/templates/group/messages.gjs)                                                                                                                                           | 私信导航、条目及收件箱/归档状态                          | 与 F08 可共同提案，不能用公开信息流改变私信语义                      |

### F04：偏好设置子页面

以下路径均位于 `/u/:username/preferences/`。加上 F01–F03 的 `account`、`security`、`profile`，核心路由共定义 14 个子路由；插件附加页另行核验。

| 子路径                   | 用途             | 模板                                                                                                        |
| ------------------------ | ---------------- | ----------------------------------------------------------------------------------------------------------- |
| `emails`                 | 邮件通知偏好     | [emails.gjs](../../frontend/discourse/app/templates/preferences/emails.gjs)                                 |
| `notifications`          | 通知偏好         | [notifications.gjs](../../frontend/discourse/app/templates/preferences/notifications.gjs)                   |
| `tracking`               | 话题跟踪偏好     | [tracking.gjs](../../frontend/discourse/app/templates/preferences/tracking.gjs)                             |
| `users`                  | 用户静音/忽略    | [users.gjs](../../frontend/discourse/app/templates/preferences/users.gjs)                                   |
| `tags`                   | 标签通知偏好     | [tags.gjs](../../frontend/discourse/app/templates/preferences/tags.gjs)                                     |
| `interface`              | 界面偏好         | [interface.gjs](../../frontend/discourse/app/templates/preferences/interface.gjs)                           |
| `apps`                   | 应用设置         | [apps.gjs](../../frontend/discourse/app/templates/preferences/apps.gjs)                                     |
| `navigation-menu`        | 导航菜单偏好     | [navigation-menu.gjs](../../frontend/discourse/app/templates/preferences/navigation-menu.gjs)               |
| `calendar-subscriptions` | 日历订阅         | [calendar-subscriptions.gjs](../../frontend/discourse/app/templates/preferences/calendar-subscriptions.gjs) |
| `email`                  | 修改邮箱流程     | [email.gjs](../../frontend/discourse/app/templates/preferences/email.gjs)                                   |
| `second-factor`          | 二次验证设置流程 | [second-factor.gjs](../../frontend/discourse/app/templates/preferences/second-factor.gjs)                   |

`/u/:username/preferences` 默认跳转 `account`，不作为额外页面。独立 [categories.gjs](../../frontend/discourse/app/templates/preferences/categories.gjs) 等模板的存在也不增加路由数量，需按实际嵌套使用检查。

### 私信与群组子路由

- F08 个人私信：默认列表、`new`、`unread`、`archive`、`sent`、`warnings`；群组私信：`group/:name` 及 `archive`、`new`、`unread`；标签私信：`tags`、`tags/:id`。均保留原有权限及私密数据加载。
- F12 群组活动：`activity`、`activity/posts`、`activity/topics`、`activity/mentions`；成员、请求和权限仍属于该群组页面组。
- F13 群组管理：`profile`、`membership`、`interaction`、`email`、`members`、`categories`、`tags`、`logs`。
- `/u/:username/activity/bookmarks-with-reminders` [重定向到书签](../../frontend/discourse/app/routes/user-activity/bookmarks-with-reminders.js)，与 F05 一并检查，不计为独立布局。

## 待核验：不能直接判定整页需要重做

这些区域先核对当前实际源码、开关及浏览器效果。确认仍不符合后，才纳入实施范围；不自动提升为 Approved，也不自动归为 Legacy。

| ID  | 页面组 / URL                                                                                            | 已知事实与源码                                                                                                                                                                                                                                                              | 待确认内容                                                                                               |
| --- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| V01 | 个人资料下部：`/u/:username/summary`、`badges`、`deleted-posts`、`profile-hidden`                       | [summary.gjs](../../frontend/discourse/app/templates/user/summary.gjs)、[user/badges.gjs](../../frontend/discourse/app/templates/user/badges.gjs)、[user/posts.gjs](../../frontend/discourse/app/templates/user/posts.gjs) 等保留原生内容；A11 仅顶部                       | 统计、徽章、删除内容/隐藏资料等各区域哪些需改；A12 公开活动预览不能自动覆盖它们                          |
| V02 | 用户目录：`/u`                                                                                          | [users.gjs](../../frontend/discourse/app/templates/users.gjs) 使用 DirectoryTable；shell 的 `/u/` 匹配不包含 `/u` 本身                                                                                                                                                      | 是否启用用户目录、与 A10 校友目录的区别、列表/筛选及整体布局方案                                         |
| V03 | 用户邀请管理：`/u/:username/invited`、`/:filter`                                                        | [user-invited/show.gjs](../../frontend/discourse/app/templates/user-invited/show.gjs) 仍有邀请表格；工作区含邀请码和角色相关修改                                                                                                                                            | 当前哪些控件已验收；列表、新邀请、批量操作与生成链接的目标外观                                           |
| V04 | 徽章目录、详情：`/badges`、`/badges/:id/:slug`                                                          | [badges/](../../frontend/discourse/app/templates/badges/)、common 的 badges 规则已有布局覆盖                                                                                                                                                                                | 徽章卡、授予用户列表、标题/动作及状态是否已符合；不能以缺少整页批准就重做已有覆盖                        |
| V05 | 信息页：`/about`、`/faq`、`/guidelines`、`/conduct`、`/rules`、`/tos`、`/privacy`                       | [about.gjs](../../frontend/discourse/app/templates/about.gjs)、[faq.gjs](../../frontend/discourse/app/templates/faq.gjs)、common 的 information 规则已调整内容和统计布局                                                                                                    | 区分管理员提供的正文与页面 UI，核对信息导航、统计和用户列表；不重写政策正文                              |
| V06 | 标签管理：`/tag_groups`、`/tag_groups/new`、`/tag_groups/:id`、`/tag/:tag_slug/:tag_id/edit` 及编辑 tab | [tag-groups/](../../frontend/discourse/app/templates/tag-groups/)、[tag/edit/tab.gjs](../../frontend/discourse/app/templates/tag/edit/tab.gjs) 仍有原生管理结构                                                                                                             | 管理表单/表格目标；标签话题列表另按 V16 核验，不与目录 F10 混为一页                                      |
| V07 | 分类创建/编辑：`/new-category`、`/new-category/setup`、`/new-category/:tab`、`/c/*slug/edit` 及 tab     | [后台路由](../../frontend/discourse/admin/routes/admin-route-map.js)、[new-category.gjs](../../frontend/discourse/admin/templates/new-category.gjs)、[edit-category/tabs.gjs](../../frontend/discourse/admin/templates/edit-category/tabs.gjs)                              | URL 虽部分在 `/c/`，实际是管理表单；确认与群组/后台的设计关系及所有编辑状态                              |
| V08 | 审核中心：`/review`、`/review/:reviewable_id`、`/review/topics`、`/review/settings`                     | [review/](../../frontend/discourse/app/templates/review/) 使用原生审核结构；现有 shell 未接管 `/review`                                                                                                                                                                     | 是否采用论坛功能页布局；筛选、审核条目、证据、状态和管理操作的规范                                       |
| V09 | 认证辅助页：密码重置、账号创建/激活、邮箱确认、邮件登录、二次验证                                       | [password-reset.gjs](../../frontend/discourse/app/templates/password-reset.gjs)、[account-created/](../../frontend/discourse/app/templates/account-created/)、[second-factor-auth.gjs](../../frontend/discourse/app/templates/second-factor-auth.gjs) 等                    | A13 只覆盖已验收认证流程；逐路由确认其他页面是否接管及能否复用认证专用表单                               |
| V10 | 异常、权限和断网界面：`/404`、`/exception`、隐藏/拒绝访问、离线页                                       | [exception.gjs](../../frontend/discourse/app/templates/exception.gjs)、[unknown.gjs](../../frontend/discourse/app/templates/unknown.gjs)、[not_found.html.erb](../../app/views/exceptions/not_found.html.erb)、[offline.html.erb](../../app/views/offline/offline.html.erb) | 全站错误/空态/离线规范缺失；服务端降级页与 Ember 页分开验收                                              |
| V11 | 学习资源：`/isbf/learning`                                                                              | 已验收 shell 保存了 learning 入口和模块引用，规范明确内部尚未完成核验；工作区版本不完整                                                                                                                                                                                     | 取得实际运行模块，核对目录、筛选、资源条目、上传/发布及错误状态                                          |
| V12 | 我的匿名帖子：`/isbf-anonymous/posts`                                                                   | [插件模板](../../plugins/isbf-anonymous/assets/javascripts/discourse/templates/isbf-anonymous-posts.gjs)、已验收 shell 有定制入口/引用                                                                                                                                      | 取得实际接管组件并核验专有列表、空态及身份边界；不能从普通公开信息流推断                                 |
| V13 | 私信详情、嵌套回复、系统/特殊帖子：`/t/:slug/:id` 内相关状态                                            | [topic-card-scope](references/theme-4/javascripts/discourse/lib/topic-card-scope.js.txt) 只批准 regular、非嵌套、`post_type === 1` 的相应区域                                                                                                                               | 同一路由内未接管区域的当前外观及专有规则；普通 A04 不能直接扩大到这些状态                                |
| V14 | 已定制功能中的未验收流程：校友资料编辑、商品发布/上传、探索完整菜单、举报、日历提交异常                 | A03/A06/A07/A09/A10 只批准限定区域；[组件规范](components.md) 已标明缺口                                                                                                                                                                                                    | 分别核验具体弹窗、表单、加载/失败/无数据状态；保留已批准的列表、地图和日历                               |
| V15 | 原生登录/注册/邀请 fallback                                                                             | `/login`、`/signup`、`/invites/:token` 和登录必需入口具有条件接管                                                                                                                                                                                                           | 核对开关及特殊注册上下文；A13 已批准的正常流程保留，不重做。未接管分支是否可达、是否需要统一须确认       |
| V16 | 其他话题筛选、标签话题列表、子分类视图                                                                  | `/:filter`、`/c/*category_slug_path_with_id/…`、`/tag/:tag_slug/:tag_id`、`/tags/c/…`；筛选由站点动态定义                                                                                                                                                                   | A02 同时包含定制卡片及原生行 fallback，先核对路由/批量选择条件和现有变体；不能把全部 fallback 判为不符合 |

V09 的实际路由包括 `/u/password-reset/:token`、`/u/account-created` 及 `resent`/`edit-email`、`/u/activate-account/:token`、`/u/confirm-new-email/:token`、`/u/confirm-old-email/:token`、`/session/email-login/:token`、`/session/2fa`。这些 URL 不继承正常 `/login` 的整页批准。

V15 的接管条件由 [academy-auth-enabled.js](../../plugins/discourse-academy-roles/assets/javascripts/discourse/lib/academy-auth-enabled.js) 和 [邀请出口](../../plugins/discourse-academy-roles/assets/javascripts/discourse/connectors/invite-registration-page/academy-auth.gjs) 定义：学院及认证页开关同时启用；邀请出口还要求 `enable_local_logins_via_code`。`signup` 在满足条件时 [转至认证注册模式](../../plugins/discourse-academy-roles/assets/javascripts/discourse/initializers/academy-auth.js)，不能算成一个新的已批准注册页。

V16 的定制卡片出口明确检查首页、`/latest`、配置的官方路径及反馈路径，并在批量选择时回退。shell 能覆盖 `/top`、`/new`、`/unread` 等，不等于这些路径都使用同一内容组件。动态筛选名称和可达状态以当前站点为准，不枚举猜测的线上 URL。

## 后台：单独确认目标后纳入

核心后台为已确认 Legacy，A01 明确排除 `/admin`。下面仅按实际路由分组，不将后台原生 UI kit 外观提取为目标设计。后台若要与公共论坛主题统一，必须先补充后台页面壳、表格、管理表单和状态规范。

| ID  | 页面组                       | 代表 URL / 范围                                                                                                  | 源码依据 / 需要确认                                                                                                                                                                                                                                                                                |
| --- | ---------------------------- | ---------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| B01 | 后台首页、仪表盘与报表       | `/admin`、`/admin/dashboard/…`、`/admin/reports/…`                                                               | [admin-route-map.js](../../frontend/discourse/admin/routes/admin-route-map.js)、[admin.gjs](../../frontend/discourse/admin/templates/admin.gjs)；指标/图表和筛选布局                                                                                                                               |
| B02 | 用户、群组、徽章管理         | `/admin/users/…`、`/admin/groups/…`、`/admin/badges/…`                                                           | [admin-users.gjs](../../frontend/discourse/admin/templates/admin-users.gjs)、[admin-groups.gjs](../../frontend/discourse/admin/templates/admin-groups.gjs)、[admin-badges.gjs](../../frontend/discourse/admin/templates/admin-badges.gjs)；列表、详情及授权操作                                    |
| B03 | 站点设置与配置中心           | `/admin/site_settings/…`、`/admin/config/…`                                                                      | [admin-config/](../../frontend/discourse/admin/templates/admin-config/)；认证、内容、分类、权限、通知、界面、安全、MCP 等配置子页                                                                                                                                                                  |
| B04 | 外观与内容定制               | `/admin/customize/…`，以及 `/admin/config/` 下主题、组件、色板、字体、logo 等                                    | 同一路由映射；主题/文本编辑器、色板编辑、上传与版本状态                                                                                                                                                                                                                                            |
| B05 | 邮件设置及日志               | `/admin/email/…`、`/admin/email-logs/…`                                                                          | 同一路由映射；服务设置、模板、预览与各类邮件日志                                                                                                                                                                                                                                                   |
| B06 | API、Webhook、备份与运维     | `/admin/api/…`、`/admin/backups/…`、`/admin/logs/…`、`/admin/problem-checks/…`                                   | 同一路由映射；密钥/权限表单、备份/恢复动作与日志                                                                                                                                                                                                                                                   |
| B07 | 插件管理、后台搜索及辅助页面 | `/admin/plugins/…`、`/admin/search`、`/admin/whats-new`、`/admin/section/account`、`/admin/schema/:setting_name` | 同一路由映射；按启用插件扩展列表，保留工程导航及原有权限                                                                                                                                                                                                                                           |
| B08 | 学生邀请管理                 | `/admin/plugins/discourse-academy-roles/student-invites` 及 `new`、`bulk`                                        | [插件路由](../../plugins/discourse-academy-roles/assets/javascripts/discourse/admin-academy-roles-plugin-route-map.js)、[管理模板目录](../../plugins/discourse-academy-roles/admin/assets/javascripts/discourse/templates/admin-plugins/show/academy-student-invites/)；功能记录不等于公共设计批准 |
| B09 | 账号关联审核                 | `/admin/plugins/isbf-account-switch/links`                                                                       | [插件路由](../../plugins/isbf-account-switch/assets/javascripts/discourse/admin-isbf-account-switch-plugin-route-map.js)、[links.gjs](../../plugins/isbf-account-switch/admin/assets/javascripts/discourse/templates/admin-plugins/show/isbf-account-switch-links.gjs)；审核表格及危险操作         |
| B10 | 头像框管理                   | `/admin/plugins/discourse-avatar-frames/frames` 及 `new`、`/:id/edit`、`/:id/grants`                             | [插件路由](../../plugins/discourse-avatar-frames/assets/javascripts/discourse/admin-avatar-frames-route-map.js)、[模板目录](../../plugins/discourse-avatar-frames/admin/assets/javascripts/discourse/templates/admin-plugins/show/avatar-frames/)；A14 只批准前台头像叠层，不批准后台整页          |

B08–B10 是已有定制插件后台，不能一律称为 Discourse 默认页面；其公共设计参考不足，待后台目标确认后逐区域核验。

## 条件范围及未完成审阅的页面

| ID  | 范围                                                     | 当前证据                                                                                                                                                                                                  | 纳入条件                                                                 |
| --- | -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| E01 | 聊天：`/chat`、频道/线程、私聊、搜索、浏览频道及频道设置 | [chat-route-map.js](../../plugins/chat/assets/javascripts/discourse/chat-route-map.js)、[chat 模板](../../plugins/chat/assets/javascripts/discourse/templates/chat/) 可读取，但此前没有 Approved 聊天参考 | 确认聊天启用及产品范围后，核对实际覆盖；不因有源码直接标 Legacy          |
| E02 | 其他可选插件的公开页面及设置页                           | 仓库包含 boards、活动、排行榜、订阅、AI 共享页及用户活动扩展等路由                                                                                                                                        | 先读取当前启用插件清单和开关，再检查相关页面；仓库自带不等于线上使用     |
| E03 | 不可读取的外部插件模块                                   | 本次主机读取 `plugins/isbf-explore`、`isbf-moderation`、`isbf-notifications`、`isbf-views` 的链接目标不可访问                                                                                             | 在实际运行环境取得来源；不猜测路由、页面数量或视觉状态                   |
| E04 | API 授权与基础设置向导                                   | `/user-api-key/new`、`/user-api-key`、`/user-api-key/activate`、`/user-api-key/otp`、`/login-preferences`、`/wizard/steps/:step_id`                                                                       | 有核心路由，但没有完整目标参考；先确认这些工具页的使用范围及设计         |
| E05 | 服务端辅助认证、嵌入和降级页面                           | `app/views/users/` 的辅助认证页、`app/views/session/`、`app/views/embed/`、`app/views/static/` 等另有模板                                                                                                 | 核对真实 HTTP 路由和是否需要论坛主题；未审阅到的页面不伪造 URL           |
| E06 | 独立帖子入口与自定义发现页                               | `/posts`、`/p/:id`、`/custom` 等有核心路由                                                                                                                                                                | 核对实际跳转、启用状态及主题覆盖；不把独立入口等同于已批准的普通话题详情 |

邮件模板、RSS/JSON/API 响应不是论坛页面，本清单不据其格式判定主题是否一致。开发用 styleguide、历史主题/原型和不可读备份也不作为设计来源或线上待改页面。

## 跨页组件：需要和页面一起处理

| 组件 / 入口                                 | 当前事实及源码                                                                                                                                                                                                     | 待处理范围                                                           |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| 点击头像弹出的用户卡                        | 已确认 Legacy：[user-card-contents.gjs](../../frontend/discourse/app/components/user-card-contents.gjs)、[user-card.scss](../../app/assets/stylesheets/common/components/user-card.scss)                           | 需独立用户卡方案，C10 的公开资料顶部不提供通用弹出卡尺寸/布局        |
| 书签及提醒弹窗                              | [modal/bookmark.gjs](../../frontend/discourse/app/components/modal/bookmark.gjs)                                                                                                                                   | 与 F05 统一提案；通用弹窗外观没有批准，保留提醒行为                  |
| 忘记密码与账号关联确认                      | [modal/forgot-password.gjs](../../frontend/discourse/app/components/modal/forgot-password.gjs)、[modal/associate-account-confirm.gjs](../../frontend/discourse/app/components/modal/associate-account-confirm.gjs) | 核对认证专用流程与论坛弹窗的边界，不沿用未经确认的通用尺寸           |
| 创建邀请与生成链接                          | [modal/create-invite-with-roles.gjs](../../frontend/discourse/app/components/modal/create-invite-with-roles.gjs)、[generated-invite-link.gjs](../../frontend/discourse/app/components/generated-invite-link.gjs)   | 当前工作区含角色/邀请码定制，先核验哪些部分已确认，再与 V03/B08 对齐 |
| 私信编辑器、特殊发布与高级管理动作          | [new-message.js](../../frontend/discourse/app/routes/new-message.js)、[new-topic.js](../../frontend/discourse/app/routes/new-topic.js)；其他动作按实际挂载组件核验                                                 | 已批准的发布按钮不批准整个编辑器；保留收件人、权限、草稿及上传逻辑   |
| 分享、举报、删除/确认及批量操作             | [modal/share-topic.gjs](../../frontend/discourse/app/components/modal/share-topic.gjs)、[举报参考](references/theme-4/stylesheets/reporting.scss.txt) 等                                                           | 按现有动作逐项核验；举报定制样式没有完整视觉批准，不推广为通用 Modal |
| 空态、加载、无权限、保存成功、验证/请求失败 | [tokens 的缺失项](tokens.md#缺失与人工确认)、[组件规范](components.md)                                                                                                                                             | 缺少全站共同规则；只能保留同用途已批准状态或先确认方案               |

以下 URL 是动作入口，不能当独立页面另造布局：`/new-topic`、`/new-message`、`/new-invite`、`/password-reset`、`/associate/:token`、`/share-target`。对应核心 route 会打开编辑器/弹窗或转至另一页，分别跟随它的实际承载组件验收。

## 已批准区域：保留作为重构参考

保留 A01–A14 已批准的限定区域：页面壳、普通信息流、官方消息/活动摘要、普通话题阅读、当前用户分组通知、分类探索、日历及既有编辑弹窗、工作台入口、商城列表、校友目录/地图、公开资料顶部、公开活动/最近讨论预览、认证流程和头像叠层。它们不是整条路由的全部状态批准。

其中 A02 原生行 fallback 是已有的独立变体，不能仅因为仍使用原生结构就判为不符合；A04 私信/特殊帖不在批准范围；A05/A06/A13 等依赖真实路由与开关。实施前按 Reference Map 逐项核对。

## 建议的实施顺序与必须补齐的规范

1. 先补设计方案：设置表单、私有条目、搜索结果/目录、管理表格、通用反馈和用户弹出卡。每项列出 Approved 来源、可复用属性及没有依据的规则，获得人工确认后实现。
2. 第一批论坛页面：F01–F10，先处理设置、书签/草稿/待审核/私信、搜索和标签目录；保留已批准外层与已有业务能力。
3. 第二批组织页面：F11–F14；群组页需要单独确认页面壳扩展及管理表单，不直接扩大 A01 接管。
4. 并行整理 V01–V16 的实际状态：只将确认有缺口的区域加入改造，不重做已匹配规范的覆盖。
5. 后台 B01–B10 在目标确认后单独实施；条件范围 E01–E06 在启用和来源确认后纳入。

不得在实施时自行补齐通用 Card、表单布局、表格密度、Modal 尺寸、用户卡、全局标题层级或反馈状态。当前规范没有明确的地方必须标记“需要人工确认”。验收至少覆盖修改涉及的桌面/手机、明暗、权限、键盘、加载/失败状态及动态数据；只有实际批准区域才能更新为 Approved。
