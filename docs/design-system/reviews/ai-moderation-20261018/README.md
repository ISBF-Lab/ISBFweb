# AI 审核后台设置接入范围

2026-10-18 用户明确选择沿用现有站点设置表单，批准四项控制：审核总开关、
模型选择、图片开关、免审核群组多选。本次仅接入既有控件和服务器校验。

- [Reference Map](../../reference-map.md) 将后台内层列为 Legacy；本次接入不把后台默认外观提升为设计标准。
- 字段来自 `plugins/isbf-moderation/config/settings.yml`；选项和校验来自
  `plugins/isbf-moderation/lib/isbf_moderation/ai_configuration.rb`；说明来自插件 server locale。
- 总开关、图片开关复用 boolean 行；模型复用 enum 行；群组复用 group_list 多选行。
  保留既有保存、重置、错误提示、键盘行为和响应式布局。
- 无新增颜色、间距、字体、形状、CSS token 或组件变体，不增加页面和主题字段。
- `/review` 仅增加已转义的 AI 来源与证据说明，不重新设计审核卡片或布局。

格式检查完成后，实际源码摘要写入 `source-manifest.json`。
批准范围仅为上述接线；服务器回归不能代替真实后台视觉核验，不自动扩大 Approved 范围。
