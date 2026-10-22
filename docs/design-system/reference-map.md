# Reference Map：修改页面前选参考

2026-10-21增量映射：A02/C09 → 卡片标题18px、标题/正文24px、局部链接状态及姓名色；本人“偏好设置 → 界面” → 本次确认的佩戴开关、开发者FormKit选色、预览及恢复主题色。只批准新增字段区域，使用原有保存按钮；其他偏好表单仍保持原验收边界。[来源与验证](reviews/feed-name-colors-20261021/README.md)。

2026-10-18 [AI 审核后台设置](reviews/ai-moderation-20261018/README.md)已确认只接入现有
boolean、enum 和 group_list 设置行，共四项控制；不新增样式或扩大后台 Approved 范围。

先读 [UI 状态](ui-status.md)、[tokens](tokens.md)、[组件规范](components.md)，再按本表找设计来源。`Axx` 是 UI 状态中的批准区域；`Cxx` 是组件规范中的条目。仅参考明确批准的区域及状态，不用同一路由的其他原生内容补齐设计。

## 执行步骤

1. 定位目标页面的 route、template/component、插件出口、主题 selector 与开关，明确桌面/手机、明暗、权限及状态。
2. 从 `ui-status.md` 选择与用途匹配的 Approved reference；使用 `references/manifest.json` 核对真实源码及版本。工作区不一致时先读验收副本，不能直接把工作区目录当成完整标准。
3. 复用业务组件和已有 tokens；工程控件遵守 UI kit/FormKit/float-kit 公开 API。目标视觉属性逐项写明来源，局部数值只用于原作用域或已确认的相同用途。
4. 若组件、状态或响应式方案没有匹配参考，先提出设计方案，明确可复用部分、缺失规则和需人工确认的决定，获得确认后再实现。不能从 Legacy、历史原型或个人审美补值。
5. 完成后按同一参考比较桌面/手机、明暗及修改涉及的状态，检查原有权限、导航、键盘、动态数据与安全区。只有实际验收覆盖的部分才能申请成为新的 Approved reference。

## 原始Approved页面映射（本轮新用途见文末确认表）

