# AI 自动审核验证记录

2026-10-18：审核插件完整回归 **65 examples, 0 failures**，随机种子 `38025`。
覆盖新审核设置、群组豁免及匿名作者、图片开关、结构化响应校验、失败重试、过期结果、
分类移动、事务回滚、人工恢复、正文接口保护，以及原有严重举报与并发保护。
上线连接检查发现服务商不接受 JSON schema 后，新增 HTTP 边界回归，
验证兼容 JSON 模式的正常、缺字段和命中结论，服务器仍严格校验后再执行隐藏。

`bin/lint --fix` 对全部修改过的 Ruby 文件运行通过；补充分类移动后又对两份实际改动文件运行通过。
兼容修复完成后，对分类器及其测试再次执行通过。
新增站点设置及中英文 YAML 在真实 Rails 测试启动中加载成功。
结果和资源数据见 `verification.json`、`executions.jsonl`、`rspec.log`。

## 复现

有完整开发依赖的环境直接运行：

```bash
LOAD_PLUGINS=1 bin/rspec plugins/isbf-moderation/spec
```

本共享主机没有宿主机 Ruby，验证使用缓存镜像
`local_discourse/isbf_app:reply-regressions-20261016-da29b7352452`。
镜像自带的生产依赖加上锁定测试包构成专用缓存，不修改系统或生产镜像。

```bash
python3 docs/ai-moderation-verification/run-tool.py \
  local_discourse/isbf_app:reply-regressions-20261016-da29b7352452 \
  bash /review/check-dependencies.sh

python3 docs/ai-moderation-verification/cache-test-gems.py

python3 docs/ai-moderation-verification/run-tool.py \
  local_discourse/isbf_app:reply-regressions-20261016-da29b7352452 \
  bash /review/install-test-gems.sh

python3 docs/ai-moderation-verification/run-tool.py \
  local_discourse/isbf_app:reply-regressions-20261016-da29b7352452 \
  bash /review/run-specs.sh plugins/isbf-moderation/spec
```

缺失包下载在宿主机完成，来源为官方 RubyGems，逐包验证 `Gemfile.lock` 的 SHA-256；
容器始终无网络。实际补齐 38 个锁定测试依赖，存放于忽略提交的
`deploy-work/ai-moderation-20261018/`。复现前需同版本的镜像缓存及源代码依赖。

`run-tool.py --lint IMAGE bash /review/lint.sh FILE...` 在同一隔离约束下调用 `bin/lint --fix`。
仅 lint 模式允许审核插件源码挂载可写，并临时开放指定文件的组写权限，退出时恢复原权限。
测试模式源代码挂载只读；临时目录复制 Ruby 源码以保持唯一加载路径，静态依赖仍只读引用，
不复制 `node_modules`。临时 PostgreSQL 与 Redis 仅通过容器内 Unix socket 工作。

## 资源和边界

- 每次按实时 `MemAvailable`、有效 cgroup 余量减至少 512MiB 服务余量计算内存上限；
  内存与内存加交换上限相同，0.5 CPU、192 PIDs，串行运行单容器。
- 最终启动可用容量 1,515,945,984 字节，服务余量 536,870,912 字节，
  容器上限 939,524,096 字节，运行峰值 939,524,096 字节，无 OOM。
- 最终完整运行 200.60 秒，容器退出后移除。未启动完整论坛预览，不连接生产数据库或 Redis，
  不读取线上模型密钥，不向真实用户发送消息，不改变线上开关。
- 模型响应采用 Discourse AI 预置响应和外部 HTTP stub 边界。真实模型的中文分类质量、实际视觉能力和
  后台页面视觉核验未在本次离线验证中完成；启用前应在获准的隔离环境用脱敏样本检查。
- 日志里的 Git 版本探测与 hostname 警告来自离线临时目录；RSpec 实际退出码为 0。

代码默认主开关关闭；本次线上启用值见[发布记录](../ai-moderation-deployment-20261018/README.md)，
使用说明见[配置文档](../ai-post-moderation-setup.md)。
今后修改审核规则时，应同步增加 `AiClassifier::RULES_VERSION`，让缓存结论失效。
