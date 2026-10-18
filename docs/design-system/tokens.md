# Design tokens：真实数值与作用域

只记录 [Approved 区域](ui-status.md) 的代码事实。`--isbf-v2-*` 是主题已定义的变量；其他数值是已有组件的局部规则，不能因重复出现而新建全局 token。没有匹配作用域的规则时标记“需要人工确认”。

主题公共来源为 [common.scss](references/theme-4/common/common.scss.txt) 的 `:root` 及对应选择器；认证来源为 [2026-10-11 academy-auth.scss](references/plugins/discourse-academy-roles/accepted-20261011/assets/stylesheets/common/academy-auth.scss.txt)。文件版本及摘要见 [参考说明](references/README.md)。阅读样式时必须检查后续覆盖，不能只取首次命中。

## Colors

### V2 语义映射

| 角色          | 已有 token                  | 代码值                                                               |
| ------------- | --------------------------- | -------------------------------------------------------------------- |
| 页面背景      | `--isbf-v2-background`      | `var(--secondary)`                                                   |
| 内容/面板背景 | `--isbf-v2-surface`         | `var(--secondary)`                                                   |
| 主文本        | `--isbf-v2-text`            | `var(--primary)`                                                     |
| 次级文本      | `--isbf-v2-muted`           | `var(--primary-medium)`                                              |
| 普通边框      | `--isbf-v2-border`          | `var(--primary-low)`                                                 |
| 较强边框      | `--isbf-v2-border-strong`   | `var(--primary-low-mid)`                                             |
| Hover 背景    | `--isbf-v2-hover`           | `var(--primary-very-low)`                                            |
| 选中区域背景  | `--isbf-v2-active-surface`  | `var(--primary-very-low)`                                            |
| 主色/强调色   | `--isbf-v2-accent`          | `var(--tertiary)`                                                    |
| 主色上文字    | `--isbf-v2-accent-contrast` | `var(--secondary)`                                                   |
| 焦点描边颜色  | `--isbf-v2-focus-ring`      | `color-mix(in srgb, var(--isbf-v2-accent) 65%, var(--isbf-v2-text))` |

必须保留变量映射，使深浅模式跟随站点配色。`primary-medium`、`primary-low` 等衍生颜色没有在本参考中定义固定十六进制值，不能自行计算并写死。V2 的 hover 使用 `primary-very-low`，不是下面色板里的 `hover` 名称。

### 主题声明的 Light / Dark 色板

来源：[about.json](references/theme-4/about.json.txt) 的 `color_schemes`。这是主题声明值，不是本次读取到的当前生产数据库有效值；要确认当前选中色板需人工核对设置。实现继续用语义变量，不直接复制色值。

| 色板键              | ISBF Community Light | ISBF Community Dark |
| ------------------- | -------------------- | ------------------- |
| `primary`           | `#17202a`            | `#e7e9ea`           |
| `secondary`         | `#ffffff`            | `#101413`           |
| `tertiary`          | `#1769aa`            | `#72c5fa`           |
| `quaternary`        | `#1769aa`            | `#72c5fa`           |
| `header_background` | `#ffffff`            | `#101413`           |
| `header_primary`    | `#17202a`            | `#e7e9ea`           |
| `highlight`         | `#e8f3fa`            | `#17354a`           |
| `selected`          | `#d9ebf8`            | `#193c53`           |
| `hover`             | `#f2f6f9`            | `#1c272c`           |
| `danger`            | `#c93545`            | `#f15b6c`           |
| `success`           | `#087e5b`            | `#38c997`           |
| `love`              | `#d63c64`            | `#f06a8a`           |

### 局部辅助色与状态

