# 2026-10-12 前台实现说明

三批19组的代码已接入隔离分支 `feature/isbf-frontend-design-consistency`，见
[Draft PR #52](https://github.com/ISBF-Lab/ISBFweb/pull/52)。未合并、未部署。
执行范围见[页面清单](frontend-rollout-20261012.md)，组合规则见
[人工确认](references/evidence/frontend-consistency-acceptance-20261012.md)。实际页面仍为In Progress。

## 基线与实际改动

以保存的生产核心 `132cc95d043db01251eedf9c93b3927cd5ffee91`、主题4/133字段为运行基线。
先将完整主题字段恢复到隔离工作树，再接入本轮样式；没有从旧128字段设计参考覆盖活动主题。
原始字段附件和Approved源码附件保存原字节，后续源码摘要见
[实现source map](frontend-implementation-source-map-20261012.json)。

| 源文件                                                                                                                              | 职责与边界                                                                                        |
| ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| [frontend-consistency-scope.js](../../themes/isbf-campus-feed/javascripts/discourse/lib/frontend-consistency-scope.js)              | 对19组及指定子路由精确分类；camelCase转为已存在路由名称，未知插件子路由不自动继承                 |
| [isbf-frontend-scope.gjs](../../themes/isbf-campus-feed/javascripts/discourse/components/isbf-frontend-scope.gjs)                   | 路由标记随导航释放，按关联弹窗的真实组件身份或原生确认状态启用容器样式                            |
| [isbf-frontend-consistency.gjs](../../themes/isbf-campus-feed/javascripts/discourse/api-initializers/isbf-frontend-consistency.gjs) | 原生出口接入范围组件及标题，不替换表单和列表数据                                                  |
| [isbf-frontend-heading.gjs](../../themes/isbf-campus-feed/javascripts/discourse/components/isbf-frontend-heading.gjs)               | 使用核心已有翻译，接入偏好设置、目录及群组目录标题                                                |
| [isbf-v2-shell.gjs](../../themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-shell.gjs)                               | 用户目录准确区分 `/u` 与用户资料，搜索、标签和指定群组页接入已有页面壳                            |
| [frontend-consistency.scss](../../themes/isbf-campus-feed/stylesheets/frontend-consistency.scss)                                    | D01–D06及D07关联弹窗的局部组合；页面标记和原生内容层级限定作用范围                                |
| [common.scss](../../themes/isbf-campus-feed/common/common.scss)                                                                     | 仅增加样式import，其余运行基线内容保留                                                            |
| [group/manage/members.js](../../themes/isbf-campus-feed/javascripts/discourse/routes/group/manage/members.js)                       | 为核心路由表已声明、但没有实现的管理成员子路由复用原生GroupIndex，继续受GroupManage拥有者权限约束 |

本轮没有修改核心业务模板、API、数据库、权限校验或现有插件文件。
`group/manage/members`只复用原生控制器、模板和动作，不新增成员管理接口。
该子路由已在第三轮四种视口/色板的群组流程中加载并通过成员列表检查。

PR以main为目标，其完整差异还包含保存的生产基线中已有的历史改动。
审阅本轮接入可比较 `6088c676701..HEAD`；比较 `132cc95d043..HEAD`时还包含运行主题还原。
`app/`、`frontend/`、`plugins/`、`config/`、`db/`及`lib/`相对生产核心基线均无改动。
main差异中的历史后台或权限改动不属于本轮新增。

## 复用的视觉材料

- 使用已有 `--isbf-v2-*` 色彩、字体、间距、圆角、宽度和焦点变量；没有补齐不存在的token。
- 设置、目录、邀请和群组管理使用D01功能区，列表主体使用已有600px内容列。
- 表单沿用FormKit/UI kit/select-kit的行为、字段和状态；D02只组合已确认的尺寸、边框、标签、间距和主操作。
- 私信、书签、草稿、待审核保留真实私有列表和原生动作；连续条目16px内距、12px间隔、1px分隔，不加卡片阴影。
  私信下部二级导航中的收件箱选择器和新建私信按钮复用同一套D02控件规则；资料上部操作区保留。
- 原生DirectoryTable、DResponsiveTable及群组列表保留动态字段、排序、分页与自身滚动区域；D04只接入目标二级导航。
- 统计、徽章、标签等使用D05双列集合；徽章图片、授予、分组和收藏语义保留。
- 关于/帮助/条款/隐私等保留完整原生正文和h1–h6语义，D06只接入已确认正文、链接及间距材料。
- D07只接入登记的邀请、偏好设置、目录、书签、草稿和群组关联弹窗，以及目标路由上的原生确认框。
  未登记的共享或后台弹窗继续排除，保留原生遮罩、Escape和焦点行为。

FormKit原样式强制设置的输入padding/border在目标字段局部覆盖；验证码、文件、checkbox/radio、
嵌入代码编辑器不据此变成通用输入。错误、disabled、readonly和active/aria-pressed继续使用原控件状态；隐藏输入和代码编辑器不会被通用输入规则覆盖。
工程API默认外观仍不是项目设计来源。

## 保留区域

用户弹出卡未接入新规则。A11资料上部、封面/无封面、头像/头像框、名称、简介、操作区、
展开/收起及一级导航保留；样式只进入目标下部wrapper。A12公开活动预览源码保留。
当前133字段运行副本的右栏最近讨论使用文字摘要；旧128字段参考中的缩略图描述不用于
改写这个运行行为。旧预览测试按真实生产基线修正了右栏文字和现有翻译的期待，没有修改预览UI。

`/admin`、认证、日历、举报及未知插件路由不纳入新页面规则。
公开活动、普通FeedCard和原有功能入口保持其批准范围，不因本次表单组合而扩权。

## 验证分层

[工作流](../../.github/workflows/isbf-frontend-consistency.yml)在GitHub独立数据库和合成记录上串行运行。
原生QUnit在安装项目主题前执行，证明相关核心行为回归；项目主题QUnit检查精确路由、标记释放、
弹窗状态、动态目录、账户校验、私有列表和保留区域。两种测试不能互相代替。

[真实页面spec](../../themes/isbf-campus-feed/spec/system/frontend_consistency_spec.rb)和
[Page Object](../../themes/isbf-campus-feed/spec/system/page_objects/pages/frontend_consistency.rb)
使用1440px/390px、明暗四种组合，访问账户/偏好、目录、邀请、书签、草稿、待审核、私信、
资料下部、徽章、群组/8管理页、搜索、标签和7信息页，检查加载、溢出、保存、取消、排除后台及上部几何。
这些是代表流程，不是对每个权限和异常状态的穷举，也不包含生产数据。
真实检查按12个用户流程、4种视口/色板组合运行，共48例，保留项目45秒单例上限。
信息页使用测试配置的合成正文话题；收件箱使用包含他人发帖的私信，遵守原生查询规则。
测试不会改写已发布的条款、隐私或帮助内容。

离线V2预览8类、16HTML、32截图、58静态检查，只验证方案组合的加载、颜色、尺寸、
溢出、hover与焦点。真实页面截图必须单独标注CI来源；不把离线图称为生产截图。
具体运行和失败修复见[验证记录](frontend-verification-20261012.json)。

第八轮完整通过：原生前端1044项、主题QUnit89项、真实页面48例均为零失败。
受测源码为 `015a1a592d96fc23993c430d1cf3480ba8d347ad`；
[112张真实页面截图及来源](reviews/frontend-20261012-v2/actual-pages/README.md)与离线原型分开保存。
这些结果验证代表流程与实现边界，实际页面的视觉接受状态仍待人工确认。

## 仍需人工确认或后续验收

- 本轮真实页面的视觉接受范围；没有因自动化通过而将19组提升为Approved。
- 游客/他人/隐藏资料、各插件字段、长文本和全部错误/分页状态的完整视觉覆盖。
- 两步验证、邀请角色提交、私信所有标签/警告变体、草稿恢复删除和全部群组管理提交操作的端到端覆盖。
- 全站通用成功/空态/骨架、后台及未登记插件组件仍无本轮设计授权。
- 以后部署前需要重新核对完整生产插件、活动数据库主题及功能链接；本次按用户指示不做生产检查。

上述缺口保留原有行为，不用默认Discourse外观或个人审美创造新的目标规范。
