# 设计参考证据

这些附件是已验收代码的非执行副本，供 AI 阅读、定位规则和核对版本。它们不会被主题或插件加载，也不是可安装的完整主题包。Approved 范围以 [UI 状态](../ui-status.md) 为准；保存某个文件不代表批准其中的所有页面、选择器或状态。

## 主题基线

主题 ID `4` 的参考版本来自 2026-10-10 头像框管理版本的发布前状态，验收记录见 [头像框发布记录摘录](evidence/avatar-management.md)，原文件为 `docs/avatar-frames-deployment-20261010.md`。核心源码基线为 `c0f4739d143a4efbb4e7f19dafadcd56a5302a58`。这是可核验的历史验收基线，不能据此判断当前线上运行版本。

重建方法：

1. 读取 `deploy-work/avatar-frames-20261010/theme-current.jsonl` 的 128 个字段。
2. 将字段 `197`、`200`、`224`、`226`、`227` 的内容替换为 `deploy-work/avatar-frames-20261010/tools/theme-changes.json` 中对应的 `after`。
3. 对每个字段的 UTF-8 内容计算 SHA-256，与 `deploy-work/avatar-frames-20261010/management/state-before.json` 比较，128 个字段全部匹配。
4. 只保存本次规范需要的字段，保留原字节及换行，以 `.txt` 后缀阻止误加载。

工作区 `themes/isbf-campus-feed/` 存在不同版本及缺失模块，不能整体替代这份数据库主题快照。每份附件与工作区的审阅时比较结果记录在 [manifest.json](manifest.json) 的 `workspace_exists_at_review`、`workspace_matches_at_review` 中；这两个字段描述对应审阅时点，不保证之后仍相同。

## 插件参考与后续验收

- `plugins/discourse-avatar-frames/`：来自头像框管理发布源码，发布提交 `7799ffe00571fc8247c0aafff99b0132e9c74fb3`。本次只批准头像叠层的视觉规则，没有把后台、上传和授予流程整体作为设计标准。
- `plugins/discourse-academy-roles/assets/`：与上述主题基线配套的早期认证组件和样式，仅用于历史比对。
- **认证页的有效参考为** `plugins/discourse-academy-roles/accepted-20261011/assets/`。这两份文件取自已验收提交 `67706a5a30d71ff0b6793e5b8f55a85c4fe3ebb5`，逐字节匹配审阅时工作区源码；发布报告和浏览器报告确认居中、主题菜单、保留手机触控及既有功能通过。
- 后续认证补丁只升级认证参考。没有以它推断其他主题字段已同步升级。

`manifest.json` 保存 128 个主题字段的摘要、78 份源码副本和 13 份验收及复用边界摘录的来源与 SHA-256。`supplements` 记录 2026-10-11 认证和头像框增量的提交、报告路径、报告摘要及核验结果。原始部署目录可能在其他开发环境缺失，附件仍能供阅读和摘要校验。

## 证据的使用范围

`evidence/` 保存必要的原文摘录及摘录时原文件的摘要，不包含配置、凭据、数据库或用户身份。验收摘录只能证明它明确说明的检查范围：路由能打开不等于数据已加载；功能通过不等于所有视觉状态已获批准；模拟浏览器触控不等于 iPhone 实机验收。

[topic-reading.md](evidence/topic-reading.md) 保存主题说明中的话题阅读、时间轴和菜单复用边界；它是源码上下文，不是新增视觉验收。

[auth-pending.md](evidence/auth-pending.md) 是历史暂停记录，已被 [auth-current.md](evidence/auth-current.md) 及原发布文档的后续验收更新。不得再用它把认证页整体标为 In Progress。

## 阅读与维护

1. 先按 `ui-status.md` 找 Approved 区域，再读对应组件、初始化入口及完整样式文件。注意同一选择器的后续覆盖、断点、插件开关和路由条件。
2. `.txt` 文件只能作为证据。实现时应在项目实际模块中复用组件/API，不直接安装或全量复制参考主题；附件没有包含完整依赖、设置、翻译及测试。
3. 新参考必须有实际来源、限定的验收范围和人工认可，随后更新状态、tokens、组件规则、Reference Map 和 manifest。不得因有新截图、未提交改动或新原型自动批准。
4. 不格式化源码副本和原文摘录。变更会破坏字节摘要；更新参考时应显式记录新来源与摘要。
5. Foundation、Horizon、平台 UI kit 说明和历史设计原型只解释工程能力，不提供目标视觉语言。

