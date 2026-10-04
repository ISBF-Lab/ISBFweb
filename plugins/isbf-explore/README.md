# ISBF Explore

独立 Discourse 插件，为国金探索信息流保存账号偏好。复用 Core 的登录、Guardian、CSRF 和 PluginStore；不新增数据库表，不修改分类或标签的原生关注、通知设置。

## 配置

`isbf_explore_enabled` 默认开启，并提供给客户端。关闭后偏好接口不可用。将插件安装到 Discourse 的 `plugins/isbf-explore`，重建或重启既有开发环境后加载。

## 接口

两个接口均要求登录。账号仅取 `current_user.id`；不接受客户端指定保存账号。

- `GET /isbf/explore/preferences.json`：读取当前账号偏好，无记录时返回空选择和 `activity`。
- `PUT /isbf/explore/preferences.json`：用完整 JSON 替换当前账号偏好。

PUT 示例：

```json
{ "category_ids": [2, 3], "tag_ids": [10, 11], "order": "hot" }
```

GET 和 PUT 均返回：

```json
{
  "preferences": {
    "category_ids": [2, 3],
    "tag_ids": [10, 11],
    "order": "hot"
  },
  "tags": [
    { "id": 10, "name": "学习", "slug": "学习" },
    { "id": 11, "name": "求职", "slug": "求职" }
  ]
}
```

`tags` 仅包含保留的已选标签，顺序与 `tag_ids` 一致。标签没有 slug 时使用 name。PUT 必须包含全部三个字段，不接受额外业务字段，包括 `user_id`。ID 必须是正整数 JSON number，最大值为 PostgreSQL integer 上限 2147483647；不接受字符串、浮点数、布尔值或嵌套对象。每组最多提交 50 项，先检查数量再去重。`order` 只接受 `activity` 或 `hot`；非法参数返回 400。

分类通过 `Category.secured(guardian)` 过滤，标签通过 `guardian.can_see_tag?` 过滤。合法但已删除或不可见的 ID 被过滤。GET 不修改存储记录，因此暂时失去权限的选择可在权限恢复后重新显示。PUT 仅保存当前可见的去重选择；空数组会清空选择。PluginStore 名空间为 `isbf-explore`，key 为当前用户 ID 的字符串。最后成功写入的完整记录生效，存储失败时保留之前的记录；不在用户表上添加外键。

PUT 沿用 Discourse Core 的 CSRF 校验。浏览器请求应通过 Discourse 请求工具发送，或携带有效 CSRF token；插件不绕过或另建认证机制。

插件通过官方 `add_to_serializer` 扩展原生 `detailed_tag` serializer：启用时，`GET /tag/<slug>/<id>/info.json` 的标签详情包含 `isbf_explore_filter_name`，其值为 canonical `Tag.name`，供原生 `/filter` 路由使用。该字段不替代本地化显示名称。访客可以通过 Core 已有接口读取可见标签；私密标签继续由原生 Guardian 检查控制。关闭插件后不包含此字段。

## 原生信息流分类过滤

插件通过官方 `add_filter_custom_filter` 为 Core `/filter.json` 注册 `isbf-category` 过滤项。例如 `q=isbf-category:4` 精确选择分类 ID 4，不包含子分类，不依赖分类 slug，也不改变 `slug_generation_method`。可与原生 `tag:标签一,标签二`（标签 OR）、`order:activity` 或 `order:hot` 组合；分类与其他条件取交集，权限、静音规则和分页继续由原生信息流处理。

只接受一个规范的正整数分类 ID，最大值为 2147483647。前导零、正负号、小数、多个 ID、重复过滤项、已删除或不可见分类都返回空信息流。分类可见性通过 `Category.secured(guardian)` 检查。插件启用时 `/site.json` 提供 `isbf_explore_category_id_filter: true`，关闭时省略此能力字段；客户端应先检查能力，再使用该过滤项。

带引号的空值 `isbf-category:""` 返回空信息流。完全缺少值的 `isbf-category:` 不会被 Core 识别为过滤项，因此不会调用插件；客户端须先校验已选分类 ID，仅生成完整、规范的过滤项。

## 验证

CI 沿用官方 `discourse/.github` 可复用插件 workflow。请求测试覆盖登录及开关、恢复、账号隔离、私密分类与标签、删除、权限变化和恢复、严格参数及数量限制、写入失败和原生通知设置不变。分类过滤测试使用 `slug_generation_method=none`，覆盖精确父子分类、访客/普通用户/staff 权限、无效与重复 ID、标签 OR 交集、原生分页及能力开关；标签数据仅由测试 fixture 创建。

在已经加载插件的 Discourse checkout 中运行：

```sh
LOAD_PLUGINS=1 bundle exec rspec plugins/isbf-explore/spec/requests
bundle exec rubocop plugins/isbf-explore/plugin.rb plugins/isbf-explore/lib plugins/isbf-explore/spec
```

在插件目录安装其轻量 lint 依赖后可运行 `bundle exec rubocop`。本机没有完整 Discourse/Ruby 运行环境，新增请求测试需在既有集成环境执行；源码静态检查不代表接口集成验证。