| 修改目标                             | Approved Reference / 实际来源                                                                                                                                                                                                                                                                                        | Reuse：可复用内容                                                                     | 边界与缺口                                                                                               |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| 首页、最新话题、普通 Topic List      | A01/A02；C01/C04/C09；[feed-card](references/theme-4/javascripts/discourse/components/isbf-v2-feed-card.gjs.txt)、[列表出口](references/theme-4/javascripts/discourse/connectors/topic-list-item/isbf-feed-card.gjs.txt)                                                                                             | shell、中央列、作者/正文、分隔线、互动组、手机间距                                    | 定制 feed 与原生 fallback 分开；确认当前 route 的接管条件，不给全部表格新增圆角 Card                     |
| 普通 Topic 详情                      | A04/A01；C01/C03/C09；[topic-card scope](references/theme-4/javascripts/discourse/lib/topic-card-scope.js.txt)、[reading](references/theme-4/javascripts/discourse/components/isbf-topic-reading.gjs.txt)、[topic-reading.scss](references/theme-4/stylesheets/topic-reading.scss.txt)                               | 普通帖子布局、真实菜单动作、阅读导航与已有正文规则                                    | 仅 regular、非嵌套和普通 post；复用 Core 单个阅读导航实例，不复制时间轴；私信和特殊帖另提方案            |
| 官方消息列表、活动摘要               | A03；C01/C06/C11；[official-feed](references/theme-4/javascripts/discourse/components/isbf-official-feed.gjs.txt)、[activity-summary](references/theme-4/javascripts/discourse/components/isbf-official-activity-summary.gjs.txt)、[official-filters.scss](references/theme-4/stylesheets/official-filters.scss.txt) | 消息顺序、筛选、活动字段、双列 grid、缺省翻译、既有互动                               | 依赖官方路径配置；手机仍两列；不创造活动字段或历史关联                                                   |
| 日历、时间项编辑、备注、变更查看     | A07；C07/C08/C11；[calendar](references/theme-4/javascripts/discourse/components/isbf-v2-calendar.gjs.txt)、[calendar-editor](references/theme-4/javascripts/discourse/components/isbf-official-calendar-editor.gjs.txt)、[official-calendar.scss](references/theme-4/stylesheets/official-calendar.scss.txt)        | 现有日历布局、真实编辑器、FormKit 字段、DModal、条目边框/间距                         | 日期及通知语义保留；生产验证未写入真实帖子，不推断全部成功/错误视觉状态；无通用 modal 尺寸标准           |
| 当前用户分组通知                     | A05；C05/C06/C13；[notifications](references/theme-4/javascripts/discourse/components/isbf-notifications.gjs.txt)、[action](references/theme-4/javascripts/discourse/components/isbf-notification-action.gjs.txt)                                                                                                    | heading、tabs、分组/条目、独立折叠及已验证的重试/分页/键盘                            | 检查当前用户及 `isbf_notifications_enabled`；不要增加整个 topic 折叠或改用公开活动预览                   |
| 探索分类                             | A06/A02；C06/C09；[explore](references/theme-4/javascripts/discourse/components/isbf-explore.gjs.txt)、[group](references/theme-4/javascripts/discourse/components/isbf-explore-group.gjs.txt)                                                                                                                       | 已接入分类分组结构、主题卡片与颜色变量                                                | 仅 `/categories` 且开关启用；全部 picker/错误/空态视觉未获确认；搜索和标签内层另处理                     |
| 工作台入口                           | A08/A01；C02/C04；[workbench](references/theme-4/javascripts/discourse/components/isbf-v2-workbench.gjs.txt)                                                                                                                                                                                                         | 既有入口网格、图标局部颜色、卡片尺寸、4/3/4 列覆盖                                    | 入口占位不等于功能已实现；不把工作台卡片外观推广到信息流                                                 |
| 商品列表                             | A09；C02；[marketplace-card](references/theme-4/javascripts/discourse/components/isbf-marketplace-card.gjs.txt)、[marketplace.scss](references/theme-4/stylesheets/marketplace.scss.txt)                                                                                                                             | 商品行、缩略图、价格、分隔线、hover/focus、移动尺寸                                   | 必须等待实际商品渲染；发布、上传和全部错误态缺少完整规范                                                 |
| 校友目录、地图展示                   | A10；[alumni](references/theme-4/javascripts/discourse/components/isbf-alumni.gjs.txt)、[alumni-map](references/theme-4/javascripts/discourse/components/isbf-alumni-map.gjs.txt)、common `.isbf-alumni`                                                                                                             | 已有地图区域尺寸、目录 grid、header、手机单列                                         | 验收明确地图初始化；编辑弹窗、所有筛选/无数据状态需确认；不当作通用用户卡                                |
| 公开个人资料顶部                     | A11/A14；C03/C10；common profile 区域、头像框附件                                                                                                                                                                                                                                                                    | 封面/无封面规则、头像边框与装饰层、顶部内容间距                                       | 上传封面与无封面、展开与收起分别看完整级联；不涵盖 preferences 与 user-card                              |
| 后台头像框校准区                     | A15/A14；C14/C03；[确认方案](proposals/avatar-frame-calibration-20261011.md)、2026-10-11 头像框参考附件                                                                                                                                                                                                              | 144px/48px 叠加预览、单列数字输入、确认；保留原上传字段与 FormKit 行为                | 仅新建/编辑上传字段内；不批准后台导航、表格或通用表单；现有两款由用户自行调整                            |
| 公开用户活动、右栏最近讨论           | A12；C12；[activity-preview](references/theme-4/javascripts/discourse/components/isbf-activity-preview.gjs.txt)、[post-preview](references/theme-4/javascripts/discourse/components/isbf-post-preview.gjs.txt)                                                                                                       | 摘要、缩略图、原生作者/分类/时间、既有加载与失败回退                                  | 公开活动最多 3 图；右栏无标题时两行/1 图；草稿、书签、待审核、私信、通知被明确排除                       |
| 登录、邀请码注册                     | A13；C01/C08；[已验收认证组件](references/plugins/discourse-academy-roles/accepted-20261011/assets/javascripts/discourse/components/academy-auth-page.gjs.txt)、[已验收认证样式](references/plugins/discourse-academy-roles/accepted-20261011/assets/stylesheets/common/academy-auth.scss.txt)                       | 原生登录/验证码流程、品牌设置、面板、居中输入、密码显隐、主题菜单、触控与减弱动效处理 | 认证专用字体/粒子/半径不移植到论坛；不要使用历史暂停版本或原型包覆盖当前参考                             |
| 用户偏好设置表单                     | 可参考 A01 外层与 A11 顶部中实际保留的区域；工程能力 C08 / FormKit                                                                                                                                                                                                                                                   | 现有颜色/字体变量、可确认的外层布局、原生表单能力                                     | **没有匹配 Approved 设置表单**；布局、字段、保存/错误状态先提设计方案；不能套认证居中表单                |
| 用户弹出卡                           | A11/C03 只能提供公开资料与头像的局部参考                                                                                                                                                                                                                                                                             | 现有头像组件、语义颜色，以及方案明确复用的局部值                                      | **没有 Approved 通用 User Profile Card**；原生 user-card 是 Legacy；尺寸、字段排列与状态需人工确认       |
| 书签、草稿、待审核、私信             | A01 仅对实际接管外层可用；C09/C12 仅用于比较边界                                                                                                                                                                                                                                                                     | 当前真实数据/权限、已有工程原语和确定的语义 token                                     | **没有完整条目视觉规范**；不得用公开帖子接管规则或预览强制替换                                           |
| 全页搜索、标签目录                   | A01 外层；A06 仅可说明相邻探索结构                                                                                                                                                                                                                                                                                   | 外层列宽、字体/颜色变量；已有搜索/标签行为                                            | **内部仍是 Legacy**；搜索条件、结果、目录与状态先提方案，不能把分类探索整块复制过来                      |
| 举报及其他新弹窗                     | A07/C07 的原语使用方式；已有举报样式只供代码理解                                                                                                                                                                                                                                                                     | DModal、已有行为与明确批准的相同任务结构                                              | 通用宽度/遮罩/内距缺失，举报全部视觉状态未批准；新增任务先确认方案                                       |
| 后台、群组、聊天及未知插件页面       | 没有匹配的完整 Approved reference；头像框校准区例外见 A15/C14                                                                                                                                                                                                                                                        | 平台的 UI kit/FormKit 及原有业务行为                                                  | 后台/群组当前内层 Legacy；聊天和不可读插件未分类。先确认目标，不从 Foundation/Horizon 或插件默认 UI 推导 |
| 学习资源、匿名帖子、徽章、信息页内部 | A01 仅限既有 shell；内部本次未完成核验                                                                                                                                                                                                                                                                               | 确认的外层/语义 token                                                                 | **需要人工确认**各区域实际完成度；有文件或 CSS 导入不等于批准                                            |

