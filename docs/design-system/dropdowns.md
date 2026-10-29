# 全站下拉菜单契约

2026-10-26：用户验收校区样板，明确要求覆盖前台、登录注册、后台与活动插件，
保留不同用途的入口形态，手机统一就地浮动，并提供展开面板的大圆角参考。
本契约取代各业务的菜单外观定义；参考与实际验证见
[本轮记录](reviews/dropdowns-20261026/README.md)。批准范围为菜单，不扩展整页设计。

## 组件选用

| 用途 | 统一入口 |
| --- | --- |
| 表单单选 | FormKit的select控件，默认使用DSelect |
| 独立单选／有限多选 | `discourse/ui-kit/d-select`；保留Option块及原生option／optgroup兼容 |
| 搜索、远程数据及专用业务选择器 | 现有ComboBox／SelectKit或DMultiSelect，共享默认菜单表面 |
| 三点、账号、筛选和导航动作 | DMenu＋DDropdownMenu，动作使用DButton，导航使用链接 |
| 兼容原有DNativeSelect调用 | 导出已转接DSelect；新代码使用DSelect或FormKit |
| 日历、二维色盘、信息面板 | DMenu显式使用`@surface="popover"`，并在检查器登记用途 |

组件、插件和主题从核心UI kit导入，不导入活动主题内部组件。
DMenu默认`surface="menu"`，不需要业务开关。所有列表菜单在手机使用浮动面板。

```gjs
import DSelect from "discourse/ui-kit/d-select";

<template>
  <DSelect @value={{@value}} @onChange={{@onChange}} as |select|>
    {{#each @options as |option|}}
      <select.Option @value={{option.value}}>{{option.label}}</select.Option>
    {{/each}}
  </DSelect>
</template>
```

真实表单优先用FormKit管理标签、校验、禁用、错误和提交。
DSelect保留原生值载体，支持name、form、required、disabled、空值、动态选项与FormData。
单选延续字符串／null回调；多选回调为字符串数组。旧原生事件适配可使用`@onInput`，
事件目标仍是原生select；可见入口是有标签关联的按钮。底层载体不是另一套可见菜单。
载体同时保留`hidden`属性与核心`hidden`工具类，避免业务表单的display规则将其重新显示；
隐藏不影响原有值、校验与FormData提交。

## 唯一外观来源

活动主题的`stylesheets/dropdowns.scss`集中定义`--d-menu-*`变量，核心提供结构、状态和动效。

| 属性 | 当前统一规则 |
| --- | --- |
| 面板／选项圆角 | 24px／16px |
| 面板内边距 | 8px，保持内外同心 |
| 文字 | 站点字体，15px／600；说明与标签保留次级文字层级 |
| 选项尺寸 | 最小44px，长内容按需要增高 |
| 配色 | secondary表面、primary文字、primary-low边框、primary-very-low高亮、tertiary勾号 |
| 边框与阴影 | 1px边框；既有isbf-v2-shadow-menu |
| 动效 | 180ms展开、120ms退出、220ms鼠标高亮滑动 |
| 可用高度 | 不超过55dvh，同时服从视口和所在弹窗剩余空间 |

保留表单字段、筛选按钮、头像和三点按钮的入口形态。业务只调整必要的宽度、排列和内容，
不另外定义菜单圆角、阴影或开合动画。危险动作继续使用danger语义。

## 行为与可访问性

- `d-menu-highlight`只呈现光标，不选择、不触发请求、不移动焦点。现有导航引擎负责键盘和搜索。
- DDropdownMenu默认提供方向键导航；已有专用导航的调用者使用`@manageFocus={{false}}`，保留单一键盘处理入口。
- 选项用`aria-selected`／`aria-checked`表达选值；操作菜单没有虚构选中项。禁用项不可激活。
- 每次打开从当前值开始，鼠标离开保留本次位置；键盘、外部值与尺寸变化直接定位。
- 单选选择后关闭，多选连续选择。搜索不提交字段值；搜索栏、标题、分隔线和底部区域不参与高亮。
- 保留Escape、Tab、方向键、Home／End及文字查找的适用语义；搜索输入保持焦点。
- 浮层按视口、软键盘和所在弹窗正文限制宽高，可上下翻转，长列表保留正常触控滚动。SelectKit的选项集合独立滚动且高亮同步随行，向上菜单固定面板下沿以适应结果高度变化；搜索栏不随列表滚动，手机搜索输入复用font-md（当前16px）；面板裁剪溢出，高度同时服从55dvh及当前可用空间。[手机分类选择回归](reviews/composer-category-mobile-20261029/README.md)。
- 嵌套浮层属于父菜单的交互范围，选择子菜单不会误关父菜单。Escape每次只关闭最内层浮层，保留父菜单及表单草稿；再次按下才关闭父菜单。
- 鼠标悬停关闭不移动现有焦点；Escape仍恢复入口焦点。销毁清理监听、观察器和待执行帧。
- 减少动态效果时取消菜单和高亮运动。颜色之外仍有勾号或ARIA状态。

## 检查与交付

修改菜单后执行定向`bin/lint --fix`、`pnpm test:menus`及`pnpm lint:menus`。
涉及字段值的回归从`discourse/tests/helpers/d-select`导入`select`，可同时定位共享入口与原生字段；
`findSelect`及`assert.dnativeselect`读取实际提交值载体，保留筛选、分组、禁用与权限断言。
鼠标和键盘交互继续通过共享选择器的组件及真实页面测试验证。
规则已接入提交检查与CI；检查当前核心、插件和活动主题。在独立PR仓库中检查
`themes/isbf-campus-feed`交付源；迁移工作区优先检查`external/active-theme`，不把历史稿件当作运行源码。
受控原生载体和非菜单浮层是已登记的工程用途，不能用于规避菜单标准。

按类型验证单选、多选、搜索、禁用、动态更新、真实提交、权限与失败重试；
覆盖电脑及320／390px手机的明暗、长内容、滚动、嵌套、键盘和减少动态效果。
新增核心模块后如开发构建提示未导出，按开发文档刷新模块发现清单。
测试与发布使用独立开发环境；迁移清单继续保留捕获时的证据。
