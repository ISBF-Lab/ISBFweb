# 核心组件规范

所有视觉规则只来自 [Approved 清单](ui-status.md)，具体变量见 [tokens](tokens.md)。以下路径指实际存在的源码或已验收 `.txt` 副本；副本的实际工作区映射与差异见 [manifest](references/manifest.json)。未指定属性表示没有从 Approved 代码建立共同规则，不能自行补值。

## 工程复用要求

视觉来源和工程能力分别核对：UI kit、FormKit、float-kit 可以提供按钮、焦点、表单和弹层能力，但平台默认外观不是本项目设计来源。遵循 [UI kit](../developer-guides/docs/03-code-internals/02-ui-kit.md)、[FormKit](../developer-guides/docs/03-code-internals/22-form-kit.md) 和 [BEM](../developer-guides/docs/03-code-internals/26-css-guidelines-bem.md)。新操作使用 UI kit 的 `DButton`，表单使用 `Form` 的公开 API，浮动菜单优先组合 float-kit；显示文本使用翻译，保留权限与键盘行为。

已有业务组件中的底层原生元素和历史实现不应被扩大为新控件模板。复用既有组件时保留其行为；需要新变体且没有 Approved 视觉参考时，先提方案并等待人工确认。头像框校准区的局部新增规则见 C14；没有新增全站 token。

## C01 · Button

### Source of Truth

- A01/A02：[common.scss](references/theme-4/common/common.scss.txt) 的 `.isbf-v2-side__compose`、`.isbf-v2-compose__button`、`.isbf-feed-card__actions`。
- A04：[topic-actions](references/theme-4/javascripts/discourse/components/isbf-topic-actions.gjs.txt) 及 common 的 `.isbf-topic-card` 互动规则。
- A13：[认证样式](references/plugins/discourse-academy-roles/accepted-20261011/assets/stylesheets/common/academy-auth.scss.txt)。
- 工程原语：[d-button.gts](../../frontend/discourse/app/ui-kit/d-button.gts)。

### Visual Rules

| 已有变体      | 尺寸、颜色、形状与状态                                                                                                                                                                                                                                                                    |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 侧栏发布/审核 | `min-height: 52px`，宽 `calc(100% - 20px)`；发布上距 `18px`、审核上距 `12px`；`17px/750`，`999px` 圆角，accent 背景、accent-contrast 文字；hover `brightness(0.92)`                                                                                                                       |
| 信息流发布    | `min-height: 38px`、`min-width: 76px`；与侧栏发布共享强调色、pill 和字重，不共享侧栏尺寸                                                                                                                                                                                                  |
| 信息流互动    | 最小宽/高 `2.75rem`、图标字号 `1.375rem`，muted 前景；使用 `isbf-card-actions` mixin 的 gap/内距，按钮内容 `justify-content: flex-start`。手机最小宽/高 `44px`；hover/focus-visible 为 accent `12%` 与 transparent 混合背景、accent 前景；`.is-liked` 用 love、`.is-bookmarked` 用 accent |
| 普通帖子互动  | 桌面基础最小 `36px × 36px`、图标 `18px`；手机 `44px` 覆盖；真实菜单条目决定操作，保留点赞人数与原生用户菜单                                                                                                                                                                               |
| 认证按钮      | welcome 最小宽 `132px`、高 `48px`、`15px/500`、两个入口 gap `14px`；面板内最小高 `44px`，局部半径 `12px`                                                                                                                                                                                  |

没有所有按钮统一的 hover、disabled、loading、danger 尺寸规范。保留被复用组件的真实状态与 UI kit 行为，新增共同视觉规则需人工确认。

### Usage Rules

先按动作语义选择现有变体：发布用发布按钮，帖子动作复用已有 action 图谱，认证仅用认证变体。导航目标用链接，执行动作使用 `DButton`。按钮名、图标提示与状态文案使用已有翻译。

### Forbidden Patterns

- 自行设计新的渐变、阴影、半径或“统一主按钮”尺寸。
- 把侧栏发布尺寸套到所有表单提交或帖子互动。
- 手工复制原生菜单动作，生成重复点赞/收藏/举报入口，移除权限或加载状态。

