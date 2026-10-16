# 继续阅读直角边框修订

2026-10-17按用户最新要求，将“接着看看”容器改为直角边框（`border-radius: 0`），已发布到主题4、字段463。仅一项SCSS声明变化，头像仍沿用原组件。

`bin/lint --fix`通过；原生公共、桌面和手机CSS编译通过；线上HTTPS CSS摘要与直角声明核对通过。其余216项字段及主题设置保持不变。本次未重复原有60项客户端或19项线上矩阵检查。

这是数据库主题字段修订，运行来源为活动主题数据库；原生核心及[回退镜像](../image-verification.json)沿用上一版本。镜像内主题文件属于初版源码归档，不能替代此处最新字段快照。需要撤销时先确认字段仍匹配本次摘要，再只恢复初版SCSS；不整体恢复主题或业务数据库。

证据见[确切源码](source-manifest.json)、[lint](lint-status.json)、[主题事务与编译](square-theme-applied.json)和[线上CSS](square-border-resources.json)。该确认只覆盖继续阅读容器的直角形状。
