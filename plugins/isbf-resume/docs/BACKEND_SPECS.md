# 后端 Specs

2026-10-13 网页反馈候选：`feedback-rspec-v1` 的 61 项 RSpec 与 `feedback-python-log-v1` 的 25 项生成器测试通过，新增真实英文 DOCX/PDF、英文标签及日期状态、原文保留和两色一致性。沿用独立 Specs 数据库，未在预览或正式数据库运行 RSpec。本轮前端及实际文件结果见 [反馈验证](FEEDBACK_20261012.md)；下文保留 2026-10-12 的基线记录。

2026-10-11：遵循服务器 `discourse-service-authoring` 阶段 7，由专门子代理编写。用户已批准页面实现与隔离开发预览；正式部署仍需真实页面验收及另外确认。

当前状态（2026-10-12）：包含私有 PNG 逐页预览的当前候选已通过 `rspec-v5` 的 60 项后端测试、`python-v3` 的 22 项容器测试、`lint-v7` 的 39 个明确指定文件，以及 5 个 settings/locales YAML 语法和两个英文 locale 的 Core i18n 检查。lint 修正已回传本地。真实页面及下载验证已完成，见 [页面验证](BROWSER_QA.md)；用户网页验收仍待进行。

测试仅在任务容器 `isbf_resume_workbench_20261011_211314_app` 执行，其 `/src`、物理 PostgreSQL、Redis 与正式环境分离。每例使用 `Dir.mktmpdir` 的私有临时文件，环境变量在例后恢复，不向公共上传目录写入简历。

## 覆盖范围

- Contract：空值、Hash 类型、Unicode 编码后的请求字节限额。
- Service：Contract 截断、访客/停用/被暂停账户 policy、真实生成、副作用、预期异常和输入清除。
- Export：UUID、0700/0600 权限、原始 JSON、完成记录、损坏记录、缺失/空文件、格式限制、符号链接、过期边界。
- Generator：真实 Python/LibreOffice、DOCX XML 原文、可读取 PDF、两套模板仅颜色变化、未知字段、危险照片/链接、缺失执行文件、非法输出、非零退出、超时及进程组终止。
- HTTP：创建 201、错误 400/422、仅本人下载、管理员没有他人简历特权、访客、停用、过期、不存在/非法 ID 与格式、私有缓存标头及内联 PDF。

下载权限用小型本地文件夹 fixture；真实 DOCX/PDF 的格式与原文通过 Generator 和创建请求直接验证。文件夹 fixture 没有替换或 mock 内部业务方法。异常通过受控可执行文件触发真实进程边界。

## 阶段 7 检查表

| # | 要求 | 结论 | 证据 |
| --- | --- | --- | --- |
| 1 | 独立 Contract describe 与 shoulda | PASS | `generate_spec.rb` 的 Contract block |
| 2 | `.call` 执行 describe | PASS | Service 公开入口 |
| 3 | 共用且参数化的首项 subject | PASS | `subject(:result) { described_class.call(params:, **dependencies) }` |
| 4 | subject、fab!、let、before 顺序 | PASS | `.call` block 声明顺序 |
| 5 | 每个分支 context，按 step 顺序 | PASS | Contract、policy、Generator 失败、成功 |
| 6 | 使用 service 特有 matcher | PASS | `fail_a_contract`、`fail_a_policy`、`fail_with_exception`、`run_successfully` |
| 7 | `.call` 不穷举 Contract | PASS | 仅数组一例证明停止执行 |
| 8 | 成功 matcher 加真实副作用 | PASS | 真实生成两份文档、owner metadata、input 清除 |
| 9 | nested let 覆写，无重复 subject | PASS | params 在失败 context 覆写 |
| 10 | 修改演员用 nested fab! | PASS | 访客 nil、暂停用户 Fabricate |
| 11 | 具体 matcher，不用 bare be | PASS | eq、include、be_empty、be_available、have_attributes |
| 12 | context 命名 when/with/without | PASS | 所有 context 以 when 开头 |
| 13 | event 用 track_events | NA | 没有事件发布 |
| 14 | MessageBus 用 lazy track_publish | NA | 没有 MessageBus 发布 |
| 15 | setup records 使用 fabricators | PASS | 所有 User/administrator 使用 fab!/Fabricate；Export 是文件模型 |
| 16 | 需要 OP 的 topic 用 topic_with_op | NA | 不访问话题 |
| 17 | 新 callback 有 model specs | NA | 没有新增 callback；Export 公开行为独立测试 |
| 18 | 复杂 action 独立测试 | PASS | Generator 独立 spec，不 stub 内部方法 |
| 19 | context 与 method 遵循 step 顺序 | PASS | Contract → policy → model/output → typed exception |

