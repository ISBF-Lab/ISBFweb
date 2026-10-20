# 修改了哪些，共多少项

统计范围是2026-10-20这次已经上线的弹窗统一，不把编译数量当成改动数量。

| 统计对象 | 数量 | 含义 |
| --- | ---: | --- |
| 实际上线修改的源码 | **12份** | 11项主题字段与1份简历插件样式 |
| 主题字段 | 11项 | 新增2项、修改9项；另外219项及设置保留 |
| 工作区审阅交付文件 | 33份 | 包含源码、规范、检查器、CI和测试；见完整清单 |
| 扫描候选 | 174个源码入口 | 包含共享原语、非任务表面及菜单 |
| 共享外观适用入口 | **167个源码入口** | 166份DModal使用源码、1个确认服务入口 |
| 排除或基础设施入口 | 7个 | 3个菜单源码、3个基础/卡片/编辑器表面、1个启动错误页 |

167是源码入口数，同一入口可能承载多个业务弹窗；它不是167个独立用户弹窗，也不是167个文件被逐个改写。统一外观由公共层自动继承。

## 实际上线的12份源码

| 文件 | 操作 | 改动 |
| --- | --- | --- |
| themes/isbf-campus-feed/common/common.scss | 修改 | 最后引入共享弹窗样式，清除旧手写日历外观 |
| themes/isbf-campus-feed/stylesheets/frontend-consistency.scss | 修改 | 移除旧页面/组件名单限定的弹窗外观 |
| themes/isbf-campus-feed/stylesheets/reporting.scss | 修改 | 举报弹窗移除手机直角和重复外框 |
| themes/isbf-campus-feed/stylesheets/learning-resources.scss | 修改 | 清除手写目录弹窗及失效容器外观 |
| themes/isbf-campus-feed/stylesheets/official-calendar.scss | 修改 | 清除旧弹窗底部局部覆盖 |
| themes/isbf-campus-feed/stylesheets/dialog-consistency.scss | 新增 | 新增统一外框、按钮、分区和手机边距 |
| themes/isbf-campus-feed/javascripts/discourse/components/isbf-frontend-scope.gjs | 修改 | 移除弹窗路由与组件名单，保留页面范围 |
| themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-calendar.gjs | 修改 | 个人日历编辑接入模态服务，保留线上订阅入口 |
| themes/isbf-campus-feed/javascripts/discourse/components/isbf-calendar-entry-editor.gjs | 新增 | 新增DModal/FormKit日历编辑器 |
| themes/isbf-campus-feed/javascripts/discourse/components/isbf-resource-directory-dialog.gjs | 修改 | 目录/课程公共编辑迁入DModal与FormKit |
| themes/isbf-campus-feed/javascripts/discourse/components/isbf-resource-parent-picker.gjs | 修改 | 保存中禁用选择器，保留线上浮层API |
| plugins/isbf-resume/assets/stylesheets/isbf-resume.scss | 修改 | 简历确认去掉独立按钮圆角及重复外框 |

可筛选清单：[实际改动12份](lists/DEPLOYED-CHANGES.csv)、[共享外观入口167个](lists/AFFECTED-DIALOG-ENTRIES.csv)、[全部候选174个](lists/ALL-CANDIDATES.csv)、[审阅交付33份](lists/DELIVERED-FILES.csv)。

原线上课程入口仍导出公共目录组件，年级选择器仍导出公共父级选择器，这两个别名保留，因此不计入12份实际改动。
新框架自动覆盖跳转、分享、书签、头像、邀请、安全设置、群组、举报、简历确认、官方活动、日历备注、资源分享等符合范围的前台任务对话框及确认提示。
菜单、后台、用户卡、图片查看器、编辑器、独立认证与招募页继续使用自身呈现；不把这些表面纳入167入口的业务验收。

184个主题模块和132个样式目标是完整编译数量；66个插件和1279项既有资源/生成清单为保留核对数量。
170项隔离检查及45项线上检查通过。原生QUnit/RSpec未在该环境执行，具体边界保留在日志中。