## C02 · Card / Panel

### Source of Truth

A01/A08：[common.scss](references/theme-4/common/common.scss.txt) 的 `.isbf-v2-rail__panel`、`.isbf-v2-workbench__panel/grid/card/icon`；A09：[marketplace-card](references/theme-4/javascripts/discourse/components/isbf-marketplace-card.gjs.txt)、[marketplace.scss](references/theme-4/stylesheets/marketplace.scss.txt)。信息流见 C09，活动字段见 C11。

### Visual Rules

- **右栏面板**：surface、`1px` border、`radius-md`；上距 `20px`，标题 `font-lg`、padding `16px 16px 8px`；链接最小高 `48px`、padding `0 16px`。没有面板阴影规则。
- **工作台**：面板 hover 背景、`22px` 圆角、padding `24px`；入口卡片 surface、border、`18px` 圆角、padding `16px 8px`。图标容器 `62px`、半径 `18px`、图标 `27px`；局部颜色必须按原语义复用。
- **工作台手机**：网格 4 列、gap `8px`，卡片 padding `8px 4px`、半径 `8px`；图标容器 `44px`、半径 `12px`、图标 `22px`；名字 `12px/1.35`。中间宽度的 3 列覆盖见 tokens。
- **商品行**：padding/gap `space-4`、底部分隔线，hover 为 hover token、focus-visible `2px` focus-ring、offset `-2px`；图片桌面 `112px`、手机 `88px`、`radius-sm`。内容 gap `space-2`，标题 `font-lg`，描述两行，价格 accent/weight-bold。

### Usage Rules

按内容形态复用明确的 Panel、工作台入口或商品行，保留 grid 与响应式规则。它们没有共同的通用 Card 组件契约。只有用途和 Approved 变体匹配时，才能复用对应外形。

### Forbidden Patterns

- 给信息流统一套工作台圆角、空隙或菜单阴影。
- 将工作台各局部颜色改名为全站品牌色。
- 因缺少通用 Card 而新建任意外观组件；先提出方案。

## C03 · Avatar

### Source of Truth

A02 的 `.isbf-feed-card__avatar`，A11 的资料头像，均在 [common.scss](references/theme-4/common/common.scss.txt)。A14 的有效定位参考为 [2026-10-11 overlay](references/plugins/discourse-avatar-frames/accepted-20261011/assets/javascripts/discourse/components/avatar-frame-overlay.gjs.txt)、[定位 modifier](references/plugins/discourse-avatar-frames/accepted-20261011/assets/javascripts/discourse/modifiers/avatar-frame-position.js.txt) 与 [样式](references/plugins/discourse-avatar-frames/accepted-20261011/assets/stylesheets/common/avatar-frames.scss.txt)。工程能力：[d-user-avatar](../../frontend/discourse/app/ui-kit/d-user-avatar.gjs)、[d-avatar helper](../../frontend/discourse/app/ui-kit/helpers/d-avatar.js)。

### Visual Rules

- Feed card 图片及列宽 `42px`、圆形 `50%`；原生话题行 fallback 的 `40px` 图片是独立变体。
- 资料头像 `4px solid surface`、`50%`；上移 `32px`，封面状态由原生结构和现有覆盖决定，未建立全局头像尺寸表。
- 头像框父级 `position: relative`；overlay 由 modifier 以实际头像图像区域定位，扣除边框和内边距。每款大小默认 `120%`、偏移默认 `0/0`，以头像内容尺寸归一化；不再以父容器的固定 `inset` 定位。
- overlay 在测量前隐藏，定位后可见；`pointer-events: none`、`z-index: 2`；框图片宽高 `100%`、无边框、半径 `0`、`object-fit: contain`。flair 在 `z-index: 3`。4px 资料白边继续保留。
- 装饰层只在插件与佩戴数据满足条件时存在，不能影响头像链接和点击。

### Usage Rules

