# 工作台学习资源列表为空的排查

2026-10-12 对 `https://isbf-one.com/isbf/learning` 进行只读排查。北京时间
10:39 核实：课程目录和资源记录仍在，全部资料被软删除或隐藏，当前可见资源为
0 条。本次没有修改生产数据、审核状态、站点设置、主题或部署。

## 直接原因

原有 8 条微观经济学资料分成两组：

| Topic ID | 资料 | 当前状态 | 记录时间（UTC+8） | 记录账号 |
| --- | --- | --- | --- | --- |
| 83 | 微观经济学 | 软删除 | 2026-10-11 19:27:39 | Yin |
| 79 | 微观计算题练习 | 软删除 | 2026-10-11 19:27:48 | Yin |
| 78 | 4.微观精简版框架 | 软删除 | 2026-10-11 19:27:51 | Yin |
| 74 | 3.微观背诵版框架 | 软删除 | 2026-10-11 19:30:50 | Yin |
| 73 | 2.微观计算题专项 | 软删除 | 2026-10-11 19:30:54 | Yin |
| 72 | 1.微观详细版框架 | 软删除 | 2026-10-11 19:32:25 | Yin |
| 70 | 微观经济学-萨缪尔森第19版（电子书） | 垃圾举报后隐藏、待审核 | 2026-10-12 00:29:51 | system |
| 71 | 微观经济学-萨缪尔森版 笔记和课后习题 | 垃圾举报后隐藏、待审核 | 2026-10-12 00:29:53 | system |

删除账号来自首帖的 `deleted_by_id=23`，时间来自主题的 `deleted_at`。
这些字段能确定记录账号与删除状态，不能证明是谁实际使用该账号或删除是否有意。
上述资料没有对应的原生 `user_histories` 删除日志，不能将未查到日志解释为没有删除。

资源课程字段共关联 11 条主题：9 条软删除、2 条隐藏、0 条可见。另三条删除
记录是 Topic 57（2026-10-06 删除）、126（Test，2026-10-10 删除）和
151（111，2026-10-11 删除）。课程目录仍有 10 门课程。

## 两条隐藏资料的触发链

这是原生同域名外链反垃圾规则产生的系统举报。系统说明帖提供了直接证据：

- 系统消息 Topic 154、Post 249：账号 Yin 尝试创建多个指向
  `www.kdocs.cn` 的帖子，被重复链接保护阻止。
- 系统举报说明 Post 250、252：新用户多次发布同域名链接，需要审核已有
  含链接帖子；分别指向资源 Topic 70、71。
- Post action 79、80：`user_id=-1`，类型 8（spam），首帖为 117、118，
  关联说明帖为 250、252。
- Reviewable 11、12：`ReviewableFlaggedPost`，状态 0（pending）。
  没有提交待审的 `ReviewableQueuedPost` 资源。

生产 Rails 日志在 2026-10-12 00:29:40、00:29:57 记录了两次
`POST /isbf/learning/resources`，均由 `LibraryController#create_resource`
处理并返回 422。

当前运行配置通过 Rails runner 只读核实：

| 设置 | 生效值 |
| --- | --- |
| `newuser_spam_host_threshold` | 3 |
| `allowed_spam_host_domains` | 空字符串 |
| `high_trust_flaggers_auto_hide_posts` | true |
| `ai_spam_detection_enabled` | false |

`ai_spam_logs` 没有记录。两条资料也没有严重举报的 hold 字段。本次证据支持
原生同域链接限制触发举报，不支持 AI 审核或成员严重举报导致隐藏。

运行源码中的处理顺序：

1. `Post#total_hosts_usage` 合计同一账号已有 `TopicLink` 与本次提交的域名
   次数，并移除 `allowed_spam_host_domains` 中的域名。
2. `Post#has_host_spam?` 对未达到原生信任等级 1 的账号检查阈值。
3. `PostCreator` 判定为同域链接垃圾内容时拒绝提交，并发送系统说明。
4. `NewPostManager#perform_create_post` 在 `creator.spam?` 时调用
   `User#flag_linked_posts_as_spam`，对该账号已有含链接帖子发出系统垃圾举报。
   此方法的范围是已有含链接帖子，不限于本次提交的域名或分类。
5. `PostActionCreator` 将对应首帖隐藏。两条首帖的 `hidden_reason_id=4`，
   对应 `flagged_by_tl3_user`；举报账号 system 的原生信任等级为 4。
6. 学习资源查询要求主题可见且首帖未删除、未隐藏，因此两条资料从列表消失。

排查时 Yin 的数据库记录为 TL0、非管理员、原生 moderator 标记为 true。
学院权限插件的 `ModeratorUser` 对受限制角色覆盖 `staff?`、`moderator?`，
使其不获得原生 staff 的全部权限；学院管理资源权限不能被当作原生反垃圾规则
豁免。该账号当前保留两条指向 `www.kdocs.cn` 的 `TopicLink`，再次提交同域
链接会达到阈值 3。

## 部署与界面检查

- `/srv/status` 返回 200；未登录访问学习资源入口正常跳转登录页。
- 生产核心提交为 `132cc95d043db01251eedf9c93b3927cd5ffee91`。
- 学习插件链接及 `.release-commit` 均指向
  `a8c3ffc9a098ef2ac568dffc0675fc709bc3c288`。
- `isbf_learning_enabled=true`，分类 ID 7 存在，课程目录仍在 PluginStore。
- 默认主题 ID 4 保留 133 个字段，学习资源相关组件、路由和样式均保留。
- 当前查询条件下没有可见资源；分类说明主题不属于学习资料，不能用整个分类的
  `Topic.visible.count` 代替资源数。

这些证据排除了本次列表为空由学习插件链接缺失造成的解释。资源当前状态
已经足以解释列表为空；本次没有进行已登录桌面或手机的视觉验收。

## 恢复范围

两条隐藏资料可由有审核权限的管理账号通过原生 Reviewable 的
`disagree_and_restore` 操作否决误报并恢复展示；该操作同时记录审核结果和
解除隐藏。六条软删除资料应在确定需要恢复哪些内容后，使用原生
`PostDestroyer#recover` 流程处理。

若要防止正常文档分享再次触发此规则，应确认受信任文档域名的许可范围，或
单独设计学习资源的重复域名规则。不要通过直接改 `hidden`/`visible` 留下
未处理举报，不需要回退数据库或重建容器。本次未执行任何恢复或配置修改。
