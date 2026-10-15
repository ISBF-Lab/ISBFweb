# 工作台简历页面实施依据

2026-10-11（Asia/Taipei），用户在六张设计稿的确认问题中回复：**“确认，按这版接入开发预览”**。

确认范围为 `design/` 中 R01–R06 的桌面浅色、桌面深色、模板选择、手机表单、手机预览及字段状态；适用于简历页面实现和任务独立开发预览。该确认不代表真实网页功能验收，也不授权正式部署。

参考包 SHA-256：`6999688e5ad99d774440a1a8672158c0c041fac1963228dc888b2f8a98006631`。设计基线提交：`a9ec933`。服务器开发指引 SHA-256：`fb40c26d29baef74bb0c98f86783e020f98aa67e5fe0157a3fe0894307bef065`。当前参考、运行主题字段及配色来源见 `design/source-audit.json`。

沿用已有工作台外壳、侧栏、移动导航和配色变量；字号、间距、8/16 px 圆角及响应式分界沿用设计规范。仅简历区域增加表单和预览布局，不增加全站 token。

| 设计元素 | 实施组件 |
| --- | --- |
| 三个编辑阶段 | UI kit `DTabs`，支持键盘操作 |
| 字段、必填校验、说明、错误摘要 | FormKit `Form`、`Object`、`Field` |
| 按钮与下载链接 | UI kit `DButton` |
| 可展开补充信息和经历 | 原生 `details` / `summary`，保留浏览器键盘行为 |
| 私有照片 | FormKit custom control；本地读取文件，随同本站生成请求提交 |
| 完成、失败及更新提示 | 原生 FormKit 错误状态与 `a11y.announce` |
| 文档预览 | 同一 PDF 经本地 Poppler 渲染的私有逐页 PNG；按页展示实际文件 |

简历模板仍只有颜色不同。输入内容原文进入机械生成程序；没有 AI、外部生成 API、自动改写或论坛公共附件上传。

网页预览使用固定本地 `pdftoppm -scale-to 1400 -png` 参数，保留 PDF 的全部页面，限时 45 秒并校验 PNG 与页数。图片按当前用户和有效期保护，网页无需原生 PDF 阅读器或 iframe 即可显示实际简历。下载仍为同一原 DOCX/PDF；旧记录没有预览 metadata 时仍可下载，重新提交内容生成新记录可获得逐页图片。这一展示方式沿用已确认的纸张、分页与完成状态，不扩大 R01–R06 的视觉确认范围。

经历条目使用 FormKit 公开的 `Object` API，并以稳定的 UUID 标识。当前 Core 的 `Collection` 按数组位置生成键；这里使用对象条目，避免删除前一条经历后重用后一条的控件和照片状态。提交时再转换为生成器要求的数组，视觉和填写规则沿用已确认设计。

## 2026-10-12 网页反馈增量

用户根据实际开发页面明确要求：扩大截断示例的填写框、区分示例与输入文字、在基础校验后确认生成、立即切换预览并显示一页与留白建议，以及提供英文版确认入口；随后明确要求保留“短时间内无法多次生成”的提醒。这些直接指令作为本轮开发预览的变更依据，不是正式上线授权。

源版本基线为插件提交 `015c482`，本轮具体源文件和校验摘要由任务候选 manifest 记录。长基本信息和链接采用现有 `--full-row`，经历中文字控件采用同一整行规则；间距、输入尺寸和说明关联不变。placeholder 局部使用 `text` 65% 与 `surface` 35% 的混合色；标签和填写内容保留 `text`，不新增全局颜色。

新增确认流程使用 Core `modal.show` 与 UI kit `DModal`、`DButton`。仅 `.isbf-resume-confirmation` 沿用当前简历预览面板的 surface、border、radius-md、space-4 和字号；最大内容宽度引用既有 feed-width，手机保留现有 32 px 页边空间。遮罩、Escape、焦点约束和焦点返回由原生 DModal 管理，不另造弹层或将此局部规则推广为全站 Modal 标准。英文说明、内容核查和频次提醒分段显示，提供“确认生成”与“返回修改”。

预览推荐文案在预览阶段持续显示。等待生成时使用同一预览面板的文字状态，并撤回示例、旧文档及下载入口，完成后显示实际 PDF 对应页面。英文输出切换固定栏目语言，继续保留用户原文；不调用翻译服务。本轮功能与真实页面验证结果见 [改进记录](../FEEDBACK_20261012.md)。

取消后的焦点复验发现 FormKit 异步校验期间原触发焦点可能变化。简历表单在公开 click/submit 捕获阶段记录触发控件，英文入口在调用公开 `submit()` 前记录；取消后使用 Ember 下一轮调度，在提交状态结束后恢复原控件焦点。DModal 继续管理弹窗焦点约束、Escape 和关闭动画，此处理仅补齐表单等待流程，不增加全站键盘规则。

## 2026-10-13 实际内容预览

用户明确要求“预览应该是用用户实际的信息渲染出来的”。基线为插件 `240361a`，增量限于 R04/R05 预览内容与更新状态，沿用已确认预览面板、空态文字、纸张和模板颜色，不新增控件或全站 token。

FormKit 当前草稿通过既有 `exportPayload` 契约交给 `ResumeDraftPaper`，浏览器直接展示当前字段、照片、经历、日期和段落，空字段与空模块省略。模板示例图继续用于两个模板 radio 的选择示例；填写页和预览阶段不再展示虚构内容。生成后的保护图片仍来自实际 PDF；旧版本失效后回到当前草稿，并撤回旧文件链接。

