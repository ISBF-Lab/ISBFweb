# 工作台排序与图标统一配置

2026-11-20 实现，2026-11-21 补充 CI 证据。源码仓库 `ISBF-Lab/ISBFweb`，目标分支 `main`，开发分支
`codex/workbench-entry-configuration`，基线 `e69bfa59825a89800215a765ecf5091a678eca0d`。
当前候选和生产验证进度见 [PR #117](https://github.com/ISBF-Lab/ISBFweb/pull/117)。

## 配置入口与格式

沿用活动主题的原生后台设置、对象编辑器、上下移动、保存及恢复默认功能。
只有现有主题设置接口允许的开发者（Discourse `admin`）能写入；本站 moderator
管理员和普通用户不因此获得写权限。没有新业务接口或数据库迁移。

`themes/isbf-campus-feed/settings.yml` 声明 `workbench_entries` 为 `objects`：

```yaml
workbench_entries:
  - key: library
    icon: heart
    tone: mint
  - key: learning_resources
    icon: ""
    tone: default
```

以上是设置值示例。`key` 是稳定业务标识，不控制名称、链接或权限。
`icon` 可空，`tone` 为 `default`、`theme`、`mint`、`amber`、`violet`。
两端共用此配置，保存后刷新工作台。两端各自的传统/玻璃布局选择继续独立。
原生 enum 显示稳定英文值，中英文说明给出对应的默认、主题色、薄荷绿、琥珀色、紫色。

最新基线实际有 **13 个**入口，需求中的 11 个已不适用。原始顺序为：

1. `learning_resources`（课程资源）
2. `library`（资料库）
3. `courses`（课程专区）
4. `careers`（求职实习）
5. `resume`（简历工具）
6. `campus_services`（校园服务）
7. `student_identity`（学生身份）
8. `alumni`（校友）
9. `marketplace`（商城）
10. `teamup`（组队）
11. `mbti`（MBTI）
12. `ai_assistant`（AI 助手）
13. `guides`（使用指南）

默认包含全部入口，图标留空、色板为 `default`。是否实际可见或可点击仍由原业务能力决定。

## 合并与回退

`workbench-entries.js` 在功能判断前按固定 key 生成完整配置：

- 按保存顺序取已知入口；重复 key 只取第一项，未知或无效对象忽略。
- 未配置的已知入口按上述原始顺序补到末尾。
- 缺失设置、非数组旧值和空数组均恢复原始顺序和显示。
- 图标清空、类型错误或原生资源中缺少对应符号时保留入口原有电脑/手机图标。
- 无效或默认 tone 保留原色调，不引入显式色板。
- 完整合并后才执行原有业务能力判断；功能关闭期间不改持久值，重新开启恢复配置位置。
- 名称、链接、占位入口和权限不从设置读取。输入与默认列表均不被合并过程修改。

## 图标与资源

复用原生对象字段 `type: icon` 和 `DIconGridPicker`，不维护另一份图标库。
原生 `SvgSprite.theme_icons` / `objects_setting_icons` 会扫描对象图标字段并将保存值纳入主题资源。
主题从页面 SVG sprite 检查图标是否可渲染。首次进入工作台时，异步到达的符号会替换回退图标。
所选图标用于两端和两种布局；清空恢复各入口原来的变体。
玻璃 glyph 支持 `currentColor` 实心图形，并保留已有 `fill="none"` 线条图形。
指南针的放大仅作用于原指南针图形，替换图标不继承放大。

**本轮明确保留的限制：** 共享对象图标字段未传 `onlyAvailable=false`，只能搜索当前可用子集。
2026-11-20 用户明确选择“暂不修改 Core，先交付其余部分”，因此未修改共享字段。
完整内置库搜索尚未实现；不能将预加载图标的选择测试写成完整库搜索通过。
若后续批准，最小改动为 `frontend/discourse/admin/components/schema-setting/types/icon.gjs`
向共享选择器传入 `@onlyAvailable={{false}}`，并验证搜索、保存、首次访问和资源缓存。
升级需复核该字段与选择器 API；插件替换后台组件或预载全库均增加维护或加载成本。

## 配色与绘制

传统布局：选中色板用于图标及底色；玻璃布局：用于背板。
未显式选择色板时保留原显示。电脑玻璃顺序固定为：

**有效单入口精确 HEX → 显式预设色板 → 有效统一精确 HEX → 原主题颜色。**

仅接受完整 `#RRGGBB`。手机玻璃不使用旧电脑精确颜色，但仍使用选中的共享色板。
精确颜色始终按 key 查询；色板属性写在同一入口 DOM 上。
绘制器按排序后的 DOM 顺序读取几何、背板与前景，避免重排后颜色或点击目标错位。

配色复用 A08/C02 与 `stylesheets/workbench.scss` 的来源：主题 accent；
薄荷 `#35b595`、琥珀 `#e5a659`、紫 `#9480d8`；传统底色混合比例为 15%/19%/21%/19%，
玻璃为 92%，均与原 surface 混色。显式色板的传统图标按同一比例与原 text 混色，改善明暗对比。
玻璃前景继续由背板亮度选择现有对比色。来源和限定范围见
[设计记录](design-system/reviews/workbench-entries-20261120/README.md)。

## 验证与接续

Windows 开发工作区缺少 Ruby、Bundle 与 Docker。已授权主机上的独立 `discourse_dev`
检出为 `de585fb1654ac6e667f33d42902e7fd94350bc9e`。3000 端口返回空响应，未发现
历史 `./dev theme-sync` 入口，开发域名指向另一地址。独立站同步及真实页面验收待补。

已执行：

- 直接调用仓库已有依赖的 Prettier、ESLint、Stylelint，定向修复后复查。
- Node VM 直接执行 4 份实际 QUnit 单元文件：37 项、192 条断言通过；这是轻量源码执行，未加载 Ember。
- `node --test script/check-menus-test.mjs`：5 项通过。
- `node script/check-menus.mjs`：全量扫描 3303 文件，5 个既有 Windows 路径兼容问题；
  允许列表使用 `/`，`normalized()` 返回 `\`，导致 4 个已登记 popover 和原生 select 载体误报。
  定向检查本次 6 个产品文件无发现。未修改检查器或放宽规则。
- `git diff --check` 通过。最终源码摘要和静态浏览器结果在工作区
  `task-artifacts/20261120-workbench-entries/`，交接时保留原始快照。
- 离线 Chrome 静态预览 56 组：7 个规定宽度 × 明暗 × 两端独立的 4 种布局组合。
  无横向溢出、不可见标签、布局选择或排序绑定错误；13 个 key 的线条/实心填充计算均通过。
  标签和显式色板图标最低对比度 4.909:1，Tab 可进入首个排序后链接并显示焦点轮廓。
  预览使用实际 tokens、SCSS 嵌套展开、图标路径、合并模块和真实玻璃静态回退；
  未加载原生 sprite、Ember 后台或 WebGL。已核对 11 份来源摘要且关闭任务浏览器。

使用仓库指定的 pnpm 10.34.5 执行 `pnpm test:menus`，Windows 通过 5 项。
在 Linux 主机的独立任务目录运行 `pnpm lint:menus`，扫描 5,912 文件零发现；
该目录下 `pnpm test:menus` 通过 4 项，余下一项缺少 ESLint 依赖。

候选 `0caa34d4bdc337545e61bba0785462c64cdd5d18` 的原生 CI 结果如下。

- `current` 和 `production-132` 各通过 6 项后台请求及浏览器系统规格。覆盖管理员保存、重载、
  清空、恢复默认、键盘和移动边界、首次 sprite 请求、普通用户及 moderator 写入拒绝。
- 两套完整主题 QUnit 各运行 320 项，318 项通过，2 项选择图标的渲染断言失败。
  原判断依赖只在开发模式初始化的图标表。后续候选改为验证原生 sprite，并增加资源晚到回归。
- 两套 `bin/lint --fix` 均修复了 Ruby 系统规格的冗余 `type: :system`，源文件校验因此失败。
  后续候选已纳入该原生修复，等待对新提交重新验证。

候选 `d8ff5dcbb6f79f000082767326ae2897753e3cb8` 的两套原生 CI 各通过 6 项后台规格、
39 项插件规格和 19 项 MBTI 浏览器规格。主题 QUnit 各通过 320/321，已选图标和首访资源晚到用例均通过。
剩余 QUnit 断言把 grid 的画布计为入口。本次改按入口 key 比较功能关闭后重新开启的完整顺序、色板和图标。
Ruby 请求规格已同步 CI 产物中的原生 Syntax Tree 格式。后续候选待检查通过后发布。
[原生 CI](https://github.com/ISBF-Lab/ISBFweb/actions/runs/44888516821)

定向复验命令：

```sh
bin/qunit themes/isbf-campus-feed/test/integration/workbench-test.gjs
bin/rspec themes/isbf-campus-feed/spec/requests/workbench_entries_spec.rb
bin/rspec themes/isbf-campus-feed/spec/system/workbench_entries_spec.rb
```

开发站需补充真实页面的两布局、两端、明暗及 390/430/600/601/768/1024/1440px、键盘和对比度验证。
静态离线预览不替代原生表单、服务端权限、主题资源加载或真机验收。


## 工作台入口临时停用

2026-11-22 的维护功能以 [PR #117 合并后的 main](https://github.com/ISBF-Lab/ISBFweb/commit/826dc60845ebb44e775477ac7b9ba66f6dd2305e) 为开发基线。新版代码、隔离验证及发布回执按本节记录。

### 开发者操作

在「外观 → 主题 → 活动主题」打开 `workbench_entries` 编辑页，展开顶部的「工作台维护」。勾选某项的「暂时停用」，点击该项旁的原生保存按钮。取消勾选并保存即可恢复。启停保存成功后，工作台刷新可见变化。全部停用时显示「暂无可用入口」。

`isbf-workbench-maintenance` 插件通过原生站点设置保存 `isbf_workbench_pause_<key>`。每项默认为 `false`。只有开发者可以读写原生后台设置，保存记录进入原生站点设置操作日志。普通用户刷新时读取客户端的布尔状态。服务端自行读取站点设置并判定业务请求。

原有 `workbench_entries` 仍保存顺序、图标和色板。移除配置行或恢复主题默认值时，已停用的入口继续停用。恢复后按当前主题配置和原业务权限显示。主题沿用统一的卡片列表，保留手机与电脑各自的布局选择。

### 服务端范围

| 入口 | 暂停范围 |
| --- | --- |
| `learning_resources`、`library` | 两个独立设置。分别检查专用页面、课程及目录接口、投稿和资料写入。已暂停的课程资源同时关闭私有文件下载和课程审批。 |
| `careers`、`marketplace`、`teamup` | 各自的页面、专用主题筛选、业务发帖与首帖写入。商城的上传、原图与缩略图使用同一门禁。 |
| `resume`、`mbti`、`guides` | 专用页面及业务 API。覆盖简历生成、分享写入与审核，MBTI 问卷与结果，以及指南详情与受保护图片。指南的独立开发者编辑后台可用于修复。 |
| `alumni` | 校友目录、地理、个人资料与身份查询、申请及证明接口，以及校友申请审批和已绑定邀请的兑现。 |
| `ai_assistant` | 本站论坛助手的会话、状态、生成及对应的共享会话与发帖操作。通用 AI 和其他代理沿用原配置与权限。 |
| `courses`、`campus_services`、`student_identity` | 隐藏工作台占位卡片。 |

暂停的业务页面与专用请求返回原生 404。共用请求按业务筛选标识、类别、专用字段或助手会话识别。已有帖子的原生阅读由原论坛权限决定。专用接口保护的附件也受同一业务开关控制。恢复时继续检查该业务原来的启用状态与权限。

### 验证记录

| 检查 | 本轮状态 |
| --- | --- |
| 本地静态检查 | 改动的 Ruby 文件通过 3.4.7 语法检查。主仓库 Ruby 源码已执行 Syntax Tree 格式化，改动 GJS 通过 Prettier 和 ESLint。YAML 解析及 Git 差异检查通过。 |
| 原生 lint | Windows 的 `bin/lint --fix` 在中文工作区路径的 Ruby `File.realpath` 调用处退出。隔离 Linux 工作流对 PR 变更运行原生修复，并检查是否改写候选源码或锁文件。 |
| 菜单检查 | `pnpm test:menus` 通过 5 项。`pnpm lint:menus` 在 Windows 扫描 3711 个文件，复现 5 个旧路径兼容问题。Linux 结果随前端 CI 记录。 |
| 原生请求与浏览器 | 集成 CI 加载五个独立插件的精确候选。覆盖旧书签、业务读写、私有下载、权限、恢复、旧主题设置、键盘、全部停用及明暗模式下两组独立布局。精确提交的 CI 结果待回执。 |

已获准的工作台设计继续沿用 [现有主题设计记录](design-system/reviews/workbench-entries-20261120/README.md)。后台沿用原生主题编辑扩展点及站点设置行。Linux 的 MBTI 兼容工作流还会验证 production-132 的主题基线。真实运行版本与隔离站同步须以发布前的重新核验为准。

首轮 CI 对候选 `a2710fd6b888a01cbfe4f97543b8f7c99888b575` 完成 Linux 定向原生 lint、323 项主题 QUnit 和 5913 文件的菜单扫描。菜单零发现。七条工作流中五条通过。插件回归与工作台联测分别报告 4 项和 7 项请求失败，本轮新增的后台与布局浏览器规格等候复验。[前端 CI](https://github.com/ISBF-Lab/ISBFweb/actions/runs/45003306924) · [插件回归](https://github.com/ISBF-Lab/ISBFweb/actions/runs/45003306877) · [工作台联测](https://github.com/ISBF-Lab/ISBFweb/actions/runs/45003306959)

复验候选在 HTML 外壳渲染前检查课程资源和资料库的停用值，并让镜像的直接下载进入原有鉴权与文件响应。请求规格按名称读取原生设置，业务测试替身完整实现门禁方法。招聘、商城和组队的独立 CI 采用同一 Ruby 3.4 镜像，保留各自的 Core 版本。联测固定到更新后的插件提交，并在隔离数据库和浏览器资产就绪后记录浏览器结果。

### 发布与回退

1. 核对主 PR 和各独立 PR 的精确提交、完整检查与未解决审查。记录用户授权、本次服务端候选和活动主题来源。
2. 按实际运行版本盘点 Core、所有插件和生效主题，核对代码、链接、隐藏条目及资源摘要。备份受影响的插件文件、主题字段与覆盖值，并备份 13 个站点设置的当前值及是否存在覆盖。
3. 先发布 13 项站点设置和各业务服务端门禁，核对所有工作进程加载同一组代码。随后发布后台组件及主题增量，确认资源回执。所有写入测试留在隔离库。
4. 必要时优先按发布后摘要回退后台组件及主题字段。保留生产已经生效的停用状态，以及继续执行这些状态所需的服务端设置定义和业务门禁。遇到后续更改先做三方审查。无法维持已停用业务时保留门禁并修复，等候核对后再继续发布。
