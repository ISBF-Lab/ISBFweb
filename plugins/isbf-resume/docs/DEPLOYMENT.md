# 简历发布

本插件随 ISBFweb 的 `plugins/isbf-resume` 维护。2026-10-13 用户完成真实网页测试并明确同意上线；验收功能源码来自 `ba949585bc431808d2d52c0620887eb45bb2811e`。接入时只补充工作台简历链接、路由归属及首页判断，保留正在运行主题的其他功能。仓库主题与数据库主题有协作差异，不能整份覆盖。

依赖安装入口是 `deploy/install-runtime.sh`：Python 虚拟环境位于 `/opt/resume-venv`，本地 LibreOffice Writer 转换 PDF，Poppler 生成实际 PDF 的逐页图片，Noto CJK 提供字体。生成不访问外部 API。新增文档 CI 与已有 Core lint、前后端测试同时运行。

当前已有正式容器可把已合并 Core commit 中本目录提取到 `/shared/isbf-resume-releases/<commit>/isbf-resume`，写入一致的 `.release-commit`，再执行 `deploy/install-plugin.sh <commit>`。安装器只创建不存在的插件链接；后续完整 Core 重建已经包含相同插件时保留该目录。生产配置 `after_code` 只增加该固定安装命令并保留其他 hooks。

私有导出默认存放在 `/shared/isbf-resume-private`，目录权限 700，属主 discourse，不能映射为公开静态目录。插件无数据库迁移。当前用户才能查看和下载自己的文件，文件有效期为 24 小时。

上线前重新读取运行核心、所有插件的隐藏文件及链接、共享版本标记和当前数据库主题。备份这次实际目标文件、配置、主题和配套数据，并校验摘要。以当前主题为基线应用 `deploy/theme-integration.patch`；该补丁仅记录 2026-10-13 读取的两个字段，基线改变时应重新整合。不要导入旧完整主题。

先预编译插件生产 JavaScript，在隔离环境验证集成；上线只启用 `isbf_resume_enabled` 并重新加载 Web。核查实际页面、填写内容预览、两色及英文 DOCX/PDF、访客和文件归属权限，同时确认原有工作台入口和数据加载。恢复只关闭该设置、比较后撤销本次两个字段、安装链接和固定 hook，保留生成文件及当前数据库。依赖镜像和备份须保留到确认不再需要，不能以旧主题、旧数据库或旧完整镜像覆盖后来的协作更新。


## 2026-10-14：生产资源发布门禁

简历页头发布首次遗漏公开脚本和 Propshaft 生产清单，只更新了 `app/assets/generated/isbf-resume/manifest.json`；所有 HTML 都引用该插件资源，因此首页及登录页返回 500。发现后恢复 `32c32fca205579be24741b33ee32c4b2d18ea99d` 的插件、生成清单和固定 hook，Edge 中原有真实账号恢复。此前“源文件已验证、Unicorn 运行”不足以证明网站能打开。

后续固定版本发布必须同时备份插件源码、生成包、公开资源清单、主题配置及 hook。在清洁且仅限本插件的 generated 目录编译，避免回滚遗留候选文件导致 JsManager 跳过编译却保留旧清单；不得清理其他插件目录。

编译后在现有 Rails 环境加载 `deploy/publish-assets.rb`，调用：

```ruby
require Rails.root.join("plugins/isbf-resume/deploy/publish-assets")
publication = IsbfResume::AssetPublication.new(
  assembly: Rails.application.assets,
  generated_path: Rails.root.join("app/assets/generated/isbf-resume"),
)
publication.publish!
publication.verify!
```

发布器使用当前 Propshaft 1.3.2 的 LoadPath、Manifest 和 Static resolver，仅发布本插件的 JS/source map，先写公开文件，再原子合并生产清单。保留所有旧版本、其他插件和已有 metadata 条目，不公开 generated 根目录的 `manifest.json`。遇到同名条目/内容冲突或清单并发变化时停止；发布操作串行执行，不调用会重写完整清单的全站 processor。

重载 Web 后，必须在 Edge 检查首页、访客登录页、真实账号和简历页面；同时确认当前 main/import/route 包在生产静态清单可解析、公开地址返回 200，且没有页面/脚本请求错误。通过这些门禁后才能记录“发布成功”。回滚保留新增的不可变公开资源条目，仅恢复该插件的源码、generated manifest 和 hook，随后同样验证网站；不覆盖后来合并的其他插件资源清单。

CI 的独立 `asset-publication` job 使用真实 Propshaft Static resolver 检查缺失清单、缺失文件、旧条目保留、冲突和重试，不依赖 Discourse test 环境会返回假路径的 `asset_path`。文档生成测试保持原有流程。此次故障的动态检查不等于所有角色、完整简历生成或 iPhone 主屏幕真机回归。
