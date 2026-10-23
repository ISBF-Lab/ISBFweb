# 前台统一执行记录

分支：`feature/isbf-frontend-design-consistency`。
持久工作树：`deploy-work/frontend-consistency-20261012/worktree`。
核心132cc95d043、默认主题4/133字段，详见[恢复基线](baselines/README.md)。

## 进度

- 三批19个页面组已提交实现；原生字段、权限和业务组件继续使用。对应源码见[实现说明](frontend-implementation-20261012.md)。
- Draft [PR #52](https://github.com/ISBF-Lab/ISBFweb/pull/52)；尚未合并或部署。
- 当前主题133字段已恢复到隔离工作树，原始附件保留原字节。核心运行基线仍为132cc95d043。
- 已合入主分支的设计文档历史以解决PR冲突，未由此替换运行基线的核心业务或UI代码。
- D01–D06及D07关联弹窗组合已确认。用户卡、个人资料上部及一级导航、公开活动预览保留；后台排除。
- 新页面仍为In Progress，尚未获得实际页面视觉验收。参考[新版离线预览](reviews/frontend-20261012-v2/index.html)。
- GitHub Actions执行原生前端、主题QUnit及真实页面检查；具体结果见[验证记录](frontend-verification-20261012.json)。
- 完整论坛预览保持停止；本任务没有继续检查生产。

## 19个页面组

| 批次 | ID  | 页面组           | 路由/子路由                                                                                                          |
| ---- | --- | ---------------- | -------------------------------------------------------------------------------------------------------------------- |
| 1    | F01 | 账户设置         | `/u/:username/preferences/account`                                                                                   |
| 1    | F02 | 安全设置         | `/u/:username/preferences/security`                                                                                  |
| 1    | F03 | 资料设置         | `/u/:username/preferences/profile`                                                                                   |
| 1    | F04 | 其他11个偏好设置 | `emails/notifications/tracking/users/tags/interface/apps/navigation-menu/calendar-subscriptions/email/second-factor` |
| 1    | V02 | 用户目录         | `/u`                                                                                                                 |
| 1    | V03 | 用户邀请管理     | `/u/:username/invited及filters`                                                                                      |
| 2    | F05 | 书签             | `activity/bookmarks及提醒别名`                                                                                       |
| 2    | F06 | 草稿             | `activity/drafts`                                                                                                    |
| 2    | F07 | 待审核           | `activity/pending`                                                                                                   |
| 2    | F08 | 个人私信列表     | `messages/new/unread/archive/sent/warnings/group/tags`                                                               |
| 2    | V01 | 个人资料下部     | `summary/badges/deleted-posts/profile-hidden`                                                                        |
| 2    | V04 | 徽章目录和详情   | `/badges及/badges/:id/:slug`                                                                                         |
| 3    | F09 | 搜索             | `/search`                                                                                                            |
| 3    | F10 | 标签目录         | `/tags；不含tag_groups`                                                                                              |
| 3    | F11 | 群组目录和创建   | `/g及/g/custom/new`                                                                                                  |
| 3    | F12 | 群组详情         | `/g/:name/members/requests/activity/permissions`                                                                     |
| 3    | F13 | 群组管理         | `manage/profile/membership/interaction/email/members/categories/tags/logs`                                           |
| 3    | F14 | 群组私信列表     | `group/messages inbox/archive`                                                                                       |
| 3    | V05 | 信息页           | `/about/faq/guidelines/conduct/rules/tos/privacy`                                                                    |

## 目标验收矩阵（不表示全部已经通过）

- 所有子路由、重定向及关联弹窗；数据加载完成才算路由检查通过。
- 桌面1440/手机390，明暗模式及600/601、1023/1024、1279/1280边界。
- 游客、本人、他人、群组管理者和staff；权限与隐私字段不因样式变化暴露。
- 空/已加载/长文本/动态字段/加载/错误/分页/disabled/焦点/提交反馈。
- 设置保存、草稿恢复删除、书签提醒、邀请角色、私信筛选、群组管理、搜索参数和徽章锚点。
- 键盘、Escape、焦点恢复、触控、表单标签、头像框完整叠层。
- 原有Approved区域及所有已部署插件功能；所有/admin外观保持排除。
- 沿用有意义的QUnit验证，补路由范围/样式泄漏检查；完成后具体文件执行bin/lint --fix。

## 资源与恢复

见[运行与持久化约束](resource-policy.md)。重启清空了/tmp，原临时工作树和未提交准备文件丢失。
从停止的测试容器恢复主题，未启动完整论坛测试服务，后续只串行执行工具。
没有恢复或修改生产数据库，也没有把本轮UI接入生产。

## 当前验证与离线交付

新版排除用户卡：8类代表区域、16份明暗HTML、32张桌面/手机截图，58项静态浏览器检查通过。
包含600/601、1023/1024、1279/1280边界的24项代表检查，以及两种模式的选择器检查。
限额工具512MiB、0.5 CPU、192进程/线程，单浏览器串行执行；首次运行达到时间预算后停止，
第二次只续跑剩余用例并完成，未增加内存，OOM kill为0，工具容器已移除。

GitHub Actions第二轮：原生前端1044项、项目主题QUnit89项通过；真实页面20项检查因
使用旧浏览器窗口接口而全部停在初始化阶段，不能据此评价页面外观。窗口接口已修正，
页面操作转入Page Object，保存和取消删除通过刷新后的可见结果验证。
第三轮真实页面20项中12项通过；8项分别停在书签和标签列表，截图显示原生空状态，
源码确认是测试缺少topic_user以及未使用标签被过滤。已补齐真实可见的数据关联；第四轮被随后发现的邮箱标题对齐和长页截图修正替代，
第五轮原生前端1042项、主题QUnit89项通过，真实页面20项中7项通过、13项失败。
其中4项为偏好表单重复规则未接入对齐修正，4项为测试未配置信息正文话题，
4项为仅有本人发帖的私信按原生规则不进入收件箱，1项为群组长流程超过45秒单例上限。
已统一表单规则、补齐合成数据，并将真实检查拆为48个较短流程；第六轮48例中44例通过，4例均在徽章详情访问前因测试误用Ruby模型的url方法失败。
已改为核心id/slug路由。第七轮被私信下部导航控件的D02补齐替代并取消。
第八轮完整通过：原生前端1044项、主题QUnit89项、真实页面48例全部通过，45秒单例上限保持。
112张真实完整页面截图及源码、工作流、附件摘要见[截图来源](reviews/frontend-20261012-v2/actual-pages/README.md)。
被替代的执行不算作回归通过，也没有扩大单例时限或取消必要断言。
最终状态以[验证记录](frontend-verification-20261012.json)为准，不把原型通过计作业务通过。

原工作区31项已有受控修改保持原字节，原运行133字段和Approved参考附件进行摘要核验。
每批实现执行具体文件的bin/lint --fix；现有预览旧包保留为历史附件，新包另存V2。
没有有效的批量改造前截图；没有重新完成生产插件库存审计，不宣称全部线上插件已验证。
