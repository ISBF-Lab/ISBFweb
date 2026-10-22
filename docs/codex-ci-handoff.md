# PR 的后台 CI 等待与原会话续跑

本仓库默认采用：推送 PR → 登记等待 → 结束模型回合 → 后台等待 CI → 原会话继续。
`AGENTS.md` 指向共同规则 `AI-AGENTS.md`，新对话在本仓库做 PR 时同样遵循这条规则。

等待器只使用 Python 标准库、GitHub 只读接口和现有 Codex daemon 的本地 Unix 控制 socket。
等待期间不调用模型，不启动或重启 Codex 服务，也不需要新的 OpenAI API key。
2026-10-22 核对的客户端为 0.163.0，现有 daemon 为 0.162.1。

## 使用

先完成源码检查、正常提交与推送，再登记已推送的 PR：

```bash
python3 script/codex_ci.py doctor
python3 script/codex_ci.py watch --pr 76 --next-step "检查审查结果；CI 通过后完成用户已授权的合并，并安全同步 main"
```

编号和剩余工作须使用当前任务的实际值。`--next-step` 只记录原有授权，不能借此为只要求创建 PR 的任务自动合并。
成功登记后报告等待状态并结束本轮。默认每 120 秒查询检查，GitHub 限流时按响应头退避。
这些网络请求和本地线程状态查询均不调用模型。

程序使用 `CODEX_THREAD_ID` 的精确 UUID，并检查线程和工作树属于同一 Git 仓库。
若环境不提供它，须明确传入 `--thread UUID`；不得猜测其他会话或使用 `--last`。
自定义本地 daemon 可传入 `--socket /absolute/path/to/control.sock`。
服务须支持 `thread/read`、`thread/queue/list`、`thread/queue/add` 和 `thread/queue/start`。

```bash
python3 script/codex_ci.py status
python3 script/codex_ci.py cancel --job 实际等待记录的UUID
```

`status` 用于开始新工作、排查或明确的状态请求，不需要让模型循环查询。
同一 PR、提交和线程的重复登记复用尚未结束的等待；一次等待结束后，可为 CI 重跑重新登记。
新提交或线程会取代该 PR 尚未投递的旧等待。已经入队或发送状态不确定的旧记录须先检查、取消。

## 完成判定与续跑

- 等待最新 check runs、经典 commit statuses 和该 SHA 的工作流全部完成，结果稳定至少 30 秒。
- 投递前核对 PR 仍打开且 head SHA 相符，避免使用旧提交的结果。
- 失败、缺少检查和等待超时分别通知，不能视为 CI 成功。
- 原线程工作时先等待，不中断该回合；保留已排队的人类消息顺序。
- 只投递状态、结果路径和原任务；续跑时再读取必要的失败日志。
- 续跑仍须核对当前检查、未解决审查和用户授权，保留其他 worktree 与新改动。

状态保存到共享 Git 主目录旁的 `deploy-work/codex-ci/`，不同 worktree 共用登记表。
目录权限为 0700，JSON 为 0600；不保存 token 或环境变量。
公共仓库可匿名读取，私有仓库使用已配置的 `GH_TOKEN` 或 `GITHUB_TOKEN`，不从凭据文件提取秘密。
后台保留现有代理和 CA，不通过关闭 TLS 或绕过网络策略重试。

每个仓库只有一个 worker，并保存自己的脚本副本，切换分支不会丢失已登记的等待。
正常投递保存消息 ID，重启后不会重复入队。若发送中断，无法确认服务器是否接受，
记录为 `delivery_unknown` 并停止自动重发；须先检查原会话与队列。
本机实测服务器不会按 `clientUserMessageId` 去重，因此不能通过直接重发来恢复未知投递。

worker 是独立后台进程，不是随主机启动的系统服务。主机重启或资源保护停止进程后，
先查看 `status`，再从记录中的 worktree、相同提交和原线程重新运行 `watch`，可复用尚未结束的等待。
升级脚本时，须先处理旧版本拥有的等待；程序不会覆盖仍在处理任务的旧运行副本。

默认等待上限为 24 小时，超时会通知原会话。投递服务长期不可用时保留阻塞记录。
PR 已关闭或 head 被外部改动时取消旧等待，因此每次推送后都应重新登记。

## 资源和验证

worker 按启动时主机可用内存和有效 cgroup 剩余额度计算预算，预留至少 512 MiB。
它设置地址空间限制，并每秒监控自身 RSS 与服务余量；超限只停止本任务 worker，保留待办。
资源和心跳记录与任务状态放在同一持久目录，不调整现有 Codex、生产或其他开发服务。

测试不需要 Codex、GitHub 认证或网络：

```bash
python3 -m unittest discover -s script/tests -p 'test_codex_ci*.py' -v
```

覆盖未完成工作流、经典状态、旧 SHA、空检查、失败、超时、忙碌线程、队列顺序、重复投递防护、
断连、WebSocket 分片和私有状态文件。`Codex CI handoff` 工作流为这些文件的变更执行检查，保留既有 CI 门禁。
2026-10-22 已在现有 daemon 上验证原线程读取、队列查询、加入和删除；探针未启动额外模型回合。

协议依据：[官方 CLI 队列命令](https://learn.chatgpt.com/docs/cli/reference)、
[App Server 协议](https://learn.chatgpt.com/docs/app-server)和本机生成的对应版本 JSON schema。
运行约束见[资源规范](design-system/resource-policy.md)。

## Windows Desktop 适配

`script/codex_ci_win.py` 为 Windows 单独提供同一等待流程，依赖 Python 3.10+、Git 和支持精确线程队列的现有 Codex CLI。Linux 工作区继续使用上面的 Unix socket 版本。Windows 版的 `watch`、`doctor`、`status` 和 `cancel` 使用相同子命令名称；线程、PR head 和已授权剩余工作的约束保持一致。

Windows 版只读查询本地线程、回合及队列元数据，通过官方 CLI 入队；不写入 Codex 数据库。它等待现有 Desktop 消费队列，核对消息收据，无法确认投递时停止重发。Desktop 元数据表和 CLI 回执发生变化时会报错，不能将缺少回执当作完成。

离线回归覆盖检查完成判定、精确线程、忙碌回合、人类消息顺序、过期回调、未知收据、只读元数据及 worker 锁；CI 同时在 Linux 和 Windows 运行该适配器测试。本次 Linux 主机没有执行真实 Windows Desktop 的端到端自动续跑；这部分仍需在目标 Desktop 环境验证。
