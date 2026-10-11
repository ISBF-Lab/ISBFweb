# auth-accepted

来源：`docs/isbf-auth-page-production.md`；原文件 SHA-256：`913c0c417e0b80dd27b8b60b3e12d2816ace17caccc1eac7b145f0d76b990068`。

以下为原文摘录。仅证明摘录中说明的检查范围。

本次仅接入已审核的粒子页面；匿名默认提供「登录」「注册」两个入口。登录保留密码、邮箱验证码、通行密钥、Google 和 GitHub。有效邀请码进入论坛原有邮箱验证及学号绑定流程；新账号真实创建成功后显示字符对勾和彩带，并提示「5 秒后进入论坛首页」。

## 发布范围

生产基线：`10004ccf5090d85f80da529aeb4ecb4f3b7b1205`。独立分支：`auth-page-20261009`。没有数据库迁移或依赖变更，页面开关为 `academy_auth_page_enabled`。数据库里的主题、学院资料、SMTP 和社交认证配置沿用现有值。