| 使用位置                         | 实际颜色规则                                      | 来源/复用边界                                                                                      |
| -------------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| 工作台默认图标                   | accent 与 surface 混合，accent `15%`；前景 accent | common `.isbf-v2-workbench__icon`；仅入口图标                                                      |
| 工作台 mint / teal               | `#35b595 19%` 与 surface 混合；前景 `#239c81`     | 对应 `__icon--mint/--teal`；不是全站辅助色                                                         |
| 工作台 amber / rose              | `#e5a659 21%` 与 surface 混合；前景 `#b67b37`     | 对应 `__icon--amber/--rose`                                                                        |
| 工作台 violet / indigo           | `#9480d8 19%` 与 surface 混合；前景 `#7965ba`     | 对应 `__icon--violet/--indigo`                                                                     |
| 个人/社区日历标记                | 个人 `#56c6a9`；社区 accent                       | common `.isbf-v2-calendar` 的类型标记，按既有语义使用                                              |
| 无封面资料页                     | accent `14%` 与 surface 混合                      | common `.about.no-background::before`                                                              |
| 信息流互动 Hover / focus-visible | accent `12%` 与 transparent 混合，前景 accent     | common 互动按钮规则；不扩大为全部按钮状态                                                          |
| 点赞 / 收藏                      | 已点赞 `var(--love)`；已收藏 accent               | feed 的 `.is-liked/.is-bookmarked`；topic 的 `.has-like/.liked/.has-liked`、`.bookmarked` 对应规则 |
| Error                            | `var(--danger)`                                   | 已有认证错误；只确认颜色，不确认全站错误容器尺寸                                                   |
| Success                          | `var(--success)` 已在色板和认证彩带变量中使用     | 尚无批准的通用成功提示容器；**需要人工确认**                                                       |

没有被代码统一定义的“辅助品牌色”。不能把工作台图标、地图、日历或认证彩带的局部颜色提升为新的品牌 token。

## Typography

### 已有共享字体变量

| Token                     | 代码值                                      |
| ------------------------- | ------------------------------------------- |
| `--isbf-v2-font-family`   | `var(--font-family, system-ui, sans-serif)` |
| `--isbf-v2-font-xs`       | `13px`                                      |
| `--isbf-v2-font-sm`       | `15px`                                      |
| `--isbf-v2-font-md`       | `16px`                                      |
| `--isbf-v2-font-lg`       | `18px`                                      |
| `--isbf-v2-font-xl`       | `20px`                                      |
| `--isbf-v2-weight-medium` | `600`                                       |
| `--isbf-v2-weight-bold`   | `750`                                       |

`--font-family` 的当前站点取值没有确认，不推断实际安装字体。认证页自有字体栈：`-apple-system, BlinkMacSystemFont, "PingFang SC", "Noto Sans CJK SC", sans-serif`；不覆盖论坛全局字体。

### 已使用的文字层级

| 区域/选择器                                                          | 字号、字重、行高等代码事实                                                                                                                                                         |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 正文 mixin `isbf-card-content`                                       | `font-md`，`line-height: 1.45`；长文本 `overflow-wrap: anywhere`                                                                                                                   |
| 信息流作者 `.isbf-feed-card__author`                                 | `weight-bold`；字号继承 header 的 `font-sm`、行高 `1.35`；手机 header 改为 `14px`                                                                                                  |
| 原生话题行 fallback `.raw-topic-link`                                | `16px` / `720` / `1.4`；摘录 `15px` / `1.45`，不能与定制卡片混同                                                                                                                   |
| 侧栏导航 `.isbf-v2-side__links a`                                    | `20px`；选中 `weight-bold`                                                                                                                                                         |
| 信息流 Tab                                                           | 普通 `weight-medium`，激活 `weight-bold`                                                                                                                                           |
| 右栏面板标题                                                         | `font-lg`；不能据此定义全局 h2                                                                                                                                                     |
| 功能区/分区标题 `.isbf-v2-feature h1`、`.isbf-v2-section-heading h1` | `clamp(28px, 3vw, 34px)`，行高 `1.25`；未在该联合选择器统一指定字重                                                                                                                |
| 工作台入口 `.isbf-v2-workbench__name`                                | 桌面 `15px` / `700`；手机 `12px` / 行高 `1.35`                                                                                                                                     |
| 官方活动摘要                                                         | 字段值 `dd` / 截止项 `span` 为 `font-xs`、muted；字段标签 `dt` 为 `600`、text；标题 `font-md`；[official-calendar.scss](references/theme-4/stylesheets/official-calendar.scss.txt) |
| 校友页面标题                                                         | 桌面 `24px`，手机 `18px`；common `.isbf-alumni__back h1`                                                                                                                           |
| 商品标题/价格                                                        | 标题 `font-lg`，价格 `weight-bold`、accent；[marketplace.scss](references/theme-4/stylesheets/marketplace.scss.txt)                                                                |
| 认证品牌文字                                                         | `17px` / `500`，字距 `-0.4px`                                                                                                                                                      |
| 认证普通输入/标签                                                    | 输入 `16px`、居中；FormKit 标签 `13px`、`primary-high`；登录 `.alt-placeholder` 另有 `400` 字重                                                                                    |

