# 等级外观权限与等级徽章

用户于 2026-11-04 确认完整方案并要求实施。设计方案已确认；技术验证、开发同步和最终用户视觉验收分别记录。

## 批准范围与来源

- C22 等级页面沿用 AdminConfigAreaCard／FormKit，新增统一佩戴门槛、品红姓名门槛和浅／深色预设；各级增加自动徽章选择。
- 逐框门槛在原有头像框编辑页增加一个 FormKit 选择器，保留原上传、校准与保存流程。
- 佩戴设置及姓名色设置沿用原控件与预览，增加锁定说明；普通用户只能开关预设色。
- 信息流沿用 A02／C09 作者姓名位置；工作人员原有主题色、自选色和渐变路径保留。

选择器使用共享 DSelect／FormKit，活动主题负责菜单外观；没有新增私有外框、CSS 视觉变量或全局 token。
品红浅／深色号由开发者配置，以安全色值数据传递，跟随原生 color-scheme；不更改正文链接或账号文字。
徽章采用原生授予及展示，不另建徽章外观。

来源快照和版本摘要见 `references/`、`source-manifest.json`；这些附件是非执行证据，不是主题安装包。
C22 原始卡片来源见[既有记录](../activity-levels-20261103/README.md)，姓名色来源见[已验收记录](../feed-name-colors-20261021/README.md)。

## 验证与交付

复现命令、权限与并发审阅、原始结果和恢复方法见[工作区记录](../../../../../docs/activity-cosmetics-20261104/README.md)。
验证只使用离线虚构测试库和隔离开发站，浏览器单实例、单页面串行运行。

前端 17 项测试／63 条断言、最终受影响后端 70 例、40 项真实流程及原生 lint／共享菜单门禁通过。
完整后端运行 538 例的 4 处失败、旧断言修正及 3 处既有问题的范围见[规格审阅](../../../../../docs/activity-cosmetics-20261104/backend-spec-audit.md)，没有将完整回归记为全绿。
界面采用 1440／390／320px 及浅深色组合核对；信息流姓名色另以实际计算值核对两套预设。

- [电脑浅色](../../../../../docs/activity-cosmetics-20261104/results/cosmetics-1440-light.png)／[电脑深色](../../../../../docs/activity-cosmetics-20261104/results/cosmetics-1440-dark.png)
- [手机浅色](../../../../../docs/activity-cosmetics-20261104/results/cosmetics-390-light.png)／[手机深色](../../../../../docs/activity-cosmetics-20261104/results/cosmetics-390-dark.png)／[320px](../../../../../docs/activity-cosmetics-20261104/results/cosmetics-320-light.png)
- [信息流浅色](../../../../../docs/activity-cosmetics-20261104/results/preset-feed-light.png)／[信息流深色](../../../../../docs/activity-cosmetics-20261104/results/preset-feed-dark.png)

两项主题字段定向同步后仍为 308 字段，其他 306 字段与 7 项设置保留；临时规则、用户选择及测试徽章／头像框均已恢复或清理。
精确源码、原始参考和验证产物摘要见[交付清单](source-manifest.json)。
本轮只交付开发环境，最终用户视觉验收尚未记录；没有发布生产。


工作区复现工具与截图链接对应迁移工作区；可独立阅读的功能、权限、数据及验证说明见[仓库指南](../../../activity-levels-and-cosmetics.md)。生产交付另记，不将开发验证记为已发布。
