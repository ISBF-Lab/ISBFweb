# 本包给Agent的阅读入口

先读README.md和CHANGELOG.md，确认实际变更与167个源码入口的统计边界。所有操作以目标项目根目录的AGENTS.md为准；本包保留了当时的规范副本。

做前台弹窗时，读取repo-files/docs/design-system/dialogs.md，以及同目录的ui-status.md、tokens.md、components.md、reference-map.md、references/README.md和manifest.json。
组件使用DModal，确认/删除/提示使用dialog服务，按钮使用DButton，表单使用FormKit。公共外框、分区、按钮和手机边距由dialog-consistency.scss负责。保留业务宽度及危险、禁用和加载语义。
外观例外按契约登记原因、设计依据和验证入口。当前认可范围仅为前台任务弹窗和确认提示；后台、菜单、卡片、编辑器、图片查看器及独立页面沿用自己的规则。
工程行为参考UI kit/FormKit文档和相关.skills；平台默认主题的外观不是本站设计依据。
完成后在目标仓库运行pnpm lint:dialogs、检查器测试、修改文件lint及相应电脑/手机、明暗、长内容、键盘和失败重试验证。源码检查与截图分别记录结果。
接入见INTEGRATION.md，业务组件实际源码见发布目录内source/*.txt；仅借鉴结构，接口与权限按新功能实现。
