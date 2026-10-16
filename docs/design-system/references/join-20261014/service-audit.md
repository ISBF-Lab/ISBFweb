# 招募登记服务审查

审查对象为 `plugins/isbf-join/app/services/isbf_join/submit_application.rb`、共享字段校验、
模型、公开及管理员控制器、序列化器与对应测试。实现依据项目服务文档，测试阶段由
专门测试代理编写并运行。用户已批准接入方案并要求实施；本记录不扩大批准范围。

服务名选择 `IsbfJoin::SubmitApplication`，直接对应招募表单提交。
评估过的其他名称为 `IsbfJoin::RegisterApplication`、`IsbfJoin::Applications::Submit`、
`IsbfJoin::Registration::Create`、`IsbfJoin::ContactApplication::Submit`。

## 结构与质量

| # | 规则 | 结果 | 依据 |
|---|------|------|------|
| 1 | 服务名表达业务概念 | PASS | `SubmitApplication` 表示提交招募登记。 |
| 2 | 每步只有一个关注点 | PASS | Contract 校验，`register_application` 登记，`submission_matches` 核对重试。 |
| 3 | 步骤采用业务名称 | PASS | 登记与重试匹配，不以底层数据库操作命名。 |
| 4 | 参数名称明确 | PASS | `name`、`student_id`、`phone`、`submission_id`。 |
| 5 | 避免直接读写 context | PASS | 通过步骤的关键字参数与 `model :application` 传递数据。 |
| 6 | 事务只包含共同成败的数据库写入 | PASS | 单条登记依赖 ActiveRecord 原子创建；没有外部副作用。 |
| 7 | 锁仅覆盖并发敏感步骤 | NA | 不加应用锁；数据库唯一索引和 `create_or_find_by` 处理并发。 |
| 8 | 不用步骤开头的条件返回代替 only_if | PASS | 两个步骤均无条件返回。 |
| 9 | 服务不放通用工具方法 | PASS | 字段归一化与校验由模型和 Contract 共享 concern 承担。 |
| 10 | Contract 自己提供参数派生逻辑 | PASS | `ApplicationFields#application_attributes` 提供归一化业务字段。 |
| 11 | 限流放控制器 | PASS | `ApplicationsController#rate_limit_submission` 为 before_action。 |
| 12 | 不用可选 model 步骤存临时值 | PASS | 唯一 model 是实际持久化的申请。 |
| 13 | model 创建直接使用 create | PASS | 使用非 bang 的 `create_or_find_by`，校验错误交给服务框架。 |
| 14 | 条件副作用各有步骤与 only_if | NA | 没有通知、事件或其他条件副作用。 |
| 15 | 只合并同概念同条件的副作用 | NA | 没有可合并副作用。 |
| 16 | 不滥用 try 掩盖持久化失败 | PASS | 无 try；控制器显式处理 model_not_found，返回503。 |
| 17 | 同一 MessageBus 通道受众一致 | NA | 没有 MessageBus 发布。 |
| 18 | 创建 model 使用自定义业务步骤名 | PASS | `model :application, :register_application`。 |
| 19 | only_if 改写保留默认分支 | NA | 没有 if/else 到 only_if 的转换。 |
| 20 | 避免不必要的外部小工具委托 | PASS | 共享字段 concern 在 Contract 和模型复用；无单次代理包装。 |
| 21 | 查询优先使用模型关联 | NA | 申请是独立记录，没有关联查询。 |
| 22 | 特权查询分支优先返回 | NA | 服务是公开提交命令，没有特权查询分支。 |
| 23 | 不保留兼容包装或 skip_policy | PASS | 控制器直接调用服务，旧独立 Node 服务未导入。 |
| 24 | 写入顺序保证回滚一致性 | PASS | 仅创建一条申请；重试匹配不修改已有申请。 |
| 25 | 序列化器继承 ApplicationSerializer | PASS | `IsbfJoin::ApplicationSerializer < ::ApplicationSerializer`。 |
| 26 | 条件属性使用 include 方法 | NA | 四个业务字段和元数据都是固定属性。 |
| 27 | 嵌套对象独立序列化 | NA | 没有嵌套业务对象。 |
| 28 | 调用点明确使用序列化器 | PASS | 后台控制器向核心 `serialize_data` 显式传入 `ApplicationSerializer`，无自定义包装。 |
| 29 | 预加载数据通过 serializer options 传入 | NA | 无关联或额外预加载数据。 |
| 30 | 控制器通过 service_params 传参 | PASS | `SubmitApplication.call(**service_params.deep_merge(params: application_params))`。 |

