# 通知分组层级与整行点击 · 2026-10-18

用户明确选择保留按帖子归组、有边界的分组块、每条通知整行点击；
确认下列尺寸和文字层级，并选择不增加正文摘要，随后授权实施。
设计方向已确认，最终视觉待用户核验。本目录保留发布前离线审阅，不使用生产测试后端；现已按用户授权[上线](../../deployments/notifications-layout-20261018/README.md)。

## 设计来源与范围

复用A05/C13的通知分组、条目、独立折叠与原生渲染器，以及C18的未读提示和菜单。
新组合登记为C19，只作用于当前用户自己的分组通知页。历史参考附件不变。

- 每个帖子分组使用border-width/border的1px边框、radius-sm的8px圆角；
  组外距、组间距和内距均为space-4（16px），无阴影。
- 帖子标题font-lg（18px）/weight-bold（750）/1.45，使用主文字色并自然换行；
  动作名称与数量font-sm（15px）/weight-medium（600）/muted，配现有通知类型图标。
- 条目font-md（16px）/1.45，人名沿用姓名及账号规则；时间font-xs（13px）/muted。
  动作之间增加既有border和space-3（12px）内距；条目头像40px及行内距沿用C13。
- 未读条目沿用active-surface；动作旁蓝点保持居中，帖子标题不放点；
  未读筛选继续位于右上角三点菜单。无关联帖子的通知采用同样的边框和原生内容。

## 点击与兼容

在单条entry内定位现有主链接的伪元素，使头像、内容、时间及空白都命中同一链接。
普通通知仍调用原有item.onClick，原生摘要继续使用MenuItem；不在容器叠加点击处理，
保留通知的精确目标、原生事件、标读及计数逻辑。键盘焦点描边为2px focus-ring、offset -2px。
原生出口中的独立控件位于主链接扩展层之上。帖子标题链接、动作展开、重试及分页保持独立。
接口、权限、通知投递、分组排序及数据结构保持现状，无数据库迁移或正文加载。
合并点赞沿用原生获赞记录地址；回复和提及继续采用各自原生目标。

## 复现与资源

使用仓库已有离线工具镜像与缓存Ember客户端，替换实际当前主题模块和完整编译SCSS，
合成API供给通知。`before-manifest.json`保存变更前五份源码快照；
[最终源码清单](source-manifest.json)冻结13份实际客户端源码及翻译，
版本为`29c1d7e8c45f283a6cb3ababd3d0599d2b85a38dc4e688ece767b75957820808`。
编译输入及最终工作区、源码快照的SHA-256均已核对一致。
缓存样式中的旧`.isbf-notifications__topic h2`规则仅在离线适配器中移除，
避免它覆盖当前标题class；原有侧栏span适配保留。实际完整当前SCSS另行编译并加载，
上述缓存适配不写入产品源码。

```bash
python3 docs/design-system/reviews/notifications-layout-20261018/run-tool.py node /review/compile.cjs
python3 docs/design-system/reviews/notifications-layout-20261018/run-tool.py ruby /review/compile-style.rb
python3 docs/design-system/reviews/notifications-layout-20261018/run-tool.py node /review/compile-browser.cjs
python3 docs/design-system/reviews/notifications-layout-20261018/run-tool.py python3 /review/check-browser.py
```

按[当前资源规范](../../resource-policy.md)，每次启动以实时可用容量和有效cgroup限额
扣除512MiB服务余量计算上限，向下取64MiB整数倍，内存加交换总量与内存相同。
0.5CPU、192进程、单个无网络工具容器、单浏览器及单页面，串行运行。
运行中记录峰值并监控服务余量，触及预算即停止本任务工具；完整预览论坛保持停止。
脚本只调整本轮工具，不修改历史运行脚本或其他服务的资源配置。

Ctrl/Cmd和中键测试在原生事件处理后观察默认行为，再阻止浏览器实际打开第二页，
以遵守单页面限制。离线检查不代替完整应用及最终视觉验收。
跳转通过记录原生路由调用及目标验证；目标页面的真实数据加载不在本轮离线范围内。

## 验证结果

- 定向`bin/lint --fix`通过ESLint、Prettier和Stylelint；仅新加测试的一处排版被格式化。
  文档不属于现有core linter范围，另行检查JSON、Python语法、链接目标及差异空白。
- 10份实际前端源码及测试编译通过；完整公共SCSS及其导入、两套色板和中英文翻译编译/解析通过。
- [客户端汇总](browser-report.json)共159项断言通过：既有行为与8组响应式布局101项，
  [整行实点及后续交互](row-clicks/browser-report.json)58项。
  电脑及手机分别检查回复、提及、合并点赞和无头像的原生徽章通知，
  覆盖头像、内容、时间、空白及展开条目；一次点击调用一次原生目标、重复点击不重复扣数。
- 键盘整行焦点、Enter、Ctrl/Cmd及中键默认语义通过；独立展开、详情失败重试、
  详情及外层分页、初始加载失败重试、跨标签页标读及未读筛选竞态均通过。
  4种宽度、8组明暗布局无横向溢出，字号和分组边界、蓝点居中及菜单位置均经过断言。
- 长标题及不换行姓名在4种宽度下正常折行；
  [电脑](row-clicks/1280-long-title.png)与[手机](row-clicks/390-long-title.png)额外预览已保存。
  代理已查看电脑浅色及手机深色页面；最终视觉仍由用户核验。
- [原生QUnit尝试](native-test-attempts.json)因缺少隔离Rails测试服务器而执行0项，未记作通过。
  新增两种条目渲染方式的原生导航及去重标读测试已保存，供完整测试环境执行。
- [最终汇总](verification-summary.json)保存实际资源及[清理结果](cleanup.json)：
  最后浏览器按当时可承受容量设置1408MiB内存及交换总量，峰值约933MiB，
  主机余量始终高于512MiB。审阅工具容器已移除，完整预览论坛保持停止；上线状态见本次发布记录。

初次工具触发动态预算保护后已停止，后续降低浏览器堆并重新评估当时容量。
早期缓存标题干扰和合并点赞目标测试预期错误的报告保留于`attempts/`；
后者发生在101项既有行为及布局断言完成之后，修正为原生获赞记录地址后，
完整58项点击阶段单独复跑通过，产品源码未改动。汇总明确记录两个阶段及原始失败来源。
没有JavaScript运行异常或缺失本地脚本/样式；控制台500来自合成失败重试，
外部资源由离线拦截，均未删除诊断记录。

| 布局 | 浅色 | 深色 |
| --- | --- | --- |
| 电脑1280px | [页面](1280-light.png) | [页面](1280-dark.png) |
| 折叠侧栏900px | [页面](900-light.png) | [页面](900-dark.png) |
| 手机390px | [页面](390-light.png) | [页面](390-dark.png) |
| 窄屏320px | [页面](320-light.png) | [页面](320-dark.png) |

2026-10-18用户授权后已发布；确切线上合并源及验证见[本次发布](../../deployments/notifications-layout-20261018/README.md)。本目录保留发布前审阅证据。
