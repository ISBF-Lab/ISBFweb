# UI 状态与设计来源

2026-10-22 用户指定[姓名渐变色](reviews/feed-name-gradients-20261022/README.md)：仅扩展本人姓名颜色区域的双端颜色和横向/竖向选择，不扩大整个偏好页的批准范围。

2026-10-21：用户已确认[信息流姓名颜色与排版方案](reviews/feed-name-colors-20261021/README.md)并要求实施。新增偏好字段区域的设计已确认，实际界面及Safari状态验证以该记录为准；此增量不将完整偏好页提升为Approved，也不表示已经发布。

主题参考审阅于 2026-10-10；本次文档整理及认证增量核对于 2026-10-11。先读本文件，再读 [tokens](tokens.md)、[组件规范](components.md) 和 [Reference Map](reference-map.md)。

唯一设计来源是已经重构且有验收依据的界面区域。Approved 按**区域及状态**授予，不按路由整体授予。平台组件的存在、CSS 覆盖、Git 未提交状态和页面能打开，都不足以单独证明一个界面已经成为标准。

## 判断方式与路径

- **Approved**：自定义实现已接入已验收版本，且有对应的检查或审核记录；只能复用下表写明的范围。未验收状态仍需人工确认。
- **Legacy**：已检查到该区域仍调用原生页面/组件，尚无替代它的 Approved 设计。外层 V2 shell 或宽度修补不会让内部表单、表格和交互变成 Approved。
- **In Progress**：有明确进行中、未完成验收的记录；不作为设计来源。未提交文件不能直接归入此类。
- **需要人工确认**：来源、视觉验收或接管范围不足；暂不强行分入其他类别。

下文“主题参考路径”均指 `references/theme-4/` 下的真实 `.txt` 附件。对应实际运行位置为主题字段映射出的 `themes/isbf-campus-feed/` 路径，映射及差异见 [manifest](references/manifest.json)。工作区并非完整验收副本，缺失文件应读附件。核心路径和插件路径则是实际源码位置。详细来源见 [参考说明](references/README.md)。

## Approved

### 页面壳与内容区域

