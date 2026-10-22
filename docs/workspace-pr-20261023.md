# 当前工作区整合（2026-10-23）

本次在隔离分支中整合当前工作区，基于`main`的`604ea93d6f5f79f8bc855e31ea48b8aad34526ab`，保留已合入的README、十段昵称渐变和窄屏颜色控件修复。原工作区189份快照文件的摘要均保持，其他worktree不变。

- 新增已确认的注册后首次设密组合：只提醒新无密码本地账号，支持确认密码、显隐和持久跳过；服务端校验会话信任、权限、限流与并发，过期会话使用邮件验证。来源和边界见[设计与验证记录](design-system/reviews/post-signup-password-20261022/README.md)。
- 时间轴通过稳定的模板内容识别导航，避免Ember重写临时class后退回底部面板；此前发布证据单独保留，此次没有生产部署。
- 保存项目UI技能和窄屏按钮规则，将其接入共同代理指南；没有新增视觉token或扩大Approved范围。
- 整理Windows CI交接适配器，并补上Linux/Windows离线队列测试配置；Linux继续沿用Unix控制socket版本。

## 验证

| 检查 | 结果 |
| --- | --- |
| 学院插件完整原生RSpec，含活动/匿名等真实依赖 | 303通过，0失败、0 pending；首次设密相关68项包含其中 |
| 最终JS/Glimmer源码及测试编译 | 12份通过 |
| 完整共享SCSS、明暗配色及中英文提取 | 通过 |
| 本地真实Ember客户端定向流程 | 35项通过，无客户端异常，无生产后端 |
| 变更文件`bin/lint --fix` | ESLint、Prettier、RuboCop、Syntax Tree、Stylelint通过 |
| `pnpm lint:dialogs` | 176个候选，0违规 |
| 弹窗契约与独立前端门禁 | 14项通过 |
| Linux及Windows适配器的离线交接回归 | Linux主机53项通过，无网络及模型调用 |

完整学院测试的宿主wrapper中途退出143，原容器继续完成且退出0、自动删除；完整原生JSON和Docker生命周期记录已保留。最终峰值与全程宿主监控记录不完整，详见[规格审阅](workspace-pr-password-spec-review-20261023.md)。其他最终验证工具正常退出并删除。

原生QUnit、主题完整回归及Windows runner的结果须以本次PR CI为准。真实Windows Desktop的端到端队列消费和自动续跑尚未在本Linux主机验证，不能由离线测试替代。设计技术检查与最终人工视觉验收分别记录。

失败调试日志、编译缓存和原始工作区快照保留在持久`deploy-work/workspace-pr-20261023/`；PR保留最终结果、可复核源码及必要来源证据。后续遵循[后台CI交接](codex-ci-handoff.md)，核对实时head、全部适用检查和未解决审查后，才执行用户已授权的合并。
