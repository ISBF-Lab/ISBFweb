# 工作台排序与图标统一配置

2026-11-20；源码仓库 `ISBF-Lab/ISBFweb`，目标分支 `main`，开发分支
`codex/workbench-entry-configuration`，基线 `e69bfa59825a89800215a765ecf5091a678eca0d`。
本轮交付主题实现、定向测试和交接。原生环境验证尚未完成，未合并或发布。

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
- 图标清空、类型错误或不在当前图标清单内时保留入口原有电脑/手机图标。
- 无效或默认 tone 保留原色调，不引入显式色板。
- 完整合并后才执行原有业务能力判断；功能关闭期间不改持久值，重新开启恢复配置位置。
- 名称、链接、占位入口和权限不从设置读取。输入与默认列表均不被合并过程修改。

## 图标与资源

复用原生对象字段 `type: icon` 和 `DIconGridPicker`，不维护另一份图标库。
原生 `SvgSprite.theme_icons` / `objects_setting_icons` 会扫描对象图标字段并将保存值纳入主题资源。
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

当前 Windows 会话没有 Ruby、Bundle 或 Docker。仅有的 WSL Ubuntu 已停止；没有启动它或完整论坛。
未找到 `./dev` 或 `theme-sync`，也未获得独立开发站 URL、主机连接或同步目录。
最新 CI 等待状态已核对：worker 未运行，记录均为 delivered/cancelled，无活动等待。
原有工作树和任务内容保持。

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

规定命令的阻塞：`bin/lint --fix` 所需 Ruby 不存在；默认 pnpm 为 11.25.0，
仓库要求 pnpm 10.34.5 / `^10`，两条 `pnpm …:menus` 被 engine 检查阻止。
未修改依赖锁或工程约束；Node 直接执行的菜单脚本与 package.json 指向相同。

已补充、尚未在 Discourse 运行的测试：

```bash
bin/qunit themes/isbf-campus-feed/test/unit/workbench-entries-test.js
bin/qunit themes/isbf-campus-feed/test/unit/workbench-colors-test.js
bin/qunit themes/isbf-campus-feed/test/unit/workbench-glass-lifecycle-test.js
bin/qunit themes/isbf-campus-feed/test/integration/workbench-test.gjs
bin/rspec themes/isbf-campus-feed/spec/requests/workbench_entries_spec.rb
bin/rspec themes/isbf-campus-feed/spec/system/workbench_entries_spec.rb
```

请求测试覆盖管理员保存、重读、清空、默认恢复、首次 sprite 请求和普通用户/moderator 写入拒绝。
系统测试覆盖移动按钮边界、Enter 与焦点、预加载图标选择、保存重载、清空和默认恢复。
恢复原生环境后使用 Ruby 3.4 与冻结锁要求的工具，串行执行测试和规定 lint/menus，
再核实独立开发站归属及资源后执行其真实 `./dev theme-sync`。
开发站需补充真实页面的两布局、两端、明暗及 390/430/600/601/768/1024/1440px、键盘和对比度验证。
静态离线预览不替代原生表单、服务端权限、主题资源加载或真机验收。
