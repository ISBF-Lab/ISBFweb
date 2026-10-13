# 简历插件前端验证

2026-10-13 的网页反馈版本新增生成确认、英文入口、加载状态和取消后的焦点恢复，验证范围扩充为 21 个场景。当前结果及准确的原生/浏览器运行范围见 [反馈验证](FEEDBACK_20261012.md)。下文保留 2026-10-12 的 PNG 预览基线记录，旧 runner 的计数不代表本轮候选。

已验证基线：原生 runner v8 的 15 个 QUnit 场景全部通过，0 skip、0 todo、0 fail，无 deprecations，包括 DOCX/PDF 的原生下载导航回归。测试在任务独立开发容器中使用真实 Chromium 151、FormKit 和 UI kit。随后根代理在真实页面确认两种文件均触发下载并保留简历编辑页。

当前候选将浏览器内嵌 PDF 预览替换为同一份 PDF 的逐页私有 PNG，修正阶段栏宽度，并扩充为 16 个 QUnit 场景。lint-v7 的 39 个文件通过，后续单文件 lint-v9 及 css-lint-v2 通过；插件真实 main/test bundle 已编译。最新 QUnit-v11 实际运行全部 16 项且全部通过，0 skip/todo/fail，无 deprecations。真实逐页图片、两色文件、手机与明暗验证见 [真实页面记录](BROWSER_QA.md)，用户验收待进行；v8 结果不用于证明新增图片行为。

| 文件 | 覆盖行为 |
| --- | --- |
| `test/javascripts/unit/lib/resume-data-test.js` | 原文保留、编辑元数据隔离、删除后顺序与服务端字段错误映射、模板切换仅更改颜色值 |
| `test/javascripts/integration/components/resume-fields-test.gjs` | 全部 58 控件说明持续可见，文字控件、勾选和自定义照片的说明关联，以及自定义照片的服务端错误标记 |
| `test/javascripts/integration/components/resume-preview-test.gjs` | 示例明确标识且不可下载、逐页私有 PDF 图片地址与本地化页码、两种文件的 Core 原生导航条件、失效或修改后撤回全部页面与文档链接、旧生成结果没有预览图片时仍可下载 |
| `test/javascripts/integration/components/resume-editor-test.gjs` | 跨阶段必填校验、删除经历不串行、模板实际提交、生成后失效状态、服务端错误保留草稿并在首次失败和收起后重试时展开模块 |
| `test/javascripts/integration/components/resume-photo-test.gjs` | 实际 PNG 解码和 FileReader 读取、无效文件不会替换原照片、移除照片不残留占位、后继无效选择和组件销毁均释放前次读取状态 |

组件测试调用当前 Core 的真实 FormKit、DTabs 和 UI kit。生成网络边界使用标准 Pretender 响应；机械生成、鉴权下载和完整站点浏览器验证由后端及隔离应用验证覆盖。

下载回归使用真实渲染的 DOCX/PDF anchor 与浏览器 `MouseEvent`，调用公开 `discourse/lib/intercept-click` 的 `wantsNewWindow(event, link)`，验证普通左键点击也会走原生导航，并检查 `download=""`、`target="_blank"`、`rel="noopener noreferrer"`。未 stub 业务组件或路由函数；保留文件 URL、实际 PDF 独立打开地址和编辑后的全部链接撤回断言。当前 Core `backup-codes.gjs` 使用同样的 DButton 原生下载属性；实际文件响应和草稿留在原页面由独立应用验收验证。

逐页预览使用生成响应中的 `preview_urls`，例如 `/isbf-resume/exports/<uuid>/previews/1`，从第 1 页顺序展示全部页面，沿用既有纸面和间距 token。图片来源由后端从本次 PDF 渲染，不替换成模板示例。组件测试验证 URL、页数、页码说明及 URL 撤回；PNG 字节、与下载 PDF 的一致性、owner/expiry 权限和实际加载由后端及真实浏览器验证覆盖。即使仅 `stale` 或仅 `unavailable` 为真，组件也移除全部页面和下载/打开链接。旧 metadata 的空预览数组显示重新生成说明，同时保留仍有效的 DOCX/PDF 下载。

2026-10-11（Asia/Taipei）只读核对当前服务器 Core API，缓存位于本地 `.local/resume-dev/frontend-test-audit/`。FormKit `@type` 明确时产出的 field 包含 `describedBy`，自定义照片控件需显式传入该属性；`custom.Control` 不自动将说明关联给内部 input。