没有可核验的全局 h1–h6、统一标题行高、链接下划线或字距体系。**需要人工确认**，不能把某页面 h1 的值推广到其他页面。

## Spacing

### 共享间距变量

| Token               | 值     |
| ------------------- | ------ |
| `--isbf-v2-space-1` | `4px`  |
| `--isbf-v2-space-2` | `8px`  |
| `--isbf-v2-space-3` | `12px` |
| `--isbf-v2-space-4` | `16px` |
| `--isbf-v2-space-5` | `20px` |
| `--isbf-v2-space-6` | `24px` |
| `--isbf-v2-space-8` | `32px` |

代码没有 `space-7`，不能自行补齐。

### 实际布局间距

| 使用场景         | 实际值                                                                                                                                      | Source of Truth                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| 主内容基础顶部   | `60px`；桌面 feed `145px`、no-compose `53px`；手机 feed `108px`                                                                             | common `body:has(.isbf-v2-shell)` 及后续 shell 变体                                         |
| 移动底部安全空间 | 基础 `calc(72px + env(safe-area-inset-bottom))`；话题另有 `108px` 加安全区覆盖                                                              | common 移动规则及 topic-reading 样式；按路由读取                                            |
| 信息流卡片       | 桌面 padding `space-4`、gap `space-3`；手机 padding `14px 12px`、gap `10px`                                                                 | common `.isbf-feed-card` 及移动覆盖                                                         |
| 互动组           | gap `space-1`；局部 `--isbf-card-action-padding: space-2`，宽 `calc(100% + 2 * var(--isbf-card-action-padding))`，负向 inline margin 同变量 | common `isbf-card-actions` mixin；不用于任意工具栏                                          |
| 右栏面板         | 上距 `20px`，标题 padding `16px 16px 8px`                                                                                                   | common `.isbf-v2-rail__panel`                                                               |
| 功能区域         | padding `92px 26px 80px`                                                                                                                    | common `.isbf-v2-feature`；手机另有覆盖，不是通用页面 padding                               |
| 工作台           | 面板 padding `24px`、上距 `space-6`；网格 gap `14px`；卡片 padding `space-4 space-2`                                                        | common `.isbf-v2-workbench`                                                                 |
| 工作台手机       | 面板 padding `8px`；网格 gap `8px`；卡片 padding `8px 4px`；名字上距 `8px`                                                                  | common `width <= 600px` 工作台覆盖                                                          |
| 官方活动摘要     | 字段/截止项 padding `space-3`；字段 grid gap `space-3`；外层 gap 及纵向 margin `space-4`                                                    | official-calendar `.isbf-official-activity-summary`                                         |
| 用户资料内层     | `.user-content` padding `16px`；无封面且未收起时顶部 `calc(120px + 12px)`                                                                   | common 后续 `.about.no-background:not(.collapsed-info)` 覆盖；不能用旧 `96px/88px` 当最终值 |
| 通知项           | padding `space-4`；动作之间 gap `space-3`、动作头 padding `space-2 0`                                                                       | common `.isbf-notifications`                                                                |
| 认证面板         | padding `72px 16px 22px`；margin `max(104px, 18dvh) auto 90px`；FormKit container gap `16px`                                                | 最新 academy-auth `__panel`                                                                 |
| 认证登录输入     | 左右 padding `44px`，标签下距 `8px`，input group 下距 `16px`                                                                                | 最新 academy-auth `#login-form`；保证密码显隐控件与文字居中                                 |

以上数值来自不同组件，不能四舍五入、归并成新比例或统一为个人选择的间距。

## Shape

### 共享变量

| Token                       | 值                            |
| --------------------------- | ----------------------------- |
| `--isbf-v2-radius-sm`       | `8px`                         |
| `--isbf-v2-radius-md`       | `16px`                        |
| `--isbf-v2-radius-pill`     | `999px`                       |
| `--isbf-v2-border-width`    | `1px`                         |
| `--isbf-v2-shadow-menu`     | `0 8px 28px rgb(0 0 0 / 22%)` |
| `--isbf-v2-transition-fast` | `120ms ease`                  |

### 组件局部外形

