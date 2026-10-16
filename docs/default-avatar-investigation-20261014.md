# 系统默认头像显示异常排查（2026-10-14）

用户提供页面：`https://isbf-one.com/u/wpf/preferences/account`。
要求：仅排查，不修复。下文时间均为北京时间（UTC+8），原始生产日志使用 UTC。

## 结论

默认字母头像通过本站 `/letter_avatar_proxy` 从 `avatars.discourse-cdn.com` 下载。
生产记录证明：下载器在读取 HTTPS 代理 CONNECT 响应时遇到
`EOFError: end of file reached`，头像接口随后返回 HTTP 500。
头像控制器没有捕获该异常，因此没有走占位图回退。

已定位直接故障环节和返回 500 的机制；现有证据不能确定代理链中具体哪个节点
关闭了连接，也不能证明代理故障已经永久消失。

## 用户与设置

- 数据库只读事务确认 `wpf` 的用户 ID 为 37。
- `uploaded_avatar_id`、`custom_upload_id`、`gravatar_upload_id` 均为空，符合使用
  系统默认头像的状态。
- 相关站点设置没有数据库覆盖，也没有发现对应容器环境变量覆盖；生产源码默认
  `external_system_avatars_url=/letter_avatar_proxy/v4/letter/{first_letter}/{color}/{size}.png`。
- 按生产调色板计算，wpf 的地址为
  `/letter_avatar_proxy/v4/letter/w/e9bcb4/{size}.png`。
- 正 ID 用户中有 13 个账户未选择上传头像；这不是实际故障人数的统计。

## 直接证据

Nginx 记录中，19:55–19:57 的 wpf 48、96 像素头像多次返回 500。
同一时间段，其他字母头像也有 500；部分已有缓存的头像返回 200。
账户页使用 `huge` 尺寸，实际图片尺寸还会根据设备像素比选择；用户当时的
账户页请求为 288 像素。

Logster 异常组 `c1a3b640cf0ebc161fab3da6ba02240a` 的消息为：

```text
Failed to process hijacked response correctly : EOFError : end of file reached
```

调用栈依次经过 `Net::HTTPResponse.read_status_line`、`Net::HTTP#connect`、
`FinalDestination::HTTP#connect`、`FinalDestination#safe_session`、
`FileHelper.download`、`UserAvatarsController#proxy_avatar` 和
`UserAvatarsController#show_proxy_letter`。
生产 `net-http-0.9.1/lib/net/http.rb:1707` 对应读取 CONNECT 响应，发生在上游
TLS 握手之前。异常上下文直接包含 wpf 的 48、96 像素请求及其他默认头像请求。

该异常组累计计数 454，首次时间为 10 月 5 日 14:30:35，最近一次为
10 月 14 日 19:57:29。计数是日志组累计次数，不是受影响用户数。

源码机制：`app/controllers/user_avatars_controller.rb:60` 只捕获
`OpenURI::HTTPError`；`lib/hijack.rb:79` 在异常后没有响应正文时设置 500。

## 后续恢复与缓存

既有访问日志与缓存文件时间互相吻合：

| wpf 尺寸 | 下载成功时间 | 日志状态及请求耗时 | 当前缓存文件大小 |
| --- | --- | --- | --- |
| 48 | 20:01:45 | 200，6.730 秒 | 905 字节 |
| 96 | 20:02:11 | 200，30.972 秒 | 1177 字节 |
| 288 | 20:02:15 | 200，29.603 秒 | 3850 字节 |

这些成功请求来自排查前的现有浏览器访问。下载成功后，后续相同地址可以直接
使用磁盘缓存；不同尺寸是不同缓存文件。因此某个头像后来可显示，不足以证明
其他未缓存头像或尺寸的外部下载链路可靠。

## 操作边界与限制

没有修改产品源码、头像选择、主题、站点设置或数据库，没有创建认证凭据，
没有重启、发布或清理生产缓存。账户页需要登录；本次没有创建登录会话，
页面行为依据用户已有请求日志、组件源码及图片响应核对，没有做完整视觉验收。

排查中有一次 wpf 144 像素图片 GET 触发服务器正常下载和自动缓存生成，
缓存时间为 20:09:31，大小 1611 字节。这是排查请求的写入副作用；不能把
本次操作描述为生产文件完全没有写入，也不能把它归入排查前的恢复证据。
公网、本站回环和容器上游响应的图片 SHA256 均为
`d86105ac099b63362fec77b0f10a2cdba19f8d0659806033cd79072c4d3b031f`。

自动审批随后拒绝再次请求生产头像，理由是 GET 可能触发代理缓存写入，
不符合用户仅排查的范围。之后只读取已有日志、异常记录和缓存文件；
没有绕过拒绝或继续发起图片请求。本次仅新增这份本地排查记录，没有实施修复。
