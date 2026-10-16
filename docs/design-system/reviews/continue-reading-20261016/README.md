# 帖子底部继续阅读列表 · 2026-10-16

用户已确认设计及实施方案，并选择让“新帖与未读”和“相关话题”共用轻量列表。
本记录只覆盖普通话题详情底部；包含平铺与嵌套阅读入口，不扩展首页、正文、侧栏或私信。
设计方向已确认；用户随后明确授权上线，发布进度另见部署记录。
本目录保留实施阶段的确切源码和离线检查证据。

## 实现与复用边界

- `MoreTopics` 增加 `more-topics-content` 包装出口，参数为 `{ topic }`。
  原服务继续负责可用模式、选择、偏好、初始化和清理；没有主题接管时保留原模板。
- 主题直接使用 `suggestedTopics` 与 `relatedTopics`，不请求、过滤、去重或重排话题。
  未知插件模式和私信回退到原组件。空列表、加载和受限内容继续由原来源控制。
- 列表条目继承原 `TopicListItem` 的点击、历史和键盘方法，并使用 `TopicLink`、
  `DUserLink`、头像、分类、日期与图标 helper。分类、时间、回复入口分别保留原 URL。
  修饰键的键盘处理只绑定到标题，分类等其他链接继续保留浏览器键盘行为。
  标题内格式化内容沿用原行的指针处理，使混合文字方向和表情的点击仍落在原链接上。
- 头像只取真实 `creator`。数据缺失时使用项目 `/images/avatar.png`，没有作者则不生成资料链接。
  回复数来自原 `replyCount`，包括真实的零；没有新增逐条接口请求。
- 普通话题使用 `unread_posts`，嵌套话题只使用 `has_new_replies`。
  新帖保留原状态和无障碍文字，已读仅降低标题字重；必要锁定、归档与受限状态保留。
- `BrowseMore.topicBrowseMoreData` 共用原计数与 URL 计算，保留 `messageCount` 更新依赖。
  新帖、未读入口分别保留；“浏览全部”沿用分类或最新话题目标，零计数分支仍保留最新/所有分类入口。
  数量不从当前列表长度推算。原底部显示条件保持不变。

## 局部视觉来源

复用 A01/A04 及 C02/C03/C09 的语义配色、头像工程能力、链接和焦点处理。
新容器与排布来自本次用户明确规格：内容区宽度、16px 圆角、1px 边框、无阴影；
桌面24px/手机16px内距，36px/30px头像，84px最小行高，16px/600标题和13px元信息。
标题最多两行，连续字符可断行，手机标题跨满可用宽度，回复数移至元信息行。
600px断点沿用主题既有约定，没有增加全局尺寸、颜色或组件变体。

13px次要文字使用已有 `primary-high` 色阶，避免浅色主题 `primary-medium` 的低对比度。
已读标题通过局部原生变量保留正文色、降低字重；清除原行下边框，只保留单条1px分隔线。
背景、边框、强调和焦点继续使用 `--isbf-v2-*` 变量。新增变量仅定义在该组件内。
历史参考附件保持原字节，工作区其他未提交修改保留。

## 检查与复现

检查结果、源码摘要及截图保存在本目录；最终结果以对应 JSON 报告为准。
工具串行运行，单容器1GiB内存及内存加交换总量、0.5CPU、192进程，无网络或生产数据挂载。
启动前至少1GiB可用内存，低于512MiB停止；浏览器仅一个实例和页面，完成后删除工具容器。
完整预览论坛保持停止，所有 API 响应来自合成夹具。

```bash
python3 docs/design-system/reviews/continue-reading-20261016/prepare-browser.py
python3 docs/design-system/reviews/continue-reading-20261016/run-tool.py node /review/run-lint.cjs
python3 docs/design-system/reviews/continue-reading-20261016/run-tool.py python3 /review/check-final-build.py
python3 docs/design-system/reviews/continue-reading-20261016/run-tool.py python3 /review/check-browser.py
python3 docs/design-system/reviews/continue-reading-20261016/run-tool.py python3 /review/check-qunit.py
```

浏览器复用本机此前已缓存且互相匹配的客户端与插件代码，加载本次实际编译组件及样式。
启动前将实际 `MoreTopics` 模板安装到缓存类；该类的原生命周期字段保持相同。
计数、模式、条目点击、链接和渲染使用真实 Ember 服务与组件，没有手写替代 DOM。
缓存资源和生成物不纳入参考附件；复现需要已有离线工具和缓存镜像。

该检查不代表完整 QUnit、服务器权限回归或生产浏览器验收。
新增主题集成测试和核心出口测试仍由项目原有测试入口执行，现有 CI 门禁不变。

## 完成结果

- 对12个修改文件执行 `bin/lint --fix`；最后两处修正另行复查，ESLint、Prettier、Stylelint通过。
- 8份实际Glimmer源码及测试编译通过；实际主题变量、局部SCSS及中英文YAML解析通过。
- 完整Ember客户端的60项定向浏览器检查通过，包含原链接目标、阅读计数更新、两种来源与顺序、
  原生模式偏好、标题格式化内容点击、历史写入和可见键盘焦点。
- 320px、390px、1280px各检查明暗两套主题，无横向溢出，长标题最多两行，头像30px/36px，
  仅单条1px分隔线。元信息对比度分别为6.33:1和8.45:1；已读标题分别为16.45:1和15.24:1。
- 原生核心和主题QUnit入口均已尝试，因隔离环境没有Rails测试服务器而未执行（0项）；不记作通过。

证据见[浏览器报告](browser-report.json)、[lint](lint-status.json)、[最后修正lint](lint-revision-status.json)、
[模板编译](compilation.json)、[样式编译](style-compilation.json)、[QUnit入口记录](qunit-attempts.json)
和[确切源码及摘要](source-manifest.json)。浏览器报告保留一条资源`ERR_FAILED`；离线夹具拦截外部请求，
没有浏览器运行异常或缺失本地代码/样式资源。

| 宽度 | 浅色 | 深色 |
| --- | --- | --- |
| 320px | [截图](320-light.png) | [截图](320-dark.png) |
| 390px | [截图](390-light.png) | [截图](390-dark.png) |
| 1280px | [截图](1280-light.png) | [截图](1280-dark.png) |

另有[相关话题模式](related-desktop-dark.png)。这些截图使用合成数据，不代表生产内容或权限回归。

实际发布与恢复见[部署记录](../../deployments/continue-reading-20261016/README.md)。本目录保留实施检查时的源码快照。

2026-10-17用户将容器改为直角；本目录的初版源码和截图保留，最新单字段源码及验证见[直角修订](../../deployments/continue-reading-20261016/square-border-20261017/README.md)。
