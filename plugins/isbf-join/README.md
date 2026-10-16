# ISBF join

招募页面与匿名登记接口，申请记录仅 Discourse 开发者（`admin`）可查看。

- 招募页：`/join/`，即使论坛要求登录也公开。
- 提交：`POST /api/applications`，JSON 字段为 `name`、`studentId`、`phone`、`submissionId`。
- 后台：`/admin/plugins/isbf-join/applications`。
- 后台数据：`GET /isbf/join/admin/applications.json?page=1`，仅管理员可读，响应禁止缓存。

姓名、学号、手机分别限制60、40、30个 UTF-16 码元，校验与原包一致。手机号允许
国家区号、空格、括号和连字符，数字总数为7至15。提交标识为 UUIDv4。
首次保存返回201，相同标识及归一化内容重试返回200，内容冲突返回409。
数据库唯一索引保证并发去重；记录保存在 `isbf_join_applications`，不产生公开 JSON 数据文件。

浏览器先请求现有 `/session/csrf.json`，再携带同源 cookie、CSRF 和 XHR 请求头提交。
接口保留 CSRF 保护，拒绝跨站请求；每 IP 每10分钟最多20次，JSON 请求体最多4096字节。
字段错误返回400及原表单可读的 camelCase 错误键；限流返回429和 `Retry-After`，
数据库不可用返回503，均不会显示成功。论坛的只读和归档写入限制继续生效。

后台按提交时间、记录 ID 倒序，每页50条，显示姓名、学号、手机和提交时间，支持
上一页、下一页和加载失败重试。普通用户和非管理员版主不能读取申请记录。

## 页面来源与构建

`web/` 来源为用户提供的 `docs/isbf-one-join-app.zip`。
原始 HTML、CSS、动画、模型、品牌、字段和提示保留；变更范围及原始 SHA-256 见
[设计来源记录](../../docs/design-system/references/join-20261014/README.md)。
简历仍由申请人邮件发送到原页面邮箱；本插件保存联系信息。

```sh
pnpm --dir plugins/isbf-join/web --ignore-workspace install --frozen-lockfile --ignore-scripts
pnpm --dir plugins/isbf-join/web --ignore-workspace build
```

构建后的入口、脚本和 CSS 位于 `web/dist/`，随插件提交。模型、字体和 Draco 等
原始静态文件保留在 `web/public/`，避免重复保存大型文件。构建同时生成
`web/asset-manifest.json`；Rails 仅提供清单中的静态文件，不暴露源码或任意目录。
页面 CSP 仅作用于招募文档，支持其原有 WebAssembly、blob worker 及内嵌纹理读取。
GLTFLoader 在 Chromium/Firefox 中通过 `fetch(blob:...)` 读取纹理，因此 `connect-src`
必须显式允许 `blob:`；Safari 使用图片加载路径，仅允许 `img-src blob:` 会漏掉这一差异。
客户端 `/join` 路由负责将论坛内部导航转为完整文档加载，使已安装 PWA 也能进入独立页面。

源码或公共资源变动后必须重新构建，并一起提交清单及构建产物。`pnpm dev` 仅供
页面预览，真实提交通过论坛提供的 `/join/` 验证；原包的独立 Node 保存服务不再使用。
Three.js、Draco、字体许可和模型来源文件原样保留。

## 数据库与验证

迁移由 Rails 插件迁移生成器创建，新增表与索引，不修改已有业务数据。
发布时先应用迁移、确认插件路由可用，再更新主题中的加入入口。回退入口或插件代码时
保留已收到的申请数据。

```sh
LOAD_PLUGINS=1 RAILS_ENV=test bin/rspec plugins/isbf-join/spec
pnpm --dir plugins/isbf-join/web --ignore-workspace test
bin/qunit plugins/isbf-join/test/javascripts/acceptance/admin-applications-test.js
```

主题入口测试位于 `themes/isbf-campus-feed/test/integration/join-menu-test.gjs`。
测试必须使用隔离数据库；不以生产论坛作为测试后端。
