# 注册与登录动画验证码

用户于2026-10-23提供分格验证码源码，要求覆盖注册和登录并采用网站主题色，确认计划后授权实施；2026-10-24进一步要求创建 PR 并部署到生产站。设计确认限 A13/C08 的验证码输入区域、响应式和反馈，最终视觉验收与实际发布状态分别记录。

核心 UI kit 增加 `DOtp @variant="animated"`，登录与邀请码注册继续共用 `CodeLoginForm`。校友申请的邮箱验证通过 FormKit 使用同一组件；配套修改位于独立的 [校友仓库](https://github.com/ISBF-Lab/ISBF-Alumni/tree/codex/auth-code-slots-20261024)。找回密码等默认 OTP 使用位置继续使用原变体。

填充、焦点和光标使用 tertiary，空槽使用 primary-very-low，数字和勾选使用 secondary，错误使用 danger。六个44×52px槽、8px间距、12px圆角；窄容器等分缩窄，保持单行。保留 numeric / one-time-code 输入、自动填充、粘贴、前导零、键盘编辑及无障碍播报。待验证时锁定操作，拒绝后倒序清空并保留说明，传输失败保留值供重试，成功反馈结束后进入原有下一步。减少动态效果时取消位移及闪烁。

实际源版本及两个仓库的基线见 [source-manifest.json](source-manifest.json)，验证摘要见 [verification-summary.json](verification-summary.json)。独立开发环境中75个用例、356条断言及22项页面/邮箱检查通过，未记录页面脚本错误。覆盖桌面1440px、手机模拟390px与320px、明暗色板、减少动态效果、拒绝重试、邀请注册与校友申请下一步；真实登录使用虚构开发账号和本地邮件收件箱。未进行 Safari/iPhone 实机视觉验收。

上游参考源于用户提供的 [组件源码](https://github.com/DavidHDev/react-bits/tree/main/src/content/Components/CodeSlots)，原始版权及许可保存在 [upstream-LICENSE.md](upstream-LICENSE.md)。该通知随应用源码保留。

生产发布尚未执行。发布须核对运行容器完整插件、隐藏文件、软链接、共享发布标记及活动数据库主题，备份后增量安装；不得以本 PR 的 main 基线整体替换线上文件。开发邮件入口和独立开发配置不属于本次生产发布内容。

2026-10-24审查修复：原生手机键盘完成选区删除后，使用浏览器已编辑的值和光标位置更新槽位，避免选中全部再删除时恢复旧数字。新增反向/正向选区删除及清空回归；核心57个用例、282条断言通过。
