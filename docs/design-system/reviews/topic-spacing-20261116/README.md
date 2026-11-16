# 主帖与回复间距修复

用户确认沿用现有 16px 帖子内边距，移除主帖与分组回复之间的额外空白。
本次复用 A04/C09/C16，不新增全局 token。

## 修改

主题隐藏了回复排序控件，但其父级 `.nested-view__controls` 仍继承核心最小高度和纵向 padding。
在现有分组回复作用域中增加 `min-height: 0` 和 `padding-block: 0`，使空控件行不再占高。
活动日志入口按实际内容撑开，主帖和根回复的 16px 内边距、子回复的 12px 间距及原有连线和操作栏保持。

源码：`themes/isbf-campus-feed/stylesheets/reply-conversations.scss`。

## 验证

- 定向 `bin/lint --fix` 通过。
- common、desktop、mobile 三种原生样式编译通过，实际提供的样式资源与编译结果一致。
- 1440px／390px、明／暗模式共 16 项浏览器记录通过，页面脚本错误为 0。
- 四组对照中，空控件行高度为 58px → 0；主帖和根回复保持 16px 内边距，子回复保持 12px。
- 活动日志入口仍可见，普通平铺帖子布局不受影响。

通用验证结果见 [verification.json](verification.json)。
