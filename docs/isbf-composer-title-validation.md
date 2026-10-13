# ISBF 发布标题校验提示

2026-10-06 用户在生产站新建官方消息，填写校区、分类和时间项后，点击发布没有提示。草稿的标题为 5 个字符，网站配置 `min_topic_title_length=6`；正文和两个时间项均已保存。发布服务在标题校验处返回，没有发出创建消息请求。

主题隐藏了原生标题输入框，使用 `ISBFV2ComposerTitle` 作为可选标题输入框。该组件虽然计算了错误原因，却没有给 `DPopupInputTip` 传递 `lastShownAt`，所以点击发布后错误仍被隐藏。修复注入 composer 服务，使用 `composer.get("lastValidatedAt")` 读取发布校验时间，并传给错误提示。经典 Ember 服务的普通属性需要通过 `get` 建立响应式依赖；直接读取属性不能让 Glimmer 校验 getter 在发布后重新计算。

修复保留站点原有的标题字数校验。标题过短时点击发布会显示当前最小字符数；改成有效标题后提示消失。可选标题留空时继续使用原有内部标题生成规则。

相关源码为 `themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-composer-title.gjs`，回归测试为 `themes/isbf-campus-feed/test/integration/composer-title-test.gjs`。测试调用实际 composer 服务的 `saveAction`，覆盖过短标题的可见提示、修改后的提示清除及空标题兼容性。隔离数据库 `isbf_calendar_ui_20261006` 上的标题、官方消息和日历相关 QUnit 共 46 项、147 个断言通过；两个源码文件通过 `bin/lint --fix`。

生产增量同步和回退脚本、原始主题备份以及实站报告位于 `deploy-work/calendar-publishing-fix-20261006/`。同步只涉及标题组件和新增测试，使用原字段 SHA256 与完整主题快照校验，保留其他字段、设置、组件及其他主题。后端无需重建。

已以提交 `a342c72d270357036377bc61c3a00c8d43872049` 同步到生产默认主题 ID 4，主题 JavaScript digest 为 `3811635bcdcaf65df5a57a987cefd5f9b898dc36`。正式网页复核通过提示显示、标题修改后的提示清除、一次提交请求及其两个时间项的序列化。生产验证使用只读密钥并拦截写请求；开发环境真实提交返回 200，详情页显示两个已保存的时间项，测试消息随后已删除。两端 390 像素布局正常，没有页面脚本错误。
