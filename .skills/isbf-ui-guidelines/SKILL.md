---
name: isbf-ui-guidelines
description: "Design, implement, or review UI in the ISBF/Discourse project using its approved design system. Use for project layouts, components, responsive action bars, and foreground dialogs, including requests for ISBF UI规范、设计规范、弹窗规范或窄屏按钮收纳. Requires the target project's docs/design-system; not a general visual design or deployment skill."
---

# ISBF UI 规范

用于本项目的 UI 设计、实施和审查。技能负责找到现行规则，具体数值、版本和验收状态以目标仓库的 `docs/design-system/` 为准。

## 找到现行设计依据

在目标 ISBF/Discourse 仓库中工作，先读其 [AGENTS.md](../../AGENTS.md)，再读以下四份规范，包括与任务相关的后续日期补充：

- [UI 状态](../../docs/design-system/ui-status.md)：区分 Approved、Legacy、In Progress 与需要人工确认的区域及状态。
- [Design tokens](../../docs/design-system/tokens.md)：找到颜色、字体、间距、形状及响应式规则的实际作用域。
- [组件规范](../../docs/design-system/components.md)：定位对应的 Cxx 条目及后续修订。
- [Reference Map](../../docs/design-system/reference-map.md)：按具体路由和用途选择 Axx/Cxx 参考。

以上链接按仓库内 `.skills/isbf-ui-guidelines/` 的位置组织；从其他位置调用时，在目标仓库根目录解析对应路径。缺少设计文档时说明缺失项，不能用平台默认外观或旧规范包补齐。

明确要改的区域、路由、开关、权限、宽窄布局和交互状态。页面壳获批不代表内层表单、菜单、异常态或整条路由获批。先查当前需求及已有记录中的用户确认，在已确认范围内直接执行；仍有设计缺口时，列出可复用来源和待决定项，获得确认后再实现相关部分。

使用参考源码前读 [来源说明](../../docs/design-system/references/README.md)，并核对 [manifest](../../docs/design-system/references/manifest.json) 的来源、摘要和适用版本。历史 `.txt` 附件、截图和规范包是审阅证据，不是可安装主题；当前工作区也不能整体视为已验收副本。读取实际样式的完整级联及后续覆盖，不把局部值提升成全局 token，不因页面能打开或代码已上线扩大 Approved 范围。

## 复用组件与外观

新控件使用目标仓库的 UI kit、FormKit 和 float-kit 公开 API。工程行为和项目外观分别核对：组件自带的默认样式、Foundation/Horizon 或通用设计技能不能代替本项目的 Approved 参考。

按工作内容遵循仓库要求的工程技能；模板和样式使用 [discourse-writing-html-css](../discourse-writing-html-css/SKILL.md)，JS/TS/Glimmer 类和模板同时使用 [discourse-frontend-conventions](../discourse-frontend-conventions/SKILL.md)。类型、模型及测试按目标仓库 AGENTS.md 的对应技能处理。

### 栏目操作区按钮收纳

执行 [C01 窄屏收纳规则](../../docs/design-system/components.md#栏目操作区窄屏收纳) 与 C06：

- 适用于栏目页头、列表及卡片操作栏。按操作区实际可用宽度判断，包含长文案、动态内容和权限变化的影响。
- 放不下一行时，禁止按钮换行；外露一个业务按钮和一个三点菜单入口，其余操作收入菜单。宽度恢复充足时还原原有排列，保留既有触控尺寸。
- 由提出需求的用户逐栏目指定外露业务按钮，先查是否已经指定；缺少决定时先向该用户确认。这里不是让站点使用者新增个人偏好设置。
- 菜单复用 `DButton`、`DMenu`、`DDropdownMenu` 和对应已批准外观，保留权限、禁用、加载、导航语义、可访问名称及键盘行为。
- 表单提交/取消、弹窗底部和认证按钮沿用各自规范，不套用本条收纳规则。

### 前台任务弹窗

读 [弹窗契约](../../docs/design-system/dialogs.md) 及任务涉及的 [例外登记](../../docs/design-system/dialog-exceptions.json)。任务弹窗使用 `DModal`，确认/删除/提示使用 `dialog` 服务，操作使用 `DButton`，表单使用 FormKit。共享外框和文字操作外观由主题提供，保留业务宽度及文档允许的布局变体，不在业务组件增加私有外框样式。

后台、用户卡、查看器、编辑器、手机菜单和独立招募页按各自批准范围处理；借用 `DModal` 不会把一个菜单变成任务弹窗。

## 验证与保存结果

启动检查或预览前读 [资源规范](../../docs/design-system/resource-policy.md)，按当前内存和有效 cgroup 余量设置预算，串行使用工具；共享主机保持完整预览论坛停止，不以生产作为测试后端。

按实际修改验证宽窄布局、明暗模式、长内容、权限、动态状态及键盘行为。栏目操作栏检查收纳和恢复，弹窗检查焦点、关闭和失败重试。遵循仓库的定向测试及 `bin/lint --fix` 要求；修改弹窗模板或样式时另运行 `pnpm lint:dialogs` 和契约要求的检查，不为纯文档修改启动应用或浏览器。

区分设计已确认、技术检查通过、实际发布和最终视觉验收，记录真实执行结果及未验证项。新获确认的区域在 `docs/design-system/` 保存来源版本、验收范围、tokens、组件规则和参考映射，必要时补充 manifest。更新规范时保持本技能引用有效，不复制整套快照到技能内。部署及其他外部变更只在用户授权范围内进行。