纸面样式的固定白底、正文 `414141`、标签 `666666`、蓝色 `4E7282` 和强调色 `C19F67` / `A5A5A5` 均来自既有 `resume_generator.py` 与 `resume_schema.json`；它们表示文档预览，不是网站 UI 色板。纸张比例、18/16 mm 页边、24/12/10.5 pt 文字和 32/17/16 pt 行高等按 210 mm 页宽缩放，保持正文和字距比例，不推广为全站尺寸。浏览器和 LibreOffice 字体度量及分页仍可能不同，页面提示生成后检查实际 PDF。

固定栏目标签在客户端两份 locale 的 `paper.zh` / `paper.en` 保存，值与 schema 及生成器一致，输出语言独立于网站语言；用户文字始终通过 Glimmer 转义，链接作为文字显示，照片只接受当前本地图片的 data URL。实际验证见 [实际内容预览](../LIVE_PREVIEW_20261013.md)。本轮仍为隔离开发预览，不构成正式部署授权。

## 隔离预览的依赖来源

2026-10-12，七个缺失的主题 SCSS 导入依赖已从用户提供的已验收参考包补齐到独立、非默认的预览主题 ID 2，逐份 SHA-256 与该包的 `manifest.json` 匹配。参考版本为 2026-10-10 主题 4 快照，Core 基线 `c0f4739d143a4efbb4e7f19dafadcd56a5302a58`。这些 partial 与当前生产版本相等尚未核验；用途限于本次隔离预览补齐原有样式依赖，设计确认范围仍为 R01–R06。

新鲜运行版 `common.scss` 和现有同伴更新保留，本次简历规则采用增量接入。临时样式指纹仅在独立容器备份后由 Core 原生 API 重新生成，没有 Core 业务源码或正式环境写入。预览主题字段的样式错误已清空，默认主题保持 `-1`。桌面手机、明暗、阶段宽度、真实文件下载及多页图片验证已完成；手机主区仅增加父容器宽度约束，不引入新视觉 token。实际证据见 [真实页面记录](../BROWSER_QA.md)。用户网页验收仍待进行；资源恢复与验证边界见 [服务器架构记录](../SERVER_ARCHITECTURE.md)。

## 2026-10-14 简历紧凑页头设计确认

用户已批准[桌面预览图](resume-header-desktop-preview.png)，并要求按该方案实现。本次仅确认简历页头设计；按用户要求不增加浏览器或真机检查，实际页面的桌面/手机、明暗、键盘及返回行为尚未复验。既有 R01–R06 和后续审批继续有效；本图是设计证据，不是运行页面截图或整页验收。

实现基线为 ISBFweb `32c32fca205579be24741b33ee32c4b2d18ea99d`，分支 `codex/resume-header`。Course（课程资源）参考的已发布来源为 ISBF-UI `f72a86ca7435a489471c0fc53be2f2fc7e84ce83`，文件为 `stylesheets/learning-resources.scss`（`.isbf-learning__header`、`.isbf-learning__back` 及手机覆盖）和 `javascripts/discourse/components/isbf-resource-page.gjs`。实际读取工作目录为 ISBF-UI-solved-poll，HEAD `cc1eb7efb47b6229f1c6df5b1f81c4f60dce1496`；两文件 SHA-256 分别为 `797861cf64e9c0f1aebedb6fa719cb0e2b28aff0656c33c5caf957cab3878348`、`ebe9a428a5605a537e986b8cdf81f5c8e13b9bb8754357ba3c9f18291fecbddd`。两文件已与上述已发布提交比较，无差异。工作目录 HEAD 不证明线上版本，本次不扩大课程页其他区域的批准范围。

批准以正常文档流中的单行“← 简历”替换独立返回链接和大标题，取消桌面 92px / 手机 82px 顶部留白，不使用 sticky/fixed。返回仍为 `/isbf/workbench`，保留 h1、链接语义、可见焦点和至少 44px 点击高度。现有说明、阶段 tabs、表单及预览自然上移；填写、确认生成、草稿、下载及预览行为沿用已有规则。

页头局部 token 映射与 Course 一致：桌面纵向 space-4（16px）、返回横向 space-3（12px）、gap space-2（8px）、20px 箭头和 font-xl（20px）；width <= 600px 时纵向 space-2（8px）、返回横向及 gap space-1（4px）、18px 箭头和 font-md（16px）。标题 margin 为 0、字体继承站点字体；沿用 `--isbf-v2-text`、`--isbf-v2-surface`、`--isbf-v2-focus-ring`，底部分隔线为 `1px solid var(--isbf-v2-border)`。不新增全站 token，不引入课程目录列宽、搜索框或滚动容器。

插件使用 `assets/javascripts/discourse/components/resume-editor.gjs` 中的局部 header/链接/图标及 `assets/stylesheets/isbf-resume.scss`。主容器顶部和横向 padding 清零，使分隔线横贯主内容宽度；局部 `--isbf-resume-content-gutter` 保留原表单左右间距（桌面 26px、手机 16px），应用于说明和布局，说明上距为 space-4。原底部间距保持桌面 80px、手机 90px 加 safe-area。跨文档索引见 [UI 状态](../../../../docs/design-system/ui-status.md)、[tokens](../../../../docs/design-system/tokens.md)、[组件规范](../../../../docs/design-system/components.md) 和 [Reference Map](../../../../docs/design-system/reference-map.md)。

预览源文件为 `exec-cf6039d2-4f0f-434e-ac7e-a3bea6fc39c5.png`，保存副本 SHA-256：`79fe077917d34a3024161e5fef01a648aafc3f95c3536fe9364433326bb341bf`。
