# ISBF弹窗统一规范包

适用于同一个Discourse/ISBF项目在其他设备上的开发。入口均为相对路径；本包不需要原服务器目录、账号或数据库即可阅读。

## 给其他Agent使用

1. 解压，先读本文件、[AGENTS.md](AGENTS.md)和[修改清单](CHANGELOG.md)。
2. 把[PROMPT.txt](PROMPT.txt)的内容连同本包路径交给Agent，并指定目标项目仓库。
3. Agent先遵循目标仓库的AGENTS.md，再读本包的弹窗契约、设计系统和相关技能。

## 主要内容

| 内容 | 路径 |
| --- | --- |
| 弹窗契约、示例、例外 | [dialogs.md](repo-files/docs/design-system/dialogs.md) |
| 当前实际共享样式 | [dialog-consistency.scss](repo-files/themes/isbf-campus-feed/stylesheets/dialog-consistency.scss) |
| 变量来源 | [上线主题token摘录](reference/tokens-from-deployed-theme.scss.txt) |
| 设计状态、tokens、组件及参考映射 | `repo-files/docs/design-system/` |
| 原始验收来源及后续补充 | `repo-files/docs/design-system/references/` |
| 当前上线源码、版本及两端截图 | [发布记录](repo-files/docs/design-system/deployments/dialog-consistency-20261020/README.md) |
| 12份改动、167个入口及完整候选 | [CHANGELOG.md](CHANGELOG.md)、`lists/` |
| 工程规范和UI kit/FormKit/BEM说明 | `repo-files/.skills/`、`repo-files/docs/developer-guides/` |
| 源码检查器和单元测试 | `repo-files/script/check-isbf-dialogs*.mjs` |
| 接入方式 | [INTEGRATION.md](INTEGRATION.md) |

采用当前已上线增量的实际源码版本，保留线上课程别名、选择器API和日历订阅等差异。
`repo-files/`用于对照和逐项合并；已有项目保留自己的其他代码与设置。完整主题、Discourse运行时和依赖由目标仓库提供。
`.txt`源码与历史附件供审阅；它们不是可直接安装的完整主题。历史记录中的服务器路径、镜像和容器名仅描述当时来源。
本包聚焦前台弹窗；其他页面的新区域继续按照目标仓库的批准范围与设计文档处理。

## 核对完整性

```bash
python3 verify-package.py
```

`MANIFEST.json`记录每份附件来源和SHA-256；`SHA256SUMS`用于传输核对。本包包含选定弹窗验证记录；其他历史记录的链接需在完整项目仓库中读取。
