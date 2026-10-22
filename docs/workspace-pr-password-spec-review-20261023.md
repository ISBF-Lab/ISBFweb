# 首次设密规格复核（2026-10-23）

本次复核属于整理当前分支的服务技能 Phase 7，由专门测试代理执行。工作范围限于隔离 worktree 的规格和本文；未修改产品代码，未操作生产环境。结构、业务和安全审阅沿用 [原服务审阅](design-system/reviews/post-signup-password-20261022/service-review.md)，此处记录增量检查与后续验证。

依据为 [服务文档 Testing](developer-guides/docs/03-code-internals/20-service-objects.md#testing)、[RSpec 规范](https://rspec.rubystyle.guide/)及 `discourse-writing-rspec-tests` 技能。以下 PASS 表示静态结构已检查，运行结果单独列出。

## Phase 7 规格检查

| # | 规则 | 结果 | 依据 |
| --- | --- | --- | --- |
| 1 | Contract 独立 `type: :model` 并使用 shoulda | PASS | `set_initial_password_spec.rb` 独立验证存在性、确认一致性及最大长度；跳过服务没有合同 |
| 2 | 服务调用以 `.call` 分组 | PASS | 两个服务 spec 均只有一个 `.call` 执行分组 |
| 3 | 共享、可参数化 subject 位于调用分组首位 | PASS | 两个服务均为 `subject(:result) { described_class.call(params:, **dependencies) }` |
| 4 | setup 顺序为 subject、fab!、let、before | PASS | 两个服务 spec 顺序一致；params 与依赖各有独立 let |
| 5 | 按服务步骤为失败分支划分 context | PASS | 首次设密依次覆盖合同、权限、查找、提醒资格、可信会话及保存失败；跳过覆盖权限、查找与幂等成功 |
| 6 | 步骤失败使用服务专用 matcher | PASS | 使用 `fail_a_contract`、`fail_a_policy`、`fail_to_find_a_model`、`fail_a_step` 和 `run_successfully` |
| 7 | `.call` 不重复穷举合同校验 | PASS | 合同细节独立测试；调用中仅以 nil 密码验证合同中止，以短密码验证 User 模型拒绝 |
| 8 | 成功分支验证执行成功及真实副作用 | PASS | 验证可用密码、提醒清除、令牌撤销、邀请失效与本人审计；跳过验证登录不变 |
| 9 | 分支覆盖通过 setup/let 调整，调用不重复 | PASS | 参数与会话状态由 let 调整，均共享 result |
| 10 | 更换 actor 使用 fab!，不替换 guardian let | PASS | 不活跃、停用、暂存与匿名账号使用 fab!；未登录场景通过依赖传入匿名 Guardian |
| 11 | 使用明确 matcher | PASS | 使用 change、eq、include、be_empty、have_password、be_expired 及服务专用 matcher，没有裸 be |
| 12 | context 以 when/with/without 描述条件 | PASS | 两个服务 spec 全部 context 符合 |
| 13 | 事件以 track_events 验证 | PASS | `password_setup_user_spec.rb` 捕获真实 `user_created` 事件；没有手工 on/off |
| 14 | MessageBus 发布以惰性 let 捕获 | NA | 本功能没有 MessageBus 发布 |
| 15 | 测试记录使用 fabricator | PASS | 使用 `academy_password_setup_user`、invite、user、令牌和二次验证等 fabricator，没有直接 create! setup |
| 16 | 需要首帖的主题使用 topic_with_op | NA | 本功能规格不构造主题 |
| 17 | 新回调通过模型公开操作验证 | PASS | User 创建及更新规格覆盖新无密码账号、已有密码、暂存/系统、历史账号、禁用登录、SSO及其他路径设密 |
| 18 | 复杂独立 Action 独立测试 | NA | 两个服务没有复杂独立 Action |
| 19 | context 与方法顺序对应步骤顺序 | PASS | 首次设密按合同到保存顺序组织；跳过成功后另列已跳过的幂等场景 |

请求规格覆盖认证、当前账号范围、确认不匹配、模型拒绝后保留登录、五分钟信任窗口及确认会话、重复设置、跳过后设置、API/用户 API、冒充、停用本地登录、SSO、限流、禁用插件和 CSRF。序列化规格覆盖本人可见、其他账号不可见、公开资料不泄露、自其他路径设密后消耗状态及冒充会话。

## 本次最小补充与修复

- `spec/services/set_initial_password_spec.rb`：模型拒绝密码时，额外验证不会产生成功改密审计，邀请仍有效；沿用原失败路径，不新增重复用例。
- `spec/requests/password_setup_controller_spec.rb`：新增客户端伪造 `trusted_session: true` 的请求，验证过了注册信任窗口仍返回 403，未创建密码且保留提醒。
- `spec/lib/moderator_permissions_spec.rb`、`spec/requests/moderator_permissions_controller_spec.rb`：将过时的 21 项计数改为 22，保留固定长度、完整布尔数组、每个权限独立授权与即时撤销检查。`origin/main` 的 `ModeratorPermissions::SETTINGS` 已列出 22 项（包含 `review_alumni` 和 `trace_anonymous`），此次不修改权限实现或默认值。

## 验证记录

复核开始前的既有记录为本功能 66 项通过、包含跨插件场景时 67 项通过；学院插件完整套件 297 项中 5 项失败，其中 3 项涉及过时的 21 项能力计数，2 项涉及离线验证未加载活动插件。它们是先前结果，不能作为上述新增断言已运行的证据。

主代理调度后已串行执行完整学院插件套件：**303 项通过，0 失败，0 pending，0 套件外错误**，随机种子 **48989**，RSpec 执行 **331.19 秒**。其中首次设密的服务、请求、模型和序列化规格共 **68 项通过**，包含新增的伪造会话参数测试及已加载匿名池插件的分支。旧的三项权限计数失败和两项活动插件缺失失败均已在完整真实加载环境下通过；没有排除、跳过或弱化原用例。

原生结果为 [`rspec-academy-merged.json`](design-system/reviews/post-signup-password-20261022/rspec-academy-merged.json)。所有新增/修改规格仍须包含在主代理最后统一执行的 `bin/lint --fix` 文件列表中；本代理不另行重复测试。

完整学院套件应使用 `ISBF_PASSWORD_SETUP_PLUGINS=automation,chat,discourse-events,discourse-academy-roles,isbf-anonymous,isbf-learning,isbf-resume`。此源码的活动插件实际目录为 `plugins/discourse-events`，没有独立的 `discourse-post-event` 或 `discourse-calendar` 插件目录。活动启动时无条件扩展 `Chat::Channel` 及其序列化类，故必须同时加载 chat；chat 启动时还调用 `add_automation_scriptable`，对应供应插件的实际目录为 `automation`。`rrule` 已在核心 Gemfile/锁文件中，离线测试缓存有 0.8.0；holidays 随活动插件 vendor 源码提供，无需联网安装。

既有隔离 `rspec.sh` 会把该名单传入 LOAD_PLUGINS，按组合生成独立 seed 标记并在合成测试库执行迁移及种子。使用的 PostgreSQL 为 `/spec-data/socket`、端口 15432；Redis 为工具容器回环 16379；容器禁用网络。测试数据和 bundle 缓存来自主仓库 `deploy-work/post-signup-password-20261022/rspec-data`，不读取生产数据库。

本轮实际命令如下，测试镜像为 `local_discourse/isbf_app:feed-name-colors-20261021-26d552c5e0ad`：

```bash
ISBF_DIALOGS_SPEC_RUNNER=1 \
ISBF_DIALOGS_TOOLS_IMAGE=local_discourse/isbf_app:feed-name-colors-20261021-26d552c5e0ad \
python3 deploy-work/workspace-pr-20261023/run-review.py \
  env ISBF_PASSWORD_SETUP_PLUGINS=automation,chat,discourse-events,discourse-academy-roles,isbf-anonymous,isbf-learning,isbf-resume \
  bash /review/rspec.sh plugins/discourse-academy-roles/spec \
  --format progress --format json --out /review/rspec-academy-merged.json
```

## 启动及资源记录的限制

仅使用一个命名工具容器，未并发启动第二个容器。首次启动因隔离目录缺少 `app/assets/generated` 挂载点而终止，创建忽略的空缓存目录后修复；第二次启动暴露 chat 需要 automation，补齐真实加载名单后才开始本次完整套件。两个未执行规格的启动日志分别为 `rspec-academy-merged-startup-mount.log` 与 `rspec-academy-merged-startup-automation.log`。

本次 runner 按当时可持续容量设置容器内存及总交换限额 **4,093,640,704 bytes**，另预留 **536,870,912 bytes**，CPU 0.5、进程上限 192、runner 原设时间上限 900 秒。宿主 wrapper 会话在测试中途以 143 结束，容器内原有套件仍继续执行。尝试接管同一容器时，套件已经完成并自动删除；没有重复执行套件。

因此 `rspec-academy-merged.log` 仅保存中断前 stdout，缺少 wrapper 最终资源摘要，**不声称完整峰值内存或全程宿主监控记录**。测试完成以完整原生 JSON 和 [Docker 生命周期证据](design-system/reviews/post-signup-password-20261022/rspec-academy-merged-lifecycle.json) 为准：该容器 `die` 的实际退出码为 **0**，随后存在 `destroy` 事件，另已确认容器对象不存在。容器固有内存、CPU 和进程限制保持；宿主中断后的超时监控无法确认。
