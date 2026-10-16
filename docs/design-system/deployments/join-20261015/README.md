# 招募接入生产发布

2026-10-15 07:40:10（UTC+8）按用户的上线授权完成发布。更多菜单的“加入我们”
在当前标签页进入 [招募页](https://isbf-one.com/join/)，未登录用户可以访问和提交。
保存的申请仅管理员可以在 [申请记录](https://isbf-one.com/admin/plugins/isbf-join/applications)
查看，每页50条，包含姓名、学号、手机和提交时间。

## 实际发布范围

招募页继续使用用户 ZIP 的 HTML、CSS、动画、字体、模型和原有表单状态，
仅接入资源地址、论坛 CSRF 和保存接口。原包与实现的逐文件比较见
[来源记录](../../references/join-20261014/README.md)及
[source-parity.json](../../references/join-20261014/source-parity.json)。
本次没有重绘招募页或菜单，没有新增视觉 token 或扩大后台的批准范围。

插件源版本为 `5f7e2e4110cdacc283af0697f925a1240aa30003c68ba9f7ef20751110536839`，
安装在 `/shared/isbf-join-releases/<上述版本>/isbf-join`，通过插件目录软链接加载。
源清单共71文件，含 `.release-sha256`；发布包、安装器和清单摘要见 [package.json](package.json)。
生产核心保持 `132cc95d043db01251eedf9c93b3927cd5ffee91`。
原有64插件的完整源码、隐藏文件、内部及顶层软链接、共享发布标记均保持，发布后为65插件。

发布前读取活动数据库主题 ID 4 的实际190字段，在其菜单字段328上增量合并跳转动作。
菜单模板字节保持，另外189字段及主题设置保持，未用工作区快照覆盖实时主题。
实际菜单源码见 [sources/menu.gjs.txt](sources/menu.gjs.txt)，字段摘要与资源地址见
[menu.json](menu.json)。

仅执行本插件迁移 `20261014151020`，建立 `isbf_join_applications` 及 UUID 唯一索引、
时间/ID排序索引，没有运行其他迁移或创建测试申请。迁移时记录数为0，
管理员只读验证时仍为0；这不是对未来申请数的断言。详见 [migration.json](migration.json)。
服务验证字段、CSRF、同源请求、4096字节请求上限及 IP 限流，保存逻辑和幂等性由隔离测试验证。

## 生产加载与重建

冷启动发现共享目录软链接会让显式 `require_relative app/...` 与 Engine eager loading
重复加载同一类。最终只在插件入口提前加载共享字段 concern、Engine 和资源模块，
由 Engine 自动加载 `app/` 下的模型、服务和控制器。最终入口摘要为
`8530c549acb5b04b58adea2b9b39727badc1b2b37661a28cd3f34e0e7368bc2d`。
这项修复只调整后端加载时机；最终版本已通过生产冷启动、单项迁移及实际 GET 检查。

生产 NGINX 的字体扩展名规则会先于 Rails 路由处理 WOFF2。安装器因此只将原字体文件
软链接到 `public/join/fonts/inter-latin-variable.woff2`，内容摘要与原包一致。
该文件由既有静态规则返回 `font/woff2`，没有 `nosniff`；其余17项资源由控制器返回并包含
`nosniff`。没有调整或重新加载 NGINX 配置。

完整构建配置的 `after_code` 已增加固定版本安装 hook，其他配置保持：

```sh
python3 /shared/isbf-join-releases/5f7e2e4110cdacc283af0697f925a1240aa30003c68ba9f7ef20751110536839/install.py 5f7e2e4110cdacc283af0697f925a1240aa30003c68ba9f7ef20751110536839
```

只重启了一次 Unicorn，PostgreSQL、Redis、代理和生产容器持续运行；没有重建或暂停生产容器。
发布镜像为 `local_discourse/isbf_app:join-20261015`，从运行文件系统以 `--pause=false` 保存。
只读候选容器挂载相同的共享插件源码，逐项核对完整核心、65插件、链接、标记、资源及清单后，
将该镜像登记为 `local_discourse/isbf_app:latest`。实际 ID 和比较结果见 [image.json](image.json)。
运行容器自身的不可变 `.Image` 仍为 `sha256:d7392bb5d64fd8cb127fdf0f594bf8e890faf6346a449f3fbde6fc190fef8ae8`。
新镜像仍依赖共享发布源码及数据库主题；镜像不能单独替代这些持久数据的备份。

## 验证结果与边界

| 检查 | 结果与范围 |
| --- | --- |
| 匿名 HTTPS | 招募页及18项清单资源200，实际大小和 SHA-256 匹配；论坛仍要求登录。见 [http-public.json](http-public.json)。 |
| 匿名会话 | `/session/csrf.json` 实际返回 token，没有保存 token 或发送表单。见 [csrf.json](csrf.json)。 |
| 管理权限 | 管理员读取200、普通成员403、匿名 JSON 403，响应不缓存；未导出联系人数据。见 [http-admin.json](http-admin.json)。 |
| 新增编译资源 | 两份插件 JS、实际菜单 JS 的内容摘要匹配；菜单比较扣除框架附加的标准 sourcemap 注释。 |
| 桌面和手机招募表单 | 使用已逐项核对生产摘要的资源与实际 CSP，在1365×900、390×844下进入原有联系表单，三字段可见；禁用 WebGL，只验证 fallback 场景，未提交。见 [browser-public.json](browser-public.json)。 |
| 完整论坛浏览器 | 未完成：限额工具420秒超时，不能确认工作台、商城、校友及后台 UI 的完整桌面/手机加载。见 [browser-forum.json](browser-forum.json)。 |
| 3D 动画与视觉对比 | 未完成；原场景源码和模型摘要保留，资源成功返回不等于动画已通过浏览器验收。 |
| 实现阶段测试 | 隔离 RSpec 44例、Node 16例、Vite 构建及前端静态编译通过；5项 QUnit 未在浏览器运行。详见 [实现验证](../../references/join-20261014/validation.md)。44例执行于上述加载修复之前，没有将其描述为最终入口的复跑结果。 |

工具容器逐个运行，内存及 swap 总额512MiB、0.5 CPU、192进程上限，完整预览论坛始终停止。
公开页面浏览器峰值工作集421187584字节，未发生 OOM；完整论坛尝试也未因 OOM 退出。
临时只读 API key 和 scope 已删除，本任务工具容器已清理，见 [cleanup.json](cleanup.json)。
镜像保存后再次核对运行源码与候选完全一致，未观察到生产容器暂停事件；
[最后一次 HTTPS 检查](serving-final.json)仍确认公开入口200、匿名申请记录接口403。
没有向生产提交测试申请。
完整论坛和3D自动验收的缺项保留，不能将本记录作为它们已通过的证明。

## 定向回退与持久证据

持久私有目录为 `deploy-work/isbf-join-release-20261015/`，保存完整发布前后清单、主题备份、
候选源码、编译日志、配置摘要、最终发布包及发布脚本。原始配置和主题备份未放入公共文档。

只回退菜单时，将该目录的 `rollback-menu.rb` 复制到生产临时目录，使用生产 Rails runner
以 `discourse` 用户执行。脚本读取生产 `/tmp/isbf-join-release-20261015.json` 及
`/var/www/discourse/tmp/isbf-join-release-20261015/theme-before-menu.json`，先锁定活动主题并核对
字段328仍为本次发布后的摘要，再仅恢复该字段并重新编译；发现后续编辑就拒绝覆盖。

若还需停用后端，先核查后续版本与新申请，停用固定安装 hook，仅移除仍指向本版本的插件链接，
再重启 Web；保留招募表与所有申请记录。不要回滚数据库、覆盖完整主题或直接使用历史旧镜像。
字体链接、编译资源及 asset manifest 的进一步清理须核对当前引用后定向处理，不能覆盖后续发布。