使用现有头像 helper/组件和框挂载点，保留尺寸参数、用户链接、替代文本及头像 flair。仅复用对应页面已有的头像尺寸。

### Forbidden Patterns

- 为配合新卡片任意修改全部头像尺寸。
- 对头像父容器统一 `overflow: hidden` 或圆形裁剪，截掉头像框。
- 把装饰框画成头像图片的一部分，或覆盖其点击区域。
- 按款式名称、UUID 或页面路由添加独立定位补丁；把头像白边、内边距或外边距算成图片内容。

## C04 · Navigation

### Source of Truth

A01：[shell](references/theme-4/javascripts/discourse/components/isbf-v2-shell.gjs.txt)、[side-nav](references/theme-4/javascripts/discourse/components/isbf-v2-side-nav.gjs.txt)、[right-rail](references/theme-4/javascripts/discourse/components/isbf-v2-right-rail.gjs.txt)、[common.scss](references/theme-4/common/common.scss.txt)。

### Visual Rules

桌面布局采用 tokens 中的左栏/feed/右栏变量及 feed-left 计算。侧栏链接最小高 `52px`、gap `18px`、padding `0 16px`、pill 半径、`font-xl`；图标 `26px`。选中背景 active-surface、字重 weight-bold。`<=1023px` 有紧凑侧栏，`<=600px` 左右栏隐藏并切换移动导航，保留 safe-area。

### Usage Rules

复用 shell 的 `pageKind`、路径匹配与既有入口。官方路径、探索开关、当前用户通知条件均有额外判断。公开资料外层被接管，不代表所有 `/u/` 子页面内部均 Approved。

### Forbidden Patterns

- 给 `/admin`、群组或未知插件页强行套用现有 shell。
- 写死页面偏移、创建另一份 sidebar/移动导航，或删去安全区。
- 以 shell 出现为依据批准内层原生表单。

## C05 · Tabs

### Source of Truth

A01 信息流 header 和 A05 通知 tabs，位于 [shell](references/theme-4/javascripts/discourse/components/isbf-v2-shell.gjs.txt)、[notifications](references/theme-4/javascripts/discourse/components/isbf-notifications.gjs.txt) 及 [common.scss](references/theme-4/common/common.scss.txt)。工程能力：[d-tabs.gts](../../frontend/discourse/app/ui-kit/d-tabs.gts)。

### Visual Rules

- 信息流 tabs：grid 两列、height `53px`，普通 muted/`600`，激活 text/`750`，hover 背景 hover；底部 accent 标记高 `4px`、左右各 `36%`、pill。
- 通知 tabs：flex 等宽按钮、padding `space-4`，普通 muted/继承字体，激活 text/weight-bold；底部 accent 标记高 `3px`、左右各 `30%`。
- 两种实际变体不同，不存在统一下划线高度。组件的导航/就地切换语义与键盘行为必须保留。

### Usage Rules

同路由类型复用相同 tabs。新建就地面板切换可以组合 UI kit `DTabs` 的行为，但必须匹配批准的视觉变体；路由链接不能机械换成就地 panel。

### Forbidden Patterns

新增胶囊/阴影 tabs、统一两个既有下划线尺寸、按文字长度临时设计标记，或将按钮/链接改成不可聚焦的 div。

## C06 · Dropdown / Menu

### Source of Truth

A01：[account-menu](references/theme-4/javascripts/discourse/components/isbf-v2-account-menu.gjs.txt)、[more-menu](references/theme-4/javascripts/discourse/components/isbf-v2-more-menu.gjs.txt)；A03：[official-picker](references/theme-4/javascripts/discourse/components/isbf-official-picker.gjs.txt)、[official-filters.scss](references/theme-4/stylesheets/official-filters.scss.txt)；A05 通知菜单。工程能力：[DMenu](../../frontend/discourse/float-kit/components/d-menu.gts)、[DDropdownMenu](../../frontend/discourse/app/ui-kit/d-dropdown-menu.gjs)。

### Visual Rules

