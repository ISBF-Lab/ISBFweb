# 服务对象审阅

本次实施授权来自用户确认后的完整方案及“Implement the plan”，后续“continue／继续”沿用同一授权。分析阶段已核对核心注册、邀请码兑换、登录、密码保存、CurrentUserSerializer、会话信任规则、Guardian、共享DModal及FormKit。服务采用`SetInitialPassword`与`DismissPasswordSetup`，分别表达首次设密与跳过提醒两个用户动作。

服务规格由独立测试代理按服务技能的Phase 7编写和运行，主代理负责产品实现与前端测试。所有容器验证串行；原生运行结果见对应日志。本文件记录代码审阅，不将静态PASS视为运行测试通过。

## 结构

| # | 规则 | 结果 | 依据 |
| --- | --- | --- | --- |
| 1 | 名称表达业务概念 | PASS | `SetInitialPassword`、`DismissPasswordSetup`对应已确认动作 |
| 2 | 步骤单一职责 | PASS | 保存、消耗提醒、邀请失效和审计各有步骤 |
| 3 | 步骤使用领域词汇 | PASS | `password_setup_pending`、`complete_password_setup`、`invalidate_invitations` |
| 4 | 参数命名明确 | PASS | 只有`password`和`password_confirmation`；目标来自guardian |
| 5 | 避免context手工存值 | PASS | 使用model、params和依赖关键字 |
| 6 | 事务只包含须原子完成的数据库写入 | PASS | 密码、提醒、邀请、审计及核心令牌失效同事务；登录cookie在控制器成功分支处理 |
| 7 | 锁仅覆盖并发敏感步骤 | PASS | 用户行锁在服务事务内，重新读取资格后保存或跳过 |
| 8 | 步骤不用顶层提前返回代替策略 | PASS | 资格及信任均为policy，写入步骤无顶层guard |
| 9 | 服务没有工具函数 | PASS | 字段存储归`PasswordSetup`，服务仅编排动作 |
| 10 | 合同逻辑集中 | PASS | 长度、存在性及确认一致性位于params |
| 11 | 限流留在控制器 | PASS | `rate_limit_password_setup` before_action |
| 12 | 不用optional model储存判断值 | PASS | 唯一模型是锁定的当前User |
| 13 | 创建模型使用create而非new/save组合 | NA | 此处更新已有User；审计使用create! |
| 14 | 独立副作用步骤及条件明确 | PASS | 提醒、邀请、审计分别独立；均只在成功保存后执行 |
| 15 | 仅同一业务动作合并副作用 | PASS | 不合并不同副作用 |
| 16 | 不过度使用try | PASS | 没有try；正常校验失败由save false和fail!表达 |
| 17 | MessageBus audience一致 | NA | 本次服务不发布MessageBus |
| 18 | 创建模型步骤有业务名称 | NA | 不创建新的业务模型 |
| 19 | only_if正确区分条件与默认行为 | NA | 没有条件副作用或only_if |
| 20 | 小型外部辅助逻辑恰当内联 | PASS | policy直接调用Guardian，字段存储跨创建／设置／跳过／序列化共享 |
| 21 | ActiveRecord关联查询 | PASS | `UserCustomField.where(user:, name:)`；当前用户行按guardian.user.id查找 |
| 22 | fetch中权限分流清晰 | PASS | 前置policy拒绝匿名和无权操作；fetch仅查当前用户 |
| 23 | 没有跳过policy或兼容包装 | PASS | 两个服务独立检查权限，没有skip_policy参数 |
| 24 | 写入顺序保证回滚一致 | PASS | 先成功保存密码，再消耗提醒、邀请和日志 |
| 25 | Serializer继承ApplicationSerializer | PASS | 扩展已有CurrentUserSerializer，无新建普通序列化类 |
| 26 | 条件属性遵守include接口 | PASS | 本人当前用户只读布尔状态；无自造动态嵌套序列化 |
| 27 | 嵌套数据独立序列化 | NA | 无嵌套序列化对象 |
| 28 | 调用点直接使用序列化接口 | PASS | 当前用户沿用插件add_to_serializer公开API |
| 29 | 批量预加载经options传递 | NA | 单个当前用户，不存在批量或N+1列表 |
| 30 | 控制器用service_params/deep_merge | PASS | update显式合并可信会话状态，destroy直接调用service_params |

## 业务与安全

| # | 规则 | 结果 | 依据 |
| --- | --- | --- | --- |
| 1 | 原注册入口及条件保留 | PASS | 原注册仅在user_created事件追加非密码持久标记，不改邀请码兑换、验证码或跳转 |
| 2 | 保留核心副作用 | PASS | 使用User#password=及User#save；令牌失效由核心回调执行，成功后重建当前登录 |
| 3 | 事务边界一致 | PASS | 一次User行锁覆盖设置与跳过，验证失败fail!回滚，成功统一完成 |
| 4 | 所有调用均校验权限 | PASS | Guardian策略同时用于服务和当前用户可见状态；控制器额外拒绝API |
| 5 | 分类与群组权限限定具体资源 | NA | 仅操作本人账号，没有分类资源 |
| 6 | MessageBus限制接收者 | NA | 不发布MessageBus |
| 7 | 不向其他用户泄露私有状态 | PASS | 状态只加在CurrentUserSerializer，不登记为可编辑字段或公共用户字段 |

已处理的实现陷阱：`User#has_changes_to_save?`可能在只有`has_one :user_password`变化时返回false，不能依靠Service::ModelStep检查密码模型错误。因此保存步骤显式检查`user.save`，失败即`fail!`，不会错误消耗提醒或记录成功审计。停用账号也在服务Guardian策略中显式拒绝，不依赖HTTP会话层代为拦截。

## 规格结构

| # | 规则 | 结果 | 依据 |
| --- | --- | --- | --- |
| 1 | Contract独立type:model及shoulda | PASS | `set_initial_password_spec.rb` |
| 2 | 服务用.call分组 | PASS | 两个服务spec |
| 3 | 共享subject位于.call首个声明 | PASS | `described_class.call(params:, **dependencies)` |
| 4 | subject/fab!/let/before顺序 | PASS | 两个服务spec |
| 5 | 每个分支context按步骤排序 | PASS | contract、permission、model、pending、trust、save |
| 6 | 服务专用matchers | PASS | fail_a_contract、fail_a_policy、fail_to_find_a_model、fail_a_step、run_successfully |
| 7 | 不在.call穷举合同校验 | PASS | 合同独立，执行路径只验证中止 |
| 8 | 成功路径验证真实副作用 | PASS | 密码、提醒、令牌、邀请、UserHistory |
| 9 | let覆盖分支而不重复subject | PASS | 服务spec共享调用 |
| 10 | fab!覆盖actor | PASS | Guardian作用于真实用户 |
| 11 | 明确匹配器 | PASS | change、eq、predicate及服务matchers |
| 12 | context使用when/with/without | PASS | 服务spec上下文 |
| 13 | 事件使用track_events | PASS | user_created模型路径 |
| 14 | MessageBus捕获方式 | NA | 没有发布 |
| 15 | 用fabricator构造 | PASS | `academy_password_setup_user`及既有fabricators |
| 16 | 有OP时用topic_with_op | NA | 没有帖子 |
| 17 | 模型回调有公开行为测试 | PASS | 无密码新建、旧账号、暂存及匿名账号 |
| 18 | 复杂独立Action单独验证 | NA | 没有复杂独立Action |
