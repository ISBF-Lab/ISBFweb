# 学号邀请码使用说明

学院插件启用（`academy_roles_enabled=true`）后，每个注册邀请码必须绑定一个学号，
并且只能用于注册一个新账号。注册成功时，服务器自动将学号绑定到该账号。
只有站点管理员能查看学号；版主、普通成员、匿名身份和访客都不能查看，包括账号本人。

## 管理员发码

1. 使用站点管理员账号登录，打开
   `/admin/plugins/discourse-academy-roles/student-invites`，点击“生成学号邀请码”。
   `/new-invite` 和个人邀请页面的创建按钮也会打开同一个学号发码表单。
2. 输入学号和有效天数。学号按字符串保存，去除首尾空白，最多 64 个字符，
   保留前导零；例如 `001234` 和 `1234` 是不同学号。有效期默认采用
   `invite_expiry_days`，可选范围为 1–36500 天。
3. 创建后复制邀请码或完整邀请链接，发给对应学生。邀请码自动限制为单次使用，
   不预先绑定邮箱，也不授予官方成员身份。

同一个学号不能重复发码。对于尚未注册的学号，在列表中点击“重新生成邀请码”
即可发新码，旧码立即失效；也可以撤销未使用的邀请码。已过期、已撤销或已删除的
邀请仍保留学号记录，重新发码应使用原记录的“重新生成邀请码”。

## 学生注册

1. 在登录页输入邀请码，或直接打开管理员发来的邀请链接。
2. 填写邮箱、用户名、密码等注册信息。页面不显示学号，也不要求学生手动填写学号。
   密码注册和邮箱验证码注册均使用服务器保存的学号绑定。
3. 注册成功后，该学号与新账号永久绑定，邀请码不能再次使用。已有正式账号不能
   使用邀请码添加或更换学号。

注册失败会回滚账号创建、邀请码兑换次数和学号绑定，不会消耗邀请码。
单纯打开链接也不会消耗邀请码。并发注册时，同一邀请码最多有一次兑换成功。

邮箱激活仍沿用 Discourse 核心流程。密码注册后可能需要邮箱验证；学院初始化关闭的
“管理员审批”与邮箱激活是两个独立步骤。生产站点若仍未配置发信，需要完成 SMTP
配置或由管理员手动激活账号；本功能不跳过邮箱验证。

## 管理员查看绑定

邀请码列表显示学号、状态和已注册账号，可点击账号进入管理员用户详情。
管理员用户详情中的“学号”是只读字段。旧账号未补绑学号，显示“未绑定学号”。

注册后的学号不能修改、重发或转移；删除邀请码或账号也不会释放该学号。
删除账号后，邀请码列表保留“已注册”记录，账号列不再提供账号链接。
任何一方已经绑定学号的账号合并操作都会被拒绝。匿名身份不会获得学号绑定。

学号保存在独立的 `academy_student_registrations` 表中，不使用公开用户自定义字段。
只有管理员专用接口和管理员用户序列化器返回学号；公开资料、当前用户、偏好设置、
邀请兑换页面及版主用户详情接口均不返回该字段。

## 升级已有站点

部署代码并执行数据库迁移后，重启 Web 和后台任务进程。插件启用时，旧的未绑定
学号邀请码会被服务器拒绝兑换，已有账号保持可用。

可再运行下列任务，让旧码在核心邀请列表中也明确显示为失效：

```bash
LOAD_PLUGINS=1 bin/rake academy_roles:invalidate_unbound_invites
```

此任务只更新无学号记录的邀请码失效时间，可重复执行；不会删除邀请码或账号。
它要求学院插件已启用。无需重新运行 `academy_roles:setup`，该初始化任务会重设
站点设置及分类权限。

## 实现与验证

本次的自动化、浏览器验证与已有匿名插件失败基线见
[验证记录](academy-student-invitations-verification.md)。

- [绑定模型与唯一约束](../plugins/discourse-academy-roles/app/models/discourse_academy_roles/student_registration.rb)：
  学号、邀请码及账号的唯一绑定；注册后的身份不可更改。
- [发码服务](../plugins/discourse-academy-roles/app/services/discourse_academy_roles/create_student_invite.rb)、
  [重发服务](../plugins/discourse-academy-roles/app/services/discourse_academy_roles/reissue_student_invite.rb)及
  [撤销服务](../plugins/discourse-academy-roles/app/services/discourse_academy_roles/revoke_student_invite.rb)：
  管理员策略、输入校验和事务。
- [兑换扩展](../plugins/discourse-academy-roles/lib/discourse_academy_roles/student_invite_extension.rb)：
  锁定学号记录后调用核心注册流程，并在同一事务内写入绑定。
- [管理员接口](../plugins/discourse-academy-roles/app/controllers/discourse_academy_roles/admin/student_invites_controller.rb)：
  分页列表、发码、重发和撤销。
- [插件测试](../plugins/discourse-academy-roles/spec)：
  管理员权限、隐私、密码及验证码注册、并发兑换、失败回滚、删除保留和合并限制。

```bash
LOAD_PLUGINS=1 bin/rspec plugins/discourse-academy-roles/spec
bin/qunit plugins/discourse-academy-roles/test/javascripts
```