- 账号触发器桌面 `36px`、圆形、图标 `20px`；手机 `44px`。
- 账号面板宽 `max(220px, 100%)`，padding `8px`、border、`radius-md`、shadow-menu；手机宽 `min(280px, calc(100vw - 32px))`。菜单项最小高 `44px`、padding `8px 12px`、`radius-sm`、`15px/600`，hover 背景 hover。
- More 菜单内部面板同样使用 border、radius-md、shadow-menu，但入口复用侧栏的大字号规则，不套账号菜单字体。
- 通知菜单另用最小宽 `190px`、padding `8px`、radius-sm、局部 `0 4px 16px rgb(0 0 0 / 12%)` 阴影。
- 官方 picker 已组合 `DMenu`、`DDropdownMenu`、`DButton`；选项、placement 和多选行为读该组件与 scoped stylesheet，不复制账号菜单定位。

### Usage Rules

复用对应账号菜单或筛选组件，保留点击外部关闭、Escape、焦点、键盘与选中状态。新增浮动菜单用公开 float-kit/API，视觉先找同用途 Approved 变体。

### Forbidden Patterns

自行拼绝对定位菜单、删除原有键盘控制、统一全部菜单阴影和字号，或从只经过部分检查的探索 picker 推断通用菜单状态。

## C07 · Modal

### Source of Truth

A07：[official-calendar-editor](references/theme-4/javascripts/discourse/components/isbf-official-calendar-editor.gjs.txt)、[note-editor](references/theme-4/javascripts/discourse/components/isbf-calendar-note-editor.gjs.txt)、[update-dialog](references/theme-4/javascripts/discourse/components/isbf-calendar-update-dialog.gjs.txt)、[official-calendar.scss](references/theme-4/stylesheets/official-calendar.scss.txt)。工程能力：[d-modal.gts](../../frontend/discourse/app/ui-kit/d-modal.gts)。

### Visual Rules

现有日历弹窗使用 `DModal`，标题及 actions 来自具体流程。时间编辑项 padding/margin-bottom `space-4`、border、radius-sm；变更查看 snapshot/latest padding-block `space-3`，latest 有上分隔线；错误文字 danger。公共 modal 的最大宽度、遮罩透明度和内距**没有形成独立 Approved 视觉规范，需要人工确认**，不能从 DModal 默认值提取目标规则。

补充代码事实：[reporting.scss](references/theme-4/stylesheets/reporting.scss.txt) 已有举报专用弹窗：desktop `>=601px` 对齐 feed-left、feed-width；容器 border/radius-md，手机顶部两角 radius-md、底部 `0`；textarea 最小高 `140px`。其完整视觉状态未在本次证据中批准，因此只供理解已有实现，不能扩展为通用 Modal 标准。

### Usage Rules

相同日历任务复用对应弹窗，保留关闭、焦点、提交流程和 FormKit。新增任务需要的 modal 若没有匹配规范，先提出方案。认证面板是独立页面专用层，不作为通用 DModal 外形。

### Forbidden Patterns

用 div 重造遮罩/焦点陷阱，借用认证粒子面板做论坛弹窗，猜测通用宽度和遮罩色，或复制举报业务动作来获得外观。

## C08 · Input / Form

### Source of Truth

A01 右栏搜索：[right-rail](references/theme-4/javascripts/discourse/components/isbf-v2-right-rail.gjs.txt) 和 common 的搜索规则。A13：[最新认证组件](references/plugins/discourse-academy-roles/accepted-20261011/assets/javascripts/discourse/components/academy-auth-page.gjs.txt)、[最新认证样式](references/plugins/discourse-academy-roles/accepted-20261011/assets/stylesheets/common/academy-auth.scss.txt)。A07 编辑器使用 `Form`；工程说明见 [FormKit](../developer-guides/docs/03-code-internals/22-form-kit.md)。

### Visual Rules

