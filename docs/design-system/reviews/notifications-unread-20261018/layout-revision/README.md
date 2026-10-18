# 通知布局修订 · 2026-10-18

本轮用户明确要求动作旁蓝点垂直居中，移除“校园讨论”等主题大标题旁的蓝点，
将“只看未读”开关放入右上角三点菜单。仅这三处布局规则得到确认；最终视觉仍待用户核验。

动作文字与蓝点使用flex居中及现有space-2间距；不改变圆点的space-2尺寸及accent颜色。
菜单内开关复用UI kit控件与现有24×48px尺寸、44px点击高度；
菜单行内距复用space-3。筛选仍作用于两个标签及懒加载详情，不改变已读语义。

复用A01/A05及C05/C06/C13，局部范围为C18。此前20份快照及61项检查保留在上级目录；
本目录独立保存修订后的源码摘要、浏览器结果与截图，不将初版结果当作本轮结果。

```bash
python3 docs/design-system/reviews/notifications-unread-20261018/run-tool.py python3 /review/build-layout-revision.py
python3 docs/design-system/reviews/notifications-unread-20261018/run-tool.py python3 /review/check-browser.py layout-revision
```

本轮检查结果见[browser-report.json](browser-report.json)和[verification-summary.json](verification-summary.json)，
实际版本见[source-manifest.json](source-manifest.json)。使用单个限额离线容器、单浏览器和合成API；
不连接生产后端，完整预览论坛保持停止。原生QUnit/RSpec的环境限制仍见上级目录记录。
尚未部署，技术检查不代表最终视觉验收。

| 布局 | 浅色页面 | 浅色菜单 | 深色页面 | 深色菜单 |
| --- | --- | --- | --- | --- |
| 电脑1280px | [截图](1280-light.png) | [截图](1280-light-menu.png) | [截图](1280-dark.png) | [截图](1280-dark-menu.png) |
| 折叠侧栏900px | [截图](900-light.png) | [截图](900-light-menu.png) | [截图](900-dark.png) | [截图](900-dark-menu.png) |
| 手机390px | [截图](390-light.png) | [截图](390-light-menu.png) | [截图](390-dark.png) | [截图](390-dark-menu.png) |
| 窄屏320px | [截图](320-light.png) | [截图](320-light-menu.png) | [截图](320-dark.png) | [截图](320-dark-menu.png) |

本轮完成：定向`bin/lint --fix`、前端及完整主题SCSS编译通过；离线真实客户端87项检查通过，
8组宽窄屏明暗布局、16张页面与菜单截图均已保存。蓝点中心与文字中心偏差不超过0.5px；
未读开关仅在菜单内显示，筛选及键盘关闭菜单通过验证。无JavaScript运行异常，源码快照20份均核对一致。
电脑浅色页面与手机深色菜单已由代理查看并复核；完整预览论坛保持停止，临时工具容器已移除。
