# ISBF - One

[访问网站](https://isbf-one.com) · [反馈问题](https://github.com/ISBF-Lab/ISBFweb/issues)

ISBF - One 是由 **ISBF-Lab** 运营的校园平台，面向在校学生与校友，将校园交流、官方消息、学习资源和日常工具汇集在同一处。

在这里，你可以分享校园生活，参与讨论，查找课程资料，把活动加入自己的日历，也可以通过工作台使用简历工具、查看校友网络与校园商城。

## 社区与工具

| 功能 | 可以做什么 |
| --- | --- |
| 校园动态与讨论 | 发布动态，浏览最新内容，参与回复，点赞和收藏感兴趣的帖子。 |
| 官方消息与活动 | 识别认证发布者的官方消息，查看活动时间、地点、主办方和报名截止日期。 |
| 个人日历 | 记录个人行程，添加官方活动或截止日期，保存私人备注，并确认后续时间变更。 |
| 学习资源 | 按年级和课程查找学习材料，提交资源分享与课程申请，经相应审核后展示。 |
| 简历工具 | 按字段填写个人内容，选择模板并预览排版，生成和下载 DOCX、PDF 文件。 |
| 校友网络与商城 | 通过名单和地区地图查找选择公开展示资料的校友，查看和发布商品信息。 |

功能入口随站点配置和账号权限开放；工作台中标注“即将开放”的模块会逐步建设。

## 加入社区

访问 [isbf-one.com](https://isbf-one.com)。社区采用邀请注册：在校学生使用站点发放、绑定学号的邀请；校友通过校友申请与审核流程加入。

登录后可从首页参与社区讨论，通过日历管理安排，在工作台查看可用工具。个人行程和私人备注仅本人可访问，校友资料是否在网络中展示由本人选择。

## 关于这个仓库

本仓库保存 ISBF - One 基于 [Discourse](https://github.com/discourse/discourse) 二次开发的社区核心、校园主题、自有插件和项目文档。

| 位置 | 内容 |
| --- | --- |
| [校园主题](themes/isbf-campus-feed/) | 信息流、话题阅读、通知及工作台页面。 |
| [身份与权限](plugins/discourse-academy-roles/) | 邀请注册、学生身份绑定、角色权限和官方发布身份。 |
| [日历](plugins/isbf-calendar/) | 个人日程、官方活动与截止日期的导入及更新确认。 |
| [学习资源](plugins/isbf-learning/) | 课程资源、资料目录、内容审核和访问权限。 |
| [简历工具](plugins/isbf-resume/) | 表单、模板、预览与文档生成。 |
| [设计与验收记录](docs/design-system/) | 已确认的界面规范、参考来源、验证和发布记录。 |

部分站点扩展独立维护，实际功能还依赖插件加载、站点设置和数据库中的主题。部署前请核对[插件与主题完整性要求](docs/workbench-plugins-missing-20261010.md)。

## 参与建设

欢迎通过本仓库的 [Issues](https://github.com/ISBF-Lab/ISBFweb/issues) 反馈问题或提出改进建议，也欢迎提交 Pull request。

开发前请阅读 [项目协作指引](AGENTS.md) 和 [开发文档](docs/developer-guides/README.md)。界面调整以[设计状态与验收范围](docs/design-system/ui-status.md)为依据；测试、构建和预览遵守[资源规范](docs/design-system/resource-policy.md)。

提交前运行受影响文件的 `bin/lint --fix` 和对应测试。PR 推送后的检查与续跑采用[后台 CI 交接流程](docs/codex-ci-handoff.md)。

## 上游与许可

感谢 Discourse 及其社区提供的开源基础。上游贡献者见 [AUTHORS](docs/AUTHORS.md)，项目沿用 GNU GPL v2 或更高版本许可，完整条款见 [LICENSE.txt](LICENSE.txt)。

Copyright 2014 - 2026 Civilized Discourse Construction Kit, Inc.

Licensed under the GNU General Public License Version 2.0 (or later);
you may not use this work except in compliance with the License.
You may obtain a copy of the License in the [LICENSE.txt](LICENSE.txt) file, or at:

   https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Discourse logo and “Discourse Forum” ®, Civilized Discourse Construction Kit, Inc.