- 右栏搜索：高 `44px`、gap `12px`、padding `0 16px`、pill、hover 背景；focus-within 为 accent 边框、surface 背景及 `0 0 0 1px` accent 阴影。
- 认证普通输入：最小高 `48px`、全宽、`16px`、居中；局部 input/button radius `12px`、input 背景 secondary。排除 checkbox、radio 及 `.d-otp-input`，保留原生 OTP 透明输入层。
- 认证 FormKit：container gap `16px`，标签及内容居中；登录输入 inline padding `44px`，标签下距 `8px`，密码显隐控件在输入右侧最小宽 `44px`。最新补丁保留密码显隐和主题菜单可操作。
- 认证输入/textarea/contenteditable 可选择与粘贴；粒子舞台的触控和普通文字选择规则只作用在认证范围。
- 没有统一的通用输入 hover/focus/invalid/disabled 外形。复用该流程已有状态，不凭 `danger` 颜色创建新的错误边框规范。

### Usage Rules

新表单通过公开 `Form` 及其 yielded fields/controls 组合。认证复用原生登录/验证码组件，不复制账号逻辑；日历复用已批准编辑器。设置页的表单布局缺少匹配规范，须提出方案。

### Forbidden Patterns

手工拼表单替代 FormKit、给所有输入加认证居中/半径、覆盖 OTP 输入透明层、全站禁止选择文字、从原生偏好设置推导目标样式。

## C09 · Topic List Item / Feed Item

### Source of Truth

A02：[feed-card](references/theme-4/javascripts/discourse/components/isbf-v2-feed-card.gjs.txt)、[topic-list 出口](references/theme-4/javascripts/discourse/connectors/topic-list-item/isbf-feed-card.gjs.txt)、[common.scss](references/theme-4/common/common.scss.txt)；A04 的帖子操作接管另受 [topic-card-scope](references/theme-4/javascripts/discourse/lib/topic-card-scope.js.txt) 限制。

### Visual Rules

- 定制 feed card 是 `42px minmax(0, 1fr)` grid、gap `12px`、padding `16px`；头像圆形，header `15px/1.35`，作者 text/750，账号及时间 muted；手机 header `14px`、gap `10px`、padding `14px 12px`。
- 正文采用 card-content 的 `16px/1.45`；手机未展开正文有 `460px` 最大高度，展开时去掉上限；媒体还有移动专用 `12px` 圆角覆盖。
- 信息流通过父级条目/相邻条目形成分隔线，不套独立浮动卡片。原生 `tr` fallback 是另一实现：头像列 `44px`、图片 `40px`、padding `14px 16px`、链接 `16px/720/1.4`，不可混算尺寸。
- 作者/账号/时间有基线截断规则，后续手机布局修补须连同完整 common 文件读取；不能单独复制早期 `white-space` 规则到其他区域。
- 点击、回复、收藏、点赞、分享及菜单均复用既有组件行为；计数不要虚构空值或重复原生操作。

### Usage Rules

改首页/话题列表首先复用 `ISBFV2FeedCard` 和已有列表出口，保留导航 callback、真实 topic/draft 加载、原生权限和动态内容。普通帖子的 layout/controls 只在既有 regular、非嵌套、普通 post 条件下复用。

### Forbidden Patterns

新建另一套“帖子卡片”、给行统一加阴影和外部 gap、用列表浅数据直接启动需完整草稿的回复、对私信/嵌套帖强行接管，或修改 UI 时顺便改数据与权限语义。

## C10 · User Profile Card

### Source of Truth

**已批准的是公开资料页顶部 A11，不是通用用户弹出卡。** 资料结构来自 [user.gjs](../../frontend/discourse/app/templates/user.gjs)，视觉来自 [common.scss](references/theme-4/common/common.scss.txt) 的 profile 规则。弹出卡仍是 Legacy：[user-card-contents.gjs](../../frontend/discourse/app/components/user-card-contents.gjs)、[user-card.scss](../../app/assets/stylesheets/common/components/user-card.scss)。

### Visual Rules

资料 `.about` 为底部分隔线、padding `0 16px 16px`、基础最小高 `238px`；无封面占位色混合 accent `14%` 与 surface。无封面且未收起状态最终使用 `--isbf-profile-cover-height: 120px`，padding-top `calc(var(--isbf-profile-cover-height) + 12px)`。不能拿早期 `96px/88px` 覆盖当最终值；有上传封面和 collapsed-info 状态使用各自原生结构及后续规则。头像规则见 C03；内容区 padding `16px`。资料用户名、其他文字层级未统一为通用用户卡契约。