另核对实际 `ajax.js` 的异常对象包含 `jqXHR`，现有 `jqXHR.responseJSON` 读取与接口一致。FormKit 的 `unregisterField` 会移除字段错误，删除记录不会保留已移除控件的错误；ErrorsSummary 展示提供的 `title`，测试要求使用可读字段名称。

2026-10-12 最新原生结果：`/src/tmp/resume-qunit-v8.log` 与 `.exit`，exit 0。新增原生下载导航、`wantsNewWindow` 和旧链接撤回断言所在 Preview 场景用 13.334 秒通过。保留 Core 官方 a11y 测试辅助接口的成对恢复，未新增 timeout 或业务 stub。`bin/lint --fix` 对 39 个明确候选文件全部通过，用 38.70 秒，日志 `/src/tmp/resume-lint-v6.log`。

命令使用 Core 公开 direct 模式：`bin/qunit --rails-port 4579 --qunit-path /tests --target isbf-resume --parallel 1`。受限容器的完整 Core 构建未成功；本次组件检查复用了已逐项确认 4206 个公开前端源码相同、前端及 asset-processor 依赖 importer 相同的缓存测试产物。这不是一次新 Core 构建或生产锁文件完全一致证明。v7 后曾验证交互预览恢复本任务新鲜生产快照中的原始前端产物，全部文件 SHA-256 与之前保留的备份一致；候选插件独立重新编译，主包和测试包 manifest 均验证存在。v8 后的真实网页下载通过；IAB 对独立 PDF 也显示灰色，因此当前候选使用逐页 PNG 展示实际 PDF，不再依赖浏览器 PDF viewer。

## 实际启动记录

2026-10-12（Asia/Taipei），在任务独立容器 `isbf_resume_workbench_20261011_211314_app` 首次调用 `bin/qunit`，浏览器未进入测试，30 秒 watchdog 失败。实际 `/tests?target=isbf-resume` 的控制台给出根因：`Could not find module discourse/form-kit imported from (require)`，发生于 `loadPluginFromModulePreload`。

当前 Core 的 `docs/developer-guides/docs/03-code-internals/22-form-kit.md` 第 20 行明确提供公开导入：

```javascript
import Form from "discourse/components/form";
```

不能假设 `discourse/form-kit` 或 `discourse/form-kit/index` 是插件可导入的 barrel。业务组件和对应测试已统一改为上述公开 default import，由根代理同步后重新编译；最终覆盖结果见本文当前状态。

修正导入后的实际 IAB 页面运行结果为 15 项中 14 项通过、1 项失败，53/58 个 assertions 通过。唯一失败是 58 字段说明场景在首次渲染时仅出现一个字段，抛出 `FKFormData.get` 的 `undefined.name`。现行 `FKFormData.get(name)` 按 `basic.name` 逐级取 `draftData.basic.name`，不会创建缺失对象；该测试未传 `@data`，导致 `basic` 不存在。测试已传入与编辑器相同的 `emptyResume()`，为各 Object 提供空对象。58 控件、全部可见说明、逐项 ARIA 关联和服务端照片错误标记的验证均完整保留，并在原生 v7/v8 通过。

原生 runner v4 使用 Core 公开 direct 模式 `bin/qunit --rails-port 4579 --qunit-path /tests --target isbf-resume --parallel 1`，运行同一批 15 场景，14 项通过、1 项失败。58 字段说明场景已通过；剩余失效提示断言依赖 `.isbf-resume__preview`，该节点属于响应式侧栏或可销毁阶段。DOCX 生成存在与编辑后撤回断言均通过。测试已将失效提示定位到所有屏幕都有的 `.isbf-resume__form .form-kit__actions`，等待实际提示后验证可见内容，并增加模板、生成预览和编辑阶段的 `data-stage` 验证。该修正在原生 v7/v8 通过。

原生 runner v5 同 15 场景中 14 项通过；失效提示场景完整通过。唯一失败是两次 422 的字段错误场景触发 `ember-qunit@9.1.0` 默认 60000 ms 测试上限，deadline 时仍有一个 AJAX 请求与 a11y 的 `#scheduleClear` timer。该场景在 v4 用 29.476 秒通过，v5 用 88.763 秒并触发 timeout；这不是字段、草稿或重新展开断言失败。

