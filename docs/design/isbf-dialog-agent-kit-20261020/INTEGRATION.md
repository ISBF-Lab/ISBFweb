# 在另一台设备接入

## 已有当前项目版本

将本包放入参考目录，指定目标仓库并交给Agent阅读。复用目标仓库已有共享层，按新功能创建DModal/FormKit组件。
本包AGENTS.md是阅读入口；repo-files/AGENTS.md及AI-AGENTS.md是原项目规范副本，合并时保留目标仓库的其他规则。

## 目标仓库缺少共享层

1. 先核对Discourse版本和UI kit/FormKit API。本次上线核心基线及实际增量摘要保存在发布source-manifest.json。
2. 比较并合并`themes/isbf-campus-feed/stylesheets/dialog-consistency.scss`，在主题common/common.scss的最后引入`@import "dialog-consistency";`。
3. 按reference/tokens-from-deployed-theme.scss.txt核对现有语义变量。该文件是原始变量摘录，完整主题的其他样式与依赖由目标项目保留。处理旧手写弹窗或局部外框覆盖时参考12份实际改动及其上线源码。
4. 合并`script/check-isbf-dialogs.mjs`、对应.test.mjs与`docs/design-system/dialog-exceptions.json`。检查器需放在项目script目录，从该位置扫描完整核心、主题和插件；本包只提供部分工程文件，不在资料包目录运行全项目扫描。
5. 将integration/package-scripts.json中的scripts字段合并到项目package.json，将integration/dialog-checks.yml.txt的步骤合并到现有CI。
6. 检查器单元测试只依赖Node内置模块；全项目扫描需要完整项目目录。Node要求>=20，项目使用pnpm 10（记录版本10.34.5）。例外清单与当前源码摘要绑定，目标分支差异应逐项审阅。

```bash
pnpm lint:dialogs
pnpm exec node --test script/check-isbf-dialogs.test.mjs
bin/lint --fix <修改文件>
```

UI kit与FormKit的工程API不定义本站视觉。真实日历/目录示例与公共SCSS来自当前上线版本；业务宽度例外仅在文档范围内复用。
一般开发在本地或隔离环境完成；本包中的历史发布记录用于追溯来源，不是新设备的自动部署脚本。