| ID  | 页面/组件与使用场景                      | 主题参考路径                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | 为什么可作参考、批准边界                                                                                                                                                                                                          | 可复用页面                                                   |
| --- | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| A01 | V2 shell：侧栏、右栏、移动导航及账号菜单 | [shell](references/theme-4/javascripts/discourse/components/isbf-v2-shell.gjs.txt)、[side-nav](references/theme-4/javascripts/discourse/components/isbf-v2-side-nav.gjs.txt)、[right-rail](references/theme-4/javascripts/discourse/components/isbf-v2-right-rail.gjs.txt)、[account-menu](references/theme-4/javascripts/discourse/components/isbf-v2-account-menu.gjs.txt)、[common.scss](references/theme-4/common/common.scss.txt)                                                                      | 已接入主题基线；[桌面/手机、明暗与账号文字检查](references/evidence/ui-layout.md)。只批准代码接管路由上的页面壳；关联账号新流程不能仅据菜单样式批准                                                                               | 普通列表、官方消息、通知、探索、公开资料和功能入口的外层布局 |
| A02 | 普通信息流与 Topic List Item             | [feed-card](references/theme-4/javascripts/discourse/components/isbf-v2-feed-card.gjs.txt)、[topic-list 出口](references/theme-4/javascripts/discourse/connectors/topic-list-item/isbf-feed-card.gjs.txt)、[common.scss](references/theme-4/common/common.scss.txt) 的 `.isbf-feed-card`、`.isbf-v2-topic`                                                                                                                                                                                                  | 原生列表通过出口显示定制内容，保留作者、正文与互动；[列表验收](references/evidence/initial-ui.md)、[手机作者完整显示](references/evidence/ui-layout.md)。原生 `tr` fallback 与定制卡片是两个变体                                  | 首页、最新话题及符合既有接管条件的分类列表                   |
| A03 | 官方消息列表与活动摘要                   | [official-feed](references/theme-4/javascripts/discourse/components/isbf-official-feed.gjs.txt)、[activity-summary](references/theme-4/javascripts/discourse/components/isbf-official-activity-summary.gjs.txt)、[official-filters.scss](references/theme-4/stylesheets/official-filters.scss.txt)、[official-calendar.scss](references/theme-4/stylesheets/official-calendar.scss.txt)                                                                                                                     | [布局记录](references/evidence/official-activity.md)明确作者/标题→正文→活动→互动顺序及手机两列；[浏览器验收](references/evidence/official-calendar.md)。只接管 `officialConfig` 认定的官方路径                                    | 官方消息、活动/截止项摘要及同类筛选栏                        |
| A04 | 普通话题阅读布局、元信息与互动区域       | [topic-card 初始化](references/theme-4/javascripts/discourse/api-initializers/isbf-topic-card.gjs.txt)、[topic-reading](references/theme-4/javascripts/discourse/components/isbf-topic-reading.gjs.txt)、[topic-actions](references/theme-4/javascripts/discourse/components/isbf-topic-actions.gjs.txt)、[topic-reading.scss](references/theme-4/stylesheets/topic-reading.scss.txt)、[接管条件](references/theme-4/javascripts/discourse/lib/topic-card-scope.js.txt)                                     | 基线已有定制帖子内容与阅读接入；[主题说明摘录](references/evidence/topic-reading.md)记录原生菜单与时间轴的复用边界。范围限 `/t/`、`regular`、非嵌套视图；帖子还要求 `post_type === 1`。不是私信、嵌套回复或全部管理菜单状态的批准 | 普通话题详情、相同语义的正文/互动区                          |
| A05 | 当前用户的分组通知页                     | [notifications](references/theme-4/javascripts/discourse/components/isbf-notifications.gjs.txt)、[action](references/theme-4/javascripts/discourse/components/isbf-notification-action.gjs.txt)、[entry](references/theme-4/javascripts/discourse/components/isbf-notification-entry.gjs.txt)、[notification-groups](references/theme-4/javascripts/discourse/lib/notification-groups.js.txt)                                                                                                               | [验收](references/evidence/ui-layout.md)覆盖独立折叠、懒加载、重试、分页及键盘。要求 `isbf_notifications_enabled`，且路径属于当前用户                                                                                             | 分组通知与现有通知条目；不能自动替代所有用户活动行           |
| A06 | 自定义探索分类区域                       | [explore](references/theme-4/javascripts/discourse/components/isbf-explore.gjs.txt)、[group](references/theme-4/javascripts/discourse/components/isbf-explore-group.gjs.txt)、[picker](references/theme-4/javascripts/discourse/components/isbf-explore-picker.gjs.txt)、[common.scss](references/theme-4/common/common.scss.txt) 的 `.isbf-explore`                                                                                                                                                        | 已接入基线；[联合验证](references/evidence/initial-ui.md)记录探索设置及列表检查。只批准已接入的分类分组结构；证据未说明所有菜单、空态和错误态的视觉验收。仅 `/categories` 且 `isbf_explore_enabled`                               | 探索分类分组；搜索结果、标签页内层需另定方案                 |
| A07 | 日历、官方时间项与既有编辑弹窗           | [calendar](references/theme-4/javascripts/discourse/components/isbf-v2-calendar.gjs.txt)、[calendar-editor](references/theme-4/javascripts/discourse/components/isbf-official-calendar-editor.gjs.txt)、[note-editor](references/theme-4/javascripts/discourse/components/isbf-calendar-note-editor.gjs.txt)、[update-dialog](references/theme-4/javascripts/discourse/components/isbf-calendar-update-dialog.gjs.txt)、[official-calendar.scss](references/theme-4/stylesheets/official-calendar.scss.txt) | [验收](references/evidence/official-calendar.md)覆盖官方列表、编辑器、北京时区转换、390px 手机与三个弹窗；生产写入被阻止，不能视为全部提交/异常状态验收。个人日历功能依赖日历插件                                                 | 现有日历、活动及截止项编辑、私人备注、变更查看               |
| A08 | 工作台入口网格                           | [workbench](references/theme-4/javascripts/discourse/components/isbf-v2-workbench.gjs.txt)、[common.scss](references/theme-4/common/common.scss.txt) 的 `.isbf-v2-workbench`                                                                                                                                                                                                                                                                                                                                | [桌面及手机入口验证](references/evidence/avatar-management.md)、[后续认证发布复验](references/evidence/auth-current.md)。批准网格和入口外观；占位入口不是已实现功能                                                               | 工作台及同类已批准入口集合                                   |
| A09 | 商城商品列表                             | [marketplace](references/theme-4/javascripts/discourse/components/isbf-marketplace.gjs.txt)、[marketplace-card](references/theme-4/javascripts/discourse/components/isbf-marketplace-card.gjs.txt)、[marketplace.scss](references/theme-4/stylesheets/marketplace.scss.txt)                                                                                                                                                                                                                                 | [实际商品渲染验收](references/evidence/avatar-management.md)、[后续复验](references/evidence/auth-current.md)。批准已加载列表的布局；不能把发布、上传、空态和全部错误态一并批准                                                   | 商品摘要和相同语义的商品行                                   |
| A10 | 校友目录与地图展示                       | [alumni](references/theme-4/javascripts/discourse/components/isbf-alumni.gjs.txt)、[alumni-map](references/theme-4/javascripts/discourse/components/isbf-alumni-map.gjs.txt)、[common.scss](references/theme-4/common/common.scss.txt) 的 `.isbf-alumni`                                                                                                                                                                                                                                                    | [地图初始化验收](references/evidence/avatar-management.md)、[后续复验](references/evidence/auth-current.md)。地图/目录现有结构有源码，验收明确地图初始化；不批准全部筛选、资料编辑和数据缺失状态                                  | 校友目录和已有地图区域；不是通用用户弹出卡规范               |

### 资料、预览与认证

