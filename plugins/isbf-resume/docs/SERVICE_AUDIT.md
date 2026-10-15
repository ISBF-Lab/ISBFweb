# Service 实施审阅

阶段 3：新增私有 `Export` 模型、本地 `Generator` 命令适配器、`Export::Generate` service、HTTP 控制器、路由、Serializer、功能开关与语言文件。原有 Python 生成器保留，不删除其他功能。用户已授权该页面实现及开发预览，审阅与必要修复在同一范围推进。

服务名候选：`IsbfResume::Export::Generate`、`IsbfResume::Export::Create`、`IsbfResume::Document::Build`、`IsbfResume::Resume::Generate`、`IsbfResume::Export::Prepare`。选用第一项，说明实际生成简历文件的行为。

## 阶段 4：结构

| # | 规则 | 判断 | 证据 |
| --- | --- | --- | --- |
| 1 | 领域服务名称 | PASS | `Export::Generate` 表示简历导出生成 |
| 2 | 单一职责步骤 | PASS | policy、创建私有任务、生成文档三个职责 |
| 3 | 步骤描述领域行为 | PASS | `can_generate`、`create_export`、`generate_documents` |
| 4 | 参数名称明确 | PASS | `resume`、`export_id`、`file_type` |
| 5 | 不直接操作 context | PASS | 使用 params、guardian、export 关键字 |
| 6 | 事务只包数据库写入 | NA | 没有数据库写入或事务；转换为文件系统操作 |
| 7 | 锁不包副作用 | NA | 不使用 service lock |
| 8 | step 开头不使用条件 return | PASS | 所有 service step 无 guard return |
| 9 | service 不包含工具方法 | PASS | IO 和子进程分别在 Export、Generator |
| 10 | Contract 拥有参数处理 | PASS | Contract 校验 resume 存在及请求字节数 |
| 11 | 限速在控制器 | PASS | `ExportsController#limit_generation` |
| 12 | 不用可选 model 存条件值 | PASS | export model 为必要任务 |
| 13 | create 而非 new/save | PASS | `Export.create` 原子创建 UUID 目录 |
| 14 | 条件副作用独立步骤 | PASS | 生成仅为一个步骤，没有条件副作用分支 |
| 15 | 同一概念副作用组合 | PASS | DOCX/PDF 和同一 PDF 的逐页 PNG 为同一次导出，验证全部文件后才写完成 metadata |
| 16 | try 只捕获预期异常 | PASS | 仅 InvalidResume / GenerationError |
| 17 | MessageBus 安全受众一致 | NA | 没有 MessageBus 发布 |
| 18 | 创建 model 使用自定义步骤名 | PASS | `model :export, :create_export` |
| 19 | only_if 转换保留默认分支 | NA | 新功能，没有旧 if/else 转换 |
| 20 | 小型工具不绕层委派 | PASS | Generator 是独立复杂命令边界；Service 无小型 helper |
| 21 | 使用关联查询 | NA | 没有 ActiveRecord 关联查询 |
| 22 | 特权查询 guard | NA | 私有导出仅本人访问，没有特权绕过 |
| 23 | 无兼容 wrapper / skip_policy | PASS | 直接调用 service，全部 caller 同一 policy |
| 24 | 写入顺序一致 | PASS | 创建私有任务、生成文档及页面图片、验证固定文件名与签名、最后写完成 metadata |
| 25 | ApplicationSerializer | PASS | `ExportSerializer < ApplicationSerializer` |
| 26 | 条件属性用 include 方法 | NA | Serializer 属性均固定，无条件属性 |
| 27 | 嵌套数据独立 Serializer | NA | 结果为固定任务属性、两个文档链接及页面 URL 字符串数组，无嵌套模型 |
| 28 | 调用处直接 Serializer | PASS | controller 直接 new / as_json |
| 29 | 预加载数据通过 options | NA | 无关联或批量加载 |
| 30 | 使用 service_params | PASS | create 使用 `Export::Generate.call(service_params)`；没有额外依赖需 deep_merge |

## 阶段 5：业务

| # | 规则 | 判断 | 证据 |
| --- | --- | --- | --- |
| 1 | 所有原有生成路径保留 | PASS | 原生成器 CLI、58 项 schema、两种颜色、长内容分页及照片处理保留 |
| 2 | 副作用条件及顺序 | PASS | 先校验权限、创建任务、调用本地生成器，再开放两个下载地址 |
| 3 | 保留原子边界 | PASS | 原生成器没有数据库事务；新增完成 metadata 阻止未完成文件下载 |

## 阶段 6：安全

| # | 规则 | 判断 | 证据 |
| --- | --- | --- | --- |
| 1 | 所有调用者一致访问控制 | PASS | Service Guardian policy；页面、文档下载及 PNG 同时检查；本人 ID 匹配 |
| 2 | 分类权限 | NA | 简历不属于论坛分类，不访问帖子或分类 |
| 3 | MessageBus 受众 | NA | 不发布实时消息 |
| 4 | 私有资源存在性泄露 | PASS | 错误、其他用户、过期与不存在任务均为 404；不返回服务器路径；整个 resume 请求参数过滤 |

以上是代码路径审阅，不能替代测试。阶段 7 在专门子代理中执行后端 Specs；实际执行结果、容器隔离证据及浏览器检查另行记录。
