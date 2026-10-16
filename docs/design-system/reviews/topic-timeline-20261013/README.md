# 右侧悬浮时间轴：实现与验收材料

已按[确认方案](../../proposals/topic-timeline-floating-20261013.md)实现源码。最终调整为**日期与阅读信息在左，轨道与滑块在右**，桌面和手机均点击顶部入口后展开。用户随后要求把返回按钮位置调整得更整齐、加强玻璃效果并上线：本轮返回放在底部操作行，背景透明混合为60%，模糊为24px。人工视觉验收仍待用户完成，本目录不授予Approved状态；上线结果见[发布记录](../../deployments/topic-timeline-20261014/README.md)。

## 查看材料

- [交互式离线布局预览](preview.html)：下载后用浏览器打开，顶部进度按钮可打开、关闭浮层。页面使用示例帖子和框架适配器，只有时间轴样式及事件处理代码来自本次实际源码，不代表完整应用渲染。
- [桌面浅色](1440-950-light.png)、[桌面深色](1440-950-dark.png)。
- [手机浅色](390-844-light.png)、[手机深色](390-844-dark.png)、[320px手机](320-568-light.png)、[短窗口](390-450-dark.png)。
- [手机长日期与大计数](390-844-dark-long.png)、[320px长日期与大计数](320-568-light-long.png)。
- [原生成参考图](reference-before-axis-swap.png)是用户提出左右对调前的方案图片；最终顺序以上述实现截图为准。参考图其他页面细节不属于本次接管范围。

## 验证结果与边界

- 本次3个实现文件和2个测试文件已执行`bin/lint --fix`，Prettier、ESLint和Stylelint通过；测试补充等待语句后的格式问题已修正并定向检查通过。指针传播守卫及其测试需要在`pointerdown`阶段工作，已限定并说明对应lint例外；动作仍通过`DButton`的click/键盘入口执行。
- 使用项目Babel配置与模板编译器检查主题组件、UI kit适配器和两份测试文件；结果见[编译记录](compilation.json)。
- 使用与Gemfile.lock一致的现有Sass依赖编译实际时间轴样式，纳入原生时间轴CSS、当前主题相关级联及主题声明的明暗配色派生。产物位于`compiled/`。
- [离线验证记录](preview-verification.json)覆盖8组桌面/手机明暗、320px、短窗口、长日期和大计数。检查文字在轨道左侧、4px轨道与16px滑块居中、50px纵向滑块区域、内容宽度、视窗边界、底部留白、44px触控目标和无横向页面溢出。
- 离线检查运行实际源码中的事件处理方法及返回索引计算，框架服务、响应式渲染和页面数据使用适配器。覆盖开关、关闭与重开、Esc、外部点击、焦点恢复、子弹窗优先、主题初始化收起、手机原生底部面板手势取消及监听清理；检查原生外部点击处理没有再排入延迟关闭。检查返回按钮在底部而非轨道中段，并调用原生`jumpToIndex`。最终适配器还模拟原生class整段重写及每次响应式赋值后的父级渲染；同步恢复标记，字段仅在值改变时更新。
- 新增6项主题渲染回归及6项完整应用回归，覆盖UI kit继承适配的捕获阶段、排除目标、参数变更及销毁，以及返回阈值、过滤索引、原生时间轴、跳转弹窗、话题切换和手机行为。这12项已编译，**未在共享主机执行完整QUnit应用回归**，需在预算允许的隔离开发环境或现有CI运行。没有将离线适配器结果等同于这些应用测试通过。

离线工具始终串行使用一个512MiB、0.5CPU、192进程上限、无网络容器，没有生产数据或Docker socket挂载；工具执行记录见[资源记录](tool-executions.jsonl)。完整预览论坛保持停止。用户授权上线后开展的主题更新与生产只读资源检查另行记入发布目录，不属于离线应用回归结果。

## 完整应用回归

在隔离数据库导入本主题后，依照主题README配置`THEME_IDS`，使用`bin/qunit --theme-id ID --qunit-path /theme-qunit --filter "/ISBF floating topic reading|ISBF.*(ISBFTopicReadingJump|isbf-close-on-click-outside)/i"`。本版本无需Core扩展；生产数据库仅用于授权发布及必要只读加载确认，不用于准备或执行QUnit回归。

## 人工视觉核验

在具备上述源码的完整应用中，桌面和手机分别切换明暗配色，确认日期和阅读信息靠左、轨道靠右、毛玻璃效果、浮层宽度与文字贴合、页面滚动时的位置，以及回复/导航和安全区。再操作拖动、首尾日期、阅读标记、楼层跳转和通知菜单，确认实际数据与权限下的操作可用。

记录实际源码版本、视窗与设备、核验结果和接受范围后，再更新设计规范及参考manifest。源码和产物摘要见[source-manifest.json](source-manifest.json)；当前工作区版本尚未提交，也不代表当前线上版本。

## 重现离线检查

`run-tool.py`使用本机已有工具镜像，提供上述资源预算并在结束时删除容器。主机可用内存不足1GiB则拒绝启动，运行中不足512MiB或超时则停止本任务工具。只运行本目录编译脚本和预览检查，不启动Rails或变更其他服务。

```sh
python3 docs/design-system/reviews/topic-timeline-20261013/run-tool.py node /review/compile.mjs
ISBF_TIMELINE_TOOLS_IMAGE=local_discourse/isbf_app:latest python3 docs/design-system/reviews/topic-timeline-20261013/run-tool.py ruby /review/compile-css.rb.txt
python3 docs/design-system/reviews/topic-timeline-20261013/run-tool.py python3 /review/check-preview.py
```

Sass步骤仅从既有镜像加载公开依赖，不加载论坛环境、数据库或应用服务。若重现环境不同，应保留相同依赖版本和预算，再按可用工具修改镜像选择器。