## 三个执行示例

### 重构 Topic List

选择 A01/A02，读取 feed-card、出口和完整 common 样式，确定当前是定制卡片还是原生 fallback。直接复用对应组件、spacing、分隔线、正文和互动规则。若目标要求新增一种“置顶卡片”而源码没有匹配，先说明现有置顶语义、拟复用区域与新增视觉缺口，等待确认；不能临时加边框色或阴影。

### 重构 Preferences

读取 Legacy 设置模板与当前插件字段，保留数据及验证。A01/A11 只能提供实际适用的外层/顶部，FormKit 提供工程能力；没有已批准的设置页表单布局。方案应标明字段分组、标签/输入位置、动作和状态分别复用什么，哪些要人工确认。确认前不实现新的表单外观。

### 重构 User Card

先区分公开资料 hero、校友目录和点击头像弹出卡。前两者的局部 Approved 不能自动覆盖第三者。复用头像 helper 和真实权限/字段，列出弹出卡尺寸、内容顺序、actions 与移动行为的缺口；等待设计确认后再改 Legacy `user-card-contents`。

## 提交方案所需记录

方案至少包含目标区域/状态、Approved ID 与真实路径、拟复用组件/tokens、没有依据的规则及需人工确认的选择。批准的新规则必须先补来源与验收范围，再同步四份文档；不要以“看起来一致”替代可追溯证据。

## 2026-10-12：本轮前台统一

[运行基线](baselines/README.md)、[19组执行记录](frontend-rollout-20261012.md)
及[D01–D07代表提案](proposals/frontend-consistency-20261012.md)已建立。
D01–D06及D07弹窗组合已人工确认，实际页面仍为In Progress；用户卡及资料上部保留，后台排除。
遵照用户要求[控制内存](resource-policy.md)，停止生产排查。

## 本轮已确认复用映射

[人工确认](references/evidence/frontend-consistency-acceptance-20261012.md)允许C15在19组目标主体中组合复用：

