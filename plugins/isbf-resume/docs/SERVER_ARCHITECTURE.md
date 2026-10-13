# 工作台简历接入：服务器架构核对

核对时间：2026-10-11，Asia/Taipei。最初的架构核查只读服务器源码、运行容器和数据库主题。用户确认设计后，新增插件在本地实现并同步到任务独立容器；共享源码、正式主题及正式配置未改变。

## 已验证语言栈

| 层 | 已读取事实 | 简历模块的对应方式 |
| --- | --- | --- |
| 应用后端 | 运行容器 Ruby 3.4.10，Rails 8.1.3.1 | Rails 插件提供页面、登录权限、生成及下载请求 |
| 浏览器前端 | Ember / Glimmer，源码 `ember-source: ~7.2.0`、`@glimmer/component: ^2.1.1` | 业务组件使用 `.gjs`，不新增另一套 React/Vue 应用 |
| 工程与构建 | 运行 Node 22.23.2；源码固定 `pnpm@10.34.5` | 使用服务器锁定工具和已有构建流程 |
| 样式 | SCSS、CSS 自定义属性，现有 `--isbf-v2-*` 语义映射 | 独立 common stylesheet、BEM、共享 tokens、响应式布局 |
| 数据库 | 运行应用连接 PostgreSQL | 生成不必新增数据库表；是否保存云端草稿另行确定 |
| 文档生成 | 已有本地 Python 生成器，在此前任务隔离容器中验证 Python 3.13.5 / LibreOffice 25.2.3.2 | Rails 固定参数启动本地生成程序，沿用 DOCX → PDF 流程 |
| 网页逐页预览 | 隔离容器已核对 Poppler `pdftoppm` 25.03.0 | 从同一 PDF 渲染私有 PNG，网页按页展示图片 |

Ruby、Rails、Node 为当前运行容器版本；Ember/Glimmer 和 pnpm 为当前源码声明，没有将它们说成运行时已加载包的精确版本。

## 当前工作台与运行主题

- `/isbf/workbench` 的服务器页面由 `plugins/isbf-calendar/config/routes.rb` 提供，对应 `PagesController#respond`；前端 route-map 注册 `isbfWorkbench`，模板是路由占位，实际工作台由主题组件呈现。
- 正式默认主题已只读确认是 ID 4，名称 `ISBF Campus Feed`。运行主题存于数据库，不能用服务器工作区主题覆盖它。
- 当前工作台组件的 `CARDS` 已有 `{ key: "resume", icon: "file-lines", tone: "mint" }`。该条目的 `href` 尚为 null，因此显示占位 div；只需要给这一条增加功能开关控制的链接。
- 当前 `ISBFV2Shell.pageKind` 对工作台使用精确路径匹配；新子路径不会自动得到壳。侧栏的 `workbenchActive` 已支持 workbench 前缀，但手机底栏依赖 `isWorkbench`，需要显式归属。
- 现有 workbench 功能区会隐藏 `#main-outlet`。新简历插件如果让正文位于 Ember route template，就必须使用独立 `resume` 壳状态并保持该正文可见，否则会出现空页。
- 当前模板的 `<ISBFV2Workbench />` 兜底分支使用 `isWorkbench`。若把 `resume` 加入该家族，必须同时把网格分支改为工作台首页的精确判定，否则会重复渲染首页内容；导航激活和右栏隐藏仍使用家族判定。
- 已有同伴未提交的主题、认证及 Core 改动；本次没有覆盖这些文件。接入时以新鲜数据库字段和源码为基线做增量修改。

已记录运行主题字段 197（common SCSS）、200（shell）、201（side-nav）、207（workbench）、198（初始化入口）的当前 SHA-256，见 [source-audit.json](../design/source-audit.json)；实际部署时必须重新读取并比较，不能把本次快照当作未来部署原件。

## 隔离预览依赖与验证状态

2026-10-12，任务独立容器使用非默认预览主题 ID 2；独立数据库的默认主题 ID 保持为 `-1`。此前捕获遗漏的七个 `extra_scss` 依赖为 `topic-reading`、`reporting`、`official-filters`、`learning-resources`、`learning-composer`、`official-calendar` 和 `marketplace`。它们已按字段增量补入该预览主题，每份 UTF-8 内容的 SHA-256 均与用户提供的 UI 参考包 `docs/design-system/references/manifest.json` 相符。来源是 2026-10-10 已验收的主题 4 快照，Core 基线为 `c0f4739d143a4efbb4e7f19dafadcd56a5302a58`；尚未核验这七份样式与当前生产 partial 完全一致。

