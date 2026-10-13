# Anthropic 技能安装记录

2026-10-09，按用户要求，将 [anthropics/skills](https://github.com/anthropics/skills) 仓库中的新增技能安装到当前 Codex 环境。

- 来源版本：[683bc88e56f3e09ba94f7055977f3d3aa499f202](https://github.com/anthropics/skills/tree/683bc88e56f3e09ba94f7055977f3d3aa499f202)。
- 安装目录：`/home/codex/.codex/skills`。
- 安装方式：使用系统 `skill-installer` 的 `install-skill-from-github.py`，指定仓库、来源版本和各技能目录，复制完整技能文件。
- 仓库包含 19 个技能，本次新增 18 个。现有系统 `skill-creator` 保留，未覆盖其文件。

## 已安装技能

- `academy-guide`
- `algorithmic-art`
- `brand-guidelines`
- `canvas-design`
- `claude-api`
- `discernment-nudge`
- `doc-coauthoring`
- `docx`
- `frontend-design`
- `internal-comms`
- `mcp-builder`
- `pdf`
- `pptx`
- `slack-gif-creator`
- `theme-factory`
- `web-artifacts-builder`
- `webapp-testing`
- `xlsx`

## 验证与使用

18 个技能均存在 `SKILL.md`，其 YAML 元数据可解析，`name` 与目录名称一致，`description` 非空。技能目录包含 399 个支持文件；系统 `skill-creator/SKILL.md` 的安装前后 SHA-256 一致。

依据当前系统安装器的说明，新技能从下一条消息起可用。可按任务需要引用技能名称，例如 `frontend-design`。关于技能自动发现和使用方式，参见 [Codex 官方技能文档](https://learn.chatgpt.com/docs/build-skills)。

本记录描述当前远端环境的安装状态。其他开发环境需要单独安装；本次只安装技能文件，各技能运行时依赖在实际使用时按其说明配置。