| 目标                                     | 组合            | 保留边界                                           |
| ---------------------------------------- | --------------- | -------------------------------------------------- |
| 设置、邀请、群组管理                     | D01/D02/D04     | 原生字段、保存、身份与权限；资料上部及一级导航不改 |
| 用户目录、群组成员与请求                 | D01/D04         | 动态列、筛选、排序及分页                           |
| 书签、草稿、待审核、个人/群组私信        | D03/D04         | 原生动作与私有数据边界，不接管公开预览             |
| 资料下部、徽章、标签与群组信息           | D04/D05         | 原有统计语义、真实徽章素材；A11/A12保留            |
| 搜索                                     | D02/D03         | 高级条件、查询参数及结果语义                       |
| 关于、帮助、指南、准则、规则、条款、隐私 | D06             | 全部正文、h1–h6、锚点和原生链接                    |
| 本轮关联弹窗                             | D02/D07弹窗部分 | 原生DModal行为；用户卡、后台、认证、日历和举报排除 |

历史缺口描述继续适用于本轮以外用途，不能将C15升级为全站控件标准。

## 本轮实现来源与验证

19组均已提交代码，实际页面仍为In Progress。具体接入文件、保留边界和未覆盖状态见
[实现说明](frontend-implementation-20261012.md)，源码摘要见
[source map](frontend-implementation-source-map-20261012.json)，检查结果见
[验证记录](frontend-verification-20261012.json)。新版离线入口为
[V2预览](reviews/frontend-20261012-v2/index.html)，已移除用户卡示例；旧包只作历史记录。


## 2026-10-14 简历紧凑页头

Course 的 .isbf-learning__header / .isbf-learning__back 及手机覆盖 → 简历插件 resume-editor.gjs / isbf-resume.scss 局部页头。已发布参考为 f72a86ca7435a489471c0fc53be2f2fc7e84ce83；下述记录保存实际读取版本、摘要、预览和 token 映射。只批准简历页头组合，不扩大课程页其他区域的批准范围；本轮未运行浏览器或真机验证。

