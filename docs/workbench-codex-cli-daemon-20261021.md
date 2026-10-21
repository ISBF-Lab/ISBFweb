# Codex CLI 默认启动超时：daemon 未继承代理

2026-10-21，在本开发主机排查并恢复。普通启动报错：

```text
Error: account/read failed during TUI bootstrap: account/read failed: workspace routing discovery timed out (code -32603)
```

`codex --no-daemon` 可以启动。

## 原因与证据

交互终端和当前 `--no-daemon` 会话均设置了以下代理：

```text
HTTP_PROXY=http://127.0.0.1:17897
HTTPS_PROXY=http://127.0.0.1:17897
http_proxy=http://127.0.0.1:17897
https_proxy=http://127.0.0.1:17897
```

此前常驻 daemon 的上述四项变量全部缺失，`ALL_PROXY` 也未设置。
其日志持续出现 `failed to refresh available models: request timed out`。
本机 `~/.bashrc` 的 `proxy` 是设置环境变量的交互别名；后来在终端执行别名，
不会更新已经运行的 daemon 的环境。

通过本地 WebSocket 完成初始化后，读取当前已加载会话数为 0。
随后发送相同的只读请求进行修复前后对照：

```json
{
  "id": 2,
  "method": "account/read",
  "params": { "refreshToken": false }
}
```

| 阶段 | 耗时 | 结果 |
| --- | --- | --- |
| 重启前 | 15.002 秒 | `-32603: workspace routing discovery timed out` |
| 从代理环境重启后 | 0.012 秒 | 成功返回已登录的 ChatGPT 账号 |

账号地址和凭据不记录在本文件中。

## 恢复操作

在已设置代理的终端执行：

```bash
proxy
codex app-server daemon restart
codex
```

`proxy` 是本机现有的 Bash 别名，其他主机应使用自己的代理配置。
重启前应确认后台没有正在进行的工作；本次通过 `thread/loaded/list`
确认后台未加载会话，当前排查会话使用独立的 `--no-daemon` 进程。

恢复后已核对新 daemon 的四个代理变量与终端一致。
CLI 为 0.163.0，缓存中的 daemon 为 0.162.1；本次使用已有管理命令重启，
没有执行升级或重新登录。

另外启动空白 TUI，使用 `--no-alt-screen` 采集界面，没有传入 `--no-daemon`。
持续观察 20.15 秒，正常显示 Codex、GPT-6.1-Sol、输入提示和额度状态，
没有出现原来的 bootstrap 错误。检查没有发送模型消息，测试终端随后退出。

后续若变更代理，或 daemon 曾在未配置代理的终端启动，需要在代理生效后重新启动它。
`--no-daemon` 可作为临时恢复方式；它绕过共享后台服务，因而能直接继承当前终端环境。

## 验证资源

有效 cgroup 层级的内存上限均为 `max`。各次检查重新读取主机可用内存，
预留 536,870,912 字节；原生 CLI 检查使用 RSS 监控，
超过本次预算或主机可用内存低于预留值时终止本次工具。
轻量 WebSocket 检查单独设置 134,217,728 字节的地址空间上限。

| 检查 | 启动时可用内存（字节） | 本次上限（字节） | 峰值 RSS（字节） |
| --- | --- | --- | --- |
| 重启前 WebSocket | 1,322,942,464 | 134,217,728 | 13,283,328 |
| daemon 重启 | 1,311,899,648 | 775,028,736 | 258,142,208 |
| 重启后 WebSocket | 1,274,572,800 | 134,217,728 | 13,262,848 |
| TUI 完整界面验证 | 1,314,889,728 | 778,018,816 | 461,910,016 |

重启峰值统计管理命令、新 daemon 与监控器；TUI 峰值统计测试客户端与监控器。

## 参考

- [OpenAI 官方 CLI 参数说明](https://learn.chatgpt.com/docs/cli/reference)：`--no-daemon` 绕过共享后台服务。
- [OpenAI 官方 App Server 协议](https://learn.chatgpt.com/docs/app-server)：初始化、`thread/loaded/list` 和 `account/read`。
- 本地管理命令以安装版本的 `codex app-server daemon --help` 为准。
