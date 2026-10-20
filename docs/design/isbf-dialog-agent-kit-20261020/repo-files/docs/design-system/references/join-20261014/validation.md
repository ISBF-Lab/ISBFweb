# 招募接入验证记录

实现日期：2026-10-14；收尾验证跨至2026-10-15。范围为新增 `isbf-join` 插件与
“更多 → 加入我们”的点击目标。下文记录实现阶段，当时未发布生产。
后续已按用户授权上线，实际版本、生产加载修复和验证边界见
[2026-10-15 发布记录](../../deployments/join-20261015/README.md)。没有提交真实申请。

## 已实现行为

- 当前标签页打开 `/join/`；压缩包原始页面布局、样式、动画、模型、字段与提示保留。
- 匿名用户可加载招募页及其资源、提交表单，论坛开启 `login_required` 时仍公开。
- `POST /api/applications` 保存至 `isbf_join_applications`。首次201，相同 UUID 与归一化
  内容重试200，冲突409；并发由数据库唯一索引处理。
- `/admin/plugins/isbf-join/applications` 展示姓名、学号、手机和时间，每页50条。
  记录 JSON 只允许管理员读取；普通用户和非管理员版主无权限。
- 保留 CSRF、同源校验、请求体上限、IP 限流及论坛写入保护；无公开的申请数据文件。

## 已执行检查

| 检查 | 结果 | 证据与范围 |
|------|------|------------|
| 完整插件 RSpec | PASS：44 examples，0 failures，seed11904 | [日志](evidence/rspec-third.log)；真实隔离 PostgreSQL/Redis。 |
| 独立页面 Node 测试 | PASS：16/16 | [日志](evidence/node-final.log)；原有几何测试、字段校验、CSRF 获取、取消和异常。 |
| Vite 生产构建 | PASS：18 modules，19.40秒 | [日志](evidence/build-final.log)；入口、拆分脚本及清单随插件保存。 |
| 数据库迁移与结构导出 | PASS | [生成结果](evidence/schema-dump-result.json)；官方 clean dump，未使用生产数据库。 |
| 模型注释生成 | PASS：仅1个新模型 | [日志](evidence/annotations.log)。 |
| 来源摘要与静态清单 | PASS | [source-parity.json](source-parity.json)；23文件完全相同，18个清单资源存在且摘要一致。 |
| 前端静态编译 | PASS：11个文件，含3个 Glimmer 模板 | [最终源码摘要与结果](evidence/frontend-syntax-results.json)；真实编译，不等同浏览器行为测试。 |
| 代码静态检查 | PASS：Ruby、JS、模板、YAML、i18n | 执行 `bin/lint --fix`；[完整只读检查](evidence/lint-final.log)发现的单个 spec 格式问题经[修复](evidence/service-spec-lint-fix.log)及[只读复查](evidence/service-spec-lint-check.log)通过。 |
| 原包与接入页浏览器对比 | 未完成：原包桌面 ready 等待超时 | [实际记录](browser-validation.json)；120000ms 超时，无截图；未进入接入页、手机或表单模拟流程。 |

RSpec 包括公开入口与资源、真实 CSRF 缺失/有效请求、跨站拒绝、JSON/4096字节限制、
字段类型和 Unicode 边界、限流、保存失败503、幂等201/200/409、两个真实连接并发、
后台各身份权限、直接刷新后台路径、排序和50条分页。数据库表在测试清理后为空。
服务结构、业务、权限与测试规范的逐项审查见 [service-audit.md](service-audit.md)。

## 前端浏览器测试限制

新增4项管理员 QUnit 测试和1项主题菜单渲染测试已编写，`bin/qunit --dry-run` 可选中。
此环境没有兼容的新核心测试构建：缓存 `BUILD_INFO.json` 的核心树摘要为
`c2394bebb19b69d50597ff15a5ea289c6aa97451`，当前干净核心树为
`ebb7c2bbfee32451ce1d6d66aa2db16657be885a`。正常资源组装会拒绝该缓存。
完整重建在低内存路径要求2048MiB Node heap，超过本任务512MiB预算，因此未启动，
也未绕过缓存校验。这5项 QUnit **未在浏览器执行**；静态编译和独立页面截图不替代它们。
详细命令与判断见 [qunit-feasibility.md](evidence/qunit-feasibility.md)。