现行 Core `services/a11y.js` 提供 `disableClearA11yAnnouncementsInTests()` 和 `enableClearA11yAnnouncementsInTests()`。测试仅在 ResumeEditor 模块的 `beforeEach` / `afterEach` 中配对调用，省去默认 2000 ms 的消息自动清除等待；真实 a11y service、live-region 写入、生成请求、原 PDF fixture 和全部状态/错误断言均保留。没有修改 Core、业务或全局 timeout，该修正在原生 v7/v8 通过。

原生 runner v6 在 Chromium 启动阶段失败，未进入 15 项。已核实 stderr 为 `pthread_create: Resource temporarily unavailable`，owned cgroup 的 PID 上限被未回收的僵尸进程占满。根代理仅重启同一任务独立容器并保留数据库及 CPU、内存、PID 限制，再运行同一批场景；此次启动错误不能列为业务断言失败或通过。

## 当前 Core 样式核对

以下结论来自本次只读获取的现行源码，作用范围仅限已确认的简历区域。

- FormKit `_variables.scss` 默认 medium input 宽度为 200 px，`_container.scss` 通过 `--full` 修饰符提供整栏宽度。字段应使用公开 `@format="full"`，包括模板选择；它同时避开 textarea 的非 full `fit-content !important` 规则。
- 标签和说明分别是 `.form-kit__container-title` 与 `.form-kit__container-help-text`。默认说明使用 `--primary-medium`；R02 已确认必读说明使用 `--isbf-v2-text`，需在简历作用域内命中真实 selector。
- FormKit `default-input` 的边界和内距带 `!important`。R02 的本地输入样式只能用同作用域窄覆盖，并说明原因；错误边界须保持同样优先级，不能仅通过普通 `border-color` 声明覆盖。
- checkbox 的真实 input 使用 `opacity: 0`，焦点需显示在紧邻的 `.form-kit__control-checkbox-checkmark`。普通 input 描边不足以形成可见的键盘焦点。
- DTabs 可在组件 root 传入 `.isbf-resume__stages`，局部调整 `--d-nav-*` 变量与 `.d-tabs__tablist` / `.d-tabs__tab`。三阶段沿用 C05 通知页的分隔线、等分布局和选中下划线；保持 DTabs 原有 ARIA、键盘与横向溢出行为。选中变量采用 accent、选中文字显式使用 text，保留 Core `nav-active` 的 forced-colors `Highlight` 下划线规则。
- 实际页面的 FormKit root 使用 column flex 与 `align-items: flex-start`，导致 DTabs 按内容收缩。当前候选只为 `.isbf-resume__stages` 增加 `width: 100%`，使三个阶段和内容占满已批准表单宽度，不覆盖全局 FormKit 或其他 ui-kit 组件。

已核对 `common/ui-kit/d-tabs.scss`、`common/foundation/mixins.scss` 的 nav mixin，以及 `common/form-kit/` 中 container、field、input、textarea、radio、checkbox、default-input 与 variables 的完整相关规则。缓存为只读依据，不作为替换服务器文件的发布包。

## PNG 候选的原生复验

QUnit-v9 因 Puma 首次冷启动健康检查超时没有进入测试；应用预热并返回 200 后，QUnit-v10 执行全部 16 项，15 通过、1 超时，0 skip/todo，无 deprecations。逐页图片与 alt、stale/unavailable 撤回、旧 metadata 可下载、原生下载导航及全部 58 控件说明均通过。

唯一超时场景连续执行两次 422 请求，并验证草稿保留、稳定字段、可读错误摘要、模块展开、手动折叠及再次展开；日志显示耗时 85.569 秒。仅该场景设置 `assert.timeout(120_000)`，保留所有交互和断言，不修改全局 timeout 或业务代码。该 API 按测试覆盖等待上限，见 [QUnit 文档](https://qunitjs.com/api/assert/timeout/)。修改后的单文件 lint-v9 通过。

QUnit-v11 虽传入单例 filter，但 direct runner 的 plugin target 实际执行全部 16 项；以实际 TAP 为准，16/16 通过，退出码 0，无 skip/todo/deprecations。两次错误重试场景在 88.499 秒完整通过。日志 `/src/tmp/resume-qunit-v11.log`。最终交互预览恢复到此次新鲜生产资源快照，逐个文件 SHA 校验一致；未修改正式环境或共享缓存。
