# 发帖审核日志入口与核验

2026-10-19（UTC+8）按用户要求核实后台日志入口，复用已部署的 Discourse AI 日志页面，
没有新增管理页面、修改日志保留策略或重新部署服务。

## 管理员入口

后台 → 插件 → Discourse AI → 日志。只有管理员可访问。

- [全部发帖审核调用](https://isbf-one.com/admin/plugins/discourse-ai/ai-logs?feature=isbf_ai_moderation)
- [主题 280 的审核调用](https://isbf-one.com/admin/plugins/discourse-ai/ai-logs?feature=isbf_ai_moderation&search=topic%3A280)
- [首帖 501 的调用详情 #35](https://isbf-one.com/admin/plugins/discourse-ai/ai-logs?feature=isbf_ai_moderation&details=35)

从普通日志入口进入时，功能选择 `isbf_ai_moderation`。
列表显示时间、模型、帖子链接、耗时、Token 和调用结果。
可按时间、模型、调用成功或失败筛选，搜索支持 `topic:280`、`post:501`、`log:35`。
若记录不在所选时间范围内，需要调整时间筛选。
点击记录的“详细信息”，再选择“回答”，查看模型返回的结构化判断：
`needs_review`、`rule`、`reason`、`evidence`。
`needs_review=false` 表示模型未要求人工复核，`true` 表示模型要求复核。

“成功 / 失败”是模型请求结果，不是最终的审核处置状态。
服务器还会验证响应并检查内容版本、审核范围和免审资格；过期结果可能被丢弃。
疑似违规内容的最终人工复核和恢复操作在原生 `/review`。
免审群组、排除范围和调用前跳过的帖子不会产生本功能的模型调用日志；
这里不是所有发帖或后台任务事件的完整流水。

## 保留配置

核验时原生页面返回 `detailed_days=0`、`summary_days=180`，
表示完整请求及回答随摘要保留 180 天，而非立即删除详情。
对应 `ai_audit_logs_detailed_retention_days=0`、`ai_audit_logs_purge_after_days=180`。
如需调整，可在日志页使用“配置保留”；这是全部 AI 日志共享的保留策略。
本次仅确认现值，没有修改配置。

## 只读核验

手机 390px 与电脑 1280px 各完成 7 项检查，共 14 项通过：
功能筛选、真实列表加载、主题搜索、帖子链接及耗时、指定记录详情、回答中的判断、关闭详情。
两端均加载 9 条本功能调用，主题 280 包含已确认的首帖 501 和回复 502，
同时也包含核验期间新产生的回复记录。日志 #35 的回答仍为 `needs_review=false`。
主题 280 最初两次审核的完成时间和任务状态另见[单帖核对](../ai-moderation-deployment-20261018/post-280-verification.json)。

没有 JavaScript 错误或静态资源加载失败。生产读取经正常 TLS 验证，
浏览器本身断网，只转发认证 GET / HEAD，拦截写请求，未提交内容或保存账户偏好。
核验完成后临时只读凭据和浏览器容器均已删除。
浏览器按实时容量限制为 832MiB，交换总量等于内存上限，0.5 CPU、192 PIDs，
保留至少 512MiB 服务余量；运行未触发资源停止条件。
完整预览论坛保持停止。原有页面的功能核验不扩大后台区域的视觉批准范围。

证据：[两端检查](production-browser.json)、[清理](production-browser-cleanup.json)、[资源预算](browser-budget.json)。
脚本及首次检查记录保存在私有目录 `deploy-work/ai-moderation-logs-20261018/`。
首次检查把实时主题记录误限为恰好两条，后修正为包含已知两条记录，并固定查看日志 #35；
这项断言调整不涉及产品代码或生产内容变更。

本次仅补充使用文档和核验摘要。`git diff --check` 通过；
已按项目要求调用 `bin/lint --fix` 检查三份说明文档，但宿主机缺少 Ruby，检查器未能启动。
这不替代发布时已完成的运行代码 lint 与 65 项隔离回归，也没有据此声称文档 lint 通过。

实现参考：

- [管理员路由与筛选](../../plugins/discourse-ai/app/controllers/discourse_ai/admin/ai_logs_controller.rb)
- [列表与详情入口](../../plugins/discourse-ai/admin/assets/javascripts/discourse/components/ai-logs.gjs)
- [模型回答详情](../../plugins/discourse-ai/admin/assets/javascripts/discourse/components/modal/ai-log-detail-modal.gjs)
- [日志保留任务](../../plugins/discourse-ai/app/jobs/scheduled/purge_ai_api_audit_logs.rb)