| 组件                        | 实际规则                                                                            |
| --------------------------- | ----------------------------------------------------------------------------------- |
| 普通信息流                  | 全宽内容及条目分隔线，不能加通用浮动圆角卡片外壳或阴影；头像 `50%`                  |
| 右栏面板                    | `1px solid border`、`radius-md`；规则未设置面板阴影                                 |
| 账号菜单                    | 面板 `radius-md`、`shadow-menu`；菜单项 `radius-sm`；触发器 `50%`                   |
| 通知/部分筛选菜单           | `radius-sm`，局部阴影 `0 4px 16px rgb(0 0 0 / 12%)`；不与账号菜单阴影混同           |
| 工作台                      | 面板 `22px`；桌面卡片/图标 `18px`；手机卡片 `8px`、图标 `12px`                      |
| 官方活动摘要字段/独立截止项 | `1px solid border`、`radius-sm`；外层摘要不设置整块边框或圆角                       |
| 认证                        | 局部 `--d-input-border-radius: 12px`、`--d-button-border-radius: 12px`；面板 `20px` |
| 资料头像                    | `4px solid surface`、`50%`；头像框独立叠层以图像内容定位，扣除白边，不裁掉框        |
| 公开活动/商品缩略图         | `radius-sm`，分别见 common `.isbf-post-preview`、marketplace `__image`              |

`12px/18px/20px/22px` 是现有局部值，尚无对应全局半径 token。菜单阴影不能扩展成所有卡片的阴影。

## Layout

### 公共布局变量与计算

| Token                     | 实际值                                                                            |
| ------------------------- | --------------------------------------------------------------------------------- |
| `--isbf-v2-left-width`    | `260px`                                                                           |
| `--isbf-v2-feed-width`    | `600px`                                                                           |
| `--isbf-v2-rail-width`    | `340px`                                                                           |
| `--isbf-v2-gap`           | `24px`                                                                            |
| `--isbf-v2-layout-max`    | `1260px`                                                                          |
| `--isbf-v2-page-left`     | `max(16px, calc((100vw - var(--isbf-v2-layout-max)) / 2))`                        |
| `--isbf-v2-feed-left`     | `calc(var(--isbf-v2-page-left) + var(--isbf-v2-left-width) + var(--isbf-v2-gap))` |
| `--isbf-v2-feature-width` | 后续 `:root` 定义为 `min(920px, calc(100vw - var(--isbf-v2-feed-left) - 24px))`   |

`layout-max` 是定位计算依据，feed 是内容列，feature 是另一个功能区域的宽度。不能把三者归并为一个最大内容宽度。

### 主题响应式覆盖

来源：common 的对应 `@media`；应结合完整级联和组件布局阅读。

| 条件              | 已有覆盖                                                                                           |
| ----------------- | -------------------------------------------------------------------------------------------------- |
| 基础桌面规则      | 左侧 `260px`、feed `600px`、右栏 `340px`、gap `24px`                                               |
| `width <= 1279px` | 左侧 `220px`，feed `600px`，右栏隐藏；page-left 为 `max(16px, calc((100vw - 844px) / 2))`          |
| `width <= 1023px` | 左侧 `72px`，gap `8px`，feed `min(600px, calc(100vw - 100px))`；导航折叠，只保留图标等既有紧凑规则 |
| `width <= 600px`  | feed/feature `100vw`、feed-left `0px`，左右栏隐藏；移动导航、header、safe-area 规则接管            |
| `width >= 601px`  | 桌面 feed 顶部高度规则生效；不能与平台 `sm` 断点互换                                               |

### 组件布局与平台断点

| 组件/机制        | 实际规则与边界                                                                                                                                                                                                                                          |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 工作台 grid      | 基础 4 列；`width <= 1099px` 为 3 列；`width <= 600px` 后续覆盖回 4 列                                                                                                                                                                                  |
| 官方活动摘要     | `repeat(2, minmax(0, 1fr))`；桌面和手机都两列                                                                                                                                                                                                           |
| 账号菜单         | 基础宽 `max(220px, 100%)`；手机面板 `min(280px, calc(100vw - 32px))`                                                                                                                                                                                    |
| 普通信息流头像列 | `42px`，gap `space-3`；原生行 fallback 列 `44px`、头像 `40px` 是不同布局                                                                                                                                                                                |
| 校友地图/目录    | 地图高桌面 `360px`、手机 `280px`；人物行桌面 `1fr 2fr 1fr`、gap `12px`，手机 1 列、gap `6px`                                                                                                                                                            |
| 认证面板         | 宽 `min(384px, calc(100% - 48px))`；专用全屏区域                                                                                                                                                                                                        |
| 平台 viewport    | [breakpoints.scss](../../app/assets/stylesheets/lib/breakpoints.scss)：`xs: 20rem`、`sm: 40rem`、`md: 48rem`、`lg: 64rem`、`xl: 80rem`、`2xl: 96rem`；[viewport.scss](../../app/assets/stylesheets/lib/viewport.scss) 的 `from` 是 `>=`、`until` 是 `<` |

