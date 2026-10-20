# 通知菜单宽度与账号筛选记忆 · 2026-10-19

用户查看前次`1280-dark-menu.png`后要求收窄菜单，并明确选择让“只看未读”跟随账号记忆，随后确认实施方案。
此次仅修订A05/C06/C18/C19的通知菜单与筛选恢复；最终视觉待用户核验，尚未上线。

## 确认规则与实现

- 菜单移除190px最小宽度，按最长一行内容确定宽度，沿逻辑方向与三点触发器末端对齐。
  最大宽度为视口减两侧space-4；继续使用8px内距、1px边框、radius-sm及现有阴影。
  账号偏好保存错误复用已有文字及内距，按菜单宽度换行，不参与面板固有宽度计算。
- 新私有账号字段`isbf_notification_filter`只接受`all`或`unread`，未设置时为`all`。
  复用原生用户更新接口和当前用户序列化，不新增表、迁移或独立设置接口；公开资料不暴露该字段。
- 页面首次请求直接使用当前用户已保存的选择。“全部”和“提及”共用该偏好，详情及分页继续携带筛选。
  开启与关闭均保存；刷新、重新登录或在其他设备打开时恢复上次成功保存的值。
  已打开的其他设备不推送实时偏好更新，重新打开站点或刷新时读取最新账号值。
- 保存中开关禁用，保存成功才更新开关和列表；失败保持原状态，并提供翻译后的错误及重试。
  重试先将焦点留在稳定的菜单触发器，避免错误控件移除后丢失Escape操作。
  服务负责保存并发出`isbf:notification-filter-changed`，当前挂载的通知组件重置分页并重新请求，
  离开的组件取消订阅；保存跨越页面组件的销毁与重建时，当前组件仍能收到结果。
- 角标显示方式与筛选分别保存；保留原有未读点、整行主链接、原生标读、独立展开及权限规则。

## 来源和复现

`before-manifest.json`及`before/`保存本轮变更前的11份文件，避免覆盖共享工作区的其他变更。
最终实际源码及测试的非执行副本见`source-manifest.json`，本轮差异见`implementation.patch`。
设计确认只限上述通知区域；历史参考和前次发布的源码附件保持原样。

```bash
python3 docs/design-system/reviews/notifications-menu-memory-20261019/run-tool.py node /review/run-lint.cjs
python3 docs/design-system/reviews/notifications-menu-memory-20261019/run-tool.py node /review/compile.cjs
python3 docs/design-system/reviews/notifications-menu-memory-20261019/run-tool.py ruby /review/compile-style.rb
python3 docs/design-system/reviews/notifications-menu-memory-20261019/run-tool.py node /review/compile-browser.cjs
python3 docs/design-system/reviews/notifications-menu-memory-20261019/run-tool.py python3 /review/check-browser.py layout
python3 docs/design-system/reviews/notifications-menu-memory-20261019/run-tool.py python3 /review/check-browser.py memory
python3 docs/design-system/reviews/notifications-menu-memory-20261019/run-tool.py python3 /review/check-browser.py regression
ISBF_NOTIFICATIONS_SPEC_RUNNER=1 python3 docs/design-system/reviews/notifications-menu-memory-20261019/run-tool.py python3 /review/check-tests.py
```

工具复用已有缓存Ember客户端，编译并安装本轮实际主题模块、完整公共SCSS、色板及翻译。
浏览器通过同一隔离工具内的合成HTTP接口保存夹具账号，不连接生产测试后端。
它能验证实际客户端的保存、恢复及交互，但不替代Rails数据库存储和权限请求测试。
缓存适配及原生通知点击检查复用前次审阅脚本，保留其来源摘要。
缓存CSS中的旧通知菜单根规则在离线适配器中移除，由本轮完整编译SCSS提供实际宽度和定位；
该适配不写入产品源码，历史缓存及参考附件不修改。

每次运行按实时`MemAvailable`及有效cgroup剩余额度，扣除至少512MiB服务余量后设置内存上限；
内存加交换总量相同，单个无网络容器、0.5CPU、192进程，单浏览器和单页面串行检查。
完整预览论坛保持停止，不调整其他服务。每次预算、峰值、最低服务余量及退出状态见`tool-executions.jsonl`。
离线静态资源使用浏览器缓存，动态账号与通知接口使用`no-store`；无网络容器及拒绝外部域名解析
共同限制浏览器的请求范围。各次浏览器脚本的实际版本保存在`harness-snapshots/`。

## 验证记录

最终结果汇总于`verification-summary.json`，包括定向lint、源码编译、菜单几何、账号恢复交互、
整行点击回归和原生测试的实际执行状态。尚未执行或因环境缺失未执行的测试不计作通过。

| 预览 | 浅色 | 深色 |
| --- | --- | --- |
| 电脑1280px | [菜单](1280-light-menu.png) | [菜单](1280-dark-menu.png) |
| 手机390px | [菜单](390-light-menu.png) | [菜单](390-dark-menu.png) |

原图为[前次1280px深色菜单](../notifications-layout-20261018/1280-dark-menu.png)。

后续发布须先让后端字段注册及序列化生效，再发布依赖该字段的主题；按现有增量发布流程核对
完整插件、活动数据库主题及独立备份，保留其他已发布功能和业务数据。

## 最终验证结果

- 实际来源版本`01242893e94754ad6ac27c90cc5689e9db260da417a44c9dae76730ab023e6b6`，保存18份源码及测试附件；编译输入摘要与最终工作区一致。
- 定向`bin/lint --fix`通过ESLint、Prettier、Stylelint、RuboCop和Syntax Tree；重试焦点修复后再次通过受影响文件的lint。
  只读`.git`使钩子自动同步被跳过，实际源码检查全部通过，仓库钩子及CI门禁未改动。
- 10份JavaScript/Glimmer源码及测试编译通过，完整公共SCSS及导入、明暗色板和中英文翻译编译/解析通过。
- 三个完成的离线客户端阶段共89项断言通过，包含8组菜单布局、账号选择的保存/失败/重试/刷新/新手机客户端/账号切换/空态/旧请求竞态，以及两端原生整行点击、键盘与角标偏好。
- 原生RSpec和QUnit的实际执行状态见`native-test-attempts.json`；本机缺少Ruby测试依赖及隔离Rails测试服务，执行0项，不计作通过。新增请求及组件测试保存供完整测试环境运行。
- 早期资源时限、RTL夹具上下文及重试焦点问题保留于`attempts/`和工具记录；最终阶段全部重跑通过。
  浏览器报告中的500来自合成保存失败，外部域名由离线规则阻止；没有JavaScript运行异常或缺失本地脚本/样式。
- 工具容器已移除，完整预览论坛保持停止；仅完成实现及本地验证，尚未上线。

2026-10-19验证后已按用户授权[上线](../../deployments/notifications-menu-memory-20261019/README.md)。本目录保留发布前离线证据，实际线上合并源和状态见发布记录。