预览保留先前读取的新鲜运行版 `common.scss` 及本次简历增量，没有用历史参考包的 common 样式替换它。七份补充样式只用于补齐原有导入依赖，其中唯一嵌套依赖是 Core 的 `lib/viewport`。预览主题字段的编译错误已清空，真实页面导航与表单、预览双栏已能呈现；这不扩大已确认设计的视觉范围，也不代表完成最终功能验收。

交互页面的 Core `dist` 已从本任务保留的运行版资源恢复并核对 SHA-256。QUnit 使用经过公开源码及前端 importer 对照的开发资源缓存；该缓存复用不计为新的全量构建成功。独立容器的临时样式指纹在备份后通过 Core 原生样式 API 重新生成，没有编辑 Core 业务源码、共享源码或正式环境。最终真实浏览器 QA 仍在进行中，下载交互需完成原生导航修复后的复验；结果由对应测试记录更新。

## 实际接入模块

已有生成项目现为独立 `isbf-resume` 插件，并保留 Python 生成器。功能代码不放到 `isbf-calendar`，也不新增 Core npm 依赖。

```text
工作台已有“简历”入口
  → /isbf/workbench/resume
  → Ember route template / ResumeEditor.gjs
  → FormKit 数据、校验及 UI kit 操作
  → Rails IsbfResume service / Guardian
  → 本地 Python 机械填写 DOCX
  → 本地 LibreOffice 转 PDF
  → 本地 Poppler 从该 PDF 渲染逐页 PNG
  → 当前用户图片预览及原 DOCX/PDF 下载
```

插件中的主要文件如下；具体执行结果由测试记录说明：

```text
plugin.rb
config/settings.yml
config/routes.rb
config/locales/client.en.yml
config/locales/client.zh_CN.yml
config/locales/server.en.yml
config/locales/server.zh_CN.yml
assets/javascripts/discourse/isbf-resume-route-map.js
assets/javascripts/discourse/routes/isbf-resume.js
assets/javascripts/discourse/templates/isbf-resume.gjs
assets/javascripts/discourse/components/resume-editor.gjs
assets/javascripts/discourse/components/resume-fields.gjs
assets/javascripts/discourse/components/resume-photo.gjs
assets/javascripts/discourse/components/resume-preview.gjs
assets/stylesheets/isbf-resume.scss
app/controllers/isbf_resume/pages_controller.rb
app/controllers/isbf_resume/exports_controller.rb
app/services/isbf_resume/export/generate.rb
app/models/isbf_resume/export.rb
app/serializers/isbf_resume/export_serializer.rb
lib/isbf_resume/generator.rb
resume_generator.py / resume_schema.json / fonts/libreoffice.conf
```

页面同时提供服务器直达 GET 和 Ember route-map。地址为 `/isbf/workbench/resume`，生成使用 `POST /isbf-resume/exports.json`，下载使用 `GET /isbf-resume/exports/:export_id/:file_type`。主应用挂载在插件 `after_initialize` 注册，Engine 路由保持在 `config/routes.rb`。访问门禁在 SPA 外壳渲染前执行，下载跳过 `check_xhr` 后执行 owner 校验和 `send_file`。这些是本站请求，生成过程不调用模型或第三方简历 API。

生成器启用 `--preview`，在 PDF 已生成并确认页数后，以固定本地 argv 调用 `pdftoppm -scale-to 1400 -png`，限时 45 秒。临时图片全部通过 PNG 和页数校验后，发布为 `preview-1.png` 至 `preview-N.png`，拒绝覆盖。它只读取原 PDF，不改变 DOCX/PDF 的内容、版式或时间字段；自然分页的全部页面都保留。

序列化结果给出按页排列的 `preview_urls`；图片端点为 `GET /isbf-resume/exports/:export_id/previews/:page`，执行同样的当前用户归属和有效期检查。图片与 DOCX/PDF 位于私有导出目录，文件名和页码由服务端限制。网页展示实际 PNG 页面，不再将 iframe 或原生 PDF 阅读器作为预览要求；原 PDF 下载与单独打开 PDF 链接仍可使用。旧 metadata 没有 `preview_files` 时保留原文件下载，重新提交填写内容生成新记录可获得 PNG 预览。

