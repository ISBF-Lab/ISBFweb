# 工作台功能页返回导航

用户于 2026-11-22 确认静态预览，随后授权实施。范围为论坛助手工作区和使用指南列表的顶栏，参考 MBTI 和课程资源已经使用的左侧返回模式。

| 页面 | 页头和返回目标 |
| --- | --- |
| 论坛助手 `/discourse-ai/ai-bot/conversations` | 左侧箭头和「论坛助手」标题。箭头进入 `/isbf/workbench`。1023px 及以下在右侧显示「历史会话」，关闭历史或按 Escape 回到对话并恢复焦点。 |
| 使用指南 `/guides` | 左侧箭头和「使用指南」标题。箭头进入 `/isbf/workbench`，简介位于顶栏下。文章页用「全部指南」返回列表。 |

两个页头使用原生左箭头、44px 点击区和站点焦点样式。标题使用 `font-xl` 和 `weight-bold`，桌面内距和间距分别为 `space-4` 和 `space-3`。600px 及以下使用 `space-2` 并适配顶部安全区。分隔线、文字和悬停沿用主题当前的明暗变量。参考页头为 [MBTI](../../../../themes/isbf-campus-feed/stylesheets/mbti.scss) 和 [课程资源](../../../../themes/isbf-campus-feed/stylesheets/learning-resources.scss)。

实现基于 `ISBF-Lab/ISBFweb` 的 `fdb989e71e8816b1da90c76c273ed8bc9470dc6f`。助手由其工作区模板渲染页头，指南列表通过 wrapper outlet 接入主题的返回链接，默认内容保留指南标题。样式位于 `themes/isbf-campus-feed/stylesheets/forum-assistant.scss` 和 `guides.scss`。

设计确认限于上述页头和返回目标。隔离浏览器规格验证两页往返、手机历史焦点、文章返回和布局尺寸。实际验收以本次 PR 对应的浏览器及 CI 证据为准。
