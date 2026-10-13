# 简历发布

本插件随 ISBFweb 的 `plugins/isbf-resume` 维护。2026-10-13 用户完成真实网页测试并明确同意上线；验收功能源码来自 `ba949585bc431808d2d52c0620887eb45bb2811e`。接入时只补充工作台简历链接、路由归属及首页判断，保留正在运行主题的其他功能。仓库主题与数据库主题有协作差异，不能整份覆盖。

依赖安装入口是 `deploy/install-runtime.sh`：Python 虚拟环境位于 `/opt/resume-venv`，本地 LibreOffice Writer 转换 PDF，Poppler 生成实际 PDF 的逐页图片，Noto CJK 提供字体。生成不访问外部 API。新增文档 CI 与已有 Core lint、前后端测试同时运行。

当前已有正式容器可把已合并 Core commit 中本目录提取到 `/shared/isbf-resume-releases/<commit>/isbf-resume`，写入一致的 `.release-commit`，再执行 `deploy/install-plugin.sh <commit>`。安装器只创建不存在的插件链接；后续完整 Core 重建已经包含相同插件时保留该目录。生产配置 `after_code` 只增加该固定安装命令并保留其他 hooks。

私有导出默认存放在 `/shared/isbf-resume-private`，目录权限 700，属主 discourse，不能映射为公开静态目录。插件无数据库迁移。当前用户才能查看和下载自己的文件，文件有效期为 24 小时。

上线前重新读取运行核心、所有插件的隐藏文件及链接、共享版本标记和当前数据库主题。备份这次实际目标文件、配置、主题和配套数据，并校验摘要。以当前主题为基线应用 `deploy/theme-integration.patch`；该补丁仅记录 2026-10-13 读取的两个字段，基线改变时应重新整合。不要导入旧完整主题。

先预编译插件生产 JavaScript，在隔离环境验证集成；上线只启用 `isbf_resume_enabled` 并重新加载 Web。核查实际页面、填写内容预览、两色及英文 DOCX/PDF、访客和文件归属权限，同时确认原有工作台入口和数据加载。恢复只关闭该设置、比较后撤销本次两个字段、安装链接和固定 hook，保留生成文件及当前数据库。依赖镜像和备份须保留到确认不再需要，不能以旧主题、旧数据库或旧完整镜像覆盖后来的协作更新。