## 保持页面外观的依据

[原始清单](source-manifest.json)记录用户 ZIP 的27个选定源文件。
除 `src/application.js`、`package.json`、`vite.config.js` 三个接线/工具文件外，
23个文件逐字节一致；原 `package-lock.json` 转为 pnpm lockfile。
`index.html`、CSS、主动画、场景、广告牌、图库、品牌、字体、模型、Draco 和共享校验
均未重写。新增 `application-transport.js` 获取论坛 CSRF 再发送原有四个 JSON 字段。
菜单源文件只删除旧弹窗 import、增加 URL import 和更换点击动作。

浏览器脚本配置为使用实际控制器 CSP 与清单资源、从 ZIP 读取原包，并模拟503后201
检查表单界面。但本次单浏览器尝试在桌面原包等待 `is-ready` 时超时，未确认超时根因；
没有截图或几何对比结果，也未执行接入页 CSP、手机和错误/成功状态的浏览器验证。
未因该超时扩大工具预算或再次启动浏览器。源文件摘要与实际后端测试已分别完成；
不能据此把浏览器检查记为通过。复现脚本作为非执行附件保存于
[静态服务源码](evidence/serve_join_reference.py.txt)、
[浏览器验证源码](evidence/verify_join_reference.py.txt)与
[运行说明](evidence/static-browser-harness.md)。

## 结构导出与复现

新迁移由官方插件迁移生成器生成，仅新增招募表与两个索引。`db/structure.sql` 使用
官方 `db:dump_structure` 从全部已纳入仓库的插件迁移重建。原结构遗漏的12张既有
学院登记、头像框、账号切换、日历、浏览和转发插件表也随生成输出补齐；并有一处
既有 automation 默认值的生成差异。没有手工删改导出内容，也没有为其他业务新增迁移。
新模型注释通过官方 `annotate:clean` 生成。

由于共享主机预算，只启动本插件的测试 Rails，再满足当前测试套件精确判断
`LOAD_PLUGINS == "1"` 的注册表约束；核心文件未改动。参数和标准 CI 命令见
[隔离运行说明](evidence/rspec-runtime-notes.txt)。低内存官方任务入口见
[schema-tasks.rake.txt](evidence/schema-tasks.rake.txt)。有充足资源的标准验证命令：

```sh
LOAD_PLUGINS=1 RAILS_ENV=test bin/rspec plugins/isbf-join/spec
pnpm --dir plugins/isbf-join/web --ignore-workspace test
pnpm --dir plugins/isbf-join/web --ignore-workspace build
bin/lint plugins/isbf-join themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-utility-actions.gjs themes/isbf-campus-feed/test/integration/join-menu-test.gjs
bin/qunit plugins/isbf-join/test/javascripts/acceptance/admin-applications-test.js
```

## 资源与交付边界

使用单个 `isbf_join_tools_20261014` 隔离工具容器，512MiB内存及 swap 总预算、0.5 CPU、
192进程/线程、无外网、无生产数据及 Docker socket 挂载。隔离 PostgreSQL 与 Redis
在后端验证完成后关闭；完整预览论坛保持停止。页面构建、后端测试和浏览器均无 OOM。
浏览器记录的峰值工作集为484143104字节，`oom`/`oom_kill` 前后均为0；已关闭浏览器
和静态服务，工具容器已删除；[清理记录](evidence/cleanup.json)确认完整预览论坛仍为
停止状态。最终76个实现文件的摘要与 [implementation-manifest.json](implementation-manifest.json)
一致，变更范围内 `git diff --check` 通过。
上述结果属于实现阶段，不能代替生产验证。后续部署已核对完整插件库存、执行单项迁移、
构建后台资产并更新菜单所在的活动主题，见[生产记录](../../deployments/join-20261015/README.md)。
生产冷启动修正了插件入口的 concern 加载时机，并移除与 Engine eager loading 重复的
`app/` 显式 require；最终入口另经 `bin/lint --fix`、实际冷启动及生产 GET 检查。
44例隔离 RSpec 在该加载修复之前执行，没有声称最终入口复跑过这44例。
生产字体由既有 NGINX 静态规则提供，安装器发布原字体的单文件链接，内容保持；
该 WOFF2 响应没有 `nosniff`，其他17项清单资源仍经控制器返回该标头。
