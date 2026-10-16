# 回复对话分组审阅 · 2026-10-15

状态：方案已确认，代码候选与离线预览已准备；未上线，人工视觉与完整应用回归待完成。
连线当前采用用户选定的B直线修订，来源和边界见[选定记录](guide-redesign/README.md)。
本轮保持完整预览论坛停止，没有读取生产作为测试后端，也没有修改生产设置、主题或数据库。

## 查看预览

- [可交互离线预览](index.html)：展开/收起、原文预览、#80目标页、明暗切换；演示数据。
- [桌面](desktop-light.png)、[手机390px](mobile-light.png)、[手机320px](mobile-320.png)。
- [桌面深色](desktop-dark.png)、[手机深色](mobile-dark.png)。
- [桌面悬浮时间轴](desktop-light-timeline.png)、[手机悬浮时间轴](mobile-light-timeline.png)。
- [桌面完整连线](thread-desktop-light.png)、[手机完整连线](thread-mobile-light.png)。

预览使用实际组件类方法和编译后的实际CSS，网络、组件服务、模板DOM由离线适配器提供。
它没有启动Ember、Rails、编辑器或完整论坛，不能代替真实通知、发布、浏览器返回、
头像框插件或完整权限回归。截图中的侧栏、头像及帖文均是合成夹具。

## 交付行为

普通话题按根回复分组，所有后代只出现一次，统一一层自然缩进，按时间从早到晚。
主干从根头像底部延伸，以直线短支线接入子回复头像中心，缩进按头像半径与间距计算，当前33px。
默认预览最早三条，展开后每页50条，收起恢复三条；根讨论每页20组。
回复对象明确显示姓名/账号和楼层，可按需查看两行原文并定位完整原帖。

讨论组时间轴复用现有悬浮布局；页头及时间轴仅显示“当前 / 总数”（如“1 / 2”）。组序号先经服务器解析为根楼层，
楼层、通知和日期跳转沿用规范话题路由。目标回复的所属根页及子回复页自动加载，
未加载的前段提供明确入口；自己的新回复跳转到其实际楼层。缓存继续保存展开、分页与滚动状态。
私信、聊天、后台、嵌入页和专用活动日志不接入主题组合。

首版审阅后，用户要求去除进度中的说明和总回复数、收起按钮只写“收起”、增加竖向引导线。
连续2px侧线随后被用户否定，最终选择B并提供直线参考HTML：1px主干、12px直线支线，
从主头像连接到末条子回复头像。分页空档的此前回复按钮参与主干，避免产生断点。
明暗模式、桌面、390px及320px手机预览已同步更新；人工视觉验收仍待完成。

## 验证与限制

- [项目lint](lint-status.json)：本次明确列出的40个源/测试文件执行`bin/lint --fix`，
  ESLint、Prettier、RuboCop、SyntaxTree和Stylelint通过。
  简洁文案修订另对[9个文件](compact-thread-files.json)执行过定向lint；B直线修订对
  [唯一受影响的应用SCSS](straight-guide-files.json)执行`bin/lint --fix`，当前日志保存该次结果。
- [模板编译](compilation.json)：通过项目Babel/Glimmer编译；[Ruby/YAML解析](ruby-yaml-syntax.json)。
- [样式编译](style-compilation.json)：缓存Sass编译器，实际嵌套、时间轴及主题样式。
- [离线浏览器报告](browser-report.json)：三条预览、100层关系平铺、50条分页、去重、
  加载此前回复失败重试、隐藏原文、规范链接，以及桌面/390px/320px明暗布局。
  当前同时核对主头像底部起点、主干对齐、直线支线、自然缩进及末条头像收尾。
- [RSpec执行状态](rspec-status.json)：在`bundle check`阶段缺少锁定的测试gems而停止；
  **0个RSpec用例运行**。[复现方法与日志](spec-runner.md)保留完整缺失清单。
- 已补充原生QUnit组件/模型测试与主题原文/组导航测试；完整QUnit依赖Rails测试端点，
  本轮资源预算下未启动完整论坛，因此未声称这些测试已运行。
- [真实SQL检查](navigation-sql-results.json)：直接加载实际Navigation/TreeLoader，
  30项全部通过。使用隔离PostgreSQL、ActiveRecord及合成表/权限参与者，
  验证排序、置顶、跨页、100层关系、可见性及循环终止；仍不替代Rails/RSpec。

离线测试限制不改变现有CI门禁。上线前需要在具备锁定测试依赖的隔离环境运行定向
RSpec/QUnit，并验证真实的发布后定位、通知/日期跳转、浏览器返回和头像框挂载。

## 来源与启用

[确认方案](../../proposals/reply-conversations-20261015.md)限定普通话题回复区与组导航。
复用A01/A04和C01/C03/C09的现有颜色、42px头像、局部间距及原生动作，登记为C16候选。
实际版本见[source manifest](source-manifest.json)；历史参考附件保持原始字节。

[activation.yml](activation.yml)仅准备开关值，不被应用加载。现有`Topic#nested_view?`
通过全站默认设置覆盖旧帖与新帖，不需要批量改写回复关系或迁移数据库。
核心代码与主题必须一起准备；后续部署需按AGENTS.md核对活动主题和完整插件清单，
不可用工作区主题覆盖数据库中无关功能。最终视觉验收仍由用户完成。

## 复现离线预览

```bash
ISBF_REPLY_TOOLS_IMAGE=local_discourse/isbf_app:join-20261015 \
python3 docs/design-system/reviews/reply-conversations-20261015/run-tool.py \
  /bin/bash /review/run-preview.sh
```

使用单个512MiB、0.5CPU、192进程/线程工具容器，无网络、无生产数据挂载。
预览与测试串行执行，退出后清理容器；运行记录见[tool-executions.jsonl](tool-executions.jsonl)。