本目录的 `.gitattributes` 保留源码附件和原文摘录的原始换行与尾部空行，防止 Git 在提交或检出时转换字节，破坏 manifest 中的 SHA-256。

## 2026-10-11 头像框校准增量

有效定位与新增校准区参考位于 `plugins/discourse-avatar-frames/accepted-20261011/`，
取自提交 `bbdabecf040bdbb6d5bb3f88d6e748738ddf7a41`，共六份非执行源码附件。
用户明确批准制作模板、统一定位和上传区布局，后续要求两款现有素材由其自行校准。
批准范围为 A14/C03 的统一内容区域定位，以及 A15/C14 的上传字段校准区；
未批准整个后台表单、导航、授予或 CSV 页面。原主题 128 字段历史基线及认证补充保持不变，
生产主题的后续 133 字段没有被替换或整体提升为新参考。验收见 [校准增量证据](evidence/avatar-calibration.md)。

## 2026-10-12 前台组合确认

见[人工确认记录](evidence/frontend-consistency-acceptance-20261012.md)。D01–D06与D07仅弹窗部分用于本轮19组主体。
用户卡、资料上部、一级导航及后台排除。历史源附件不修改，运行快照不整体升级为Approved。

## 2026-10-13 前台生产运行证据

见[主题增量发布](../deployments/frontend-consistency-20261013/README.md)及其 manifest。
该记录保存基于当时162字段、63插件生产状态合并的八份实际发布源码；最终主题为168字段。
它是运行来源与回退证据，19组主体仍为In Progress，不新增Approved范围。

## 2026-10-13 个人页面修复增量

见[单样式字段发布](../deployments/profile-fixes-20261013/README.md)。
用户明确选择单行内部滚动，并要求移除三个总结区块及活动书签选项；
主题字段404的实际源码与摘要已保存。视觉核验由用户完成，待确认，
不能将本次技术发布等同于新增Approved组件或整页认可。

## 2026-10-13 总结隐藏规则续更

用户确认前次热门类别与徽章仍显示。[修正记录](../deployments/summary-visibility-20261013/README.md)
保存排除网格覆盖后的实际样式字段；发布时生产已169字段，另外168字段及63插件保持。
技术发布已完成，视觉仍待用户再次核验，不扩大Approved范围。

## 2026-10-14 招募接入批准

见[招募来源与批准范围](join-20261014/README.md)和其 source manifest。用户提供招募页
压缩包并要求保持外观，随后批准最小跳转/鉴权接线和后台四列只读申请表。公开范围仅为
招募页和提交，申请记录仍限 Discourse admin。记录不扩展为整个后台的视觉标准，
实现验证与生产发布分别记录。2026-10-15 已按授权[上线](../deployments/join-20261015/README.md)，
保留原有插件与其余主题字段；完整论坛和3D动画的浏览器验收未完成，不扩大批准范围。

## 2026-10-15 回复对话候选

[方案](../proposals/reply-conversations-20261015.md)已由用户确认，要求代码及电脑/手机预览先行。
实际源码版本、SHA-256、验证限制和截图见[审阅记录](../reviews/reply-conversations-20261015/README.md)
及其source manifest。C16只登记该方案的局部组合，不把工作区差异或静态演示提升为Approved参考。
未部署，既有历史附件和生产主题来源保持原记录；后续上线必须单独核对完整插件与活动主题。

回复连线的最新来源为用户选定B后粘贴的HTML参考，限定主头像延伸的1px主干及直线短支线。
[选定记录与非执行CSS摘录](../reviews/reply-conversations-20261015/guide-redesign/README.md)
保存33px自然缩进的几何计算和复用边界；原2px侧线与A/B圆弧预览不作最终视觉参考。
设计方向已由用户确认，完整应用与最终视觉验收仍待完成，未部署。

## 2026-10-16 继续阅读设计确认

用户明确指定帖子底部轻量列表，并确认相关话题也采用同一外观。
[局部规格、来源及验证边界](../reviews/continue-reading-20261016/README.md)仅覆盖普通话题底部，
实际源码摘要另存source manifest；最终视觉验收待完成，历史参考附件不变。

2026-10-16继续阅读经用户授权发布，确切合并源和验证范围见[部署记录](../deployments/continue-reading-20261016/README.md)。参考附件仍为非执行证据，最终视觉状态不自动扩展至其他区域。
