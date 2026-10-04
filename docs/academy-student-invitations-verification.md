# 学号邀请码验证记录

验证日期：2026-10-04。功能使用方式和部署步骤见
[学号邀请码使用说明](academy-invitation-guide.md)。

## 测试环境

在独立 Docker 容器中创建空的开发与测试数据库，执行核心和插件迁移，使用
Ruby 3.4.10、PostgreSQL 18、Node 22、pnpm 10.34.5 和 Chrome 151。
生产容器与生产数据库未修改。测试账号、邮箱、学号均为合成数据。

后端测试加载现有插件；浏览器服务加载学院身份、匿名及关联账号插件。
浏览器检查分别使用桌面视口和 Pixel 7 手机视口。密码注册验证临时关闭隔离数据库
中的邮箱验证码注册设置；两种注册路径均由请求测试覆盖。

## 自动化结果

| 范围 | 结果 |
| --- | --- |
| 学院插件 RSpec | 97 项通过，0 失败，随机种子 25299 |
| 学院插件 QUnit | 12 项通过，0 失败，随机种子 JoqNz16v，无弃用提示 |
| 核心邀请模型、兑换模型、邀请接口及关联账号插件 | 326 项通过 |
| 数据库结构导出与模型注释 | 通过；新增模型注释已更新 |
| Ruby 格式与 RuboCop | 通过 |
| Prettier、ESLint、Stylelint | 通过 |
| `git diff --check` | 通过 |

后端覆盖管理员发码权限、字符串学号与前导零、学号及账号唯一性、重复发码、
过期与撤销、重新发码、密码及邮箱验证码注册、并发兑换、失败回滚、隐私、
删除保留、账号合并限制以及插件关闭时的核心行为。

前端覆盖表单校验、权限隐藏、创建结果、两种核心邀请弹窗开关、管理员新建路由
的实际表单渲染、未来到期日期的明确年份，以及管理员学号只读展示。

复运行主要测试：

```bash
LOAD_PLUGINS=1 bin/rspec plugins/discourse-academy-roles/spec
bin/qunit plugins/discourse-academy-roles/test/javascripts
LOAD_PLUGINS=1 bin/rspec spec/models/invite_spec.rb \
  spec/models/invite_redeemer_spec.rb spec/requests/invites_controller_spec.rb \
  plugins/isbf-account-switch/spec
```

`bin/lint --fix` 已执行。该未内置插件没有独立安装前端 lint 工具，因此
`bin/lint` 的插件分支找不到 `prettier`、`eslint` 和 `stylelint`；对应检查使用
仓库根目录的 `pnpm exec` 工具完成。Ruby 分支的 stree 和 RuboCop 正常通过。

## 浏览器操作验证

管理员实际创建邀请码、重发、撤销并重新发码均成功。访客邀请页面不包含学号；
使用邀请码注册后，管理员列表显示已注册账号，邀请码不再显示，用户详情中的学号
为只读字段。已绑定账号不显示合并入口，服务器同时拒绝将其他账号合并到它。

## 匿名插件基线

合并运行核心邀请、关联账号与匿名插件时，共 363 项，29 项失败，全部位于
`plugins/isbf-anonymous/spec`。随后从加载名单中完全排除学院插件，保留其他
52 个插件并单独运行匿名插件测试：37 项中仍有相同 29 项失败，随机种子 55689。
基线脚本在 suite 开始前断言 `DiscourseAcademyRoles` 未加载、`IsbfAnonymous`
已加载，排除了学院插件补丁仍在内存中影响测试的情况。

已有失败包括旧匿名身份迁移中的 `topics.last_post_user_id` 非空约束、匿名发帖
返回 403、未创建帖子及后续审核对象为空。本次未修改匿名插件。上述失败应在
匿名插件维护中单独处理，不能将该合并测试报告标记为全绿。