### Usage Rules

仅相同资料页顶部复用现有封面/头像规则。用户弹出卡和校友编辑卡需要分别找到匹配 Approved 参考；当前没有完整弹出卡设计，先提出方案并等待人工确认。

### Forbidden Patterns

把个人资料 hero 缩小成自行设计的弹出卡、以原生 `.user-card` 外观补齐规范、把无封面状态套到上传封面，或用 profile 外层批准整个 preferences 页面。

## C11 · Official Activity Summary

### Source of Truth

A03：[activity-summary](references/theme-4/javascripts/discourse/components/isbf-official-activity-summary.gjs.txt)、[official-calendar.scss](references/theme-4/stylesheets/official-calendar.scss.txt)、[布局验收说明](references/evidence/official-activity.md)。

### Visual Rules

外层 grid、gap/margin-block `space-4`；标题 `font-md`、下距 `space-2`。字段 grid 在桌面和手机均两列、gap `space-3`。每个字段及独立截止项 padding `space-3`、border、radius-sm；字段标签 text/600、值 muted/font-xs，长文字换行。普通公告不显示活动字段；无截止显示既有“无”，缺地点/主办方显示既有“未填写”翻译。

### Usage Rules

仅用于真实官方活动/截止项，保持作者和正文之后、互动之前的位置。使用组件现有缺省文案及历史独立项语义，不为旧数据猜测关联。

### Forbidden Patterns

手机改一列、用整块新卡片替换字段格、填入推测地点/主办方、将历史截止自动关联为报名截止。

## C12 · Post Preview

### Source of Truth

A12：[post-preview](references/theme-4/javascripts/discourse/components/isbf-post-preview.gjs.txt)、[activity-preview](references/theme-4/javascripts/discourse/components/isbf-activity-preview.gjs.txt)、[preview lib](references/theme-4/javascripts/discourse/lib/post-preview.js.txt)、[验收范围](references/evidence/post-preview.md)。

### Visual Rules

公开活动保留原生作者、分类、时间及展开，最多 3 张缩略图；common 预览缩略图基础 `7rem`、radius-sm、gap/margin-top `space-2`。右栏最近讨论有标题则显示标题，无标题则显示两行摘要和最多 1 图；右栏缩略图 `3.5rem`。坏图按现有回退逻辑处理；没有图片时保留文字和链接。

### Usage Rules

复用完整预览组件及加载/缓存 helper，保留视口附近加载、去重、失败回退与失效机制。只用于公开活动和既有最近讨论区域。

### Forbidden Patterns

把公开预览直接套到草稿、书签、待审核、私信或通知；为外观变化改请求策略、显示隐藏内容，或手工编造无标题替代文本。

## C13 · Notification Group / Entry

### Source of Truth

A05：[notifications](references/theme-4/javascripts/discourse/components/isbf-notifications.gjs.txt)、[action](references/theme-4/javascripts/discourse/components/isbf-notification-action.gjs.txt)、[entry](references/theme-4/javascripts/discourse/components/isbf-notification-entry.gjs.txt)、[notification-groups](references/theme-4/javascripts/discourse/lib/notification-groups.js.txt)、common 的 `.isbf-notifications`。

### Visual Rules

主列为 feed-width、surface、两侧 border；heading padding `32px 26px 24px`，h1 `clamp(28px, 3vw, 34px)/1.25/750`。topic/standalone 项 padding `16px`、底部 border；动作组 gap `12px`，每动作保留独立展开按钮。tabs 与菜单分别见 C05/C06；具体 entry 排版及已读/折叠状态须复用源码，不定义通用通知卡片新变体。

### Usage Rules

只在当前用户自己的通知页且通知开关启用时复用；保留各动作独立折叠、懒加载、重试、分页和键盘操作。

### Forbidden Patterns

