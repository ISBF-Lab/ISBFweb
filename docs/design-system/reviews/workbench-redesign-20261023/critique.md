# 审图记录

本次为应用界面，按 `references/app-screens.md` 的七项检查审图。营销页的照片、入场动效和展示字号要求不适用；评分是自评，不是外部评审或用户验收。

ROUND 1
Seen in one second: 工作台标题，以及同一区域的九个校园服务入口。
Idea (one sentence): 让校园里已能使用的学习、简历、校友和商品服务先被找到。
Live thing: 已开放入口整块直达原地址；更多菜单和明暗预览可操作。
Layout words by section: shell=既有导航 / heading=名词与一句说明 / services=十二列网格，三、二、单列适配。
Scores: design 7.0 · usability 8.0 · creativity 6.0 · content 7.5 → overall 7.2
Caps applied: 创意按通用服务目录评分；不套用营销页的图片与动效下限。
Top three problems (most visible first), each with the screenshot it shows in and the fix:
1. 初版 `desktop-fold.jpg` 中全部面板都是浅灰，开放与筹备的差异依赖小字。改为开放入口白底与蓝色箭头、筹备入口浅灰和可读的次级文字。
2. `desktop-fold.jpg` 下方留白较多。保留九项服务的自然高度，不用虚构统计或新功能填充；页面没有第二个空白章节。
3. `tablet-fold.jpg` 的末项跨整行，比其余入口宽。按已选择的末行补齐规则保留，确保页面两端对齐，不留孤立空格。

ROUND 2
Seen in one second: 可点击的学习资源、简历工具和校友网络，以及明确标为筹备中的其他服务。
Idea (one sentence): 用现有校园服务的真实名称、用途与开放状态，组成一页可以直接出发的工作台。
Live thing: 所有开放入口使用原始链接；单文件版支持直接打开和明暗切换。
Layout words by section: shell=既有导航 / heading=工作台 / services=单层面板，开放优先、同区呈现。
Scores: design 7.2 · usability 8.5 · creativity 6.0 · content 7.5 → overall 7.4
Caps applied: 继续将创意按常见目录方案计分；当前不是有完整品牌素材的最终视觉稿。
Top three problems (most visible first), each with the screenshot it shows in and the fix:
1. `after/desktop-fold.jpg` 的品牌识别仍依赖侧栏名称。缺少已核对的线上徽标与字体，示例不虚构素材；实际接入时沿用当前站点资产。
2. `after/desktop-fold.jpg` 的外层左右空间来自既有 A01 的定位和 920px 功能区。用户选择保留导航与页面壳，本次不扩大布局改动范围。
3. `after/mobile-page-01.jpg` 需要滚动查看后五项筹备服务。四个开放入口均在首屏，保留单列的可读性和完整用途说明。

## 应用界面七项检查

1. 主问题是“现在有哪些工具可以使用”；开放入口优先，筹备项目有文字状态。
2. 三列、两列、单列共享边缘与16px间距；最后一行补齐。没有额外统计卡或空图表。
3. 主题蓝只出现在原导航动作、可用状态和跳转箭头；图标没有彩色底块。
4. 没有业务统计数字。九项服务与四个开放入口来自同一独立夹具，不声称反映线上实时配置。
5. 不制造零值或增长数据；无链接项目直接显示筹备状态，不做可点击占位。
6. 没有图表、图例或数字标签冲突。
7. 手机保留既有四项导航结构；入口单列，无页面横向溢出，触控目标不少于44px。

## 技术结果与保留项

- 最终工作台主体 `after/report.json`：1440、768、390px，**0 FAIL，2 WARN**。所有三种宽度的首屏与整页联系图均已打开审阅。
- `hero-void`：九项服务结束后剩余的桌面空间。它是工具页的自然结束，不插入无依据内容。
- `unused-canvas`：保留的 A01 页面壳和920px功能区造成的窗口左右空间；网格在其内容区内左右对齐。
- 源码 `lint --app`：0 FAIL，1 WARN；唯一阴影属于打开时浮动的“更多”菜单，不是静态面板。
- `bin/lint --fix` 已执行；命令明确报告此文档目录没有对应核心 linter，未把该跳过结果描述为代码规则全部通过。示例源码另经 Prettier 和技能源码检查。
- 旧版离线基线 inspector 在辅助页创建时出现 `Page.enable` 超时，已保留其成功生成的截图。未获得完整旧版测量报告，不捏造前后分数。最终新版检查使用单进程浏览器完成，测量规则未削弱。
- 单文件版本的脚本原先在正文之前执行，导致主题按钮未绑定；已把内联脚本移到正文后，并对交付文件本身重新验证。

这是待用户审阅的示例。7.4分表示清晰、克制的目录方案；尚未达到有完整品牌素材的最终视觉稿，不提升任何区域的 Approved 状态。