| ID  | 页面/组件与使用场景                      | Source of Truth                                                                                                                                                                                                                                                                                                                                                                                                          | 为什么可作参考、批准边界                                                                                                                                                                                                                                                     | 可复用页面                                           |
| --- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| A11 | 公开用户资料顶部：封面、头像、文字及导航 | [common.scss](references/theme-4/common/common.scss.txt) 的 `body:has(.isbf-v2-shell--profile)`；原生 [user.gjs](../../frontend/discourse/app/templates/user.gjs) 提供结构                                                                                                                                                                                                                                               | [上传封面与手机文字检查](references/evidence/ui-layout.md)。无封面、展开状态有后续 CSS 覆盖，须读完整级联。只批准顶部，不批准偏好设置表单或弹出卡                                                                                                                            | 公开个人资料顶部                                     |
| A12 | 公开个人活动摘要与右栏最近讨论预览       | [activity-preview](references/theme-4/javascripts/discourse/components/isbf-activity-preview.gjs.txt)、[post-preview](references/theme-4/javascripts/discourse/components/isbf-post-preview.gjs.txt)、[post-preview lib](references/theme-4/javascripts/discourse/lib/post-preview.js.txt)                                                                                                                               | [验收与边界](references/evidence/post-preview.md)明确公开活动最多 3 图、最近讨论无标题时 2 行/1 图；草稿、书签、待审核、私信、通知不接管                                                                                                                                     | 公开活动、右栏最近讨论                               |
| A13 | 学院认证页：登录、邀请码注册及认证面板   | [2026-10-11 组件](references/plugins/discourse-academy-roles/accepted-20261011/assets/javascripts/discourse/components/academy-auth-page.gjs.txt)、[2026-10-11 样式](references/plugins/discourse-academy-roles/accepted-20261011/assets/stylesheets/common/academy-auth.scss.txt)；实际路径 `plugins/discourse-academy-roles/assets/…`                                                                                  | [已审核集成](references/evidence/auth-accepted.md)、[面板对齐](references/evidence/auth-alignment.md)、[最新验收](references/evidence/auth-current.md)。依赖 `academy_auth_page_enabled`；粒子和居中表单属于认证页专用设计。手机验收为浏览器触控模式，注册部分曾使用模拟请求 | 同一认证流程；不移植成论坛一般页面背景或全局表单规范 |
| A14 | 可选头像框叠层及内容区域定位             | [2026-10-11 overlay](references/plugins/discourse-avatar-frames/accepted-20261011/assets/javascripts/discourse/components/avatar-frame-overlay.gjs.txt)、[定位](references/plugins/discourse-avatar-frames/accepted-20261011/assets/javascripts/discourse/modifiers/avatar-frame-position.js.txt)、[样式](references/plugins/discourse-avatar-frames/accepted-20261011/assets/stylesheets/common/avatar-frames.scss.txt) | [确认方案](proposals/avatar-frame-calibration-20261011.md)与[验收](references/evidence/avatar-calibration.md)。保留 A11 白边、完整装饰和点击行为；参数按头像内容归一化；不批准全部后台                                                                                       | 已有头像挂载点、选择预览                             |
| A15 | 后台头像框上传校准区                     | [上传组件](references/plugins/discourse-avatar-frames/accepted-20261011/admin/assets/javascripts/admin/components/avatar-frame-upload.gjs.txt)、[局部样式](references/plugins/discourse-avatar-frames/accepted-20261011/assets/stylesheets/common/avatar-frames-admin.scss.txt)                                                                                                                                          | 用户以“开始实现”批准[布局](proposals/avatar-frame-calibration-20261011.md)，后续明确两款由其自行校准。144px/48px 预览在上，三项调节单列在下，手机同样竖排；只批准该字段内区域                                                                                                | 头像框新建、编辑页的校准区                           |

## Legacy

这些区域仍需后续重构。源码可复用权限、数据、可访问性和工程能力，不能据其默认外观推导目标样式。部分区域已受 V2 外层或小范围补丁影响，下表描述的是仍保留原生实现的**内层区域**。

| 文件路径                                                                                                                                                                                                                                                                                            | 当前作用与判定依据                                                                              | 后续需要重构的区域                                       |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| [admin.gjs](../../frontend/discourse/admin/templates/admin.gjs)、`frontend/discourse/admin/templates/`                                                                                                                                                                                              | 后台原生导航/页面；V2 shell 明确排除 `/admin`                                                   | 后台页面壳、表格和表单；须先确定后台是否采用公共论坛设计 |
| [groups/index.gjs](../../frontend/discourse/app/templates/groups/index.gjs)、`frontend/discourse/app/templates/group/`                                                                                                                                                                              | 原生群组列表与详情；shell 无 `/groups`、`/g` 接管                                               | 群组页内层及页面布局                                     |
| [preferences.gjs](../../frontend/discourse/app/templates/preferences.gjs)、[profile.gjs](../../frontend/discourse/app/templates/preferences/profile.gjs)、[account.gjs](../../frontend/discourse/app/templates/preferences/account.gjs)                                                             | 偏好设置仍通过原生表单/区域组件呈现；公开资料顶部批准不涵盖它们。插件增加字段也不等于整页已重构 | 设置导航、表单排版与各状态；新插件字段分别核验           |
| [user/bookmarks.gjs](../../frontend/discourse/app/templates/user/bookmarks.gjs)、[bookmark-list.gjs](../../frontend/discourse/app/components/bookmark-list.gjs)                                                                                                                                     | 书签列表仍用原生组件，预览明确排除书签                                                          | 书签条目及其操作、空态                                   |
| [user-activity.gjs](../../frontend/discourse/app/templates/user-activity.gjs)、[drafts.js](../../frontend/discourse/app/routes/user-activity/drafts.js)、[pending.gjs](../../frontend/discourse/app/templates/user-activity/pending.gjs)、`frontend/discourse/app/templates/user-private-messages/` | 草稿、待审核、私信仍走原生渲染；部分草稿文字换行修补不构成完整重构                              | 各类专有列表及操作，不套用公开帖子预览                   |
| [full-page-search.gjs](../../frontend/discourse/app/templates/full-page-search.gjs)、[search-result-entries.gjs](../../frontend/discourse/app/components/search-result-entries.gjs)                                                                                                                 | 原生搜索控件及结果，V2 只限制容器宽度/外层                                                      | 搜索条件、结果条目、加载及无结果状态                     |
| [tags.gjs](../../frontend/discourse/app/templates/tags.gjs)、[tags/index.gjs](../../frontend/discourse/app/templates/tags/index.gjs)                                                                                                                                                                | 标签目录内容仍为原生实现；shell 的 explore 类型不等于自定义探索组件                             | 标签目录内层                                             |
| [user-card-contents.gjs](../../frontend/discourse/app/components/user-card-contents.gjs)、[user-card.scss](../../app/assets/stylesheets/common/components/user-card.scss)                                                                                                                           | 用户弹出卡仍为原生内容及样式，不能与个人资料页顶部混同                                          | 用户弹出卡；需要独立设计方案                             |

