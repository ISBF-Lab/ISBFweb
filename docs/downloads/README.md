# 前端设计规范离线阅读包

[下载 ZIP](isbf-design-system-review-20261011.zip)，解压整个压缩包后双击 `index.html`，即可在浏览器中离线阅读，无需启动项目或安装依赖。在 GitHub 文件页可点击 Download raw file 下载。

包内包含四份设计规范、72 份源码参考、12 份验收及复用边界摘录、Agent 指令，以及文档直接引用的工程和 Legacy 上下文。原始路径和参考源码字节保留，`read/` 是生成的 HTML 阅读副本；`AGENTS.md` 与 `AI-AGENTS.md` 在包内保存为普通文件，项目中的符号链接保持不变。

主题基线为 2026-10-10 已验收主题 ID 4，认证组件采用 2026-10-11 的已验收补充。Approved 范围以 `docs/design-system/ui-status.md` 为准；补充上下文和离线阅读器外观不构成新的设计标准。该包供审阅，不是完整项目或可安装主题。

[ZIP 的 SHA-256 摘要](isbf-design-system-review-20261011.zip.sha256) 用于下载后校验。包内 `SHA256SUMS.txt` 列出文件摘要，`PACKAGE-MANIFEST.json` 记录来源；如已安装 Python 3，可运行 `python verify-package.py` 校验解压文件，打开阅读入口不需要 Python。

## 2026-10-12 前台改造审核包 V2

[下载新版 ZIP](isbf-frontend-review-20261012-v2.zip)，解压完整文件夹后双击 `INDEX.html`。
内含19组页面清单、实现说明、四份设计规范、实际主题源码、验证记录，以及8类离线代表预览。
真实页面测试截图单独标注 GitHub Actions、合成数据及实际源码版本，不是生产截图。
用户卡样例已移除；个人资料上部和一级导航、公开活动预览保留，后台排除。
未合并、未部署，实际页面仍为 In Progress，等待人工视觉验收。

[新版 SHA-256 摘要](isbf-frontend-review-20261012-v2.zip.sha256)供下载后校验。
包内 `CHECKSUMS.json`记录文件摘要，可选运行 `python3 verify-package.py`校验解压内容。
历史包继续保留；其用户卡样例不能扩大本次批准范围。

## 2026-10-13 四处截图修复

[下载修复包](isbf-frontend-fixes-20261013.zip)，完整解压后打开INDEX.html。
包含私信、账号设置、书签、草稿的16张桌面/手机和明/暗原始截图、来源摘要、修复记录及局部样式。
受测源码7008a3662fbcebebf2e9dd9469a75e280cfbeed5；原生1043项、主题89项、真实页面48例全部通过。
截图来自独立CI测试库及合成数据；不是生产截图，也不扩展Approved范围。
生产发布仍等待必要生产操作的明确确认。
[SHA-256摘要](isbf-frontend-fixes-20261013.zip.sha256)可校验下载文件。