额外加整 topic 折叠、移除独立重试/分页、把公开活动预览用于通知，或以通知模板改写所有用户活动列表。

## 尚无组件规范的区域

设置表单、用户弹出卡、后台公共样式、全站 empty/loading/success 容器，以及校友/商品全部编辑与异常状态仍需人工确认。处理这些区域时先按 [Reference Map](reference-map.md) 说明可复用部分与缺口；不在实现阶段临时补设计。

## C14 · Avatar frame calibration

### Source of Truth

A15 的 [确认方案](proposals/avatar-frame-calibration-20261011.md)，对应提交
`bbdabecf040bdbb6d5bb3f88d6e748738ddf7a41` 的 [上传组件](references/plugins/discourse-avatar-frames/accepted-20261011/admin/assets/javascripts/admin/components/avatar-frame-upload.gjs.txt)、
[表单接入](references/plugins/discourse-avatar-frames/accepted-20261011/admin/assets/javascripts/admin/components/avatar-frame-form.gjs.txt)
及 [局部样式](references/plugins/discourse-avatar-frames/accepted-20261011/assets/stylesheets/common/avatar-frames-admin.scss.txt)。
仅批准既有上传字段内的校准区，不批准整个后台表单或导航。

### Visual Rules

- 两种叠加预览位于输入上方，头像尺寸为 144px 和 48px；圆形 `50%`，图片 margin 为 0。
- 预览及操作使用 flex、垂直居中、允许换行，gap 复用既有上传区的 `0.75em`。
- `--avatar-frame-preview-size` 只控制两种预览；容器外距为该尺寸的 `10%`，为默认框预留空间，不裁切更大的装饰。
- 大小、左右位置、上下位置的 FormKit 数字输入单列排列，后接恢复默认、可选建议操作和确认复选框。桌面与手机保持此顺序。
- 沿用既有 FormKit/UI kit 控件，没有新增品牌色、字体、阴影、全局半径或全站输入样式。

### Usage Rules

叠加预览复用 C03 的内容区域定位和静态/动画选择。修改参数或替换素材后重新确认；
建议位置需管理员主动采用。只用于头像框新建、编辑页的上传字段。

### Forbidden Patterns

把局部布局推广为整个后台、偏好设置或所有上传控件的规范；用一排三列输入替代已确认的单列布局；
裁掉装饰或自动替管理员确认建议。现有两款的校准由用户自行完成。

## 2026-10-12：本轮前台统一

[运行基线](baselines/README.md)、[19组执行记录](frontend-rollout-20261012.md)
及[D01–D07代表提案](proposals/frontend-consistency-20261012.md)已建立。
D01–D06及D07弹窗组合已人工确认，实际页面仍为In Progress；用户卡及资料上部保留，后台排除。
遵照用户要求[控制内存](resource-policy.md)，停止生产排查。

## C15 · 本轮前台主体与关联弹窗

### Source of Truth

[人工确认与保留边界](references/evidence/frontend-consistency-acceptance-20261012.md)、[D01–D07组合](proposals/frontend-consistency-20261012.md)。
实现位于[frontend-consistency.scss](../../themes/isbf-campus-feed/stylesheets/frontend-consistency.scss)及[路由范围](../../themes/isbf-campus-feed/javascripts/discourse/lib/frontend-consistency-scope.js)。页面接入仍为In Progress。

### Visual Rules

严格按D01–D06和D07关联弹窗组合复用现有token；600px内容列、最大920px功能区只作用于对应主体。
原生控件和浮层保留字段、数据加载、错误/disabled语义、焦点和权限。二级导航使用D04；资料一级导航不接入。

### Usage Rules

仅用于19组目标主体及明确登记的关联弹窗。原生FormKit/UI kit/select-kit负责行为；私有列表不使用公开FeedCard或A12加载器。
没有匹配规则的状态记录为待确认，不能从平台默认外观填入新设计值。

### Forbidden Patterns

全局改写.btn/input/.d-modal；给用户卡换肤；修改资料上部或其父容器宽度；裁切头像框；移除动态列、私信权限或表单字段；增加新阴影、颜色或装饰。