RSpec 习惯查询来源：[RSpec Style Guide](https://rspec.rubystyle.guide/) 的 Leading subject、Contexts、Let grouping 和 Hook scope。Service 测试结构来源为当前服务器 `20-service-objects.md` 的 Testing 节。

## 实际执行

使用主代理指定的独立 Specs 数据库 `isbf_resume_specs_20261011_211314`，没有使用预览数据库或正式数据库。Windows 调用 Python 时加 `-X utf8`，避免日志里的 Unicode 被默认 GBK 输出编码阻断。

```text
env RAILS_DB=isbf_resume_specs_20261011_211314 bin/rspec plugins/isbf-resume/spec
Randomized with seed 19191
Finished in 1 minute 37.19 seconds (files took 50.06 seconds to load)
43 examples, 10 failures
```

首轮实际发现九个 HTTP 正常/访客场景均返回 404，已交由主代理修复路由或插件启用通路。因为正常下载也没有通过，此时不能把另一个用户获得 404 判定为已完成权限验证。Contract、Service、Export 和真实 Python/LibreOffice 生成场景通过。

第十项失败来自超时 fixture 未写入 PID 文件。测试改用 `/bin/sh` 与 `/bin/sleep`，显式设置执行权限，并为非法输出和非零退出案例加入启动哨兵，防止“程序根本没启动”被误当作指定故障。还增加 HTTP 原始请求字节上限、两模板实际颜色值的检查。首轮修订后共 44 个测试，后续统一备份同步和重跑结果见下文。

首轮容器日志：`/src/tmp/resume-rspec.log`；退出码 `1`。该轮结束时，修订尚未通过实际执行；后续通过结果单独记录，保留失败历史。

第二轮在路由生命周期修订、统一备份同步后执行：

```text
Randomized with seed 56499
Finished in 49.6 seconds (files took 13.78 seconds to load)
44 examples, 9 failures
```

Generator 全部场景通过，包括确实执行受控程序、进程组超时、两套实际颜色值和颜色归一后的整份 DOCX 包一致性。新增原始 HTTP 请求字节上限检查通过。

请求层发现两项业务接入问题，交由主代理修复：正常创建的 Serializer 调用普通文件模型时缺少 `read_attribute_for_serialization`，导致 500；下载和关闭后的页面得到 200 HTML，当时尚未进入应有的私有下载/功能关闭路径。继续保留原断言，不能以 HTML 200 代替文件、404 或认证响应。第二轮日志 `/src/tmp/resume-rspec-v2.log`、退出码 `1`；该轮尚未完成下载权限验证，随后回归已覆盖。

随后只读核对 Core：`ApplicationController#check_xhr` 在非 JSON、非 XHR 请求时触发 `RenderEmpty`，原生 `UploadsController` 等文件控制器会跳过该检查；父类的 `requires_login` 仅设置当前类实例变量，其配置不会自动沿用到插件子控制器。此证据用于主代理修复真实下载与页面鉴权路径，没有放松 Specs 断言。

第三轮在模型序列化接口、XHR 处理和前置访问控制修订、统一备份同步后执行：

```text
env RAILS_DB=isbf_resume_specs_20261011_211314 bin/rspec plugins/isbf-resume/spec
Randomized with seed 20185
Finished in 1 minute 11.12 seconds (files took 24.68 seconds to load)
44 examples, 0 failures
```

容器日志：`/src/tmp/resume-rspec-v3.log`；退出码 `0`。第三轮所有既定状态、数据和文件断言保留，没有降低要求来通过测试。随后 lint 产生 Guardian 接入结构修订；当前候选的第四轮回归记录见本节末尾。阶段 7 的 19 项结构表已复核，仍为 PASS/NA。

## 当前候选的安全行为审阅

以下原有行为在第三、第四轮验证后，第五轮针对包含 PNG 逐页预览的当前候选完整回归并全部通过。

| # | 行为 | 结论 | 实际证据 |
| --- | --- | --- | --- |
| 1 | 身份认证 | PASS | 访客创建、下载、页面 JSON 请求均 403；不创建文件 |
| 2 | 功能关闭 | PASS | 关闭后创建、已完成导出下载和直接页面均 404 |
| 3 | 私有资源范围 | PASS | 本人 DOCX/PDF/PNG 200；其他成员与管理员请求均 404 |
| 4 | 暂停账户 | PASS | Service 的真实暂停演员在 can_generate policy 截断 |
| 5 | 结构和大小由服务器检查 | PASS | 数组 400；Unicode 编码字节与 HTTP 原始字节上限；未知模块/字段及不安全照片/链接拒绝 |
| 6 | 文件系统权限 | PASS | 任务目录 0700、输入和 metadata 0600；仅完成且两文件存在的任务可用 |
| 7 | 路径和格式 | PASS | 非法/不存在 UUID、txt 和模型路径穿越拒绝；符号链接、空文件和缺失文件不可下载 |
| 8 | 生命周期 | PASS | 到期边界返回 404；失败任务没有可读取的 metadata |
| 9 | 响应与缓存 | PASS | 正确 DOCX/PDF/PNG MIME、private/no-store、nosniff；PNG/PDF 内联和 DOCX 附件明确区分 |
| 10 | 敏感输入和错误 | PASS | 成功/验证失败/异常/超时均清除 input.json；错误响应不公开私有目录；成功 JSON 仅含七个导出属性，包括 preview_urls |
| 11 | 进程边界 | PASS | 缺失程序、非法输出、非零退出受控；超时后主/子进程无活跃记录，输入清除 |
| 12 | 输出可信 | PASS | 真正 Python/LibreOffice 生成；DOCX 原文保留、PDF 可解析；每页 PNG 通过 PIL verify、签名与非空画面检查，数量与 PDF 一致；两模板仍只改颜色 |
| 13 | 分类、MessageBus 与事件受众 | NA | 本功能没有分类资源、MessageBus 或事件发布 |
| 14 | 预览名单与页码 | PASS | 必须为与 pages 一致的有序 basename；绝对路径、穿越、重排、缺页与非规范页码拒绝 |
| 15 | 旧导出和缺图兼容 | PASS | 旧 metadata 无图片 URL、PNG 404而文档可下载；缺图时同样保留正常文档下载 |

这是独立环境的后端行为证据，前端真实浏览器与用户验收由主代理继续完成。测试结果不产生正式环境部署授权。

## lint 与后续回归

主代理在任务独立源码中使用空 Git index，仅记录插件的 `plugin.rb`，让 `bin/lint` 按 native Core 路径使用现有锁定工具与配置。该 index 不涉及共享或正式 Git，不提交业务文件，也不进入外部插件自动安装依赖的分支。检查传入的是本插件明确列出的 Ruby、GJS、JS、SCSS、YAML 文件，没有使用全目录、`--recent` 或其他 Git selector 扩大范围。

原脚本的外部插件分支会先执行 `bundle install` 和 `pnpm --ignore-workspace i`；修正模式不会主动追加 frozen 参数，且该分支没有 YAML linter。因此执行前必须核对实际分类、锁文件与依赖目录，不能把未检查的 YAML 或依赖安装视为纯粹的格式修正。采用 Core 路径后，Root 负责此前备份、显式文件调用、候选哈希和修正回传；额外缓存、日志、任务 Git index 与工具产生的文件也需留在独立环境，并核对只读依赖挂载没有被写入。

第一轮 lint 已指出并由主代理修复：

- Guardian 的 `class_eval` 改为在 `reloadable_patch` 内 `prepend IsbfResume::GuardianExtension`。
- 三处测试 selector/断言规范修正。
- 业务模板中的 `section` 变量遮蔽修正。

主代理已确认第二轮 `lint-v2` 退出码 `0`、耗时 `38.43` 秒：39 个明确指定的候选文件通过 eslint、prettier、rubocop、stylelint、syntax_tree，修正已回传本地。这 39 项包括两份主题 lint 副本，实际主题发布仍保留最小增量 patch。

附加语言检查日志 `/src/tmp/resume-locales-check.log`，退出码 `0`：`config/settings.yml` 及四份 `config/locales/*.yml` 共 5 个 YAML 语法通过；Core `script/i18n_lint.rb` 对 `client.en.yml`、`server.en.yml` 检查通过。

Guardian 的集成结构变动会影响 Service 和 HTTP 权限，所以最新候选再次执行完整 44 项后端 Specs。第四轮 `rspec-v4` 在专用 `isbf_resume_specs_20261011_211314` 数据库完成：

```text
Randomized with seed 24184
Finished in 42.01 seconds (files took 11.43 seconds to load)
44 examples, 0 failures
```

日志 `/src/tmp/resume-rspec-v4.log`，退出码 `0`。该结果对应在 `reloadable_patch` 内 `prepend GuardianExtension` 和 lint 修正后的该轮候选，未沿用旧版本测试结果。随后 PNG 增量再执行第五轮 60 项回归；真实浏览器页面检查和用户网页验收仍待完成。

## 真实 PDF 逐页 PNG 预览增量

实际浏览器的 PDF 内嵌和独立打开显示灰色，原始 PDF 下载正常。本次增加从同一 PDF 渲染的私有 PNG 逐页展示；DOCX/PDF 生成和下载继续保留，不增加数据库表，不引入外部服务。主代理已确认隔离环境提供 `/usr/bin/pdftoppm` 25.03.0；Python 渲染与前端展示由各自代理实现，本节只记录 Ruby 和 Specs 的增量。

Ruby 命令适配器固定追加 `--preview`。生成器 JSON 的 `preview_files` 必须严格等于从 `preview-1.png` 到 `preview-N.png` 的有序相对文件名数组，`N` 与整数 `pages` 一致。完成 metadata 前校验每个固定私有路径中的实际文件、非符号链接和 PNG 签名；不接收绝对路径、目录穿越或重排/缺页名单。

`Export#preview_path(page)` 只允许 1 到该导出页数的整数或规范十进制字符串，并检查文件和过期状态。路由为 `/isbf-resume/exports/:export_id/previews/:page`，从第 1 页开始，禁用隐含 format 拆分，避免 `1.0` 被拆成页码 1 和格式 0。图片 action 复用 Guardian 的本人、启用状态与有效期检查，跳过仅限该 action 的 XHR 检查，返回 `image/png`、inline、private/no-store、nosniff。Serializer 新增按页序排列的 `preview_urls`，包含站点 base path。

旧 metadata 没有 `preview_files` 时，图片数量与 URL 列表为空，PNG 返回 404，原 DOCX/PDF 仍可下载。完成后的某张预览丢失或损坏时该页返回 404，文档下载仍由原规则决定。

新增 16 项测试，合计 60 项：

- Export 7 项：旧 metadata、损坏名单、规范页码/界限、同一过期边界、缺失/符号链接/错误 PNG、严格有序 manifest 及完成状态。
- HTTP 8 项：真实 PNG 类型/内容与缓存标头、本人/其他成员/管理员/访客、功能关闭、过期、非法页或路径、缺图但保留下载、旧导出兼容。
- Generator 1 项：内容超过一页时对每一张实际 PDF 预览使用 PIL `verify()`，检查 PNG 签名、非空画面、数量与页序；既有原文和两模板只改颜色的测试继续保留并加强。

共享 fixture 增加有效小型 PNG，原 44 项测试的语义与断言保留；创建响应增加第七个属性 `preview_urls`，并实际请求首张图片。真实生成测试验证完整 PDF/DOCX 与实际生成 PNG，权限测试的轻量 fixture 不替换内部业务方法。

本次本地改动为 5 个 Ruby 业务文件（Export、Generator、ExportsController、ExportSerializer、routes），4 个 Spec/helper 文件和本记录。子代理没有同步服务器、运行重型测试或改 Core/前端/Python；主代理备份同步后串行完成以下原生验证，并回传 lint 修正，避免与预览服务器争用资源。

## PNG 当前候选的实际验证结果

第五轮后端回归 `rspec-v5`：

```text
Randomized with seed 43145
Finished in 50.99 seconds (files took 14.55 seconds to load)
60 examples, 0 failures
```

该轮退出码 `0`，包含原 44 项及 PNG 增量 16 项；真实 PNG 解析、页数/顺序、私有访问、非法页/路径、过期和旧文档下载兼容均通过。阶段 7 的 19 项表与当前安全行为表复核保持 PASS/NA，没有放松原断言。

同一候选的其他验证由主代理确认：

- `lint-v7`：39 个明确指定文件全部通过，38.53 秒，修正已回传本地。
- `python-v3`：隔离容器内 22 项通过，0.877 秒。
- 5 个 settings/locales YAML 语法通过；`bundle exec ruby script/i18n_lint.rb` 对 `client.en.yml`、`server.en.yml` 检查通过。

这些结果验证当前候选的后端、生成器和静态规范。真实页面显示及文件验证已完成，用户网页验收仍待进行，不据此声明已获正式部署授权。