平台断点仅解释 Approved 代码引用的 `viewport` mixin，并非根据默认主题提取设计风格。不要假定 `rem` 的当前像素值，也不要用平台断点替换主题的 `600px` 等条件。

## 缺失与人工确认

- 当前数据库实际色板和 `--font-family` 值。
- 全局标题层级、通用 Card、设置表单，以及通用 modal 的宽度/页边距。
- 所有按钮的 loading、disabled、危险/成功状态是否需要共同视觉规格。
- 通用输入框的 hover、focus、invalid、disabled 视觉规则；已有认证输入和右栏搜索只是局部变体。
- 全站空态、骨架屏、成功提示与错误容器的设计。

缺失项不能用 Discourse 默认样式补为目标规范。先选匹配 Approved 变体；仍无匹配则提交方案，等待人工确认。

## 头像框校准区局部尺寸

A15/C14 来源为 [2026-10-11 校准样式](references/plugins/discourse-avatar-frames/accepted-20261011/assets/stylesheets/common/avatar-frames-admin.scss.txt)。
`--avatar-frame-preview-size` 在 large/small modifier 上分别为 `144px`、`48px`；
预览外距为该值的 `10%`，预览及操作 gap 为原上传区已有的 `0.75em`。数字输入单列。
这些值只限本次批准的校准区，不形成通用头像、间距或后台 token。

款式定位数据默认大小 `120%`、偏移 `0/0` 是 C03 的图片几何接口，
以实际头像内容尺寸计算，不是排版 token。个人主页 `4px` 白边保持原批准值。

## 2026-10-12：本轮前台统一

[运行基线](baselines/README.md)、[19组执行记录](frontend-rollout-20261012.md)
及[D01–D07代表提案](proposals/frontend-consistency-20261012.md)已建立。
D01–D06及D07弹窗组合已人工确认，实际页面仍为In Progress；用户卡及资料上部保留，后台排除。
遵照用户要求[控制内存](resource-policy.md)，停止生产排查。

## 本轮已确认的用途组合

[人工确认](references/evidence/frontend-consistency-acceptance-20261012.md)只扩展D01–D06和D07关联弹窗的用途，没有新增全站token。
输入最小44px、radius-sm 8px、1px边框、左右space-3；按钮最小44px、font-sm/600及pill，主按钮accent/contrast、hover brightness(0.92)。
功能区沿用feature-width，内容列表沿用feed-width；16/24px间距、双列12px gap及18px/600分区标题均限定在目标主体。
信息正文16px/1.45，段落16px、列表内缩32px。关联弹窗最大600px、16px内距/圆角、1px边框，手机全宽与安全区。
用户卡的340px/96px提案被排除，不是可复用token。资料上部及一级导航的实际级联不得改变。

## 本轮实现来源与验证

19组均已提交代码，实际页面仍为In Progress。具体接入文件、保留边界和未覆盖状态见
[实现说明](frontend-implementation-20261012.md)，源码摘要见
[source map](frontend-implementation-source-map-20261012.json)，检查结果见
[验证记录](frontend-verification-20261012.json)。新版离线入口为
[V2预览](reviews/frontend-20261012-v2/index.html)，已移除用户卡示例；旧包只作历史记录。


## 2026-10-14 简历紧凑页头

桌面纵向 space-4、返回横向 space-3、gap space-2、20px 图标/font-xl；≤600px 纵向 space-2、返回横向及 gap space-1、18px 图标/font-md。沿用站点字体、text/surface/border/focus-ring、1px 底部分隔线和最小 44px 点击高度。局部 content-gutter 保留桌面 26px/手机 16px 内容间距，无新增全站 token。

