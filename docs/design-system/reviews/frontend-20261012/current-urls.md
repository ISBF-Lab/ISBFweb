# 预览与当前网址对照

站点域名：`https://isbf-one.com`，来自主工作区的既有部署记录。
路由按本轮基线 `132cc95d043db01251eedf9c93b3927cd5ffee91` 的代码核对；没有重新访问生产验证可用性。
本文件是现有入口对照，不表示预览方案已经上线或成为 Approved。

`/my/...` 是服务端提供的当前用户快捷入口，登录后重定向到 `/u/你的用户名/...`。
设置、草稿、私信、邀请和群组管理继续受实际权限控制。

## 9 类代表预览

| 审核包预览 | 当前入口 | 对照范围 |
| --- | --- | --- |
| 账户设置 `account` | [账户](https://isbf-one.com/my/preferences/account)、[安全](https://isbf-one.com/my/preferences/security)、[资料设置](https://isbf-one.com/my/preferences/profile) | 样例直接对应账户页；表单组合提案供其他偏好设置复用，不代表每个子页已有单独预览。 |
| 书签 `bookmarks` | [书签](https://isbf-one.com/my/activity/bookmarks)、[有提醒的书签](https://isbf-one.com/my/activity/bookmarks-with-reminders) | 书签列表；私人列表提案还供草稿、待审核和私信列表复用。 |
| 用户目录 `directory` | [用户目录](https://isbf-one.com/u) | 用户目录的筛选、表格和分页。 |
| 邀请管理 `invitations` | [待接受](https://isbf-one.com/my/invited/pending)、[已接受](https://isbf-one.com/my/invited/redeemed)、[已过期](https://isbf-one.com/my/invited/expired) | 三个筛选子页；入口 `/my/invited` 在前端转到 pending，详情受权限控制。 |
| 个人资料下部 `summary` | [个人资料概要](https://isbf-one.com/my/summary)、[个人徽章](https://isbf-one.com/my/badges) | 概要下部的统计、徽章和导航组合；不是资料页上部 hero 的新设计。 |
| 徽章 `badges` | [徽章目录](https://isbf-one.com/badges) | 点击真实徽章进入 `/badges/:id/:slug` 详情；预览图标为示意，不对应某个实际徽章 ID。 |
| 关于与帮助 `information` | [关于](https://isbf-one.com/about)、[帮助](https://isbf-one.com/faq)、[社区指南](https://isbf-one.com/guidelines)、[行为准则](https://isbf-one.com/conduct)、[规则](https://isbf-one.com/rules)、[条款](https://isbf-one.com/tos)、[隐私](https://isbf-one.com/privacy) | 信息页的正文与标题组合，保留各页真实内容和锚点。 |
| 用户卡 `usercard` | 话题页中点击带用户卡交互的头像或用户名 | 页面内组件，没有独立网址；示例成员是合成资料。 |
| 关联弹窗 `modal` | 邀请管理页的创建邀请操作；[邀请快捷入口](https://isbf-one.com/new-invite) | 以邀请表单演示容器。`/new-invite` 是弹窗快捷入口，会按登录与邀请权限处理，不是独立详情页。 |

明暗预览共用这些实际路由，不是两套网址。9 类样例也不是 19 个页面组的逐页截图。

## 全部 19 个页面组

所有下列路径都以 `https://isbf-one.com` 为前缀。参数 `:name`、`:id`、`:slug` 等必须使用实际数据；不构造虚假的群组或徽章链接。

| ID | 页面组 | 入口与子路由 |
| --- | --- | --- |
| F01 | 账户设置 | `/my/preferences/account` |
| F02 | 安全设置 | `/my/preferences/security` |
| F03 | 资料设置 | `/my/preferences/profile` |
| F04 | 其他偏好设置 | `/my/preferences/` 下的 `emails`、`notifications`、`tracking`、`users`、`tags`、`interface`、`apps`、`navigation-menu`、`calendar-subscriptions`、`email`、`second-factor` |
| V02 | 用户目录 | `/u` |
| V03 | 用户邀请管理 | `/my/invited/pending`、`/my/invited/redeemed`、`/my/invited/expired` |
| F05 | 书签 | `/my/activity/bookmarks`、`/my/activity/bookmarks-with-reminders` |
| F06 | 草稿 | `/my/activity/drafts` |
| F07 | 待审核内容 | `/my/activity/pending`；不是全站 `/review` 审核后台 |
| F08 | 个人私信列表 | `/my/messages` 及其 `new`、`unread`、`archive`、`sent`、`warnings`；`group/:name` 及其 `new`、`unread`、`archive`；`tags`、`tags/:id` |
| V01 | 个人资料下部 | `/my/summary`、`/my/badges`、`/my/deleted-posts`、`/my/profile-hidden`；他人资料使用 `/u/:username/` 对应子路径，受权限限制 |
| V04 | 徽章目录和详情 | `/badges`、`/badges/:id/:slug` |
| F09 | 搜索 | `/search` |
| F10 | 标签目录 | `/tags`；不含 `/tag_groups` |
| F11 | 群组目录和创建 | `/g`、`/g/custom/new` |
| F12 | 群组详情 | `/g/:name/members`、`/g/:name/requests`、`/g/:name/activity` 及 `posts`、`topics`、`mentions`，`/g/:name/permissions` |
| F13 | 群组管理 | `/g/:name/manage/` 下的 `profile`、`membership`、`interaction`、`email`、`members`、`categories`、`tags`、`logs` |
| F14 | 群组私信列表 | `/g/:name/messages/inbox`、`/g/:name/messages/archive` |
| V05 | 信息页 | `/about`、`/faq`、`/guidelines`、`/conduct`、`/rules`、`/tos`、`/privacy` |

开发者和站点管理后台 `/admin` 不在本次外观改造范围内。群组管理 F13 是前台群组拥有者的管理页，仍在范围内。

## 代码依据

- [前端路由表](../../../../frontend/discourse/app/routes/app-route-map.js)
- [服务端路由](../../../../config/routes.rb) 的 `my/*path`，以及 [UsersController](../../../../app/controllers/users_controller.rb) 的 `my_redirect`
- [邀请入口重定向](../../../../frontend/discourse/app/routes/user-invited/index.js) 与 [邀请筛选导航](../../../../frontend/discourse/app/templates/user-invited.gjs)
- [邀请弹窗快捷入口](../../../../frontend/discourse/app/routes/new-invite.js)
- [19 个页面组执行记录](../../frontend-rollout-20261012.md)
