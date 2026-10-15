# ISBF Resume

按照明确字段机械排版的简历生成模块。只把用户提供的内容写入 DOCX，然后调用本地转换程序生成 PDF，不调用外部 API、不生成或润色经历。

`resume_schema.json` 保存字段标签、必填规则、类型、长度限制、填写说明和示例。必填项只有姓名、联系电话和电子邮箱；其他模块可省略，新增的非空经历需填写对应学校、单位、项目或条目名称。每个字段都带有 `help`，界面应持续显示说明并用 `aria-describedby` 关联，不能仅把说明作为输入后消失的 placeholder。

2026-10-11，用户确认六张设计稿并授权接入开发预览。页面使用当前 Discourse 的 Glimmer、FormKit 和 UI kit；Rails 插件调用本地 Python/LibreOffice 机械生成文件，并由本地 Poppler 将同一 PDF 渲染为私有逐页 PNG。入口为 `/isbf/workbench/resume`，页面包含填写内容、选择模板、预览与下载三个阶段。网页按页展示图片，无需依赖浏览器原生 PDF 阅读器；下载仍提供原 DOCX 和 PDF。照片随本站生成请求提交到私有目录，不进入论坛公共附件。

查看 [设计审阅入口](design/index.html)、[设计 V2](docs/UI_DESIGN_V2.md)、[实施依据](docs/design-system/resume-approval.md) 和 [服务器架构](docs/SERVER_ARCHITECTURE.md)。实际验证进度见 [实施记录](docs/IMPLEMENTATION_PHASES.md)、[后端测试](docs/BACKEND_SPECS.md)、[前端测试](docs/FRONTEND_TESTS.md) 和 [真实页面验证](docs/BROWSER_QA.md)。开发预览与正式部署分开验收。

2026-10-12 的网页反馈调整见 [本轮改进记录](docs/FEEDBACK_20261012.md)。长字段占整行，示例颜色与输入内容区分；通过基本校验后先确认，确认生成即进入预览。旁边的“生成英文版”只切换固定栏目、标签和日期状态文字，不翻译用户内容。两个入口均显示内容核查和短时间内无法多次生成的提醒；本次没有新增频次限制。

2026-10-13 按用户要求，填写页及预览阶段使用当前表单内容实时排版，清空字段或移除经历后立即更新；空表单显示填写提示。模板示例图仅用于模板选择。生成成功后改为展示同一实际 PDF 的全部页面；修改内容后立即回到最新草稿预览并禁用旧文件下载。草稿预览不提交内容，最终分页以生成后的 PDF 为准。实现及验证见 [实际内容预览](docs/LIVE_PREVIEW_20261013.md)。

参考文档及布局样稿位于本地工作区 `.local/resume-layout-20261011/`。这些个人材料及真实简历内容不进入仓库。源 DOCX 不被覆盖。

## 运行文档生成器

准备 Python 环境并安装 `requirements.txt` 中锁定的依赖。PDF 转换使用本机或隔离容器中的 LibreOffice Writer；不向第三方服务发送简历内容。Linux 环境还需安装 Noto Sans CJK 字体，随程序的 `fonts/libreoffice.conf` 将微软雅黑映射到简体中文无衬线字体，避免中英文各自回退。

网页逐页预览还需要 PATH 中可执行的 Poppler `pdftoppm`。隔离容器已核对安装版本为 25.03.0；生产镜像的依赖仍需单独核验。生成器使用固定参数 `-scale-to 1400 -png` 读取已生成的同一 PDF，通过参数数组启动本地程序，限时 45 秒，不经过 shell。它保留全部页面，并校验页数、PNG 格式及尺寸；预览图片不改变原文件内容或版式。

```sh
python -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python resume_generator.py input.json --output-dir output/new-run
```

Windows 的虚拟环境命令位于 `.venv/Scripts/`。若转换器不在 PATH 中，传入 `--soffice` 指定本地可执行文件；只验证 DOCX 时可使用 `--docx-only`。输出目录中的同名文件已存在时会拒绝覆盖。

CLI 的默认输出仍为 DOCX 和 PDF。需要同时生成 PNG 预览时使用：

```sh
.venv/bin/python resume_generator.py input.json --output-dir output/new-preview --preview
```

成功 JSON 会增加按页顺序排列的相对文件名 `preview_files`，例如 `["preview-1.png", "preview-2.png"]`；同名预览文件存在时拒绝覆盖。`--preview` 与 `--docx-only` 不能同时使用。网页生成请求启用逐页预览，PNG 与原 DOCX/PDF 一同保存在服务器私有目录，并检查当前用户归属及过期时间。旧导出 metadata 未包含预览时，原 DOCX/PDF 仍可下载；重新提交填写内容生成新记录后可获得逐页预览。

最小输入如下，模块与字段的完整契约见 `resume_schema.json`。界面填写结果可以直接映射为同一结构。

```json
{
  "version": 1,
  "template": "blue-gold",
  "basic": {
    "name": "示例用户",
    "phone": "+86 138 0000 0000",
    "email": "name@example.com"
  }
}
```

模板值为 `blue-gold` 或 `blue-gray`；文字和排版规则完全相同，仅强调色不同。照片使用经过验证的 JPG、PNG 或 WebP data URL，限制为 5 MB、1600 万像素。输入总文字限制为 40000 字符；内容超过一页时自然分页，程序不删减经历或自动缩小字号。

`language` 可选，省略时为 `zh_CN`。设为 `en` 或在 CLI 使用 `--language en`，会输出英文栏目标题、基本信息标签、内容前缀以及 `Present` / `(expected)` 日期状态；姓名、学校、经历与其他填写内容仍按原文排版。中文版和英文版都共享同一排版函数和两种配色。

校验失败会返回字段路径和中文提示。姓名、邮箱、国际电话号码格式、有效年月、起止顺序、照片及链接均在生成器中验证；未知导入模块或字段会明确报错，避免静默丢失内容。程序保留用户的记录顺序和原文。

## 验证

```sh
python -m unittest discover -s tests -v
```

自动验证覆盖必填规则、空模块、日期、原文保留、图片比例和两款仅颜色不同。生成后的 PDF 还需要检查实际页数、文字完整性和逐页视觉排版；静态页面提案不能替代 ISBF 的真实交互验收。

预览主题补齐的七个 SCSS 导入依赖来自用户提供的已验收参考包，并已逐份核对 manifest 摘要。它们与最新生产 SCSS 完全一致尚未证明；隔离预览保留新鲜运行版 `common.scss` 和同伴更新。来源与验证限制见 [服务器架构](docs/SERVER_ARCHITECTURE.md)；新增逐页 PNG 预览的集成及真实浏览器验证以最新测试记录为准。