主题只修改必要的入口链接、resume 路由归属和正文容器规则。页面正文从插件的 route template 渲染，主题不 import 插件组件；插件关闭时入口回到占位状态，未知路径仍走已有边界。`isWorkbench` 用于导航归属，新 `isWorkbenchHome` 或 `pageKind === "workbench"` 用于原首页网格渲染；工作台、学习库、商城和校友原有页面行为须保留。

## 前端公开 API 与数据契约

使用 `Form` 的 `@data` POJO、`@onSet` 和公开 fields。基本字段映射到 `basic.name`、`basic.phone` 等路径；经历使用公开 `Object` API 和稳定 UUID，提交时按用户顺序转为生成器接受的数组。该方式避开当前 `Collection` 以位置生成控件键的行为。

- `@title` 对应翻译后的标签，`@helpText` 对应常驻填写说明，placeholder 对应示例；不用 `@description` 代替控件下方说明。
- `input-text`、`input-tel`、`input-email`、`input-url`、`input-month`、`textarea`、`checkbox` 对应已有字段类型。
- 照片使用 custom field，本地选图后生成受限的图像数据；不借用默认论坛公开上传流程。
- 阶段切换使用 `DTabs`，提交使用 FormKit 的 `form.Submit` 并经过表单校验，新增及删除等操作使用 `DButton` 或 FormKit yielded button；状态播报使用 `a11y` service。
- 错误按稳定字段路径关联，重新展开所在模块；错误摘要采用用户可读标签。前后端 UI 文案提供中英文；已有生成器的详细字段校验仍返回中文，这是当前英文界面的已知限制。

字段的 ID、模块、类型、标签与帮助翻译键见 [ui-contract.json](../design/ui-contract.json)，其中记录用户对开发预览的设计确认范围。

## 语言与翻译组织

当前主题显示文案使用 `virtual:theme` 的 `themePrefix` 与 `discourse-i18n` 的 `i18n`，主题分别有 `locales/en.yml` 和 `locales/zh_CN.yml`。工作台已有 `isbf_v2.workbench_resume`，应继续复用该入口标签。

新的简历业务文案放在插件 `config/locales/client.en.yml` / `client.zh_CN.yml` 的 `js.isbf_resume` 命名空间；服务端错误放在相应 `server.*.yml`。例如：

```text
isbf_resume.title
isbf_resume.steps.content
isbf_resume.steps.template
isbf_resume.steps.preview
isbf_resume.fields.basic.phone.label
isbf_resume.fields.basic.phone.help
isbf_resume.fields.experience.details.help
isbf_resume.actions.generate
isbf_resume.errors.required
```

插值使用完整翻译字符串，不拼接翻译碎片。界面语言可以跟随站点或用户偏好；用户填写的经历保持原文，不自动翻译或补写。现有导出模板使用中文栏目标题，本阶段没有新增英文导出模板。

现行 `discourse-content-localization` skill 针对数据库动态内容的本地化，与本页静态 UI 文案不同；本任务不引入 Localizable 模型、AI 检测或自动翻译依赖。

## 生成与验收边界

生成程序由服务端调用固定可执行程序及固定 argv，不拼用户内容到 shell。每次任务使用自己的私有目录和临时转换配置；下载检查当前用户归属，日志不记录完整简历或照片。

正式镜像需要满足 Python 依赖、LibreOffice、Poppler `pdftoppm` 与字体条件，当前尚未证明生产容器已经具备这些依赖。2026-10-13 网页反馈候选通过 61 项 RSpec、25 项生成器测试，以及 21 项前端场景的原生分批覆盖和完整浏览器运行；英文两色实际文件、取消与加载状态的最新结果见 [反馈验证](FEEDBACK_20261012.md)。初版桌面手机、明暗和多页预览记录见 [真实页面验证](BROWSER_QA.md)。开发预览已完成，用户网页验收仍待进行。

在任务独立测试栈验证 route-map、直接刷新、字段及错误、失败后保留填写内容、图片、两款导出、长内容、插件关闭、未登录/其他用户下载权限、桌面手机和明暗。当前填写状态保留在本次页面会话中；刷新页面会重新开始，不宣称已实现跨会话草稿。测试环境不连接正式数据。只有该版本实际交互页面经用户验收和明确授权后才进入正式部署。
