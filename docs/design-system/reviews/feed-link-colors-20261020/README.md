# 首页标题与作者名颜色排查（2026-10-20）

用户反馈首页部分帖子标题为蓝色、作者名为白色，另一些相反。本次只核查源码，没有修改界面或发布主题；此记录不新增设计验收范围。

## 样式来源

- [信息流组件](../../../../themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-feed-card.gjs)分别为作者和标题渲染独立链接，使用 `.isbf-feed-card__author` 和 `.isbf-feed-card__title`。
- [主题样式](../../../../themes/isbf-campus-feed/common/common.scss)为两者设置 `color: var(--isbf-v2-text)`；该变量映射到 `--primary`，在用户描述的深色模式下显示为白色。
- [核心链接样式](../../../../app/assets/stylesheets/common/foundation/base.scss)同时为 `a`、`a:visited`、`a:hover`、`a:active` 设置 `color: var(--d-link-color)`。
- [核心色板](../../../../app/assets/stylesheets/color_definitions.scss)将 `--d-link-color` 映射到 `--tertiary`，即站点链接强调色。

## 原因与边界

在这些普通规则之间，`a:visited` 的选择器优先级 `(0,1,1)` 高于主题单类选择器的 `(0,1,0)`，所以访问过的链接会使用链接色。作者主页与帖子链接的访问状态分别判断，因此可以一蓝一白，也可以反过来。悬停和按下链接也会命中同样优先级的全局规则，产生临时变色。

这两个链接没有原生话题标题的 `.title` 类，因此原生列表针对 `.title` 的已读规则不控制这里的颜色。

以上是工作区源码的级联结论；同日弹窗发布保存的 [主题样式副本](../../deployments/dialog-consistency-20261020/source/themes/isbf-campus-feed/common/common.scss.txt)也包含相同的作者与标题规则。本次没有读取生产数据库或启动浏览器，未对用户具体链接的访问历史作运行时核验。

已尝试对本文件运行 `bin/lint --fix`，当前执行环境未提供 `ruby`，检查未能启动。该次检查按实时容量设置729759744字节地址空间上限，启动时MemAvailable为1266630656字节，预留536870912字节，并检查三层可读cgroup内存约束；没有启动编译或浏览器进程。
