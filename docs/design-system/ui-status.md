# UI 状态与设计来源

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
遵照用户要求[控制内存](resource-policy.md)，停止生产排查。

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