[局部 token 映射](../../plugins/isbf-resume/docs/design-system/resume-approval.md#2026-10-14-简历紧凑页头设计确认)保存用户批准范围、来源版本和实现边界。

## 2026-10-14 招募独立页

用户批准沿用压缩包原样接入 `/join/`，颜色、字体、间距与动画仅作用于该独立文档，
不作为论坛通用 token。原始 CSS 和资源摘要见 [来源记录](references/join-20261014/README.md)。
后台申请列表复用已批准的后台组件接入方案，不新增颜色、间距或控件变体。

## 2026-10-15 回复对话的局部复用

2026-10-16确认的[手机操作栏对齐](deployments/reply-conversations-20261015/alignment-20261016.md)复用上述头像/列间距与33px缩进计算，仅在局部抵消操作栏缩进并采用五个等宽列；不修改全局token。定位提示复用既有`tertiary-low`和2秒淡出，减少动态效果时短暂静态显示。

[C16方案](proposals/reply-conversations-20261015.md)复用现有42px头像及单层回复结构、
space-3（12px）列间距、1px语义分隔线和font-md/1.45正文。操作采用UI kit按钮，手机目标至少44px。
原文预览使用hover背景、border-strong边线和muted文字，最多两行；进度仅显示“当前 / 总数”，
如“1 / 2”，复用已有页头和悬浮时间轴字体；按钮只写“收起”。
用户已选定B的直线修订：主干从根头像底部沿中心线向下延伸，以1px border-strong直线接入子回复，
缩进按头像半径与space-3计算，当前为`42px / 2 + 12px = 33px`；支线长space-3，末条头像中心处收尾。
该尺寸仅是头像连接的几何计算，不新增全局token、颜色、圆角、阴影或字体。
三条预览、50条子回复分页和20组根分页是行为常量，不是视觉token；当前仍待实际视觉验收。

## 认证欢迎按钮位置修复（2026-10-16）

认证欢迎态的按钮组采用局部 Y 轴 +24px 位移，沿用认证页既有24px间距尺度；这不是新的全局间距 token。

来源与实施记录见[局部修复](deployments/auth-welcome-buttons-20261016/README.md)。

## 2026-10-16 继续阅读局部尺寸

[本次用户规格](reviews/continue-reading-20261016/README.md)限定帖子底部：直角（0圆角）、1px边框、
桌面24px/手机16px内距、36px/30px头像、84px最小行高、16px/600标题和13px元信息。
600px断点沿用现有主题；头像尺寸变量只定义在组件内，不新增全局token。
次要文字使用已有primary-high色阶提高浅色可读性，主文字、背景、边框、强调和焦点复用现有V2语义变量。
用户规格只确认该局部组合，最终视觉验收待完成。

2026-10-16补充：用户明确授权上线，局部继续阅读已发布。原生及线上检查、实际源码版本、保留范围和回退见[发布记录](deployments/continue-reading-20261016/README.md)。最终视觉仍待用户核验，不扩大其他区域的Approved范围。

2026-10-17继续阅读修订：用户明确要求容器直角，局部`border-radius: 0`取代初版16px圆角；其他组件的圆角token不变。源码及线上CSS验证见[修订记录](deployments/continue-reading-20261016/square-border-20261017/README.md)。

## 2026-10-18 通知未读局部组合

C18仅用于通知铃铛及分组页：数字角标最小宽高space-5、内距space-1、
font-xs/weight-bold/radius-pill，圆点宽高space-2；颜色复用accent及accent-contrast。
动作未读点使用space-2及同尺寸文字间距，以flex与文字垂直居中；主题标题无点。
只看未读开关移入右上角菜单，菜单行使用space-3、font-sm；
UI kit开关使用space-6高、两倍space-6宽，点击区域高度space-6+space-5。
不新增全局token。设计确认、实际源码和验证见[局部记录](reviews/notifications-unread-20261018/README.md)。

2026-10-18通知未读提示已按用户授权发布；精确线上合并源、已验证镜像、两端功能与资源核对见[发布记录](deployments/notifications-unread-20261018/README.md)。C18的角标、动作点和菜单筛选规则保持局部范围。

## 2026-10-18 通知层级局部组合

C19仅用于当前用户的分组通知：组外距、组间距及内距复用space-4，
边框复用border-width/border，圆角radius-sm；不加阴影。
帖子标题font-lg/weight-bold/1.45，主文字色；动作分类font-sm/weight-medium、muted，
配已有通知图标；条目font-md/1.45，时间font-xs/muted。
动作间距及分隔线内距space-3，行内距和头像间距space-3、头像40px沿用C13。
整行主链接的键盘焦点复用2px focus-ring、offset -2px。
上述组合经用户明确确认，仅扩展本地通知区域，不新增全局token。
来源与验证见[审阅记录](reviews/notifications-layout-20261018/README.md)。

2026-10-18通知页层级与整行点击已按用户授权发布；活动主题4项字段的确切合并源、插件及镜像核对、两端只读验证见[发布记录](deployments/notifications-layout-20261018/README.md)。C19仅限本次通知区域。