## In Progress

2026-10-11最初审阅时，没有可以准确认定为“正在修改且仍未完成验收”的正式参考条目。不为填满分类而猜测。

认证触控候选曾被 [暂停记录](references/evidence/auth-pending.md) 标为未验收，后续发布已完成并有 [最新验收](references/evidence/auth-current.md)，因此不再列为 In Progress。工作区未提交差异、历史原型和缺少报告的组件均不能直接当作进行中标准。

## 需要人工确认

| 区域/问题                                        | 已知事实                                                   | 待确认内容                                                     |
| ------------------------------------------------ | ---------------------------------------------------------- | -------------------------------------------------------------- |
| 学习资源、匿名帖子、徽章及信息页内部             | shell 或样式已有覆盖；本次没有完成区域级源码与视觉验收核对 | 哪些内部区域已完成重构、哪些状态可批准；保存相关导入不等于批准 |
| 探索所有菜单/错误态、校友资料编辑、商品发布/上传 | 有自定义源码或相关入口，列表/地图已有限定验收              | 全流程状态与表单视觉规则，不能从成功列表推断                   |
| 通用 Card、通用表单、全局标题层级、反馈消息      | 现有组件存在不同作用域的数值，尚无统一批准的组件契约       | 选择哪种已验收变体，或提交方案后人工确认                       |
| 用户弹出卡、设置页、后台目标设计                 | 当前内层主要为原生实现                                     | 与已批准页面的复用边界及需要补充的组件                         |
| 当前线上精确色板、字体和新插件字段               | 参考源码能说明变量映射，未读取当前数据库/生产              | 当前设置的有效值、最新字段是否已获视觉验收                     |
| 不可读取的部署目录、外部插件及聊天界面           | 工作区存在软链接和权限限制，本次未完整检查                 | 取得对应来源后再分类，不能批量标 Legacy                        |

## 状态维护

提升为 Approved 必须记录区域、实际源码版本、路由/开关、验收范围和可复用边界，并同步其余三份规范及参考 manifest。若目标没有匹配的 Approved 组件或状态，必须先提出包含来源、缺口和复用方式的设计方案，获得人工确认后再实现；最初分析阶段只记录；2026-10-12后的实施范围见下文确认记录。

## 2026-10-12：本轮前台统一

[运行基线](baselines/README.md)、[19组执行记录](frontend-rollout-20261012.md)
及[D01–D07代表提案](proposals/frontend-consistency-20261012.md)已建立。
D01–D06及D07弹窗组合已人工确认，实际页面仍为In Progress；用户卡及资料上部保留，后台排除。
遵守现行[运行约束](resource-policy.md)，停止生产排查。

## 本轮接入状态与保留区域

19个页面组进入In Progress，原生模板的Legacy审阅记录不表示其仍待设计选择。
范围与进度以[执行记录](frontend-rollout-20261012.md)为准，新增组合以[人工确认记录](references/evidence/frontend-consistency-acceptance-20261012.md)为准。
用户弹出卡仍是Legacy且明确排除；资料顶部A11、一级导航、头像框A14和公开活动预览A12保留。
资料设置表单属于接入范围。新页面未完成实际交互与保留区域验证前，不标为Approved。

## 本轮实现来源与验证

19组均已提交代码，实际页面仍为In Progress。具体接入文件、保留边界和未覆盖状态见
[实现说明](frontend-implementation-20261012.md)，源码摘要见
[source map](frontend-implementation-source-map-20261012.json)，检查结果见
[验证记录](frontend-verification-20261012.json)。新版离线入口为
[V2预览](reviews/frontend-20261012-v2/index.html)，已移除用户卡示例；旧包只作历史记录。

## 2026-10-13 头像框显示技术修复

[首页及个人卡片的定位修复](deployments/avatar-frame-visibility-20261013/README.md) 已上线，
复用 A14/C03 的叠层视觉规则，只修正锚点及头像查找；没有新增颜色、尺寸或页面布局。
用户明确最后自行视觉核验，当前待确认。该记录不批准整个用户卡片或提升新的视觉标准。


## 2026-10-14 简历紧凑页头

用户已批准单行“← 简历”的设计预览。仅页头设计获批，实际页面验证待完成；按用户要求，本轮没有浏览器或真机复验。既有整页状态和其他区域的批准范围不因此扩大。