## 业务逻辑

| # | 规则 | 结果 | 依据 |
|---|------|------|------|
| 1 | 保留批准范围内所有原始流程 | PASS | 原表单字段、校验、错误/成功状态和15秒取消保留；仅增加 CSRF 请求接线。 |
| 2 | 副作用条件和顺序正确 | PASS | 校验失败不写库；首次201，相同内容重试200，冲突409且不覆盖记录。 |
| 3 | 保持原子性 | PASS | UUID 唯一索引；两个真实连接并发的相同/冲突提交均有回归测试。 |

## 权限与数据保护

| # | 规则 | 结果 | 依据 |
|---|------|------|------|
| 1 | 所有调用入口执行一致权限 | PASS | 公开服务仅允许创建/重试；记录列表继承管理员控制器，前端入口也只注册给管理员。 |
| 2 | 分类版主必须拥有具体分类权限 | NA | 独立申请无分类；普通用户与非管理员版主均无查看权限。 |
| 3 | MessageBus 安全受众一致 | NA | 没有 MessageBus 通道。 |
| 4 | 不泄漏私有记录 | PASS | 公开响应仅包含提交者给定 UUID 与结果；列表禁止缓存；请求日志过滤姓名/学号/手机；公开静态文件使用清单白名单。 |

另已通过请求测试验证 JSON 类型、4096字节上限、服务端字段校验、CSRF、
Origin/Sec-Fetch-Site、每 IP 限流、路径穿越与静态 MIME。只读/归档保护通过继承
`ApplicationController` 保留，未跳过对应回调；未为其单列新增测试。

## 测试结构

| # | 规则 | 结果 | 依据 |
|---|------|------|------|
| 1 | 独立 Contract model describe 和 shoulda 校验 | PASS | `submit_application_spec.rb` 的 Contract 分组使用 `allow_values`。 |
| 2 | .call 独立分组 | PASS | 执行测试置于 `describe ".call"`。 |
| 3 | 首先声明可复用的 result subject | PASS | `described_class.call(params:, **dependencies)`。 |
| 4 | subject、fab!、let、before 排序 | PASS | 执行分组按该顺序声明。 |
| 5 | 分支按步骤顺序排列 | PASS | Contract、持久化、重试匹配。 |
| 6 | 使用服务专用 matcher | PASS | `fail_a_contract`、`fail_to_find_a_model`、`fail_a_policy`、`run_successfully`。 |
| 7 | .call 不重复穷举 Contract | PASS | .call 仅用一个无效输入验证停止执行；完整字段校验在 Contract。 |
| 8 | 成功路径检查真实副作用 | PASS | 检查保存字段与数据库记录数量。 |
| 9 | 嵌套 let 触发分支，不复制 subject | PASS | 持久化失败和重试分支复用 result。 |
| 10 | 切换 actor 用 fab! | NA | 公开命令无 actor；后台权限在请求测试覆盖。 |
| 11 | 使用具体 RSpec matcher | PASS | 精确检查 change、eq、include 和记录字段，无裸 be。 |
| 12 | context 使用 when/with/without | PASS | 每个执行分支使用条件描述。 |
| 13 | 事件通过 track_events 验证 | NA | 无事件。 |
| 14 | MessageBus 使用 lazy track_publish | NA | 无 MessageBus。 |
| 15 | 准备数据使用 fabricator | PASS | 重试记录由 `isbf_join_application` fabricator 创建。 |
| 16 | 主题需首帖时用 topic_with_op | NA | 无主题数据。 |
| 17 | 新模型回调有 model spec | PASS | `application_spec.rb` 覆盖实际保存时归一化及校验。 |
| 18 | 复杂 action 独立测试 | NA | 没有独立 action；并发单列专门服务测试文件。 |
| 19 | 测试 context 顺序对应服务步骤 | PASS | 与 Contract → application → submission_matches 一致。 |

回归测试发现并修复两项实际问题：Rails 对无 XHR 请求头的公共模块脚本返回422；
服务框架将数据库异常记为 model 失败时，未处理分支导致隐式204。静态文件路由现在
单独跳过只读 JavaScript 响应校验，POST 的 CSRF 保留；持久化失败显式返回503。
最终结果与浏览器验证限制见 [validation.md](validation.md)。