[参考映射](../../plugins/isbf-resume/docs/design-system/resume-approval.md#2026-10-14-简历紧凑页头设计确认)保存用户批准范围、来源版本和实现边界。

## 2026-10-14 招募接入映射

- 更多菜单“加入我们”：保留原菜单外观，关闭菜单后在当前标签页完整跳转 `/join/`。
- `/join/`：用户提供的 `docs/isbf-one-join-app.zip`，有效来源和逐文件摘要见
  [招募来源记录](references/join-20261014/README.md)。
- `/admin/plugins/isbf-join/applications`：本次已批准的只读后台表格，姓名、学号、手机、
  提交时间四列；权限和分页不作为新视觉 token。

- 招募页六张图库图片：复用原图库，仅按用户图片包01–06顺序填入既有六项；
  [实际素材与配置](deployments/join-gallery-20261015/README.md)。布局、样式、响应式及滚动机制保持。

## 2026-10-15 普通话题回复对话映射

2026-10-16用户确认的[局部补充](deployments/reply-conversations-20261015/alignment-20261016.md)约束手机五项动作跨主帖/根回复/子回复的列对齐，以及电脑/手机原文跳转后的目标article高亮；电脑互动栏仍用原规则。

同日确认的[回复回归修复](deployments/reply-conversations-20261015/regressions-20261016.md)将手机回复图标起点定为主竖线右侧12px，并约束成功保存立即显示、原文跳转保留展开内容及共享分页缓存；不新增全局视觉规则。

| 目标与状态 | 来源及复用范围 | 验收边界 |
| --- | --- | --- |
| 根讨论、单层子回复及手机展示 | A01/A04、C01/C03/C09；42px头像、现有动作和语义token；用户选定的B直线参考见[选定记录](reviews/reply-conversations-20261015/guide-redesign/README.md) | 主头像延伸主干、直线支线及自然缩进已确认；实际视觉待验收 |
| 回复对象与两行原文 | C09正文、UI kit按钮、已有权限接口；真实父楼层与规范链接 | 按需加载、隐藏正文和重试有离线检查；服务器权限由完整回归验证 |
| 讨论组时间轴与楼层跳转 | 2026-10-13悬浮时间轴及2026-10-14定位修复；原生拖动、跳转弹窗 | 适配组序号，保留精确楼层；完整发布、历史返回与通知待集成验证 |

[提案](proposals/reply-conversations-20261015.md)、[审阅入口](reviews/reply-conversations-20261015/README.md)
和对应source manifest共同记录来源。现阶段不扩大Approved范围，不触碰私信、聊天、后台或生产设置。

## 认证欢迎按钮位置修复（2026-10-16）

`/login` 欢迎态的登录/注册入口：复用A13/C01，按用户截图与指定选择器将原按钮组下移24px；原有认证面板、粒子与响应式规则继续沿用。

来源与实施记录见[局部修复](deployments/auth-welcome-buttons-20261016/README.md)。

## 帖子与通知菜单对齐修复（2026-10-16）

用户要求电脑端每帖三点菜单位于右上角、手机举报项文字对齐，以及电脑/手机通知菜单两项文字左对齐。复用已有帖子动作与菜单内距，不改变五项互动栏。实际来源和检查边界见[局部修复](deployments/menu-alignment-20261016/README.md)。

## 2026-10-16 帖子底部继续阅读映射

普通话题详情底部：复用A01/A04及C02/C03/C09的语义变量、原条目行为、头像与链接，
排布及36px/30px头像尺寸来自[本次已确认规格](reviews/continue-reading-20261016/README.md)。
“新帖与未读”和“相关话题”共享样式，原来源、模式选择、权限及阅读状态继续生效。
实际源摘要、定向检查与截图见审阅目录；仅设计方向已确认，最终视觉验收待用户完成。

2026-10-16补充：用户明确授权上线，局部继续阅读已发布。原生及线上检查、实际源码版本、保留范围和回退见[发布记录](deployments/continue-reading-20261016/README.md)。最终视觉仍待用户核验，不扩大其他区域的Approved范围。

2026-10-17继续阅读修订：用户明确要求容器直角，局部`border-radius: 0`取代初版16px圆角；其他组件的圆角token不变。源码及线上CSS验证见[修订记录](deployments/continue-reading-20261016/square-border-20261017/README.md)。

## 2026-10-18 通知未读提示映射

A01侧栏/移动导航及A05分组通知 → C18局部角标、显示偏好、未读筛选和分组状态。
复用C05/C06/C13及既有语义配色，不改变通知生成或分组权限。
后续修订沿用C06菜单容纳未读开关；C18蓝点仅标动作并与文字垂直居中，不标主题标题。
[实施与来源](reviews/notifications-unread-20261018/README.md)限定本次设计确认和验证范围；
最终视觉待验收，不升级其他导航或全站控件规范。

2026-10-18通知未读提示已按用户授权发布；精确线上合并源、已验证镜像、两端功能与资源核对见[发布记录](deployments/notifications-unread-20261018/README.md)。C18的角标、动作点和菜单筛选规则保持局部范围。

## 2026-10-18 通知分组层级与点击映射

A05/C13帖子与动作分组、C18未读及菜单规则 → C19边界分组、四级文字与整行主链接。
仅为当前用户通知页组合既有border、radius-sm、space和字体token，
不移植A12公开正文预览，不改变通知权限、生成、排序或接口。
[确认范围、实际源和预览](reviews/notifications-layout-20261018/README.md)单独保存；
最终视觉待用户核验，未部署，不将历史C13源码附件替换为本轮实现。

2026-10-18通知页层级与整行点击已按用户授权发布；活动主题4项字段的确切合并源、插件及镜像核对、两端只读验证见[发布记录](deployments/notifications-layout-20261018/README.md)。C19仅限本次通知区域。

## 2026-10-19 通知菜单与账号筛选记忆

A05/C06/C18/C19 → 用户确认的内容宽菜单及账号级筛选恢复。
沿用菜单space-2/space-3、radius-sm及既有边框与阴影；新的筛选保存错误复用已有偏好错误排版。
首次请求采用当前用户的私有筛选值，两个标签、展开及分页继续携带同一筛选。
[实际源、预览及验证边界](reviews/notifications-menu-memory-20261019/README.md)单独保存；最终视觉待核验，尚未上线。

2026-10-19通知菜单收窄与账号筛选记忆已按用户授权上线；精确增量源码、完整插件及镜像核对、两端只读页面和验证边界见[发布记录](deployments/notifications-menu-memory-20261019/README.md)。最终视觉待用户核验。

## 2026-10-19 公开个人活动与总结映射

A12/C12 → 历史公开活动按主题/楼层读取正文、最多三图；用户确认的总结无标题条目 → 两行纯文字正文及原始楼层链接。有标题条目与统计信息保留原生行为。[源码与检查边界](reviews/profile-previews-20261019/README.md)独立保存；私信、草稿、书签、待审、通知和右栏最近讨论不接管，最终视觉待用户核验。

2026-10-19补充：个人活动与总结预览修复已上线，用户确认“没有问题，可以了”。本次验收仅限这两页的无标题正文与图片预览；确切合并源、原生22项布局检查、资源/镜像核对及线上自动化限制见[发布记录](deployments/profile-previews-20261019/README.md)。不扩大其他区域的Approved范围。


- 招募页开场鞋部近景：按用户确认计划恢复原模型近裁剪值，复用原相机轨迹和行走动作；
  [实际修复与范围](deployments/join-camera-20261019/README.md)。

## 2026-10-19 普通404与片段导航

A01品牌与共享语义变量、C01强调色/按钮机制 → C20独立404、弹性数字及隐藏弹球。直接链接及未知路由片段共享同一轻量模块；桌面、触摸、键盘、明暗与减少动态效果纳入离线验证。403、群组申请、自定义权限信息及永久链接不接管。[首版记录](reviews/elastic-404-20261019/README.md)保存历史来源，当前版本以修订和发布记录为准。

用户后续指定BOC真实404的已发布代码 → C20二维位移场、邻域耦合及阻尼回弹；本站仍使用A01/C01字体、颜色及按钮。覆盖动态视口、逐渐加速与无暂停规则属于同次明确修订，见[当前记录](reviews/elastic-404-fullscreen-20261019/README.md)及其中REA静态分析的范围与未知项。

用户随后确认“可以了，我验证了”，当前404交付已验收；精确源版本与线上自动化边界见[发布记录](deployments/elastic-404-fullscreen-20261019/README.md)，不扩大至其他区域或整站回归。

## 注册用户名提醒（2026-10-19）

邀请码注册的用户名字段 → A13 / C08 既有说明排版与主题强调色；增加不可更改提醒及输入框描述关联，仅覆盖该注册步骤。
见[局部实现与来源](reviews/auth-username-hint-20261019/README.md)。

2026-10-20补充：注册用户名主题蓝色提醒已按授权增量发布，既有内容保留；
见[确切来源及恢复边界](deployments/auth-username-hint-20261019/README.md)。最终视觉待用户核验。

## 2026-10-20 接着看看无标题修复

用户确认将此前的无标题正文规则补齐到C17两种推荐来源。新增文字预览模式沿用现有两行标题、字体、颜色和直角边框，首帖摘要与原未读跳转位置分别保留。实际三字段来源、两端验证与回退见[发布记录](deployments/continue-reading-previews-20261020/README.md)；不扩大其他区域的Approved范围。

## 2026-10-20 前台对话框映射

用户头像修改截图＋C01/C07及D02/D07的现有token → 共享前台DModal/确认框外框、文字操作和手机留边。ISBFFrontendScope仅负责页面范围；弹窗直接继承公共样式，不再按路由或组件名单选择。

个人日历、课程和资源目录手写对话框 → DModal＋FormKit，保留真实字段、日期换算、请求接口和审核回执。后台、用户卡、查看器、编辑器、菜单和`/join/`招募页保留自己的参考。

[本轮来源与验证](reviews/dialog-consistency-20261020/README.md)记录精确源码和边界；[开发契约](dialogs.md)及例外清单供后续所有开发者复用。本次不升级其他页面或全部插件为Approved。

2026-10-20补充：前台弹窗共享外观已按授权上线，184个模块与132个样式目标完整编译，
既有功能及数据加载经两端只读确认；[源码、证据和恢复边界](deployments/dialog-consistency-20261020/README.md)。最终视觉待用户核验。

## 2026-10-21 帖子操作栏等距映射

用户截图`IMG_1027.PNG`＋A04/C09/C16 → 帖子、根评论和子回复的五列等距、点赞/热度4px图文距离及本人点赞入口窄屏左对齐。沿用18px图标、36px/44px点赞目标、手机操作起点和既有子回复缩进；不替换各级动作、原生点赞用户列表或评论展开入口。以当前数据库主题作增量合并，不能用工作区公共样式整体替换。实际源码摘要、前后截图和检查边界见[记录](reviews/post-action-spacing-20261021/README.md)，上线和恢复另见[发布记录](deployments/post-action-spacing-20261021/README.md)。


2026-10-21 用户选择的“合并简短提示/打开原帖正文” → A04/C09及既有回复对话，局限删除占位、分组、管理入口与系统目标回退。实际源版本和复用边界见[记录](reviews/deleted-replies-system-targets-20261021/README.md)。
