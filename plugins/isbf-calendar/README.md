# ISBF Calendar

Discourse 插件，提供 `/isbf/calendar` 和 `/isbf/workbench` 页面路由，以及仅登录用户本人可访问的个人行程 API。页面视觉和交互由 `ISBF-UI` 主题实现；社区活动读取 Discourse Events 原生接口和话题，不在此插件重复存储。

## API

- `GET /isbf/api/entries.json?from=<ISO8601>&to=<ISO8601>`：当前用户在时间范围内的行程，范围最多 62 天。
- `POST /isbf/api/entries.json`：创建行程。
- `PATCH /isbf/api/entries/:id.json`：更新本人行程。
- `DELETE /isbf/api/entries/:id.json`：删除本人行程。

写入参数置于 `entry` 对象：`title`、`starts_at`、`ends_at`、`all_day`、`note`。时间使用带时区的 ISO 8601 字符串，数据库存 UTC。全天行程的 `ends_at` 为结束日期次日零点（不包含该时刻）。不支持重复、提醒或公开个人行程。

## 部署依赖

先安装本插件并运行迁移，再导入包含日历页面的主题。站点已有 Discourse Events 插件但相关开关尚未启用；启用后应创建仅 staff 可发主题、公众可阅读的“校园活动”分类，将其配置为 Events 分类，并把分类 ID 和路径写入主题设置。活动发布和报名继续由 Discourse Events 控制。
