# 时间轴跳转定位定向检查

用户要求修复跳到第二条帖子时顶部被截断，并明确电脑、手机同步，减少不必要检查。
普通 V2 话题隐藏了 `.d-header`，原生页头服务因此测量到 0px；可见页头实际仍为固定的 60px。
`LockOn.elementTop()` 只减去这个原生 `headerOffset()`，没有让出可见页头所占的高度。

修复复用信息页已有的测量规则：仅在 `.isbf-v2-shell--topic-feed-style` 存在时，
让 `.d-header-wrap` 成为 60px 高、固定定位且不接收指针事件的测量盒。
原生页头服务、帖子定位和阅读位置跟踪共用正确偏移；不新增滚动处理或延迟校正。
尺寸来源为 A01 页头的实际样式，布局和帖子内容保持 A04 的边界。

仅修改 `stylesheets/topic-reading.scss`。`bin/lint --fix`、Prettier、Stylelint 和 SassC 编译通过。
使用一个 512MiB、0.5 CPU、192 进程上限且无网络的工具容器，串行核对 1440×950 和 390×844。
检查脚本使用实际编译的样式及原生 `recalculateHeaderOffset()`、`headerOffset()`、`LockOn` 源码，
页面结构和帖子内容为离线夹具；不声称执行了完整 Ember 应用或生产交互。

[定向结果](verification.json)的八项断言通过：两端第二条帖子顶边均为 60px、短帖底边为 300px，
向上跳转也对齐；高帖从头显示；离开目标话题后测量恢复为 0px。
桌面和手机的离线截图见 [桌面](desktop-second-post.png)、[手机](mobile-second-post.png)。
高于可用视口的帖子仍需滚动阅读，修复保证其开头不被页头遮挡。

实际代码和原生依赖的摘要、快照见 [源码 manifest](source-manifest.json) 与 `sources/`。
没有运行完整论坛、全量回归或额外生产浏览器；最终桌面与手机视觉验收由用户完成，仍待确认。
