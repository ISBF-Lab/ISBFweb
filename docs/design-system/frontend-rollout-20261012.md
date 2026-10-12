# 前台统一执行记录

分支：`feature/isbf-frontend-design-consistency`。
持久工作树：`deploy-work/frontend-consistency-20261012/worktree`。
核心132cc95d043、默认主题4/133字段，详见[恢复基线](baselines/README.md)。

## 进度

- 已恢复当前主题133字段及现有设计系统，附件保留原字节。
- 本轮预览容器保持停止；不再检查生产运行状态。
- 代表设计见[D01–D07提案](proposals/frontend-consistency-20261012.md)及[离线预览](reviews/frontend-20261012/index.html)。
- 实际UI接入尚未开始，D01–D07新用途组合待人工确认。
- 没有批量截图验收通过的结论，未创建本轮实现PR、未合并或部署。

## 19个页面组

| 批次 | ID | 页面组 | 路由/子路由 |
| --- | --- | --- | --- |
| 1 | F01 | 账户设置 | `/u/:username/preferences/account` |
| 1 | F02 | 安全设置 | `/u/:username/preferences/security` |
| 1 | F03 | 资料设置 | `/u/:username/preferences/profile` |
| 1 | F04 | 其他11个偏好设置 | `emails/notifications/tracking/users/tags/interface/apps/navigation-menu/calendar-subscriptions/email/second-factor` |
| 1 | V02 | 用户目录 | `/u` |
| 1 | V03 | 用户邀请管理 | `/u/:username/invited及filters` |
| 2 | F05 | 书签 | `activity/bookmarks及提醒别名` |
| 2 | F06 | 草稿 | `activity/drafts` |
| 2 | F07 | 待审核 | `activity/pending` |
| 2 | F08 | 个人私信列表 | `messages/new/unread/archive/sent/warnings/group/tags` |
| 2 | V01 | 个人资料下部 | `summary/badges/deleted-posts/profile-hidden` |
| 2 | V04 | 徽章目录和详情 | `/badges及/badges/:id/:slug` |
| 3 | F09 | 搜索 | `/search` |
| 3 | F10 | 标签目录 | `/tags；不含tag_groups` |
| 3 | F11 | 群组目录和创建 | `/g及/g/custom/new` |
| 3 | F12 | 群组详情 | `/g/:name/members/requests/activity/permissions` |
| 3 | F13 | 群组管理 | `manage/profile/membership/interaction/email/members/categories/tags/logs` |
| 3 | F14 | 群组私信列表 | `group/messages inbox/archive` |
| 3 | V05 | 信息页 | `/about/faq/guidelines/conduct/rules/tos/privacy` |

## 接入验证

- 所有子路由、重定向及关联弹窗；数据加载完成才算路由检查通过。
- 桌面1440/手机390，明暗模式及600/601、1023/1024、1279/1280边界。
- 游客、本人、他人、群组管理者和staff；权限与隐私字段不因样式变化暴露。
- 空/已加载/长文本/动态字段/加载/错误/分页/disabled/焦点/提交反馈。
- 设置保存、草稿恢复删除、书签提醒、邀请角色、私信筛选、群组管理、搜索参数和徽章锚点。
- 键盘、Escape、焦点恢复、触控、表单标签、头像框完整叠层。
- 原有Approved区域及所有已部署插件功能；所有/admin外观保持排除。
- 沿用有意义的QUnit验证，补路由范围/样式泄漏检查；完成后具体文件执行bin/lint --fix。

## 资源与恢复

见[内存与持久化约束](resource-policy.md)。重启清空了/tmp，原临时工作树和未提交准备文件丢失。
从停止的测试容器恢复主题，未启动完整论坛测试服务，后续只串行执行限额工具。
没有恢复或修改生产数据库，也没有把本轮UI接入生产。


## 离线交付检查

9类代表区域、18份明暗HTML、36张桌面/手机截图；62项静态浏览器检查通过。
检查色板、加载、溢出、输入尺寸和圆角、主按钮hover、焦点及弹窗适配。
限额工具512MiB、0.5 CPU、192进程/线程；OOM kill为0，退出后工具容器移除。
基线133字段及原Approved源码逐字节摘要核验；原工作区31项受控修改保持不变。
bin/lint --fix执行完成，文档路径无匹配规则；另对实际预览CSS/JS做了格式和语法检查。

这些结果只证明离线提案可审阅，不证明19组真实页面及业务操作已经通过回归。
实际UI仍待D01–D07确认后接入；完整论坛预览保持停止，生产排查按用户要求停止。
