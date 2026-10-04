# 本地开发站点故障排查

本说明适用于当前仓库的 `discourse_dev` 开发容器。宿主机的
`127.0.0.1:3000` 转发到容器内的网页服务。容器运行、端口发布和网页服务正常
是三个独立状态。

## 2026-10-01 故障记录

北京时间 22:47 左右，网页服务停止响应。排查时发现：

- 宿主机 3000 端口仍由 Docker 转发，直接访问得到 `Empty reply from server`。
- 环境中的 HTTP 代理将该失败转换成了 `502 Bad Gateway`。
- 容器仍在运行，但内部没有监听 3000 端口的 Rails/Pitchfork 进程。
- PostgreSQL 的 `pg_isready` 正常，Redis 返回 `PONG`，前端构建进程仍在运行。
- 容器的 `memory.events` 中 `oom` 和 `oom_kill` 均为 0，`pids.events` 中
  `max` 为 0；检查时磁盘和可用内存没有耗尽。宿主机内核日志因权限限制未能
  完整读取，因此不据此判断故障前的全部资源变化。

容器内 `/tmp/isbf-rails.log` 的末尾记录了以下故障链路：

```text
worker=0 gen=0 pid=10909 timed out, exiting
Pitchfork worker is about to timeout, dumping backtrace for main thread
... pitchfork/http_parser.rb:79:in 'IO#readpartial'
mold gen=0 pid=9485 failed to spawn a worker, retrying
mold gen=0 pid=9485 failed to spawn a worker twice in a row - corrupted mold process?
mold gen=0 pid=9485 reaped (#<Process::Status: pid 9485 exit 1>)
Finished Plugin JS watcher thread
```

工作进程超时时正在读取 HTTP 请求。随后负责创建替代工作进程的 mold 连续两次
失败并退出。Docker 在北京时间 22:47:51 记录到原启动 exec 结束，退出码为 0；
该退出码不能代表网页服务健康。最后一条已完成的普通请求仍是 `200 OK`，
不能把日志中最近的业务请求直接认定为故障源。

本地安装的 Pitchfork 0.18.2 在 `fork_sibling` 未获得子进程 PID 时抛出
`ForkFailure`，mold 重试一次后退出。日志没有记录该中间进程为何未成功完成，
尚不能确定是 fork 回调阻塞、调度延迟或其他底层原因。

容器使用 `--restart=always`，但容器主进程仍在运行，因此网页子进程退出不会
触发容器自动重启。`bin/pitchfork` 的开发包装器只在收到 `USR2` 时安排重启，
没有通用的崩溃重启循环。

### 超时发生的位置

进一步核对原日志中的七次超时，堆栈均停在 `HttpParser#read` 的第 79 行：

```ruby
socket.readpartial(16384, buf)
```

这是接受 TCP 连接后对 HTTP 请求数据的第一次读取，尚未调用 Rails 应用。
因此，堆栈表明工作进程正在等待连接上的第一批请求数据，不能把它解释成某个
控制器或数据库查询执行了很久。开发配置默认在等待 60 秒后触发软超时，
另外保留 2 秒用于退出清理。

浏览器预连接、端口转发产生的空连接或连接中断前的停滞是可能来源，但目前
没有记录超时连接的客户端身份，无法确定具体来源。

恢复后的进一步检查又发现一次相同读取位置的超时；这次替代工作进程成功启动，
三个工作进程保持运行，健康检查仍返回 `200 ok`。这说明连接读取超时与后续
创建替代进程失败是两个需要分别追踪的问题。

## 检查步骤

从仓库根目录执行，访问本地地址时绕过环境代理：

```bash
docker ps --filter name=discourse_dev
curl --noproxy '*' --max-time 10 -v http://127.0.0.1:3000/srv/status
docker exec discourse_dev ss -ltnp '( sport = :3000 )'
docker exec discourse_dev pgrep -af 'pitchfork|rolldown|sidekiq'
docker exec discourse_dev pg_isready
docker exec discourse_dev redis-cli ping
docker exec discourse_dev cat /sys/fs/cgroup/memory.events
docker exec discourse_dev cat /sys/fs/cgroup/pids.events
```

查看网页服务的启动输出，而不只查看 `log/development.log`。本次原始启动输出
位于容器内 `/tmp/isbf-rails.log`，恢复输出位于
`/tmp/isbf-rails-recovery-20261001.log`。这些日志可能包含用户数据和认证信息，
共享排查记录时只提取必要的错误堆栈和时间信息。

## 恢复网页服务

先确认容器内没有网页服务监听 3000 端口，避免重复启动。本次已有一个独立的
Sidekiq 进程仍在运行，因此使用 `-x` 仅恢复网页服务：

```bash
docker exec -d -u discourse:discourse -w /src \
  -e RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
  -e LD_PRELOAD=/usr/lib/libjemalloc.so \
  -e NO_COLOR=1 \
  discourse_dev bash -lc \
  'exec bin/pitchfork -p 3000 -x >> /tmp/isbf-rails-recovery-20261001.log 2>&1'
```

启动后等待日志出现 `Pitchfork ready on http://localhost:3000`。首次请求可能
需要编译插件和样式，再检查首页、`/srv/status` 和浏览器加载情况。启用登录限制
的站点在未登录时对 `/site.json` 返回 `403 not_logged_in` 是正常的权限响应。

如果 Sidekiq 也已经停止，省略 `-x`，让网页服务按开发环境默认设置启动后台
任务。前端构建若也停止，应另外运行 `pnpm --dir frontend/discourse start`。
容器重启后需要重新启动这些开发服务，以及邮件捕获服务。

本次恢复后，三个网页工作进程均正常运行，首页返回 `200`，`/srv/status`
返回 `200` 和 `ok`。使用普通 Chrome 用户代理的浏览器成功显示站点首页及登录
入口，没有捕获到 JavaScript 异常或请求加载失败。未登录的 `/site.json` 返回
预期的 `403 not_logged_in`。

浏览器验证应使用普通用户代理：默认无头浏览器和 curl 可能被识别成爬虫，
返回不包含完整前端入口的爬虫页面，仅凭该页面的 HTTP 状态不能确认前端正常。

## 后续改进

应在开发环境为网页服务设置独立的进程监护和 HTTP 健康检查，并保存带时间戳的
启动、退出和重启记录；容器重启策略不能代替网页进程监护。若创建替代工作进程
再次失败，保留中间进程的堆栈和当时的资源指标，再决定是否调整服务器配置或
依赖版本。本次未修改进程监护配置或服务器实现。
