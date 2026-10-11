# initial-ui

来源：`docs/isbf-one-production-deployment.md`；原文件 SHA-256：`2a1cfe74d8ea8451afeaa4a9ed83f1df7686be0af2e9767ec34164b768b27b73`。

以下为原文摘录。仅证明摘录中说明的检查范围。

九个插件均加载成功：学院角色、账号切换、匿名发布、日历、探索、审核、通知、
转发、浏览量。账号关联、匿名池、日历及浏览量等插件表计数与备份一致。
没有重新执行会重设设置和分类权限的 `academy_roles:setup`。

- 九插件联合 RSpec：170 项，0 失败；八个修改的 Ruby 文件通过 `bin/lint --fix`。
- 使用真实管理员和普通成员验证身份、列表、日历、探索设置、通知及后台权限。
  普通成员访问后台返回 404，管理员返回 200；临时只读 API 密钥已删除。
- 登录页标题为 `ISBF-Space`，引用默认主题 ID 4；29 个脚本和样式均返回 200。
- 本机及外网 HTTPS 健康检查返回 200，TLS 校验为 0。
- HTTP 和 HTTPS www 请求均返回 301，目标为 HTTPS 根域名。
- 页面不再引用 `localhost:3000` 或临时 `isbf-one.com:8080` 地址。