[设计确认及来源](../../plugins/isbf-resume/docs/design-system/resume-approval.md#2026-10-14-简历紧凑页头设计确认)保存用户批准范围、来源版本和实现边界。

## 2026-10-13 帖子与站内通知姓名显示

[姓名显示增量](deployments/user-display-20261013/README.md) 已更新活动主题 ID 4，
统一首页、普通话题主帖/回复和站内通知的姓名与账号显示，保留全站姓名设置、
原有作者与通知组件、样式及交互。实际来源和摘要已保存；没有新增视觉 token。
用户明确自行完成最终视觉验收，当前待确认，不扩大 A02/A04/A05 的 Approved 范围。

## 2026-10-13 右侧悬浮时间轴

[方案](proposals/topic-timeline-floating-20261013.md)经用户审查参考图后确认，最终调整为日期和阅读信息在左、时间轴在右。
普通V2话题的时间轴统一点击后展开为窄幅毛玻璃浮层，不再占用右栏空间；复用A04的原生阅读行为及A01的局部视觉规则。
实际源码与检查边界保存于[验收目录](reviews/topic-timeline-20261013/README.md)。2026-10-14已按用户要求调整底部返回按钮及60%背景/24px玻璃效果并[上线](deployments/topic-timeline-20261014/README.md)。当前为In Progress，人工视觉验收待用户完成；不扩大Approved范围。

2026-10-14 [跳转定位修复](deployments/topic-jump-alignment-20261014/README.md)同步上线电脑和手机，
复用 A01 固定 60px 页头和既有信息页测量规则，使目标帖子顶部对齐页头底部。
仅恢复 A04 阅读跳转的可见性，没有新增视觉 token；离线定位及线上资源核对通过，人工视觉验收仍待确认。

## 2026-10-14 个人资料邀请人显示

用户要求关闭资料页的邀请人显示，并明确自行视觉验证。
[单字段发布记录](deployments/profile-inviter-visibility-20261014/README.md)保存实际源码与验证边界；
复用 A11/C10 既有资料详情行的隐藏规则，只加入邀请人整行选择器。
样式 lint、主题编译与线上 CSS 资源核对通过，人工视觉验收待用户完成，不扩大 Approved 范围。

## 2026-10-14 页头返回导航

[返回导航增量](deployments/back-navigation-20261014/README.md) 已更新活动主题 ID 4，
复用现有页头结构，将 V2 shell、校友页、共用工作台话题页及共用资源页的左箭头
接入当前标签页的站内历史。共用页头保留线上商城、组队、学习资源和资源库的既有布局与功能。
历史回归、候选 lint、主题编译和实际脚本资源核对通过；生产浏览器交互未自动验收。
仅修复导航行为，没有新增视觉 token 或扩大 Approved 范围。

## 2026-10-14 招募接入

用户已批准保留压缩包招募页面外观，仅修改菜单跳转、资源前缀及表单鉴权接线，
并新增开发者后台只读申请表格。页面与提交公开，申请记录仅 Discourse `admin` 可读。
批准边界、实际来源及验证记录见 [招募接入记录](references/join-20261014/README.md)。
这项批准仅限上述区域，不将其他后台或主题区域提升为 Approved。
2026-10-15 已按授权[上线](deployments/join-20261015/README.md)，实际菜单只更换跳转动作。
公开页与权限检查通过；桌面/手机表单仅在禁用 WebGL 的 fallback 场景验证，
完整论坛与3D动画浏览器验收未完成。


2026-10-15 已上线[纹理与桌面 App 导航兼容修复](deployments/join-compat-20261015/README.md)，
以及用户指定的[六张图库图片](deployments/join-gallery-20261015/README.md)。
复用原招募页布局、样式和模型；用户要求减少不必要检查，最终视觉验收由用户完成。

## 2026-10-15 回复对话分组

用户已确认[分组方案](proposals/reply-conversations-20261015.md)，要求先交付代码和电脑/手机预览，
验收后再上线。普通话题采用单层回复结构、最早三条预览、组内50条分页、回复对象原文预览，
悬浮时间轴按讨论组导航，旧楼层链接保留精确定位。复用A01/A04及C01/C03/C09的局部规则。
实现、源码摘要和离线验证保存在[审阅目录](reviews/reply-conversations-20261015/README.md)。
当前为In Progress：方案已确认，实际视觉和完整应用回归待验收；未部署、未修改生产设置，
不将静态预览或编译通过视为新增Approved范围。

用户首版审阅后要求进度简化为“1 / 2”、按钮只写“收起”、子回复增加竖向引导线。
已按要求更新候选与桌面/手机明暗预览，复用既有token；视觉验收仍为In Progress。

用户随后选择B方案，要求支线改为直线，主干从根回复头像底部延伸，并提供完整参考HTML。
当前按[选定记录](reviews/reply-conversations-20261015/guide-redesign/README.md)实施：
33px自然缩进、1px主干与直线短支线、末条头像中心处收尾。设计方向已确认，实际视觉仍待验收；未上线。

2026-10-16补充：用户随后确认最终视觉并授权上线，回复交互修正已增量发布。
上文“未上线”记录设计阶段；当前源码与完整浏览器验收进度见
[交互修正阶段记录](deployments/reply-conversations-20261015/interaction-progress.md)，
后续最终状态以同目录发布README为准。

2026-10-16后续手机互动栏、连续回复发布及同帖原文跳转的批准范围和检查结果，见[回复回归修复](deployments/reply-conversations-20261015/regressions-20261016.md)。

## 认证欢迎按钮位置修复（2026-10-16）

A13 / C01 的欢迎态按用户指定，将登录和注册按钮组下移24px；已技术发布，最终视觉待用户核验，不扩大其他认证状态的批准范围。

来源与实施记录见[局部修复](deployments/auth-welcome-buttons-20261016/README.md)。

## 2026-10-16 帖子底部继续阅读

用户确认将“新帖与未读”和“相关话题”统一为轻量“接着看看”列表，保留来源、排序、权限、阅读状态及跳转。
仅覆盖普通话题详情底部，包含平铺与嵌套入口；私信和未知插件模式沿用原组件。
设计方向已确认，实施及定向检查见[审阅记录](reviews/continue-reading-20261016/README.md)；
最终视觉验收待用户完成，不据此扩大 A04 或其他页面的 Approved 范围。

2026-10-16补充：用户明确授权上线，局部继续阅读已发布。原生及线上检查、实际源码版本、保留范围和回退见[发布记录](deployments/continue-reading-20261016/README.md)。最终视觉仍待用户核验，不扩大其他区域的Approved范围。

2026-10-17继续阅读修订：用户明确要求容器直角，局部`border-radius: 0`取代初版16px圆角；其他组件的圆角token不变。源码及线上CSS验证见[修订记录](deployments/continue-reading-20261016/square-border-20261017/README.md)。

## 2026-10-18 通知未读提示增量

用户已确认：两端主题色数字/圆点角标、账号偏好、默认全部及只看未读、
点开具体通知才标读。C18仅扩展A01/A05的通知入口、菜单、筛选和分组提示。
用户后续修订已明确：动作旁蓝点居中、主题大标题无点、只看未读开关放入右上角三点菜单。
[实际来源与验证](reviews/notifications-unread-20261018/README.md)保存局部组合及验收边界；
设计方向已确认，最终视觉待用户核验，不扩大其他导航或通知投递的Approved范围。

2026-10-18通知未读提示已按用户授权发布；精确线上合并源、已验证镜像、两端功能与资源核对见[发布记录](deployments/notifications-unread-20261018/README.md)。C18的角标、动作点和菜单筛选规则保持局部范围。

## 2026-10-18 通知页层级与整行点击

用户确认保留按帖子归组，采用有边界的分组块，每条通知整行可点击；
确认1px边框、8px圆角、16px组间距及18/15/16/13px文字层级，不增加正文摘要。
C19仅组合A05/C13与C18的当前用户通知页；实际源码和离线预览见
[审阅记录](reviews/notifications-layout-20261018/README.md)。
设计方向已确认，最终视觉待用户核验，尚未部署；不扩大其他页面的Approved范围。

2026-10-18通知页层级与整行点击已按用户授权发布；活动主题4项字段的确切合并源、插件及镜像核对、两端只读验证见[发布记录](deployments/notifications-layout-20261018/README.md)。C19仅限本次通知区域。

## 2026-10-19 通知菜单与筛选记忆修订

用户要求收窄菜单，并确认“只看未读”跟随账号保存。通知菜单采用内容固有宽度，
沿用既有边框、圆角和内距；账号未设置时显示全部，之后恢复上次成功保存的选择。
本次仅修订A05/C06/C18/C19，源码、预览及验证边界见[审阅记录](reviews/notifications-menu-memory-20261019/README.md)。
设计方向已确认，最终视觉待用户核验，尚未上线；不扩大其他区域的Approved范围。

2026-10-19通知菜单收窄与账号筛选记忆已按用户授权上线；精确增量源码、完整插件及镜像核对、两端只读页面和验证边界见[发布记录](deployments/notifications-menu-memory-20261019/README.md)。最终视觉待用户核验。

## 2026-10-19 个人活动与总结预览修复

用户确认公开活动隐藏无标题占位名并最多显示三图，总结页使用两行正文摘要、保持文字列表。复用A12/C12，补齐历史记录缺少帖子ID的读取路径；[实际源码与验证边界](reviews/profile-previews-20261019/README.md)独立保存。设计选择已确认，最终视觉待用户核验，不扩大资料顶部或其他活动类型的Approved范围。

2026-10-19补充：个人活动与总结预览修复已上线，用户确认“没有问题，可以了”。本次验收仅限这两页的无标题正文与图片预览；确切合并源、原生22项布局检查、资源/镜像核对及线上自动化限制见[发布记录](deployments/profile-previews-20261019/README.md)。不扩大其他区域的Approved范围。


## 2026-10-19 招募页鞋部近景裁切

[相机裁切修复](deployments/join-camera-20261019/README.md)按用户确认计划增量上线，
开场恢复模型原始近裁剪距离，中段和隧道深度参数保持。原布局、模型动作与六图保持，
最终视觉由用户验收，不扩大其他区域的 Approved 范围。

## 2026-10-19 弹性404局部设计确认

用户确认独立品牌页、站点同色弹性数字、拖开0的隐藏按钮、极简弹球及浏览器本地最长存活记录，并授权验证后上线。C20只覆盖普通404与片段导航；403和权限专用说明保持原流程。[首版审阅记录](reviews/elastic-404-20261019/README.md)保留历史来源，当前版本以修订和验收记录为准。

同日用户进一步要求全屏、球速逐渐加快、开始后不能暂停，并指定使用REA分析BOC实际404后应用；以[修订记录](reviews/elastic-404-fullscreen-20261019/README.md)为当前局部确认范围。技术验证与最终视觉验收分开记录，首版快照不再代表当前布局或游戏规则。

当前404修订已上线，用户回复“可以了，我验证了”，C20当前交付的视觉状态为Approved。确切源版本、验收范围、自动化未完成项与恢复镜像见[发布记录](deployments/elastic-404-fullscreen-20261019/README.md)；不推定用户逐项测试或完成整站回归。临时凭据与工具已清理，停止额外测试。

## 注册用户名提醒（2026-10-19）

A13 / C08 新增注册用户名提醒，用户已确认文案及主题蓝色。范围仅为用户名字段下方的居中说明；最终视觉待用户核验。
见[局部实现与来源](reviews/auth-username-hint-20261019/README.md)。

2026-10-20补充：注册用户名主题蓝色提醒已按授权增量发布，既有内容保留；
见[确切来源及恢复边界](deployments/auth-username-hint-20261019/README.md)。最终视觉待用户核验。

## 2026-10-20 接着看看无标题修复

用户确认将此前的无标题正文规则补齐到C17两种推荐来源。新增文字预览模式沿用现有两行标题、字体、颜色和直角边框，首帖摘要与原未读跳转位置分别保留。实际三字段来源、两端验证与回退见[发布记录](deployments/continue-reading-previews-20261020/README.md)；不扩大其他区域的Approved范围。

## 2026-10-20 前台弹窗统一

用户已确认[截图与范围](reviews/dialog-consistency-20261020/README.md)：前台DModal及确认框使用C07共享外框、文字操作按钮及手机留边；招募独立页、后台、菜单、用户卡与查看器保留。原D07手机全宽在此范围由16px留边加安全区取代。设计标准已明确，实施及最终视觉状态见本轮验证记录；不把全部弹窗的业务、权限或异常状态整体标为Approved。

2026-10-20补充：前台弹窗共享外观已按授权上线，184个模块与132个样式目标完整编译，
既有功能及数据加载经两端只读确认；[源码、证据和恢复边界](deployments/dialog-consistency-20261020/README.md)。最终视觉待用户核验。

## 2026-10-21 帖子、评论与子回复操作栏间距

用户指定点赞与赞数沿用热度的4px距离，五个图标等距，保留评论和子回复的不同原生动作，并授权验证后上线。复用A04/C09/C16的图标、触控尺寸、手机起点与缩进；本人点赞入口另作窄屏对齐。[实际来源与235项离线检查](reviews/post-action-spacing-20261021/README.md)限定本次局部组合，最终线上视觉待用户核验，不扩大其他区域的Approved范围。发布状态见[上线记录](deployments/post-action-spacing-20261021/README.md)。


## 2026-10-21 删除回复与系统活动目标

用户明确确认[简短删除提示与首帖回退方案](reviews/deleted-replies-system-targets-20261021/README.md)并要求实施。批准边界限单层回复中的删除占位、分组展开/定位/恢复，以及公开系统活动链接；不授予整页或其他菜单新的视觉批准。源版本与检查记录随该补充保存。

实际版本 `deeb83874f16187abeca003e4a12f583087b0d0ea738901c4d7fbc74b2f3fc9c` 已于2026-10-21发布；电脑和手机的实际页面、系统目标及刷新已确认。来源、检查边界和恢复镜像见[发布记录](deployments/deleted-replies-system-targets-20261021/README.md)。

## 2026-10-22 时间轴展开布局恢复

用户确认修复方案并要求验证后上线，恢复此前确认的右侧窄幅毛玻璃时间轴。
普通话题和分组回复通过模板标题识别阅读区域，移除依赖原生class补写的布局方式。
桌面和手机的真实Ember客户端定向复现、开关、话题切换和定位记录见
[本次修复审阅](reviews/topic-timeline-stability-20261022/README.md)。
沿用A01/A04/C16及既有浮层局部规则，不新增token或扩大Approved范围，最终视觉待用户核验。

2026-10-22 19:20:22（UTC+8）已[增量上线](deployments/topic-timeline-stability-20261022/README.md)，
234字段中的其他229项、全部设置及完整运行库存保持。两端定向组件检查和实际JS/CSS资源核对通过，视觉待用户确认。

## 2026-10-22 栏目操作区按钮收纳规则

用户已确认：栏目存在多个操作按钮，实际可用宽度不足以一行容纳时，不允许按钮换行；只保留一个由提出需求的用户逐栏目指定的业务按钮，其余操作收入三点菜单。三点入口不计入业务按钮数量，宽度充足时恢复原有排列。未指定外露按钮时，开发者须先向该用户确认，不新增站点使用者的个人偏好设置。

适用范围为栏目页头、列表及卡片操作栏；表单提交/取消、弹窗底部和认证按钮沿用各自规范。具体规则见 [C01](components.md#栏目操作区窄屏收纳) 与 [C06](components.md#c06--dropdown--menu)，实施及检查要求见 [Reference Map](reference-map.md#执行步骤)。按钮和菜单继续复用已有组件、样式及触控尺寸，保留权限、禁用、加载和键盘行为，不新增视觉token。

本次仅将已确认的行为规则写入规范，尚未修改或验收任何具体栏目界面，不扩大现有Approved范围。各栏目实施时须记录外露按钮的用户决定、实际源码版本及宽窄状态的验证结果。

## 2026-10-22 注册后首次设密

用户已确认新注册无密码账号的双密码输入弹窗，设置或跳过后不再提醒；关闭按钮、Escape和遮罩按跳过处理。复用C07共享前台弹窗及FormKit，本次只批准该任务组合。实际界面、异常状态及最终视觉的验证边界见[实施记录](reviews/post-signup-password-20261022/README.md)，不扩大完整账号设置页的Approved范围。

## 2026-10-23 工作台方形十入口

用户确认原站十入口顺序、电脑五列/手机两列、方形卡片和电脑悬停/手机点击的图标反馈，并要求直接上线。A08 增量范围与实际源码见[本次记录](reviews/workbench-square-20261023/README.md)。仅确认工作台排布及反馈，不扩大未开放入口和其他业务页的验收范围。实际发布及线上检查另见[发布记录](deployments/workbench-square-20261023/README.md)。

## 2026-10-23 注册与登录动画验证码

用户提供分格验证码源码，明确覆盖网站注册和登录，指定网站主题色，并在计划后要求开始实施。A13/C08 内新增动画验证码的设计已确认：六位数字、逐格落入、错误倒序清空、成功合并填充与勾选。校友申请的邮箱验证使用同一工程组件。最终视觉待用户核验；开发验证和实际源版本见[实施记录](reviews/auth-code-slots-20261023/README.md)。此确认限验证码输入区域及其反馈，不扩大认证页面或校友申请其他表单的验收范围。

## 2026-10-24 工作台后台分端布局发布范围

用户已确认工作台传统/玻璃的后台分端选择、电脑无雾化材质与局部配色、名称入玻璃、指定文案清理及未满行左对齐，并授权提交 PR、合并和上线。只覆盖 C02/A08 工作台主内容，沿用 600px 分界和既有入口权限；不扩大其他页面的 Approved 范围。来源、局部规则、版本及实际检查见[本次记录](reviews/workbench-layout-20261024/README.md)。CI、生产发布与最终视觉验收分别记录，不以开发检查替代。

## 2026-10-24 引用头像尺寸修复

用户提供手机截图并确认实施修复方案。A02/A04及A12展开正文中的引用头像恢复渲染器声明的24×24px；正文媒体样式排除`img.avatar`，沿用C03/C09/C12现有布局。此增量修复不新增头像变体或扩大整页Approved范围。实际源码、开发站同步、定向检查及视觉验收边界见[记录](reviews/quote-avatar-sizing-20261024/README.md)。


## 2026-10-24 无标题展示补齐

用户已确认全部前台入口的无标题正文摘要替换。仅批准本次文字展示、紧凑链接两行和原始编辑值保护；不批准私有列表采用公开信息流或扩大整页验收范围。来源、接口与验证边界见[本次记录](reviews/untitled-displays-20261024/README.md)。

## 2026-10-25 帖子互动按钮回弹

用户确认信息流卡片、详情主帖、根评论和子回复的点赞／引用／评论／收藏统一采用PulseHeart动效，保留现有图标、外形、尺寸、颜色与排列。点击立即反馈，数字与状态沿用现有业务结果；设计已确认，实际验证及最终视觉验收见[独立记录](reviews/post-action-pulse-20261025/README.md)。本次仅扩展A02/A04/C09/C16局部交互，不扩大其他区域的Approved范围。

### 2026-10-25 鼠标悬停修订

用户根据最新截图确认去掉这排按钮的鼠标悬停底色，仅保留图标变色及点击回弹。点赞和独立赞数入口同时清理；通过局部hover变量覆盖，原按钮／触控范围、排列及键盘焦点保留。来源、截图及验证见[本次记录](reviews/post-action-pulse-20261025/README.md)。

## 2026-10-26 全站下拉菜单

用户已认可校区样板，并确认全站包含前台、认证、后台与活动插件，保留入口用途、手机统一浮动及最新大圆角方案。菜单采用独立[共享契约](dropdowns.md)，来源、接受范围及实际验证见[本轮记录](reviews/dropdowns-20261026/README.md)。样板已获用户认可；本轮全站组合最终视觉验收另记，不批准整个后台或认证区域。

## 2026-10-26 通知页长按标读

用户已确认电脑端三点左侧外露“全部标为已读”、手机同排显示“全部已读”，以及300ms长按、主题蓝色填充、中性底色和保留高优先级确认框。范围仅为A05通知页的此项操作，最终视觉待用户验收；实现和实际检查见[审阅记录](reviews/notifications-hold-20261026/README.md)。独立菜单改造不因本次按钮接入扩大批准范围。

## 2026-10-27 独立热门榜单

用户选择独立热门页与紧凑榜单并确认实施。根`/top`的页头、周期筛选、排名条目及手机布局按[本次记录](reviews/top-topics-20261027/README.md)执行；复用A01、A02、C04、C06、C09及C12，排名组合属于本次确认的局部设计。开发验证、最终视觉验收与生产发布分别记录，不扩大其他列表或整站Approved范围。

## 2026-10-28 桌面账号菜单包裹

用户选择一体包裹：上方菜单与底部原椭圆个人卡片处于同一外框，并按整卡居中。该确认仅扩展A01／C06的完整桌面侧栏账号菜单；沿用共享外观，技术验证和最终视觉确认另记。来源及实现见[本轮记录](reviews/account-menu-enclosure-20261028/README.md)。

## 2026-10-28 工作台 MBTI 专区

用户已确认 MBTI 专区的入口、逐题作答、结果、私人历史和本机续答设计范围；实现及实际视觉验收仍在进行。来源与局部组件/token规则见[专区记录](reviews/mbti-workbench-20261028/README.md)，不扩大现有工作台及共享组件的验收范围。
